//
//  HRPVideoRecordViewController.m
//  HromadskyiPatrul
//
//  Created by msm72 on 04.09.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//


#import "HRPVideoRecordViewController.h"
#import "HRPVideoRecordModel.h"

#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "UIColor+HexColor.h"
#import "HRPButton.h"
#import "MBProgressHUD.h"
#import "HRPCollectionViewController.h"
#import "HRPPhoto.h"
#import <CoreLocation/CoreLocation.h>


typedef NS_ENUM (NSInteger, HRPVideoRecordViewControllerMode) {
    HRPVideoRecordViewControllerModeStreamVideo,
    HRPVideoRecordViewControllerModeAttentionVideo,
    HRPVideoRecordViewControllerModeDismissed
};


@interface HRPVideoRecordViewController () <CLLocationManagerDelegate, AVCaptureFileOutputRecordingDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate>

@property (assign, nonatomic) HRPVideoRecordViewControllerMode recordingMode;

@property (strong, nonatomic) IBOutlet UIView *statusView;
@property (strong, nonatomic) IBOutlet UIView *videoView;

@property (strong, nonatomic) IBOutlet HRPButton *controlButton;
@property (strong, nonatomic) IBOutlet UILabel *controlLabel;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *statusViewVerticalSpaceConstraint;

@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureConnection *videoConnection;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (strong, nonatomic) AVCaptureMovieFileOutput *videoFileOutput;
@property (strong, nonatomic) AVAudioRecorder *audioRecorder;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (strong, nonatomic) AVAudioSession *audioSession;
@property (strong, nonatomic) AVMutableComposition *composition;

@property (strong, nonatomic) IBOutlet UILabel *timerLabel;

- (void)startStreamVideoRecording;
- (void)startAttentionVideoRecording;

@end


@implementation HRPVideoRecordViewController {
    MBProgressHUD *progressHUD;
    NSUserDefaults *userApp;
    CLLocationManager *locationManager;

    AVCaptureVideoOrientation previewNewOrientation;
    AVCaptureVideoOrientation videoNewOrientation;

    NSTimer *timerVideo;
    NSString *mediaFolderPath;
    NSInteger timerSeconds;
    NSInteger snippetNumber;
    NSInteger sessionDuration;
    NSArray *videoFilesNames;
    NSArray *audioFilesNames;
    NSDictionary *audioRecordSettings;
    NSString *voiceLanguageModelPath;
    NSString *voiceDictionaryPath;
    NSArray *voiceCommands;
    NSString *arrayPath;
    NSMutableArray *photosDataSource;
    NSURL *videoAssetURL;
    UIImage *videoImageOriginal;
    CGFloat latitude;
    CGFloat longitude;

    BOOL isVideoSaving;
    BOOL isControlLabelFlashing;
}

#pragma mark - Constructors -
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set Session Duration
    sessionDuration                                     =   10;
    
    // Start Geolocation
    locationManager                                     =   [[CLLocationManager alloc]init];    // initializing locationManager
    locationManager.delegate                            =   self;                               // we set the delegate of locationManager to self.
    locationManager.desiredAccuracy                     =   kCLLocationAccuracyBest;            // setting the accuracy
    [locationManager startUpdatingLocation];                                                    //requesting location updates

    // App Folder
    mediaFolderPath                                     =   [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];

    userApp                                             =   [NSUserDefaults standardUserDefaults];
    [self createStoreDataPath];
    [self readPhotosCollectionFromFile];

    // Set Media session parameters
    snippetNumber                                       =   0;
    isVideoSaving                                       =   NO;
    isControlLabelFlashing                              =   NO;
    videoFilesNames                                     =   @[@"snippet_video_0.mp4", @"snippet_video_1.mp4", @"snippet_video_2.mp4"];
    audioFilesNames                                     =   @[@"snippet_audio_0.caf", @"snippet_audio_1.caf", @"snippet_audio_2.caf"];
    
    audioRecordSettings                                 =   [NSDictionary dictionaryWithObjectsAndKeys:
                                                                [NSNumber numberWithInt:kAudioFormatLinearPCM],     AVFormatIDKey,
                                                                [NSNumber numberWithInt:AVAudioQualityMax],         AVEncoderAudioQualityKey,
                                                                [NSNumber numberWithInt:32],                        AVEncoderBitRateKey,
                                                                [NSNumber numberWithInt:2],                         AVNumberOfChannelsKey,
                                                                [NSNumber numberWithFloat:44100.f],                 AVSampleRateKey, nil];

    // Create ProgressHUD
    progressHUD                                         =   [[MBProgressHUD alloc] init];

//    [self deleteFolder];
    
    // Set items
    self.controlLabel.text                              =   nil; //NSLocalizedString(@"Attention", nil);

    // Set Notification Observers
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleUserLogout:)
                                                 name:@"HRPSettingsViewControllerUserLogout"
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.recordingMode                                  =   HRPVideoRecordViewControllerModeStreamVideo;

    // Set Status Bar
    UIView *statusBarView                               =  [[UIView alloc] initWithFrame:CGRectMake(0.f, -20.f, CGRectGetWidth(self.view.frame), 20.f)];
    statusBarView.backgroundColor                       =  [UIColor colorWithHexString:@"0477BD" alpha:1.f];
    [self.navigationController.navigationBar addSubview:statusBarView];

    timerSeconds                                        =   0;
    self.timerLabel.text                                =   @"00:00:00";
    self.navigationItem.title                           =   NSLocalizedString(@"Record a Video", nil);
    
    // Start new camera video & audio session
    [self removeAllFolderMediaTempFiles];
    [self readAllFolderFile];
    
    [self startCameraSession];
    [self startStreamVideoRecording];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:0.5f
                     animations:^{
                         [self showLoaderWithText:NSLocalizedString(@"Launch text", nil)];
                     }
                     completion:^(BOOL finished) {
                         [self hideLoader];
                     }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    self.recordingMode                                  =   HRPVideoRecordViewControllerModeDismissed;
    [self.captureSession stopRunning];
    self.captureSession                                 =   nil;
    self.videoFileOutput                                =   nil;
    [_audioRecorder stop];
    _audioSession                                       =   nil;
    [_audioPlayer stop];
    [self stopAudioRecording];
    _composition                                        =   nil;
    _videoConnection                                    =   nil;
    
//    [self.videoPreviewLayer removeFromSuperlayer];
//    self.videoPreviewLayer                              =   nil;
    
    [timerVideo invalidate];
    timerSeconds                                        =   0;
    self.timerLabel.text                                =   [self formattedTime:timerSeconds];
    timerVideo                                          =   nil;

    [locationManager stopUpdatingLocation];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - UIViewControllerRotation -
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    if (!isVideoSaving) {
        self.videoPreviewLayer.frame                        =   CGRectMake(0.f, 0.f, size.width, size.height);
        
        self.statusViewVerticalSpaceConstraint.constant     =   ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait) ?
        0.f : -20.f;
        
        switch ([[UIDevice currentDevice] orientation]) {
            case UIDeviceOrientationPortrait: {
                previewNewOrientation                       =   AVCaptureVideoOrientationPortrait;
            }
                break;
            case UIDeviceOrientationPortraitUpsideDown:
                previewNewOrientation                       =   AVCaptureVideoOrientationPortraitUpsideDown;
                break;
                
            case UIDeviceOrientationLandscapeLeft: {
                previewNewOrientation                       =   AVCaptureVideoOrientationLandscapeRight;
                videoNewOrientation                         =   AVCaptureVideoOrientationLandscapeLeft;
            }
                break;
                
            case UIDeviceOrientationLandscapeRight: {
                [self.videoView.layer setAffineTransform:CGAffineTransformIdentity];
                
                previewNewOrientation                       =   AVCaptureVideoOrientationLandscapeLeft;
                videoNewOrientation                         =   AVCaptureVideoOrientationLandscapeRight;
            }
                break;
                
            default:
                previewNewOrientation                       =   AVCaptureVideoOrientationPortrait;
        }
        
        self.videoPreviewLayer.connection.videoOrientation  =   previewNewOrientation;
        self.videoConnection.videoOrientation               =   videoNewOrientation;
        
        [timerVideo invalidate];
        timerSeconds                                        =   0;
        timerVideo                                          =   [self createTimer];
        
        [self.videoFileOutput stopRecording];
    }
}


#pragma mark - Actions -
- (IBAction)actionControlButtonTap:(HRPButton *)sender {
    if (self.recordingMode == HRPVideoRecordViewControllerModeStreamVideo) {
        self.controlLabel.text                              =   NSLocalizedString(@"Violation", nil);
        isVideoSaving                                       =   YES;
        self.navigationItem.rightBarButtonItem.enabled      =   NO;
        
        [self startControlLabelFlashing];
        [self startAttentionVideoRecording];
    }
}


#pragma mark - NSNotification -
- (void)handleUserLogout:(NSNotification *)notification {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UIGestureRecognizer -
- (IBAction)tapGesture:(id)sender {
    [self actionControlButtonTap:self.controlButton];
}

    
#pragma mark - Methods -
- (void)startCameraSession {
    NSError *error;
    
    // Initialize the Session object
    self.captureSession                                 =   [[AVCaptureSession alloc] init];
    self.captureSession.sessionPreset                   =   AVCaptureSessionPresetHigh;

    // Initialize a Camera object
    AVCaptureDevice *videoDevice                        =   [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *videoInput                    =   [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    self.videoConnection                                =   [self.videoFileOutput connectionWithMediaType:AVMediaTypeVideo];

    if (videoNewOrientation)
        self.videoConnection.videoOrientation           =   videoNewOrientation;
    
    AVCaptureVideoStabilizationMode stabilizationMode   =   AVCaptureVideoStabilizationModeCinematic;
    
    if ([videoDevice.activeFormat isVideoStabilizationModeSupported:stabilizationMode])
        [self.videoConnection setPreferredVideoStabilizationMode:stabilizationMode];
    
    [self.captureSession addInput:videoInput];
    
    // Configure the audio session
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive:YES error:nil];
    
    // Find the desired input port
    NSArray* inputs = [audioSession availableInputs];
    AVAudioSessionPortDescription *builtInMic = nil;
    for (AVAudioSessionPortDescription* port in inputs) {
        if ([port.portType isEqualToString:AVAudioSessionPortBuiltInMic]) {
            builtInMic = port;
            break;
        }
    }
    
    // Find the desired microphone
    for (AVAudioSessionDataSourceDescription* source in builtInMic.dataSources) {
        if ([source.orientation isEqual:AVAudioSessionOrientationFront]) {
            [builtInMic setPreferredDataSource:source error:nil];
            [audioSession setPreferredInput:builtInMic error:&error];
            break;
        }
    }
    
    // VIDEO
    // Add output file
    self.videoFileOutput                                =   [[AVCaptureMovieFileOutput alloc] init];

    if ([self.captureSession canAddOutput:self.videoFileOutput])
        [self.captureSession addOutput:self.videoFileOutput];
    
    // Initialize the video preview layer
    self.videoPreviewLayer                              =   [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    [self.videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [self.videoPreviewLayer setFrame:self.videoView.layer.bounds];
   
    if (previewNewOrientation)
        self.videoPreviewLayer.connection.videoOrientation  =   previewNewOrientation;

    [self.videoView.layer insertSublayer:self.videoPreviewLayer below:self.controlButton.layer];
    [self.captureSession startRunning];
}

- (void)startAudioRecording {
    if (!_audioRecorder.recording) {
        [self setNewAudioRecorder];
        
        [_audioRecorder record];
    }
}

- (void)startStreamVideoRecording {
    [self startAudioRecording];
    [self.videoFileOutput startRecordingToOutputFileURL:[self setNewVideoFileURL:snippetNumber] recordingDelegate:self];
}

- (void)startAttentionVideoRecording {
    // Stop video capture and make the capture session object nil
    timerSeconds                                        =   0;
    self.recordingMode                                  =   HRPVideoRecordViewControllerModeAttentionVideo;
    
    [self.videoFileOutput stopRecording];
}

- (void)startControlLabelFlashing {
    if (isControlLabelFlashing)
        return;
    
    isControlLabelFlashing                              =   YES;
    self.controlLabel.alpha                             =   1.f;
    
    [UIView animateWithDuration:0.10f
                          delay:0.f
                        options:UIViewAnimationOptionCurveEaseInOut |
                                UIViewAnimationOptionRepeat         |
                                UIViewAnimationOptionAutoreverse    |
                                UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.controlLabel.alpha        =   0.f;
                     }
                     completion:^(BOOL finished) { }];
}

- (void)stopAudioRecording {
    if (_audioRecorder.recording)
        [_audioRecorder stop];
}

- (NSURL *)setNewVideoFileURL:(NSInteger)count {
    NSString *videoFilePath                             =   [mediaFolderPath stringByAppendingPathComponent:videoFilesNames[count]];
    NSURL *videoFileURL                                 =   [NSURL fileURLWithPath:videoFilePath];
    
    return videoFileURL;
}

- (NSURL *)setNewAudioFileURL:(NSInteger)count {
    NSString *audioFilePath                             =   [mediaFolderPath stringByAppendingPathComponent:audioFilesNames[count]];
    NSURL *audioFileURL                                 =   [NSURL fileURLWithPath:audioFilePath];
    
    return audioFileURL;
}

- (void)setNewAudioRecorder {
    NSError *error                                      =   nil;
    
    _audioSession                                       =   [AVAudioSession sharedInstance];
    [_audioSession setCategory:AVAudioSessionCategoryRecord error:nil];
    [_audioSession setActive:YES withOptions:0 error:nil];

    _audioRecorder                                      =   [[AVAudioRecorder alloc] initWithURL:[self setNewAudioFileURL:snippetNumber]
                                                                                        settings:audioRecordSettings
                                                                                           error:&error];
    if (error)
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Alert error API title", nil)
                                    message:[error localizedDescription]
                                   delegate:nil
                          cancelButtonTitle:nil
                          otherButtonTitles:NSLocalizedString(@"Alert error button Ok", nil), nil] show];
    
    else
        [_audioRecorder prepareToRecord];
}

- (void)createStoreDataPath {
    NSError *error;
    NSArray *paths                                  =   NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    arrayPath                                       =   paths[0]; // [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Photos"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:arrayPath]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:arrayPath
                                       withIntermediateDirectories:NO
                                                        attributes:nil
                                                             error:&error])
            NSLog(@"Create directory error: %@", error);
    }
}

- (NSTimer *)createTimer {
    return [NSTimer scheduledTimerWithTimeInterval:1.f
                                            target:self
                                          selector:@selector(timerTicked:)
                                          userInfo:nil
                                           repeats:YES];
}

- (void)timerTicked:(NSTimer *)timer {
    timerSeconds++;
    
    if (timerSeconds == sessionDuration) {
        if (self.recordingMode == HRPVideoRecordViewControllerModeStreamVideo)
            timerSeconds                                =   0;
        else {
            [timerVideo invalidate];
            timerSeconds                                =   0;
        }
        
        [self.videoFileOutput stopRecording];
    }
    
    self.timerLabel.text                                =   [self formattedTime:timerSeconds];
}

- (NSString *)formattedTime:(NSInteger)secondsTotal {
    NSInteger seconds                                   =   secondsTotal % 60;
    NSInteger minutes                                   =   (secondsTotal / 60) % 60;
    NSInteger hours                                     =   secondsTotal / 3600;
    
    return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
}

- (NSInteger)countVideoSnippets {
    NSArray *allFolderFiles                             =   [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mediaFolderPath error:nil];
    NSPredicate *predicate                              =   [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", @"snippet"];
    
    NSLog(@"HRPVideoRecordViewController (323): COUNT = %ld", (long)[[allFolderFiles filteredArrayUsingPredicate:predicate] count]);
    
    return [[allFolderFiles filteredArrayUsingPredicate:predicate] count];
}

- (void)deleteFolder {
    if ([[NSFileManager defaultManager] removeItemAtPath:mediaFolderPath error:nil])
        NSLog(@"HRPVideoRecordViewController (352): DELETE");
    else
        NSLog(@"HRPVideoRecordViewController (354): NOT DELETE");
}

- (void)readPhotosCollectionFromFile {
    NSArray *paths                                      =   NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    arrayPath                                           =   paths[0]; // [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Photos"];
    arrayPath                                           =   [arrayPath stringByAppendingPathComponent:[userApp objectForKey:@"userAppEmail"]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:arrayPath]) {
        NSData *arrayData                               =   [[NSData alloc] initWithContentsOfFile:arrayPath];
        photosDataSource                                =   [NSMutableArray array];
        
        if (arrayData)
            photosDataSource                            =   [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithData:arrayData]];
        else
            NSLog(@"File does not exist");
    }
}

- (void)readAllFolderFile {
    NSArray *allFolderFiles                             =   [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mediaFolderPath error:nil];
    
    NSLog(@"HRPVideoRecordViewController (335): FOLDER FILES = %@", allFolderFiles);
}

- (void)removeAllFolderMediaTempFiles {
    NSArray *allFolderFiles                             =   [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mediaFolderPath error:nil];
    
    for (NSString *fileName in allFolderFiles) {
        if ([fileName containsString:@"snippet_"] ||
            [fileName containsString:@"attention_video"])
            [[NSFileManager defaultManager] removeItemAtPath:[mediaFolderPath stringByAppendingPathComponent:fileName] error:nil];
    }
    
    // Start new video & audio session
    isVideoSaving                                       =   NO;
    self.controlButton.enabled                          =   YES;
}

- (void)removeMediaSnippets {
    NSArray *allFolderFiles                             =   [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mediaFolderPath error:nil];
    
    for (NSString *fileName in allFolderFiles) {
        if ([fileName containsString:@"snippet_video_1.mp4"] ||
            [fileName containsString:@"snippet_audio_1.caf"])
            [[NSFileManager defaultManager] removeItemAtPath:[mediaFolderPath stringByAppendingPathComponent:fileName] error:nil];
    }
}

- (void)mergeAndSaveVideoFile {
    if (!progressHUD.alpha) {
        progressHUD                                     =   [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        progressHUD.labelText                           =   NSLocalizedString(@"Merge & Save video", nil);
        progressHUD.color                               =   [UIColor colorWithHexString:@"05A9F4" alpha:0.8f];
        progressHUD.yOffset                             =   0.f;
        self.controlLabel.text                          =   nil;
    }

    // Create the AVMutable composition to add tracks
    self.composition                                    =   [AVMutableComposition composition];
    
    // Create the mutable composition track with video media type
    [self mergeAudioAndVideoFiles];
    
    // Create the export session to merge and save the video
    AVAssetExportSession *videoExportSession            =   [[AVAssetExportSession alloc] initWithAsset:self.composition
                                                                                             presetName:AVAssetExportPresetHighestQuality];
    
    NSString *videoFileName                             =   @"attention_video.mov";
    
    NSURL *videoURL                                     =   [[NSURL alloc] initFileURLWithPath:
                                                             [mediaFolderPath stringByAppendingPathComponent:videoFileName]];
    
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
    AVMutableCompositionTrack *videoCompositionTrack    =   [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                                          preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVMutableCompositionTrack *audioCompositionTrack    =   [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                                          preferredTrackID:kCMPersistentTrackID_Invalid];

    // Create assets URL's for videos snippets
    NSArray *allFolderFiles                             =   [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mediaFolderPath error:nil];
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
        NSString *videoSnippetFilePath                  =   [mediaFolderPath stringByAppendingPathComponent:allVideoTempSnippets[i]];
        AVURLAsset *videoSnippetAsset                   =   [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:videoSnippetFilePath] options:nil];
        NSString *audioSnippetFilePath                  =   [mediaFolderPath stringByAppendingPathComponent:allAudioTempSnippets[i]];
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
                                                    videoAssetURL   =   assetURL;
                                                    [self saveVideoRecordToFile];
                                                    
                                                    [self removeAllFolderMediaTempFiles];
                                                }
                                            });
                                        }];
        }
    }
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

    videoImageOriginal                                  =   [[UIImage alloc] initWithCGImage:oneRef scale:1.f orientation:imageOrientation];
    
    if (videoImageOriginal)
        [self mergeAndSaveVideoFile];
}

- (void)showAlertViewWithTitle:(NSString *)titleText andMessage:(NSString *)messageText {
   [[[UIAlertView alloc] initWithTitle:titleText
                               message:messageText
                              delegate:nil
                     cancelButtonTitle:nil
                     otherButtonTitles:NSLocalizedString(@"Alert error button Ok", nil), nil] show];
}
                                                           
- (void)saveVideoRecordToFile {
    HRPPhoto *photo                                     =   [[HRPPhoto alloc] init];
    ALAssetsLibrary *assetsLibrary                      =   [[ALAssetsLibrary alloc] init];
    
    (photosDataSource.count == 0) ? [photosDataSource addObject:photo] : [photosDataSource insertObject:photo atIndex:0];

    [assetsLibrary writeImageToSavedPhotosAlbum:videoImageOriginal.CGImage
                                    orientation:(ALAssetOrientation)videoImageOriginal.imageOrientation
                                completionBlock:^(NSURL *assetURL, NSError *error) {
                                    photo.assetsVideoURL =   [videoAssetURL absoluteString];
                                    photo.assetsPhotoURL =   [assetURL absoluteString];
                                    
                                    photo.latitude      =   latitude;
                                    photo.longitude     =   longitude;
                                    photo.isVideo       =   YES;
                                    
                                    [photosDataSource replaceObjectAtIndex:0 withObject:photo];                                    
                                    [self savePhotosCollectionToFile];
                                }];
}

- (void)savePhotosCollectionToFile {
    NSData *arrayData                                   =   [NSKeyedArchiver archivedDataWithRootObject:photosDataSource];
    NSArray *paths                                      =   NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    arrayPath                                           =   paths[0]; // [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Photos"];
    arrayPath                                           =   [arrayPath stringByAppendingPathComponent:[userApp objectForKey:@"userAppEmail"]];
    
    [[NSFileManager defaultManager] createFileAtPath:arrayPath
                                            contents:arrayData
                                          attributes:nil];
    
    self.navigationItem.rightBarButtonItem.enabled      =   YES;
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    // Start new Video Session
    [self startCameraSession];
    timerVideo                                          =   [self createTimer];
    
    [self startStreamVideoRecording];
}


#pragma mark - AVCaptureFileOutputRecordingDelegate -
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL
      fromConnections:(NSArray *)connections {
    if (!timerSeconds)
        timerSeconds                                    =   0;
    
    if (!timerVideo)
        timerVideo                                      =   [self createTimer];
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
      fromConnections:(NSArray *)connections error:(NSError *)error {

    // START Button taped
    if (self.recordingMode == HRPVideoRecordViewControllerModeStreamVideo) {
        snippetNumber                                   =   (snippetNumber == 0) ? 1 : 0;
        
        [self stopAudioRecording];
        [self startStreamVideoRecording];
        
        // Delete media snippets_1
        if (snippetNumber == 0)
            [self removeMediaSnippets];
    }
    
    // ATTENTION Button taped
    else if (self.recordingMode == HRPVideoRecordViewControllerModeAttentionVideo) {
        // Get first video frame image
        if (snippetNumber == 2) {
            snippetNumber                               =   0;
            [self stopAudioRecording];
            
            NSString *videoFilePath                     =   [mediaFolderPath stringByAppendingPathComponent:videoFilesNames[2]];
            NSURL *videoFileURL                         =   [NSURL fileURLWithPath:videoFilePath];
            self.recordingMode                          =   HRPVideoRecordViewControllerModeStreamVideo;

            [self extractFirstFrameFromVideoFilePath:videoFileURL];
        }
        
        else {
            snippetNumber                               =   2;

            [self stopAudioRecording];
            [self startStreamVideoRecording];
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


#pragma mark - UITextFieldDelegate -
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}


#pragma mark - CLLocationManagerDelegate -
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [self showAlertViewWithTitle:NSLocalizedString(@"Alert error location title", nil)
                      andMessage:NSLocalizedString(@"Alert error location retrieving message", nil)];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *crnLoc                                  =   [locations lastObject];
    latitude                                            =   crnLoc.coordinate.latitude;
    longitude                                           =   crnLoc.coordinate.longitude;
}


#pragma mark - OEEventsObserverDelegate -
- (void) pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID {
    NSPredicate *predicate                              =   [NSPredicate predicateWithFormat:@"SELF == [cd] %@", hypothesis];
    NSString *voiceCommand                              =   [voiceCommands filteredArrayUsingPredicate:predicate][0];
    
    if (self.recordingMode == HRPVideoRecordViewControllerModeStreamVideo) {
        if (([NSLocalizedString(@"Settings", nil) isEqualToString:@"Settings"] && [voiceCommand isEqualToString:@"VIOLATION"])      ||
            ([NSLocalizedString(@"Settings", nil) isEqualToString:@"Настройки"] && [voiceCommand isEqualToString:@"NARUSHENIE"])     ||
            ([NSLocalizedString(@"Settings", nil) isEqualToString:@"Налаштування"] && [voiceCommand isEqualToString:@"PAYRUSHAYNNA"]))
            [self actionControlButtonTap:self.controlButton];
    }
}

- (void) pocketsphinxDidStartListening {
    NSLog(@"Pocketsphinx is now listening.");
}

- (void) pocketsphinxDidDetectSpeech {
    NSLog(@"Pocketsphinx has detected speech.");
}

- (void) pocketsphinxDidDetectFinishedSpeech {
    //    NSLog(@"Pocketsphinx has detected a period of silence, concluding an utterance.");
}

- (void) pocketsphinxDidStopListening {
    //    NSLog(@"Pocketsphinx has stopped listening.");
}

- (void) pocketsphinxDidSuspendRecognition {
    //    NSLog(@"Pocketsphinx has suspended recognition.");
}

- (void) pocketsphinxDidResumeRecognition {
    //    NSLog(@"Pocketsphinx has resumed recognition.");
}

- (void) pocketsphinxDidChangeLanguageModelToFile:(NSString *)newLanguageModelPathAsString andDictionary:(NSString *)newDictionaryPathAsString {
    //    NSLog(@"Pocketsphinx is now using the following language model: \n%@ and the following dictionary: %@",newLanguageModelPathAsString,newDictionaryPathAsString);
}

- (void) pocketSphinxContinuousSetupDidFailWithReason:(NSString *)reasonForFailure {
    //    NSLog(@"Listening setup wasn't successful and returned the failure reason: %@", reasonForFailure);
}

- (void) pocketSphinxContinuousTeardownDidFailWithReason:(NSString *)reasonForFailure {
    //    NSLog(@"Listening teardown wasn't successful and returned the failure reason: %@", reasonForFailure);
}

- (void) testRecognitionCompleted {
    //    NSLog(@"A test file that was submitted for recognition is now complete.");
}

@end