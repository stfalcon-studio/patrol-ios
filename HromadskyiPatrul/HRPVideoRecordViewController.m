//
//  HRPVideoRecordViewController.m
//  HromadskyiPatrul
//
//  Created by msm72 on 04.09.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//


#import "HRPVideoRecordViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "UIColor+HexColor.h"
#import "HRPButton.h"
#import "MBProgressHUD.h"
#import <OpenEars/OELanguageModelGenerator.h>
#import <OpenEars/OEAcousticModel.h>
#import <OpenEars/OEPocketsphinxController.h>
#import <OpenEars/OEAcousticModel.h>
#import <OpenEars/OEEventsObserver.h>


typedef NS_ENUM (NSInteger, HRPVideoRecordViewControllerMode) {
    HRPVideoRecordViewControllerModeStreamVideo,
    HRPVideoRecordViewControllerModeAttentionVideo
};


@interface HRPVideoRecordViewController () <AVCaptureFileOutputRecordingDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate, OEEventsObserverDelegate>

@property (assign, nonatomic) HRPVideoRecordViewControllerMode recordingMode;

@property (strong, nonatomic) OEEventsObserver *openEarsEventsObserver;

@property (strong, nonatomic) IBOutlet UIView *statusView;
@property (strong, nonatomic) IBOutlet UIView *videoView;
@property (strong, nonatomic) IBOutlet UIView *testTopView;

@property (strong, nonatomic) IBOutlet HRPButton *controlButton;
@property (strong, nonatomic) IBOutlet UILabel *controlLabel;
@property (strong, nonatomic) IBOutlet UIButton *resetButton;

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

    AVCaptureVideoOrientation previewNewOrientation;
    AVCaptureVideoOrientation videoNewOrientation;

    NSTimer *timerVideo;
    NSString *mediaFolderPath;
    NSInteger timerSeconds;
    NSInteger snippetNumber;
    NSInteger sessionDuration;
    UIImage *videoImageOriginal;
    NSArray *videoFilesNames;
    NSArray *audioFilesNames;
    NSDictionary *audioRecordSettings;
    NSString *voiceLanguageModelPath;
    NSString *voiceDictionaryPath;
    NSArray *voiceCommands;

    BOOL isVideoSaving;
    BOOL isControlLabelFlashing;
}

#pragma mark - Constructors -
- (void)viewDidLoad {
    [super viewDidLoad];

    // NSLog(@"self.statusView.bounds 0 = %@", NSStringFromCGRect(self.statusView.frame));
    
    // Set Session Duration
    sessionDuration                                     =   10;
    
    // Test Top View
    self.testTopView.alpha                              =   0.f;
    
    // App Folder
    mediaFolderPath                                     =   [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];

    // Set Media session parameters
    snippetNumber                                       =   0;
    isVideoSaving                                       =   NO;
    isControlLabelFlashing                              =   NO;
    videoFilesNames                                     =   @[@"snippet_video_0.mp4", @"snippet_video_1.mp4", @"snippet_video_2.mp4"];
    audioFilesNames                                     =   @[@"snippet_audio_0.caf", @"snippet_audio_1.caf", @"snippet_audio_2.caf"];
    self.recordingMode                                  =   HRPVideoRecordViewControllerModeStreamVideo;
    
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
//    self.controlButton.tag                              =   0;
    self.controlLabel.text                              =   nil; //NSLocalizedString(@"Attention", nil);
    self.timerLabel.text                                =   @"00:00:00";
    
    [self.resetButton setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
    
    // Start new camera video & audio session
    [self removeAllFolderMediaTempFiles];
    [self readAllFolderFile];
    [self startCameraSession];
    
    // Set Voice command
    self.openEarsEventsObserver                         =   [[OEEventsObserver alloc] init];
    [self.openEarsEventsObserver setDelegate:self];
    [self setVoiceRecognizeSpeech];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self startStreamVideoRecording];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Remove the video preview layer from the viewPreview view's layer.
    [self.captureSession stopRunning];
    [self.videoPreviewLayer removeFromSuperlayer];

    self.videoPreviewLayer                              =   nil;
    self.captureSession                                 =   nil;
    self.videoFileOutput                                =   nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - UIViewControllerRotation -
- (BOOL)shouldAutorotate {
    BOOL isRotationPossible                                 =   !isVideoSaving;
    
    if (isRotationPossible) {
        self.videoPreviewLayer.frame                        =   self.videoView.bounds;
        
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

        return YES;
    }
    
    else
        return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscape;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [[UIApplication sharedApplication] statusBarOrientation];
}


#pragma mark - Actions -
- (IBAction)actionControlButtonTap:(HRPButton *)sender {
    if (self.recordingMode == HRPVideoRecordViewControllerModeStreamVideo) {
        self.controlLabel.text                              =   NSLocalizedString(@"Attention", nil);
        
        [self startControlLabelFlashing];
        [self startAttentionVideoRecording];
    }
}

- (IBAction)actionResetButtonTap:(UIButton *)sender {
    [self.captureSession stopRunning];
    [self.videoFileOutput stopRecording];
    [self removeAllFolderMediaTempFiles];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

// TEST
- (IBAction)actionTest:(UIButton *)sender {
    [self readAllFolderFile];
}

- (IBAction)actionDELETE:(id)sender {
    [self removeAllFolderMediaTempFiles];
    [self readAllFolderFile];
}

- (IBAction)actiomMERGE:(id)sender {
    [self mergeAndSaveVideoFile];
}

- (IBAction)actionPLAY:(id)sender {
    if (!_audioRecorder.recording) {
        NSError *error;
        
        if (self.textField.text.length > 0)
            snippetNumber = [self.textField.text integerValue];
        
        _audioRecorder                  =   [[AVAudioRecorder alloc] initWithURL:[self setNewAudioFileURL:snippetNumber]
                                                                        settings:audioRecordSettings
                                                                           error:&error];
        
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:_audioRecorder.url error:&error];
        _audioPlayer.delegate = self;
        [_audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
        
        if (error)
            NSLog(@"Error: %@", [error localizedDescription]);
        
        else [_audioPlayer play];
    }
}


#pragma mark - UIGestureRecognizer -
- (IBAction)tapGesture:(id)sender {
    [self.textField resignFirstResponder];
    
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
        if (![OEPocketsphinxController sharedInstance].isListening)
            [[OEPocketsphinxController sharedInstance] setActive:TRUE error:nil];
        
        [self setNewAudioRecorder];
        
        [_audioRecorder record];
    }
}

- (void)startStreamVideoRecording {
    [self startAudioRecording];
    [self.videoFileOutput startRecordingToOutputFileURL:[self setNewVideoFileURL:snippetNumber] recordingDelegate:self];
    [self startVoiceRecognizeSpeech];
}

- (void)startAttentionVideoRecording {
    // Stop video capture and make the capture session object nil
    timerSeconds                                        =   0;
//    self.controlButton.enabled                          =   NO;
    self.recordingMode                                  =   HRPVideoRecordViewControllerModeAttentionVideo;
    
    [self.videoFileOutput stopRecording];
}

- (void)stopAudioRecording {
    if (_audioRecorder.recording) {
        [_audioRecorder stop];
        [self stopVoiceRecognizeSpeech];
    }
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

- (void)setVoiceRecognizeSpeech {
    NSString *voiceFileName                             =   @"voiceWords";
    OELanguageModelGenerator *lmGenerator               =   [[OELanguageModelGenerator alloc] init];
    [[OEPocketsphinxController sharedInstance] setActive:TRUE error:nil];
    
    voiceCommands                                       =   [NSArray arrayWithObjects:
                                                                @"VIDEO",
                                                                @"PHOTO",
                                                                @"ATTENTION",
                                                                @"START",
                                                                @"RECORD", nil];
    
    
    // Change "AcousticModelEnglish" to "AcousticModelSpanish" to create a Spanish language model instead of an English one.
    NSError *err                                        =   [lmGenerator generateLanguageModelFromArray:voiceCommands
                                                                                         withFilesNamed:voiceFileName
                                                                                 forAcousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"]];
    
    if (err == nil) {
        voiceLanguageModelPath                          =   [lmGenerator pathToSuccessfullyGeneratedLanguageModelWithRequestedName:voiceFileName];
        voiceDictionaryPath                             =   [lmGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName:voiceFileName];
    } else
        NSLog(@"Error: %@",[err localizedDescription]);
}

- (void)startVoiceRecognizeSpeech {
    if (![OEPocketsphinxController sharedInstance].isListening) {
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:voiceLanguageModelPath
                                                                        dictionaryAtPath:voiceDictionaryPath
                                                                     acousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"]
                                                                     languageModelIsJSGF:FALSE];
    }
}

- (void)stopVoiceRecognizeSpeech {
    NSError *error                                  =   nil;

    if ([OEPocketsphinxController sharedInstance].isListening) {
        error                                       =   [[OEPocketsphinxController sharedInstance] stopListening];
        
        if (error)
            NSLog(@"Error stopping listening in stopButtonAction: %@", error);
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
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)removeMediaSnippets {
    NSArray *allFolderFiles                             =   [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mediaFolderPath error:nil];
    
    for (NSString *fileName in allFolderFiles) {
        if ([fileName containsString:@"snippet_video_1.mp4"] ||
            [fileName containsString:@"snippet_audio_1.caf"])
            [[NSFileManager defaultManager] removeItemAtPath:[mediaFolderPath stringByAppendingPathComponent:fileName] error:nil];
    }
}

- (void)readAllFolderFile {
    NSArray *allFolderFiles                             =   [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mediaFolderPath error:nil];
  
    NSLog(@"HRPVideoRecordViewController (335): FOLDER FILES = %@", allFolderFiles);
}

- (void)mergeAndSaveVideoFile {
    if (!progressHUD.alpha) {
        progressHUD                                     =   [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        progressHUD.labelText                           =   NSLocalizedString(@"Merge & Save video", nil);
        progressHUD.color                               =   [UIColor colorWithHexString:@"05A9F4" alpha:0.8f];
        progressHUD.yOffset                             =   0.f;
        isVideoSaving                                   =   YES;
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

    for (int i = 0; i < allVideoTempSnippets.count; i++) {
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

- (void)exportDidFinish:(AVAssetExportSession*)session {
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
                                                    [self removeAllFolderMediaTempFiles];
                                                    [self startCameraSession];
                                                    timerVideo  =   [self createTimer];

                                                    [self startStreamVideoRecording];
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


#pragma mark - OEEventsObserverDelegate -
- (void) pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID {
    NSPredicate *predicate                              =   [NSPredicate predicateWithFormat:@"SELF == [cd] %@", hypothesis];
    NSString *voiceCommand                              =   [voiceCommands filteredArrayUsingPredicate:predicate][0];

    if (voiceCommand && self.recordingMode == HRPVideoRecordViewControllerModeStreamVideo)
        [self actionControlButtonTap:self.controlButton];
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