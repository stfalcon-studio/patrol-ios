//
//  HRPCameraManager.m
//  HromadskyiPatrul
//
//  Created by msm72 on 12.12.15.
//  Copyright © 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPCameraManager.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "HRPPhoto.h"


@implementation HRPCameraManager {
    AVCaptureVideoOrientation _videoOrientation;
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

        [self createCaptureSession];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - NSNotification -
- (void)handlerVideoSessionStopRecording:(NSNotification *)notification {
    [_videoFileOutput stopRecording];
}


#pragma mark - Timer Methods -
- (void)createTimerWithLabel:(UILabel *)label {
    _timerSeconds           =   0;
    _sessionDuration        =   11;
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
        
        [_videoFileOutput stopRecording];
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
//    NSError *error;
    
    // Create the AVCaptureSession.
    _captureSession                                         =   [[AVCaptureSession alloc] init];
    _captureSession.sessionPreset                           =   AVCaptureSessionPresetHigh;
    
    
    // Communicate with the session and other session objects on this queue.
    _sessionQueue                                           =   dispatch_queue_create( "session queue", DISPATCH_QUEUE_SERIAL );
    _setupResult                                            =   HRPCameraManagerSetupResultSuccess;
    
    [self checkVideoAuthorizationStatus];
    
    [self setupCaptureSession];
    
    
/*
    // VIDEO
    // Add output file
    _videoFileOutput                                        =   [[AVCaptureMovieFileOutput alloc] init];

    _videoConnection                                        =   [_videoFileOutput connectionWithMediaType:AVMediaTypeVideo];
    
    if ([_videoConnection isVideoOrientationSupported])
        [_videoConnection setVideoOrientation:[self getVideoOrientation]];

    if ([_captureSession canAddOutput:_videoFileOutput])
        [_captureSession addOutput:_videoFileOutput];
    
    // Initialize the video preview layer
    _videoPreviewLayer                                      =   [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    CGRect layerRect                                        =   [[UIScreen mainScreen] bounds];
    CGPoint layerCenter                                     =   CGPointMake(CGRectGetMidX(layerRect), CGRectGetMidY(layerRect));

    [_videoPreviewLayer setBounds:layerRect];
    [_videoPreviewLayer setPosition:layerCenter];
    _videoPreviewLayer.connection.videoOrientation          =   AVCaptureVideoOrientationPortrait;
//    [self setVideoSessionOrientation];
    
    [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill]; 
 */
}

- (void)checkVideoAuthorizationStatus {
    // Check video authorization status. Video access is required and audio access is optional.
    // If audio access is denied, audio is not recorded during movie recording.
    switch ( [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] ) {
        case AVAuthorizationStatusAuthorized: {
            // The user has previously granted access to the camera.
            break;
        }
            
        case AVAuthorizationStatusNotDetermined: {
            // The user has not yet been presented with the option to grant video access.
            // We suspend the session queue to delay session setup until the access request has completed to avoid
            // asking the user for audio access if video access is denied.
            // Note that audio access will be implicitly requested when we create an AVCaptureDeviceInput for audio during session setup.
            
            dispatch_suspend(_sessionQueue);
            
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^( BOOL granted ) {
                if (!granted) {
                    _setupResult                            =   HRPCameraManagerSetupResultCameraNotAuthorized;
                }
                
                dispatch_resume(_sessionQueue);
            }];
            
            break;
        }
            
        default: {
            // The user has previously denied access.
            _setupResult                                    =   HRPCameraManagerSetupResultCameraNotAuthorized;
            break;
        }
    }
}

- (void)setupCaptureSession {
    // Setup the capture session.
    // In general it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time.
    // Why not do all of this on the main queue?
    // Because -[AVCaptureSession startRunning] is a blocking call which can take a long time. We dispatch session setup to the sessionQueue
    // so that the main queue isn't blocked, which keeps the UI responsive.
    dispatch_async( _sessionQueue, ^{
        if (_setupResult != HRPCameraManagerSetupResultSuccess)
            return;
        
        NSError *error                                      =   nil;
        
        // VIDEO
        // Initialize a Camera object
        AVCaptureDevice *videoDevice                        =   [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        _videoDeviceInput                                   =   [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
//        AVCaptureVideoStabilizationMode stabilizationMode   =   AVCaptureVideoStabilizationModeCinematic;
        
//        if ([videoDevice.activeFormat isVideoStabilizationModeSupported:stabilizationMode])
//            [_videoConnection setPreferredVideoStabilizationMode:stabilizationMode];
//        

        if (!_videoDeviceInput)
            [self showAlertViewWithTitle:NSLocalizedString(@"Alert error location title", nil)
                              andMessage:[NSLocalizedString(@"Alert create input video error message", nil) stringByAppendingString:error.localizedDescription]];
        
        else {
            [_captureSession beginConfiguration];
            
            if ([_captureSession canAddInput:_videoDeviceInput]) {
                [_captureSession addInput:_videoDeviceInput];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    // Why are we dispatching this to the main queue?
                    // Because AVCaptureVideoPreviewLayer is the backing layer for AAPLPreviewView and UIView
                    // can only be manipulated on the main thread.
                    // Note: As an exception to the above rule, it is not necessary to serialize video orientation changes
                    // on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                    
                    // Use the status bar orientation as the initial video orientation. Subsequent orientation changes are handled by
                    // -[viewWillTransitionToSize:withTransitionCoordinator:].
                    
                    UIInterfaceOrientation statusBarOrientation         =   [UIApplication sharedApplication].statusBarOrientation;
                        _videoOrientation                               =   AVCaptureVideoOrientationPortrait;
                    
                    if (statusBarOrientation != UIInterfaceOrientationUnknown)
                        _videoOrientation                               =   (AVCaptureVideoOrientation)statusBarOrientation;
                } );
            }
            
            else {
                [self showAlertViewWithTitle:NSLocalizedString(@"Alert error location title", nil)
                                  andMessage:NSLocalizedString(@"Alert add input video error message", nil)];

                _setupResult                                            =   HRPCameraManagerSetupResultSessionConfigurationFailed;
            }
        }

        // AUDIO
        // Configure the audio session
        AVAudioSession *audioSession                            =   [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        [audioSession setActive:YES error:nil];
        
        // Find the desired input port
        NSArray *inputs                                         =   [audioSession availableInputs];
        AVAudioSessionPortDescription *builtInMic               =   nil;
        
        for (AVAudioSessionPortDescription *port in inputs) {
            if ([port.portType isEqualToString:AVAudioSessionPortBuiltInMic]) {
                builtInMic                                      =   port;
                
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

        AVCaptureDevice *audioDevice                            =   [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        AVCaptureDeviceInput *audioDeviceInput                  =   [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
        
        if (!audioDeviceInput)
            [self showAlertViewWithTitle:NSLocalizedString(@"Alert error location title", nil)
                              andMessage:[NSLocalizedString(@"Alert create input audio error message", nil) stringByAppendingString:error.localizedDescription]];
        
        if ([_captureSession canAddInput:audioDeviceInput])
            [_captureSession addInput:audioDeviceInput];
        
        else
            [self showAlertViewWithTitle:NSLocalizedString(@"Alert error location title", nil)
                              andMessage:NSLocalizedString(@"Alert add input audio error message", nil)];
        
        // Video output
        _videoFileOutput                                        =   [[AVCaptureMovieFileOutput alloc] init];
        
        if ([_captureSession canAddOutput:_videoFileOutput]) {
            [_captureSession addOutput:_videoFileOutput];
            
            AVCaptureConnection *connection                     =   [_videoFileOutput connectionWithMediaType:AVMediaTypeVideo];
            
            if (connection.isVideoStabilizationSupported)
                connection.preferredVideoStabilizationMode      =   AVCaptureVideoStabilizationModeAuto;
        }
        
        else {
            [self showAlertViewWithTitle:NSLocalizedString(@"Alert error location title", nil)
                              andMessage:NSLocalizedString(@"Alert add output video file error message", nil)];
            
            _setupResult                                        =   HRPCameraManagerSetupResultSessionConfigurationFailed;
        }
        
        // Screenshot
        _stillImageOutput                                       =   [[AVCaptureStillImageOutput alloc] init];
        
        if ([_captureSession canAddOutput:_stillImageOutput]) {
            _stillImageOutput.outputSettings                    =   @{ AVVideoCodecKey : AVVideoCodecJPEG };

            [_captureSession addOutput:_stillImageOutput];
        }
        
        else {
            [self showAlertViewWithTitle:NSLocalizedString(@"Alert error location title", nil)
                              andMessage:NSLocalizedString(@"Alert add still image error message", nil)];
            
            _setupResult                                        =   HRPCameraManagerSetupResultSessionConfigurationFailed;
        }
        
        [_captureSession commitConfiguration];
    } );
}

- (void)startStreamVideoRecording {
    [self startAudioRecording];
    
    [_videoFileOutput startRecordingToOutputFileURL:[self setNewVideoFileURL:_snippetNumber] recordingDelegate:self];
}

- (void)startAudioRecording {
    if (!_audioRecorder.recording) {
        [self setNewAudioRecorder];
        
        [_audioRecorder record];
    }
}

- (void)restartStreamVideoRecording {
    _snippetNumber              =   1;

    [_videoFileOutput stopRecording];
}

- (void)stopVideoSession {
//    [_captureSession stopRunning];
    [_videoFileOutput stopRecording];
    [self stopAudioRecording];
    [_locationManager stopUpdatingLocation];
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

- (void)setVideoPreviewLayerOrientation:(UIView *)view {
    _videoPreviewLayer.frame    =   view.bounds;
    _videoConnection            =   _videoPreviewLayer.connection;
    
    if ([_videoConnection isVideoOrientationSupported])
        [_videoConnection setVideoOrientation:[self getVideoOrientation]];
}

- (AVCaptureVideoOrientation)getVideoOrientation {
    AVCaptureVideoOrientation videoOrientation          =   AVCaptureVideoOrientationLandscapeLeft;
//    UIDeviceOrientation cameraOrientation               =   [[UIDevice currentDevice] orientation];
    UIInterfaceOrientation cameraOrientation            =   [[UIApplication sharedApplication] statusBarOrientation];
    
    switch (cameraOrientation) {
        case UIInterfaceOrientationPortrait:
            videoOrientation                            =   AVCaptureVideoOrientationPortrait;
            break;
            
        case UIInterfaceOrientationPortraitUpsideDown:
            videoOrientation                            =   AVCaptureVideoOrientationPortraitUpsideDown;
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
            videoOrientation                            =   AVCaptureVideoOrientationLandscapeRight;
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            videoOrientation                            =   AVCaptureVideoOrientationLandscapeLeft;
            break;

        default:
            videoOrientation                            =   AVCaptureVideoOrientationPortrait;
            break;
    }

    /*
    CGFloat width                                       =   CGRectGetWidth([[UIScreen mainScreen] bounds]);
    CGFloat height                                      =   CGRectGetHeight([[UIScreen mainScreen] bounds]);
    CGFloat maxSide                                     =   (width - height > 0) ? width : height;
    CGFloat minSide                                     =   (width - height > 0) ? height : width;

    NSLog(@"minSide = %2.f, maxSide = %2.f", minSide, maxSide);
    
    if (videoOrientation == AVCaptureVideoOrientationPortrait ||
        videoOrientation == AVCaptureVideoOrientationPortraitUpsideDown)
        _previewRect                                    =   CGRectMake(0.f, 0.f, minSide, maxSide);
    
    else
        _previewRect                                    =   CGRectMake(0.f, 0.f, maxSide, minSide);
*/
    
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

- (void)setVideoSessionOrientation {
    _videoOrientation                                   =   [self getVideoOrientation];
 
    _videoPreviewLayer.connection.videoOrientation      =   _videoOrientation;
    _videoPreviewLayer.frame                            =   _previewRect;
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
    NSData *arrayData                                       =   [NSKeyedArchiver archivedDataWithRootObject:_photosDataSource];
    NSArray *paths                                          =   NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    _arrayPath                                              =   paths[0];
    // [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Photos"];
    _arrayPath                                              =   [_arrayPath stringByAppendingPathComponent:[_userApp objectForKey:@"userAppEmail"]];
    
    [[NSFileManager defaultManager] createFileAtPath:_arrayPath
                                            contents:arrayData
                                          attributes:nil];
    
//    self.navigationItem.rightBarButtonItem.enabled      =   YES;
    
    // Start new Video Session
//    [self stopVideoSession];
    
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
        imageOrientation                                =   UIImageOrientationUp;
    else if ([[UIApplication sharedApplication] statusBarOrientation] == UIDeviceOrientationLandscapeRight)
        imageOrientation                                =   UIImageOrientationRight;
    else if ([[UIApplication sharedApplication] statusBarOrientation] == UIDeviceOrientationLandscapeLeft)
        imageOrientation                                =   UIImageOrientationLeft;
    
    _videoImageOriginal                                 =   [[UIImage alloc] initWithCGImage:oneRef scale:1.f orientation:imageOrientation];
    
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
    [[NSNotificationCenter defaultCenter] postNotificationName:@"didStartRecordingToOutputFileAtURL"
                                                        object:nil
                                                      userInfo:nil];
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
      fromConnections:(NSArray *)connections error:(NSError *)error {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"didFinishRecordingToOutputFileAtURL"
                                                        object:nil
                                                      userInfo:nil];
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
