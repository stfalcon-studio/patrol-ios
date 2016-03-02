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
#import "HRPViolation.h"
#import "HRPViolationManager.h"


@implementation HRPCameraManager {
    AVAudioRecorder *_audioRecorder;
    AVAudioPlayer *_audioPlayer;
    AVAudioSession *_audioSession;
    AVMutableComposition *_composition;
    UILabel *_timerLabel;

    NSDictionary *_audioRecordSettings;
    NSString *_arrayPath;
    NSString *_mediaFolderPath;
    NSURL *_videoAssetURL;
    UIImage *_videoImageOriginal;
    CGRect _previewRect;
    
    CGFloat _latitude;
    CGFloat _longitude;
    
    int _currentTimerValue;
    NSString *_snippetVideoFileName;
    NSString *_snippetAudioFileName;
}

#pragma mark - Constructors -
+ (HRPCameraManager *)sharedManager {
    static HRPCameraManager *singletonManager = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        singletonManager = [[HRPCameraManager alloc] init];
    });
    
    return singletonManager;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        // App Folder
        _mediaFolderPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        
        _snippetVideoFileName = nil;
        _snippetAudioFileName = nil;
        
        // Saved user data
        _userApp = [NSUserDefaults standardUserDefaults];
        
        [self createStoreDataPath];
//        [self readAllFolderFile];
//        [self readPhotosCollectionFromFile];
        
        // Set Media session parameters
        _isVideoSaving = NO;
        
        _audioRecordSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
                                    [NSNumber numberWithInt:AVAudioQualityMax], AVEncoderAudioQualityKey,
                                    [NSNumber numberWithInt:32], AVEncoderBitRateKey,
                                    [NSNumber numberWithInt:2], AVNumberOfChannelsKey,
                                    [NSNumber numberWithFloat:44100.f], AVSampleRateKey, nil];
        
        // [self deleteFolder];
        
        // HSPLocations
        _locationsService = [[HRPLocations alloc] init];
        
        if ([_locationsService isEnabled]) {
            _locationsService.manager.delegate = self;
        }
        
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
    _sessionDuration = 120; // 2 minutes
    _violationTime = 0;
    _timerLabel = label;
    _timerLabel.text = [self formattedTime:_currentTimerValue];
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.f
                                              target:self
                                            selector:@selector(timerTicked:)
                                            userInfo:nil
                                             repeats:YES];
}

- (void)timerTicked:(NSTimer *)timer {
    _currentTimerValue++;
    
    if (_currentTimerValue == _sessionDuration) {
        if (_videoSessionMode == NSTimerVideoSessionModeStream)
            _currentTimerValue = 0;
        
        else {
            [_timer invalidate];
        }
        
        // Stop Video & Audio recording
        [self stopVideoRecording];
    }
    
    _timerLabel.text = [self formattedTime:_currentTimerValue];
}

- (NSString *)formattedTime:(NSInteger)secondsTotal {
    NSInteger seconds = secondsTotal % 60;
    NSInteger minutes = (secondsTotal / 60) % 60;
    NSInteger hours = secondsTotal / 3600;
    
    return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
}


#pragma mark - Methods -
- (void)createCaptureSession {
    NSError *error;
    
    // Initialize the Session object
    _captureSession = [[AVCaptureSession alloc] init];
    _captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    
    // Initialize a Camera object
    AVCaptureDevice *inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:&error];
    
    if ([_captureSession canAddInput:deviceInput])
        [_captureSession addInput:deviceInput];
    
    // Configure the audio session
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive:YES error:nil];
    
    // Find the desired input port
    NSArray *inputs = [audioSession availableInputs];
    AVAudioSessionPortDescription *builtInMic = nil;
    
    for (AVAudioSessionPortDescription *port in inputs) {
        if ([port.portType isEqualToString:AVAudioSessionPortBuiltInMic]) {
            builtInMic = port;
           
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
    _videoFileOutput = [[AVCaptureMovieFileOutput alloc] init];

    if ([_captureSession canAddOutput:_videoFileOutput])
        [_captureSession addOutput:_videoFileOutput];
    
    // Set Connection
    AVCaptureConnection *videoConnection = nil;
    
    for (AVCaptureConnection *connection in _videoFileOutput.connections) {
        for (AVCaptureInputPort *port in connection.inputPorts) {
            if ([port.mediaType isEqual:AVMediaTypeVideo])
                videoConnection = connection;
        }
    }
    
    if ([videoConnection isVideoOrientationSupported])
        [self setVideoSessionOrientation];
    
    // Create StillImageOutput
    AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [stillImageOutput setOutputSettings:outputSettings];
        
    [_captureSession addOutput:stillImageOutput];
}

- (void)startStreamVideoRecording {
    [self startAudioRecording];
    
    _snippetVideoFileName = ([_snippetVideoFileName isEqualToString:@"snippet_video_1.mp4"] || _snippetVideoFileName == nil) ?
                                @"snippet_video_0.mp4" : @"snippet_video_1.mp4";
    
    NSString *videoFilePath = [_mediaFolderPath stringByAppendingPathComponent:_snippetVideoFileName];
    NSURL *videoFileURL = [NSURL fileURLWithPath:videoFilePath];

    [_videoFileOutput startRecordingToOutputFileURL:videoFileURL recordingDelegate:self];
}

- (void)startAudioRecording {
    if (!_audioRecorder.recording) {
        NSError *error = nil;
        _audioSession = [AVAudioSession sharedInstance];
        
        [_audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        [_audioSession setActive:YES withOptions:0 error:nil];
        
        _snippetAudioFileName = ([_snippetAudioFileName isEqualToString:@"snippet_audio_1.caf"] || _snippetAudioFileName == nil) ?
                                    @"snippet_audio_0.caf" : @"snippet_audio_1.caf";
        
        NSString *audioFilePath = [_mediaFolderPath stringByAppendingPathComponent:_snippetAudioFileName];
        NSURL *audioFileURL = [NSURL fileURLWithPath:audioFilePath];
        
        _audioRecorder = [[AVAudioRecorder alloc] initWithURL:audioFileURL
                                                     settings:_audioRecordSettings
                                                        error:&error];
        
        if (error)
            [self showAlertViewWithTitle:NSLocalizedString(@"Alert error API title", nil)
                              andMessage:[error localizedDescription]];
        
        else
            [_audioRecorder prepareToRecord];
        
        [_audioRecorder record];
    }
}

- (void)restartStreamVideoRecording {
    _currentTimerValue = 0;

    // Stop Video & Audio recording
    [self stopVideoRecording];
}

- (void)stopVideoSession {
    [_captureSession stopRunning];

    _videoSessionMode = NSTimerVideoSessionModeDismissed;

    // Stop Video & Audio recording
    [self stopVideoRecording];
    
    // Stop Timer
    [_timer invalidate];
    
    _captureSession = nil;
    _videoPreviewLayer = nil;
    _audioSession = nil;
    _audioRecorder = nil;
    _audioPlayer = nil;
    _violationTime = 0;
    _currentTimerValue = 0;
    _snippetVideoFileName = nil;
}

- (void)stopVideoRecording {
    [self stopAudioRecording];
    [_videoFileOutput stopRecording];
}

- (void)stopAudioRecording {
    if (_audioRecorder.recording)
        [_audioRecorder stop];
}

- (void)setVideoPreviewLayerOrientation:(CGSize)newSize {
    _videoPreviewLayer.frame = CGRectMake(0.f, 0.f, newSize.width, newSize.height);
    
    [self setVideoSessionOrientation];
}

- (void)setVideoSessionOrientation {
    AVCaptureVideoOrientation videoOrientation  =   AVCaptureVideoOrientationPortraitUpsideDown;
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            videoOrientation = AVCaptureVideoOrientationPortrait;
            break;
            
        case UIDeviceOrientationPortraitUpsideDown:
            videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
            
        case UIDeviceOrientationLandscapeLeft:
            videoOrientation = AVCaptureVideoOrientationLandscapeRight;
            break;
            
        case UIDeviceOrientationLandscapeRight:
            videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
            
        default:
            videoOrientation = AVCaptureVideoOrientationPortrait;
            break;
    }
    
    [_videoPreviewLayer.connection setVideoOrientation:videoOrientation];
    [[_videoFileOutput connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:videoOrientation];
}

- (int)getCurrentTimerValue {
    return _currentTimerValue;
}

- (void)createStoreDataPath {
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    _arrayPath = paths[0]; // [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Photos"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:_arrayPath]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:_arrayPath
                                       withIntermediateDirectories:NO
                                                        attributes:nil
                                                             error:&error])
            DebugLog(@"Create directory error: %@", error);
    }
}

- (void)deleteFolder {
    if ([[NSFileManager defaultManager] removeItemAtPath:_mediaFolderPath error:nil])
        DebugLog(@"HRPVideoRecordViewController (352): DELETE");
    
    else
        DebugLog(@"HRPVideoRecordViewController (354): NOT DELETE");
}

- (void)readAllFolderFile {
    NSArray *allFolderFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_mediaFolderPath error:nil];
    
    DebugLog(@"HRPVideoRecordViewController (335): FOLDER FILES = %@", allFolderFiles);
}

// DELETE AFTER TESTING
/*
- (void)readPhotosCollectionFromFile {
    _violations = [NSMutableArray array];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    _arrayPath = paths[0]; // [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Photos"];
    _arrayPath = [_arrayPath stringByAppendingPathComponent:[_userApp objectForKey:@"userAppEmail"]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:_arrayPath]) {
        NSData *arrayData = [[NSData alloc] initWithContentsOfFile:_arrayPath];
        
        if (arrayData)
            _violations = [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithData:arrayData]];
        else
            DebugLog(@"File does not exist");
    }
}
*/

- (void)removeOldVideoFile {
    NSArray *allFolderFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_mediaFolderPath error:nil];
    
    for (NSString *fileName in allFolderFiles) {
        if ([fileName containsString:@"violation_video"])
            [[NSFileManager defaultManager] removeItemAtPath:[_mediaFolderPath stringByAppendingPathComponent:fileName] error:nil];
    }
}

- (void)removeAllFolderMediaTempFiles {
    NSArray *allFolderFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_mediaFolderPath error:nil];
    _videoImageOriginal = nil;
    
    for (NSString *fileName in allFolderFiles) {
        if ([fileName containsString:@"snippet_"] ||
            [fileName containsString:@"violation_video"])
            [[NSFileManager defaultManager] removeItemAtPath:[_mediaFolderPath stringByAppendingPathComponent:fileName] error:nil];
    }
    
    _snippetVideoFileName = nil;
    _snippetAudioFileName = nil;
    _violationTime = 0;
}

- (void)removeMediaSnippets {
    NSArray *allFolderFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_mediaFolderPath error:nil];
    
    for (NSString *fileName in allFolderFiles) {
        if ([fileName containsString:@"snippet_"])
            [[NSFileManager defaultManager] removeItemAtPath:[_mediaFolderPath stringByAppendingPathComponent:fileName] error:nil];
    }
}

- (NSInteger)countVideoSnippets {
    NSArray *allFolderFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_mediaFolderPath error:nil];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", @"snippet"];
    DebugLog(@"HRPVideoRecordViewController (323): COUNT = %ld", (long)[[allFolderFiles filteredArrayUsingPredicate:predicate] count]);
    
    return [[allFolderFiles filteredArrayUsingPredicate:predicate] count];
}

- (void)handlerVideoSession {
    // Create the AVMutable composition to add tracks
    _composition = [AVMutableComposition composition];
    
    // Create the mutable composition track with video media type
    [self removeOldVideoFile];
    [self mergeAudioAndVideoSnippets];
    
    // Create the export session to merge and save the video
    AVAssetExportSession *videoExportSession = [[AVAssetExportSession alloc] initWithAsset:_composition
                                                                                presetName:AVAssetExportPresetHighestQuality];
    
    NSString *videoFileName = @"violation_video.mov";
    NSURL *videoURL = [[NSURL alloc] initFileURLWithPath:[_mediaFolderPath stringByAppendingPathComponent:videoFileName]];
    videoExportSession.outputURL = videoURL;
    videoExportSession.outputFileType = @"com.apple.quicktime-movie";
    videoExportSession.shouldOptimizeForNetworkUse = YES;
    
    [videoExportSession exportAsynchronouslyWithCompletionHandler:^{
        switch (videoExportSession.status) {
            case AVAssetExportSessionStatusFailed:
                DebugLog(@"HRPVideoRecordViewController (449): Failed to export video");
                break;
                
            case AVAssetExportSessionStatusCancelled:
                DebugLog(@"HRPVideoRecordViewController (453): export cancelled");
                break;
                
            case AVAssetExportSessionStatusCompleted: {
                // Here you go you have got the merged video :)
                DebugLog(@"HRPVideoRecordViewController (458): Merging completed");
                [self exportDidFinish:videoExportSession];
            }
                break;
                
            default:
                break;
        }
    }];
}

- (void)mergeAudioAndVideoSnippets {
    AVMutableCompositionTrack *videoCompositionTrack = [_composition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                                 preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVMutableCompositionTrack *audioCompositionTrack = [_composition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                                 preferredTrackID:kCMPersistentTrackID_Invalid];
    
    // Create assets URL's for videos snippets
    NSArray *allFolderFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_mediaFolderPath error:nil];
    NSPredicate *predicateVideo = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", @"snippet_video_"];
    NSMutableArray *allVideoTempSnippets = [NSMutableArray arrayWithArray:[allFolderFiles filteredArrayUsingPredicate:predicateVideo]];
    NSPredicate *predicateAudio = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", @"snippet_audio_"];
    NSMutableArray *allAudioTempSnippets = [NSMutableArray arrayWithArray:[allFolderFiles filteredArrayUsingPredicate:predicateAudio]];
    CMTimeRange range_0, range_1;
    
//    NSArray *arr = @[[NSValue valueWithCMTimeRange:range_0]];
//    
//    range_1 = [arr[0] CMTimeRangeValue];
    
    // Case 1 - get violation from one video & audio snippet
    if (_violationTime >= 20) {
        predicateVideo = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", _snippetVideoFileName];
        allVideoTempSnippets = [NSMutableArray arrayWithArray:[allFolderFiles filteredArrayUsingPredicate:predicateVideo]];
        predicateAudio = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", _snippetAudioFileName];
        allAudioTempSnippets = [NSMutableArray arrayWithArray:[allFolderFiles filteredArrayUsingPredicate:predicateAudio]];
        
        CMTime start = CMTimeMakeWithSeconds(_violationTime - 20, 600);
        CMTime duration = CMTimeMakeWithSeconds(30.0, 600);
        range_0 = CMTimeRangeMake(start, duration);
    }
    
    // Case 2 - get violation from two video & audio snippets: violation take in first (0) snippet
    else  if (allVideoTempSnippets.count == 1) {
        predicateVideo = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", _snippetVideoFileName];
        allVideoTempSnippets = [NSMutableArray arrayWithArray:[allFolderFiles filteredArrayUsingPredicate:predicateVideo]];
        predicateAudio = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", _snippetAudioFileName];
        allAudioTempSnippets = [NSMutableArray arrayWithArray:[allFolderFiles filteredArrayUsingPredicate:predicateAudio]];
        
        CMTime start = CMTimeMakeWithSeconds(0, 600);
        CMTime duration = CMTimeMakeWithSeconds(_sessionDuration, 600);
        range_0 = CMTimeRangeMake(start, duration);
    }
    
    // Case 3 - get violation from two video & audio snippets: violation take in second (1) snippet
    else {
        // Sort arrays
        int rest = 21 - _violationTime;
        CMTime start = CMTimeMakeWithSeconds(0, 10);
        CMTime duration = CMTimeMakeWithSeconds(rest, 10);
        range_1 = CMTimeRangeMake(start, duration);
        
        start = CMTimeMakeWithSeconds(1, 10);
        duration = CMTimeMakeWithSeconds(_sessionDuration, 10);
        range_0 = CMTimeRangeMake(start, duration);
    }
    
    for (int i = 0; i < allAudioTempSnippets.count; i++) {
        // Case 3 - get violation from two video & audio snippets: violation take in second (1) snippet
        if (allVideoTempSnippets.count == 2) {
            // Sort arrays
            BOOL ascendingKey = ([_snippetVideoFileName hasSuffix:@"_0"]) ? YES : NO;
            NSSortDescriptor *sortDescription = [[NSSortDescriptor alloc] initWithKey:nil ascending:ascendingKey];
            allVideoTempSnippets = [NSMutableArray arrayWithArray:[allVideoTempSnippets sortedArrayUsingDescriptors:@[sortDescription]]];
            allAudioTempSnippets = [NSMutableArray arrayWithArray:[allAudioTempSnippets sortedArrayUsingDescriptors:@[sortDescription]]];
        }
        
        NSString *videoSnippetFilePath = [_mediaFolderPath stringByAppendingPathComponent:allVideoTempSnippets[i]];
        AVURLAsset *videoSnippetAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:videoSnippetFilePath] options:nil];
        NSString *audioSnippetFilePath = [_mediaFolderPath stringByAppendingPathComponent:allAudioTempSnippets[i]];
        AVURLAsset *audioSnippetAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:audioSnippetFilePath] options:nil];
        AVAssetTrack *videoAssetTrack = [[videoSnippetAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        UIImageOrientation videoAssetOrientation = UIImageOrientationUp;
        BOOL isVideoAssetPortrait = NO;
        CGAffineTransform videoTransform = videoAssetTrack.preferredTransform;
        
        if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
            videoAssetOrientation = UIImageOrientationRight;
            isVideoAssetPortrait = YES;
        }
        
        if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
            videoAssetOrientation = UIImageOrientationLeft;
            isVideoAssetPortrait = YES;
        }
        
        if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0)
            videoAssetOrientation = UIImageOrientationUp;
        
        if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0)
            videoAssetOrientation = UIImageOrientationDown;
        
        // Set the video snippet time ranges in composition
        [videoCompositionTrack insertTimeRange:(i == 0) ? range_0 : range_1
                                       ofTrack:[[videoSnippetAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                                        atTime:kCMTimeZero
                                         error:nil];
        
        CGFloat FirstAssetScaleToFitRatio = 320.0 / videoAssetTrack.naturalSize.width;
        
        if (isVideoAssetPortrait) {
            FirstAssetScaleToFitRatio = 320.0 / videoAssetTrack.naturalSize.height;
            CGAffineTransform FirstAssetScaleFactor = CGAffineTransformMakeScale(FirstAssetScaleToFitRatio,FirstAssetScaleToFitRatio);
            
            [videoCompositionTrack setPreferredTransform:CGAffineTransformConcat(videoAssetTrack.preferredTransform, FirstAssetScaleFactor)];
        }
        
        else {
            CGAffineTransform FirstAssetScaleFactor = CGAffineTransformMakeScale(FirstAssetScaleToFitRatio,FirstAssetScaleToFitRatio);
           
            [videoCompositionTrack setPreferredTransform:CGAffineTransformConcat(CGAffineTransformConcat(videoAssetTrack.preferredTransform, FirstAssetScaleFactor),CGAffineTransformMakeTranslation(0, 160))];
        }
        
        if (audioSnippetAsset)
            [audioCompositionTrack insertTimeRange:(i == 0) ? range_0 : range_1
                                           ofTrack:[[audioSnippetAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]
                                            atTime:kCMTimeZero
                                             error:nil];
    }
}

- (void)exportDidFinish:(AVAssetExportSession *)session {
    if (session.status == AVAssetExportSessionStatusCompleted) {
        NSURL *outputURL = session.outputURL;
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        
        // Save merged video to album
        if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL]) {
            [library writeVideoAtPathToSavedPhotosAlbum:outputURL
                                        completionBlock:^(NSURL *assetURL, NSError *error) {
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                if (error)
                                                    [self showAlertViewWithTitle:NSLocalizedString(@"Alert error email title", nil)
                                                                      andMessage:NSLocalizedString(@"Alert error saving video message", nil)];
                                                else {
                                                    _videoAssetURL = assetURL;
                                                    [self saveVideoRecordToFile];
                                                    
                                                    [self removeAllFolderMediaTempFiles];
                                                }
                                            });
                                        }];
        }
    }
}

- (void)saveVideoRecordToFile {
    HRPViolation *violation = [[HRPViolation alloc] init];
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
    
    (_violations.count == 0) ? [_violations addObject:violation] : [_violations insertObject:violation atIndex:0];
    
    [assetsLibrary writeImageToSavedPhotosAlbum:_videoImageOriginal.CGImage
                                    orientation:(ALAssetOrientation)_videoImageOriginal.imageOrientation
                                completionBlock:^(NSURL *assetURL, NSError *error) {
                                    violation.assetsVideoURL = [_videoAssetURL absoluteString];
                                    violation.assetsPhotoURL = [assetURL absoluteString];
                                    violation.date = [NSDate date];
                                    violation.latitude = _latitude;
                                    violation.longitude = _longitude;
                                    violation.type = HRPViolationTypeVideo;
                                    violation.state = HRPViolationStateUpload;
                                    
                                    [_violations replaceObjectAtIndex:0 withObject:violation];
                                    [self saveViolationsToFile];
                                }];
}

- (void)saveViolationsToFile {
    NSData *arrayData = [NSKeyedArchiver archivedDataWithRootObject:_violations];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    _arrayPath = paths[0];   // [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Photos"];
    _arrayPath = [_arrayPath stringByAppendingPathComponent:[_userApp objectForKey:@"userAppEmail"]];

    [HRPViolationManager sharedManager].violations = _violations;

    [[NSFileManager defaultManager] createFileAtPath:_arrayPath
                                            contents:arrayData
                                          attributes:nil];
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"startVideoSession"
                                                        object:nil
                                                      userInfo:nil];
    
    _videoImageOriginal = nil;
}

- (void)extractFirstFrameFromVideoFilePath:(NSURL *)filePathURL {
    NSError *err = NULL;
    AVURLAsset *movieAsset = [[AVURLAsset alloc] initWithURL:filePathURL options:nil];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:movieAsset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMake(_violationTime, _violationTime + 1);
    CGImageRef oneRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:&err];
    _videoImageOriginal = [[UIImage alloc] initWithCGImage:oneRef scale:1.f orientation:UIImageOrientationUp];
    
    if (_videoImageOriginal)
        [self handlerVideoSession];
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
    [self setVideoSessionOrientation];
    
    if (!_currentTimerValue)
        _currentTimerValue = 0;
    
    if (!_timer)
        [self createTimerWithLabel:_timerLabel];
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
      fromConnections:(NSArray *)connections error:(NSError *)error {
    // Stream mode
    if (_videoSessionMode == NSTimerVideoSessionModeStream) {
        [self startStreamVideoRecording];
    }
    
    // Violation mode
    else if (_videoSessionMode == NSTimerVideoSessionModeViolation) {
        // Finish Record Violation Video
        _videoSessionMode = NSTimerVideoSessionModeStream;
        _currentTimerValue = 0;
        _timer = nil;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"showMergeAndSaveAlertMessage"
                                                            object:nil
                                                          userInfo:nil];
        
        NSString *videoFilePath = [_mediaFolderPath stringByAppendingPathComponent:_snippetVideoFileName];
        NSURL *videoFileURL = [NSURL fileURLWithPath:videoFilePath];
        
        [self extractFirstFrameFromVideoFilePath:videoFileURL];
    }
    
    else if (_videoSessionMode == NSTimerVideoSessionModeDismissed) {
        _videoFileOutput = nil;
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
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    if (_videoSessionMode == NSTimerVideoSessionModeViolation) {
        _latitude = newLocation.coordinate.latitude;
        _longitude = newLocation.coordinate.longitude;
    }
}

- (void)requestAlwaysAuthorization {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    // If the status is denied or only granted for when in use, display an alert
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusDenied) {
        NSString *titleText = NSLocalizedString(@"Alert error location title background", nil);
        
        NSString *messageText = (status == kCLAuthorizationStatusDenied) ?  NSLocalizedString(@"Alert error location message off", nil) :
        NSLocalizedString(@"Alert error location message background", nil);
        
        [[[UIAlertView alloc] initWithTitle:titleText
                                    message:messageText
                                   delegate:nil
                          cancelButtonTitle:nil
                          otherButtonTitles:NSLocalizedString(@"Alert error button Ok", nil), nil] show];
    }
    
    // The user has not enabled any location services. Request background authorization.
    else if (status == kCLAuthorizationStatusNotDetermined) {
        [_locationsService.manager requestAlwaysAuthorization];
    }
}

@end
