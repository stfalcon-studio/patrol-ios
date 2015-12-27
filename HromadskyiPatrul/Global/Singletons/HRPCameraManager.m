//
//  HRPCameraManager.m
//  HromadskyiPatrul
//
//  Created by msm72 on 12.12.15.
//  Copyright © 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPCameraManager.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "HRPVideoRecordView.h"
#import "HRPPhoto.h"


@implementation HRPCameraManager {
//    AVCaptureVideoOrientation _videoOrientation;
    AVAudioRecorder *_audioRecorder;
    AVAudioPlayer *_audioPlayer;
    AVAudioSession *_audioSession;
    AVMutableComposition *_composition;
    CLLocation *_location;
    HRPCameraManagerSetupResult _setupResult;
    UILabel *_timerLabel;

    NSArray *_audioFilesNames;
    NSDictionary *_audioRecordSettings;
    NSString *_arrayPath;
    NSMutableArray *_photosDataSource;
    NSURL *_videoAssetURL;
    UIImage *_videoImageOriginal;
    CGRect _previewRect;
    
    NSInteger _sessionDuration;
    NSInteger _timerSeconds;
    NSInteger _snippetNumber;
}

#pragma mark - Constructors -
+ (HRPCameraManager *)sharedManager {
    static HRPCameraManager *singletonManager           =   nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        singletonManager                                =   [[HRPCameraManager alloc] init];
    });
    
    return singletonManager;
}

- (instancetype)init {
    self                                                =   [super init];
    
    if (self) {
        // App Folder
        _mediaFolderPath                                =   [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        
        // Saved user data
        _userApp                                        =   [NSUserDefaults standardUserDefaults];
        
        [self createStoreDataPath];
        
#warning DELETE IN RELEASE - READ ONLY FOR CHECK
        [self readPhotosCollectionFromFile];
        
        // Set Media session parameters
        _snippetNumber          =   0;
        _isVideoSaving          =   NO;
        _videoFilesNames        =   @[@"snippet_video_0.mp4", @"snippet_video_1.mp4", @"snippet_video_2.mp4"];
        _audioFilesNames        =   @[@"snippet_audio_0.caf", @"snippet_audio_1.caf", @"snippet_audio_2.caf"];
        
        _audioRecordSettings    =   [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithInt:kAudioFormatLinearPCM],     AVFormatIDKey,
                                     [NSNumber numberWithInt:AVAudioQualityMax],         AVEncoderAudioQualityKey,
                                     [NSNumber numberWithInt:32],                        AVEncoderBitRateKey,
                                     [NSNumber numberWithInt:2],                         AVNumberOfChannelsKey,
                                     [NSNumber numberWithFloat:44100.f],                 AVSampleRateKey, nil];
        
        // [self deleteFolder];
        
        _locationManager                                    =   [[CLLocationManager alloc] init];
        _locationManager.delegate                           =   self;
        _locationManager.desiredAccuracy                    =   kCLLocationAccuracyBest;
        
        [_locationManager startUpdatingLocation];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handlerVideoSessionStopRecording:)
                                                     name:@"videoSessionStopRecording"
                                                   object:nil];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - NSNotification -
- (void)handlerVideoSessionStopRecording:(NSNotification *)notification {
    // Stop Video & Audio recording
    [self stopVideoRecording];
}


#pragma mark - Timer Methods -
- (void)createTimerWithLabel:(UILabel *)label {
    _timerSeconds           =   0;
    _sessionDuration        =   5;
    _timerLabel             =   label;
    _timerLabel.text        =   [self formattedTime:_timerSeconds];    
    
    _timer                  =   [NSTimer scheduledTimerWithTimeInterval:1.f
                                                                 target:self
                                                               selector:@selector(timerTicked:)
                                                               userInfo:nil
                                                                repeats:YES];
}

- (void)timerTicked:(NSTimer *)timer {
    _timerSeconds++;
    
    if (_timerSeconds == _sessionDuration) {
        if (_videoSessionMode == NSTimerVideoSessionModeStream)
            _timerSeconds   =   0;
        
        else {
            [_timer invalidate];
            _timerSeconds   =   0;
        }

        // Stop Video & Audio recording
        [self stopVideoRecording];
    }
    
    _timerLabel.text        =   [self formattedTime:_timerSeconds];
}

- (NSString *)formattedTime:(NSInteger)secondsTotal {
    NSInteger seconds       =   secondsTotal % 60;
    NSInteger minutes       =   (secondsTotal / 60) % 60;
    NSInteger hours         =   secondsTotal / 3600;
    
    return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
}


#pragma mark - Methods -
- (void)createCaptureSession {
    NSError *error;
    
    // Initialize the Session object
    _captureSession                                     =   [[AVCaptureSession alloc] init];
    _captureSession.sessionPreset                       =   AVCaptureSessionPresetHigh;
    
    // Initialize a Camera object
    AVCaptureDevice *videoDevice                        =   [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *videoInput                    =   [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    _videoConnection                                    =   [_videoFileOutput connectionWithMediaType:AVMediaTypeVideo];
    
    AVCaptureVideoStabilizationMode stabilizationMode   =   AVCaptureVideoStabilizationModeCinematic;
    
    if ([videoDevice.activeFormat isVideoStabilizationModeSupported:stabilizationMode])
        [_videoConnection setPreferredVideoStabilizationMode:stabilizationMode];
    
    [_captureSession addInput:videoInput];
    
    // Configure the audio session
    AVAudioSession *audioSession                        =   [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive:YES error:nil];
    
    // Find the desired input port
    NSArray *inputs                                     =   [audioSession availableInputs];
    AVAudioSessionPortDescription *builtInMic           =   nil;
    
    for (AVAudioSessionPortDescription *port in inputs) {
        if ([port.portType isEqualToString:AVAudioSessionPortBuiltInMic]) {
            builtInMic                                  =   port;
           
            break;
        }
    }
    
    // Find the desired microphone
    for (AVAudioSessionDataSourceDescription *source in builtInMic.dataSources) {
        if ([source.orientation isEqual:AVAudioSessionOrientationFront]) {
            [builtInMic setPreferredDataSource:source error:nil];
            [audioSession setPreferredInput:builtInMic error:&error];
           
            break;
        }
    }
    
    // VIDEO
    // Add output file
    _videoFileOutput                                    =   [[AVCaptureMovieFileOutput alloc] init];
    _videoConnection                                    =   nil;
    
    for (AVCaptureConnection *connection in _videoFileOutput.connections) {
        NSLog(@"%@", connection);
        
        for ( AVCaptureInputPort *port in connection.inputPorts) {
            NSLog(@"%@", port);
            if ([port.mediaType isEqual:AVMediaTypeVideo])
                _videoConnection                        =   connection;
        }
    }
    
    //[_videoConnection setVideoOrientation:[self getVideoOrientation]];
    
    if ([_captureSession canAddOutput:_videoFileOutput])
        [_captureSession addOutput:_videoFileOutput];
}

//- (void)createVideoPreviewLayer:(AVCaptureVideoPreviewLayer *)videoPreviewLayer {
//    _videoPreviewLayer                                  =   videoPreviewLayer;
//    _videoPreviewLayer.connection.videoOrientation      =   self.videoOrientation;
//}

- (void)startStreamVideoRecording {
    if ([_videoConnection isVideoOrientationSupported])
        [self setVideoSessionOrientation];

    [self startAudioRecording];
    
    [_videoFileOutput startRecordingToOutputFileURL:[self setNewVideoFileURL:_snippetNumber]
                                  recordingDelegate:self];
}

- (void)startAttentionVideoRecording {
    // Stop video capture and make the capture session object nil
    _timerSeconds       =   0;
    
    // Stop Video & Audio recording
    [self stopVideoRecording];
}

- (void)startAudioRecording {
    if (!_audioRecorder.recording) {
        [self setNewAudioRecorder];
        
        [_audioRecorder record];
    }
}

- (void)restartStreamVideoRecording {
    _timerSeconds       =   0;
    _snippetNumber      =   1;

    // Stop Video & Audio recording
    [self stopVideoRecording];
}

- (void)stopVideoSession {
    [_captureSession stopRunning];

    // Stop Video & Audio recording
    [self stopVideoRecording];
    
    // Stop Location service
    [_locationManager stopUpdatingLocation];
    
    // Stop Timer
    [_timer invalidate];
    
    _videoPreviewLayer  =   nil;
    _captureSession     =   nil;
    _videoSessionMode   =   NSTimerVideoSessionModeDismissed;
}

- (void)stopVideoRecording {
    [self stopAudioRecording];
    [_videoFileOutput stopRecording];
}

- (void)stopAudioRecording {
    if (_audioRecorder.recording)
        [_audioRecorder stop];
}

- (NSURL *)setNewVideoFileURL:(NSInteger)count {
    NSString *videoFilePath     =   [_mediaFolderPath stringByAppendingPathComponent:_videoFilesNames[count]];
    NSURL *videoFileURL         =   [NSURL fileURLWithPath:videoFilePath];
    
    return videoFileURL;
}

- (NSURL *)setNewAudioFileURL:(NSInteger)count {
    NSString *audioFilePath     =   [_mediaFolderPath stringByAppendingPathComponent:_audioFilesNames[count]];
    NSURL *audioFileURL         =   [NSURL fileURLWithPath:audioFilePath];
    
    return audioFileURL;
}

- (void)setNewAudioRecorder {
    NSError *error              =   nil;
    _audioSession               =   [AVAudioSession sharedInstance];
    
    [_audioSession setCategory:AVAudioSessionCategoryRecord error:nil];
    [_audioSession setActive:YES withOptions:0 error:nil];
    
    _audioRecorder              =   [[AVAudioRecorder alloc] initWithURL:[self setNewAudioFileURL:_snippetNumber]
                                                                settings:_audioRecordSettings
                                                                   error:&error];
    
    if (error)
        [self showAlertViewWithTitle:NSLocalizedString(@"Alert error API title", nil)
                          andMessage:[error localizedDescription]];
    
    else
        [_audioRecorder prepareToRecord];
}

- (void)setVideoPreviewLayerOrientation:(CGSize)newSize {
    _videoPreviewLayer.frame    =   CGRectMake(0.f, 0.f, newSize.width, newSize.height);
    _videoConnection            =   _videoPreviewLayer.connection;
    
    if ([_videoConnection isVideoOrientationSupported])
        [_videoConnection setVideoOrientation:[self getVideoOrientation]];
}

- (void)setVideoSessionOrientation {
    AVCaptureVideoOrientation videoOrientation  =   AVCaptureVideoOrientationPortraitUpsideDown;
    UIDeviceOrientation deviceOrientation       =   [[UIDevice currentDevice] orientation];
    
    switch (deviceOrientation) {
        case UIInterfaceOrientationPortrait:
            videoOrientation                    =   AVCaptureVideoOrientationPortrait;
            break;
            
        case UIInterfaceOrientationPortraitUpsideDown:
            videoOrientation                    =   AVCaptureVideoOrientationPortraitUpsideDown;
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
            videoOrientation                    =   AVCaptureVideoOrientationLandscapeLeft;
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            videoOrientation                    =   AVCaptureVideoOrientationLandscapeRight;
            break;
            
        default:
            videoOrientation                    =   AVCaptureVideoOrientationPortrait;
            break;
    }
    
    [_videoPreviewLayer.connection setVideoOrientation:videoOrientation];
    [[_videoFileOutput connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:videoOrientation];
}

- (void)setPreviewLayerVideoOrientation:(UIInterfaceOrientation)interfaceOrientation {
    //UIInterfaceOrientation cameraOrientation            =   [[UIApplication sharedApplication] statusBarOrientation];
    AVCaptureConnection *previewLayerConnection         =   _videoPreviewLayer.connection;
    
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortrait: {
            [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
            
            [[_videoFileOutput connectionWithMediaType:AVMediaTypeVideo]
                                   setVideoOrientation:AVCaptureVideoOrientationPortrait];
        }
            break;
            
        case UIInterfaceOrientationPortraitUpsideDown: {
            [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown];

            [[_videoFileOutput connectionWithMediaType:AVMediaTypeVideo]
                                   setVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
        }
            break;
    
        case UIInterfaceOrientationLandscapeLeft: {
            [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
            
            [[_videoFileOutput connectionWithMediaType:AVMediaTypeVideo]
                                   setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
        }
            break;
            
        case UIInterfaceOrientationLandscapeRight: {
            [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];

            [[_videoFileOutput connectionWithMediaType:AVMediaTypeVideo]
                                   setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
        }
            break;
            
        default: {
            [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
            
            [[_videoFileOutput connectionWithMediaType:AVMediaTypeVideo]
                                   setVideoOrientation:AVCaptureVideoOrientationPortrait];
        }
            break;
    }
}

- (void)setNextSnippetNumber {
    if (_videoSessionMode == NSTimerVideoSessionModeStream)
        _snippetNumber      =   !_snippetNumber;
    
    else if (_videoSessionMode == NSTimerVideoSessionModeAttention)
        ++_snippetNumber;
}

- (AVCaptureVideoOrientation)getVideoOrientation {
    AVCaptureVideoOrientation videoOrientation          =   AVCaptureVideoOrientationPortraitUpsideDown;
    UIDeviceOrientation deviceOrientation               =   [[UIDevice currentDevice] orientation];
    
    switch (deviceOrientation) {
        case UIInterfaceOrientationPortrait: {
            videoOrientation                            =   AVCaptureVideoOrientationPortrait;
            
            [[_videoFileOutput connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:videoOrientation];
        }
            break;
            
        case UIInterfaceOrientationPortraitUpsideDown: {
            videoOrientation                            =   AVCaptureVideoOrientationLandscapeLeft;
            
            [[_videoFileOutput connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:videoOrientation];
        }
            break;
            
        case UIInterfaceOrientationLandscapeLeft: {
            videoOrientation                            =   AVCaptureVideoOrientationLandscapeLeft;

            [[_videoFileOutput connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:videoOrientation];
        }
            break;
            
        case UIInterfaceOrientationLandscapeRight: {
            videoOrientation                            =   AVCaptureVideoOrientationLandscapeLeft;
            
            [[_videoFileOutput connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:videoOrientation];
        }
            break;

        default: {
            videoOrientation                            =   AVCaptureVideoOrientationLandscapeLeft;
            
            [[_videoFileOutput connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:videoOrientation];
        }
            break;
    }
    
    return videoOrientation;
}

- (void)createStoreDataPath {
    NSError *error;
    NSArray *paths              =   NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    _arrayPath                  =   paths[0]; // [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Photos"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:_arrayPath]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:_arrayPath
                                       withIntermediateDirectories:NO
                                                        attributes:nil
                                                             error:&error])
            NSLog(@"Create directory error: %@", error);
    }
}

- (void)deleteFolder {
    if ([[NSFileManager defaultManager] removeItemAtPath:_mediaFolderPath error:nil])
        NSLog(@"HRPVideoRecordViewController (352): DELETE");
    
    else
        NSLog(@"HRPVideoRecordViewController (354): NOT DELETE");
}

- (void)readAllFolderFile {
    NSArray *allFolderFiles     =   [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_mediaFolderPath error:nil];
    
    NSLog(@"HRPVideoRecordViewController (335): FOLDER FILES = %@", allFolderFiles);
}


- (void)readPhotosCollectionFromFile {
    NSArray *paths              =   NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    _arrayPath                  =   paths[0];
    // [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Photos"];
    _arrayPath                  =   [_arrayPath stringByAppendingPathComponent:[_userApp objectForKey:@"userAppEmail"]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:_arrayPath]) {
        NSData *arrayData       =   [[NSData alloc] initWithContentsOfFile:_arrayPath];
        _photosDataSource       =   [NSMutableArray array];
        
        if (arrayData)
            _photosDataSource   =   [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithData:arrayData]];
        else
            NSLog(@"File does not exist");
    }
}

- (void)removeAllFolderMediaTempFiles {
    NSArray *allFolderFiles     =   [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_mediaFolderPath error:nil];
    _videoImageOriginal         =   nil;
    _snippetNumber              =   0;
    
    for (NSString *fileName in allFolderFiles) {
        if ([fileName containsString:@"snippet_"] ||
            [fileName containsString:@"attention_video"])
            [[NSFileManager defaultManager] removeItemAtPath:[_mediaFolderPath stringByAppendingPathComponent:fileName] error:nil];
    }    
}

- (void)removeMediaSnippets {
    NSArray *allFolderFiles     =   [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_mediaFolderPath error:nil];
    
    for (NSString *fileName in allFolderFiles) {
        if ([fileName containsString:@"snippet_video_1.mp4"] ||
            [fileName containsString:@"snippet_audio_1.caf"])
            [[NSFileManager defaultManager] removeItemAtPath:[_mediaFolderPath stringByAppendingPathComponent:fileName] error:nil];
    }
}

- (NSInteger)countVideoSnippets {
    NSArray *allFolderFiles     =   [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_mediaFolderPath error:nil];
    NSPredicate *predicate      =   [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", @"snippet"];
    
    NSLog(@"HRPVideoRecordViewController (323): COUNT = %ld", (long)[[allFolderFiles filteredArrayUsingPredicate:predicate] count]);
    
    return [[allFolderFiles filteredArrayUsingPredicate:predicate] count];
}

- (void)mergeAndSaveVideoFile {
    // Create the AVMutable composition to add tracks
    _composition                =   [AVMutableComposition composition];
    
    // Create the mutable composition track with video media type
    [self mergeAudioAndVideoFiles];
    
    // Create the export session to merge and save the video
    AVAssetExportSession *videoExportSession            =   [[AVAssetExportSession alloc] initWithAsset:_composition
                                                                                             presetName:AVAssetExportPresetHighestQuality];
    
    NSString *videoFileName                             =   @"attention_video.mov";
    
    NSURL *videoURL                                     =   [[NSURL alloc] initFileURLWithPath:
                                                             [_mediaFolderPath stringByAppendingPathComponent:videoFileName]];
    
    videoExportSession.outputURL                        =   videoURL;
    videoExportSession.outputFileType                   =   @"com.apple.quicktime-movie";
    videoExportSession.shouldOptimizeForNetworkUse      =   YES;
    
    [videoExportSession exportAsynchronouslyWithCompletionHandler:^{
        switch (videoExportSession.status) {
            case AVAssetExportSessionStatusFailed:
                NSLog(@"HRPVideoRecordViewController (449): Failed to export video");
                break;
                
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"HRPVideoRecordViewController (453): export cancelled");
                break;
                
            case AVAssetExportSessionStatusCompleted: {
                // Here you go you have got the merged video :)
                NSLog(@"HRPVideoRecordViewController (458): Merging completed");
                [self exportDidFinish:videoExportSession];
            }
                break;
                
            default:
                break;
        }
    }];
}

- (void)mergeAudioAndVideoFiles {
    AVMutableCompositionTrack *videoCompositionTrack    =   [_composition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                                      preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVMutableCompositionTrack *audioCompositionTrack    =   [_composition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                                      preferredTrackID:kCMPersistentTrackID_Invalid];
    
    // Create assets URL's for videos snippets
    NSArray *allFolderFiles                             =   [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_mediaFolderPath error:nil];
    NSPredicate *predicateVideo                         =   [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", @"snippet_video_"];
    NSMutableArray *allVideoTempSnippets                =   [NSMutableArray arrayWithArray:[allFolderFiles filteredArrayUsingPredicate:predicateVideo]];
    NSPredicate *predicateAudio                         =   [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", @"snippet_audio_"];
    NSMutableArray *allAudioTempSnippets                =   [NSMutableArray arrayWithArray:[allFolderFiles filteredArrayUsingPredicate:predicateAudio]];
    
    // Sort arrays
    NSSortDescriptor *sortDescription                   =   [[NSSortDescriptor alloc] initWithKey:nil ascending:NO];
    allVideoTempSnippets                                =   [NSMutableArray arrayWithArray:
                                                             [allVideoTempSnippets sortedArrayUsingDescriptors:@[sortDescription]]];
    
    allAudioTempSnippets                                =   [NSMutableArray arrayWithArray:
                                                             [allAudioTempSnippets sortedArrayUsingDescriptors:@[sortDescription]]];
    
    for (int i = 0; i < allAudioTempSnippets.count; i++) {
        NSString *videoSnippetFilePath                  =   [_mediaFolderPath stringByAppendingPathComponent:allVideoTempSnippets[i]];
        AVURLAsset *videoSnippetAsset                   =   [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:videoSnippetFilePath] options:nil];
        NSString *audioSnippetFilePath                  =   [_mediaFolderPath stringByAppendingPathComponent:allAudioTempSnippets[i]];
        AVURLAsset *audioSnippetAsset                   =   [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:audioSnippetFilePath] options:nil];
        
        // Set the video snippet time ranges in composition
        [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoSnippetAsset.duration)
                                       ofTrack:[[videoSnippetAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                                        atTime:kCMTimeZero
                                         error:nil];
        
        if (audioSnippetAsset)
            [audioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioSnippetAsset.duration)
                                           ofTrack:[[audioSnippetAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]
                                            atTime:kCMTimeZero
                                             error:nil];
    }
}

- (void)exportDidFinish:(AVAssetExportSession *)session {
    if (session.status == AVAssetExportSessionStatusCompleted) {
        NSURL *outputURL                                =   session.outputURL;
        ALAssetsLibrary *library                        =   [[ALAssetsLibrary alloc] init];
        
        // Save merged video to album
        if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL]) {
            [library writeVideoAtPathToSavedPhotosAlbum:outputURL
                                        completionBlock:^(NSURL *assetURL, NSError *error) {
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                if (error)
                                                    [self showAlertViewWithTitle:NSLocalizedString(@"Alert error email title", nil)
                                                                      andMessage:NSLocalizedString(@"Alert error saving video message", nil)];
                                                else {
                                                    _videoAssetURL   =   assetURL;
                                                    [self saveVideoRecordToFile];
                                                    
                                                    [self removeAllFolderMediaTempFiles];
                                                }
                                            });
                                        }];
        }
    }
}

- (void)saveVideoRecordToFile {
    HRPPhoto *photo                                         =   [[HRPPhoto alloc] init];
    ALAssetsLibrary *assetsLibrary                          =   [[ALAssetsLibrary alloc] init];
    
    (_photosDataSource.count == 0) ? [_photosDataSource addObject:photo] : [_photosDataSource insertObject:photo atIndex:0];
    
    [assetsLibrary writeImageToSavedPhotosAlbum:_videoImageOriginal.CGImage
                                    orientation:(ALAssetOrientation)_videoImageOriginal.imageOrientation
                                completionBlock:^(NSURL *assetURL, NSError *error) {
                                    photo.assetsVideoURL    =   [_videoAssetURL absoluteString];
                                    photo.assetsPhotoURL    =   [assetURL absoluteString];
                                    
                                    photo.latitude          =   _location.coordinate.latitude;
                                    photo.longitude         =   _location.coordinate.longitude;
                                    photo.isVideo           =   YES;
                                    
                                    [_photosDataSource replaceObjectAtIndex:0 withObject:photo];
                                    [self savePhotosCollectionToFile];
                                }];
}

- (void)savePhotosCollectionToFile {
    NSData *arrayData   =   [NSKeyedArchiver archivedDataWithRootObject:_photosDataSource];
    NSArray *paths      =   NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    _arrayPath          =   paths[0];   // [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Photos"];
    _arrayPath          =   [_arrayPath stringByAppendingPathComponent:[_userApp objectForKey:@"userAppEmail"]];
    
    [[NSFileManager defaultManager] createFileAtPath:_arrayPath
                                            contents:arrayData
                                          attributes:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"startVideoSession"
                                                        object:nil
                                                      userInfo:nil];
}

- (void)extractFirstFrameFromVideoFilePath:(NSURL *)filePathURL {
    NSError *err                                        =   NULL;
    
    AVURLAsset *movieAsset                              =   [[AVURLAsset alloc] initWithURL:filePathURL options:nil];
    AVAssetImageGenerator *imageGenerator               =   [[AVAssetImageGenerator alloc] initWithAsset:movieAsset];
    imageGenerator.appliesPreferredTrackTransform       =   YES;
    CMTime time                                         =   CMTimeMake(1, 2);
    CGImageRef oneRef                                   =   [imageGenerator copyCGImageAtTime:time actualTime:NULL error:&err];
    
    UIImageOrientation imageOrientation;
    
    if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait)
        imageOrientation    =   UIImageOrientationUp;
    
    else if ([[UIApplication sharedApplication] statusBarOrientation] == UIDeviceOrientationLandscapeRight)
        imageOrientation    =   UIImageOrientationRight;
    
    else if ([[UIApplication sharedApplication] statusBarOrientation] == UIDeviceOrientationLandscapeLeft)
        imageOrientation    =   UIImageOrientationLeft;
    
    _videoImageOriginal     =   [[UIImage alloc] initWithCGImage:oneRef scale:1.f orientation:imageOrientation];
    
    if (_videoImageOriginal)
        [self mergeAndSaveVideoFile];
}

- (void)showAlertViewWithTitle:(NSString *)titleText andMessage:(NSString *)messageText {
    [[[UIAlertView alloc] initWithTitle:titleText
                                message:messageText
                               delegate:nil
                      cancelButtonTitle:nil
                      otherButtonTitles:NSLocalizedString(@"Alert error button Ok", nil), nil] show];
}


#pragma mark - AVCaptureFileOutputRecordingDelegate -
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL
      fromConnections:(NSArray *)connections {
    if (!_timerSeconds)
        _timerSeconds       =   0;
    
    if (!_timer)
        [self createTimerWithLabel:_timerLabel];
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
      fromConnections:(NSArray *)connections error:(NSError *)error {
    // Stream mode
    if (_videoSessionMode == NSTimerVideoSessionModeStream) {
        [self setNextSnippetNumber];
        
        [self startStreamVideoRecording];
        
        // Delete media snippets_1
        if (_snippetNumber == 0)
            [self removeMediaSnippets];
    }
    
    // Attention mode
    else if (_videoSessionMode == NSTimerVideoSessionModeAttention) {
        // Start Attention mode
        if (_videoImageOriginal == nil) {
            [self setNextSnippetNumber];
            
            _videoImageOriginal         =   [UIImage new];

            [self startStreamVideoRecording];
        }
        
        // Finish Attention mode
        else {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"showMergeAndSaveAlertMessage"
                                                                object:nil
                                                              userInfo:nil];
            
            NSString *videoFilePath     =   [_mediaFolderPath stringByAppendingPathComponent:_videoFilesNames[_snippetNumber]];
            NSURL *videoFileURL         =   [NSURL fileURLWithPath:videoFilePath];
            
            [self extractFirstFrameFromVideoFilePath:videoFileURL];
        }
    }
}


#pragma mark - AVAudioRecorderDelegate -
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
}


#pragma mark - AVAudioPlayerDelegate -
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
}


#pragma mark - CLLocationManagerDelegate -
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [self showAlertViewWithTitle:NSLocalizedString(@"Alert error location title", nil)
                      andMessage:NSLocalizedString(@"Alert error location retrieving message", nil)];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    _location   =   [locations lastObject];
}

@end
