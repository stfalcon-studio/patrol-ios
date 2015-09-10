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
#import <MediaPlayer/MediaPlayer.h>
#import "UIColor+HexColor.h"
#import "HRPButton.h"
#import "MBProgressHUD.h"


@interface HRPVideoRecordViewController () <AVCaptureFileOutputRecordingDelegate>

@property (strong, nonatomic) IBOutlet UIView *statusView;
@property (strong, nonatomic) IBOutlet UIView *videoView;
@property (strong, nonatomic) IBOutlet HRPButton *controlButton;
@property (strong, nonatomic) IBOutlet UILabel *controlLabel;
@property (strong, nonatomic) IBOutlet UIButton *resetButton;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *statusViewVerticalSpaceConstraint;

@property (strong, nonatomic) AVCaptureSession *videoSession;
@property (strong, nonatomic) AVCaptureConnection *videoConnection;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (strong, nonatomic) AVCaptureMovieFileOutput *videoFileOutput;
@property (strong, nonatomic) IBOutlet UILabel *timerLabel;

- (void)startStreamVideoRecord;
- (void)startAttentionVideoRecord;

@end


@implementation HRPVideoRecordViewController {
    MBProgressHUD *progressHUD;

    NSTimer *timerVideo;
    NSString *videoFolderPath;
    NSInteger timerSeconds;
    NSInteger snippetNumber;
    UIImage *videoImageOriginal;
}

#pragma mark - Constructors -
- (void)viewDidLoad {
    [super viewDidLoad];

    NSLog(@"self.statusView.bounds 0 = %@", NSStringFromCGRect(self.statusView.frame));

    // App Folder
    videoFolderPath                                     =   [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];

    // Create ProgressHUD
    progressHUD                                         =   [[MBProgressHUD alloc] init];

//    [self deleteFolder];
    [self readVideoFile];
    
    // Set items
    self.controlButton.tag                              =   0;
    self.controlLabel.text                              =   NSLocalizedString(@"Start", nil);
    self.timerLabel.text                                =   @"00:00:00";
    snippetNumber                                       =   0;
    
    [self.resetButton setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
    
    [self initCameraView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Remove the video preview layer from the viewPreview view's layer.
    [self.videoSession stopRunning];
    [self.videoPreviewLayer removeFromSuperlayer];

    self.videoPreviewLayer                              =   nil;
    self.videoSession                                   =   nil;
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
    AVCaptureVideoOrientation newOrientation;
    
    self.videoPreviewLayer.frame                        =   self.videoView.bounds;
    
    self.statusViewVerticalSpaceConstraint.constant     =   ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait) ?
                                                            0.f : -20.f;
    
    switch ([[UIDevice currentDevice] orientation]) {
        case UIDeviceOrientationPortrait:
            newOrientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            newOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIDeviceOrientationLandscapeLeft:
            newOrientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        case UIDeviceOrientationLandscapeRight:
            [self.videoView.layer setAffineTransform:CGAffineTransformIdentity];
            break;
        default:
            newOrientation = AVCaptureVideoOrientationPortrait;
    }
    
    self.videoPreviewLayer.connection.videoOrientation  =   newOrientation;

    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscape;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [[UIApplication sharedApplication] statusBarOrientation];
}


#pragma mark - Actions -
- (IBAction)actionControlButtonTap:(HRPButton *)sender {
    [UIView animateWithDuration:0.05f
                     animations:^{
                         sender.fillColor               =   [UIColor colorWithHexString:@"05A9F4" alpha:0.4f];
                         sender.borderColor             =   [UIColor colorWithHexString:@"FF464D" alpha:0.4f];
                     } completion:^(BOOL finished) {
                         sender.fillColor               =   [UIColor colorWithHexString:@"05A9F4" alpha:0.8f];
                         sender.borderColor             =   [UIColor colorWithHexString:@"FF464D" alpha:0.8f];
                     }];
    
    self.controlButton.tag++;

    // Start record stream video session
    if (self.controlButton.tag == 1) {
        self.controlLabel.text                          =   NSLocalizedString(@"Attention", nil);
        
        [self startStreamVideoRecord];
    }
    
    // Start record attention video session
    else if (self.controlButton.tag == 2)
        [self startAttentionVideoRecord];
}

- (IBAction)actionResetButtonTap:(UIButton *)sender {
    [self.videoSession stopRunning];
    [self.videoFileOutput stopRecording];
    [self removeAllTempVideoSnippets];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

// TEST
- (IBAction)actionTest:(UIButton *)sender {
    [self readVideoFile];
}

- (IBAction)actionDELETE:(id)sender {
    [self removeAllTempVideoSnippets];
    [self readVideoFile];
}

- (IBAction)actiomMERGE:(id)sender {
    [self mergeAndSaveVideoFile];
}


#pragma mark - Methods -
- (void)initCameraView {
    NSError *error;
    
    // Initialize the Session object
    self.videoSession                                   =   [[AVCaptureSession alloc] init];
    self.videoSession.sessionPreset                     =   AVCaptureSessionPresetHigh;

    // Initialize a Camera object
    AVCaptureDevice *videoDevice                        =   [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *videoInput                    =   [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    self.videoConnection                                =   [self.videoFileOutput connectionWithMediaType:AVMediaTypeVideo];
    AVCaptureVideoStabilizationMode stabilizationMode   =   AVCaptureVideoStabilizationModeCinematic;
    
    if ([videoDevice.activeFormat isVideoStabilizationModeSupported:stabilizationMode])
        [self.videoConnection setPreferredVideoStabilizationMode:stabilizationMode];
    
    [self.videoSession addInput:videoInput];
    
    // Add support audio
    AVCaptureDevice *audioDevice                        =   [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioInput                    =   [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    [self.videoSession addInput:audioInput];
    
    // Add support output video file
    self.videoFileOutput                                =   [[AVCaptureMovieFileOutput alloc] init];

    if ([self.videoSession canAddOutput:self.videoFileOutput])
        [self.videoSession addOutput:self.videoFileOutput];
    
    // Initialize the video preview layer
    self.videoPreviewLayer                              =   [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.videoSession];
    [self.videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [self.videoPreviewLayer setFrame:self.videoView.layer.bounds];
   
    [self.videoView.layer insertSublayer:self.videoPreviewLayer below:self.controlButton.layer];
    [self.videoSession startRunning];
}

- (void)startStreamVideoRecord {
    // Start video capture
    snippetNumber++;
    
    NSURL *videoFolderURL                               =   [NSURL fileURLWithPath:videoFolderPath isDirectory:YES];
    NSString *videoFileName                             =   [NSString stringWithFormat:@"snippet_%06li.mp4", (long)snippetNumber];
    NSURL *videoFileURL                                 =   [NSURL URLWithString:videoFileName relativeToURL:videoFolderURL];
    
//    NSLog(@"STREAM: name = %@", videoFileName);
    
    [self.videoFileOutput startRecordingToOutputFileURL:videoFileURL recordingDelegate:self];
}

- (void)startAttentionVideoRecord {
    // Stop video capture and make the capture session object nil
    timerSeconds                                        =   0;
    self.controlButton.userInteractionEnabled           =   NO;
    
    [self.videoFileOutput stopRecording];
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
    
    if (timerSeconds == 6) {
        if (self.controlButton.tag == 1)
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
    NSArray *allFolderFiles                             =   [[NSFileManager defaultManager] contentsOfDirectoryAtPath:videoFolderPath error:nil];
    NSPredicate *predicate                              =   [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", @"snippet"];
    
    NSLog(@"COUNT = %ld", (long)[[allFolderFiles filteredArrayUsingPredicate:predicate] count]);
    
    return [[allFolderFiles filteredArrayUsingPredicate:predicate] count];
}

- (void)removeFirstTempVideoSnippet {
    NSArray *allFolderFiles                             =   [[NSFileManager defaultManager] contentsOfDirectoryAtPath:videoFolderPath error:nil];
    NSPredicate *predicate                              =   [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", @"snippet"];
    NSArray *allTempVideoSnippets                       =   [allFolderFiles filteredArrayUsingPredicate:predicate];
    NSString *videoFileName                             =   [videoFolderPath stringByAppendingPathComponent:allTempVideoSnippets[0]];
    
    if ([[NSFileManager defaultManager] removeItemAtPath:videoFileName error:nil])
        NSLog(@"DELETE: array = %@", allTempVideoSnippets);
    else
        NSLog(@"NOT DELETE");
}

- (void)deleteFolder {
    if ([[NSFileManager defaultManager] removeItemAtPath:videoFolderPath error:nil])
        NSLog(@"DELETE");
    else
        NSLog(@"NOT DELETE");
}

- (void)removeAllTempVideoSnippets {
    NSArray *allFolderFiles                             =   [[NSFileManager defaultManager] contentsOfDirectoryAtPath:videoFolderPath error:nil];
    
    for (NSString *fileName in allFolderFiles) {
        if ([fileName containsString:@"snippet"] /*|| [fileName containsString:@"attention_video"]*/)
            [[NSFileManager defaultManager] removeItemAtPath:[videoFolderPath stringByAppendingPathComponent:fileName] error:nil];
    }
}

- (void)readVideoFile {
    NSArray *allFolderFiles                             =   [[NSFileManager defaultManager] contentsOfDirectoryAtPath:videoFolderPath error:nil];
  
    NSLog(@"FOLDER FILES = %@", allFolderFiles);
}

- (void)mergeAndSaveVideoFile {
    if (!progressHUD.alpha) {
        progressHUD                                     =   [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        progressHUD.labelText                           =   NSLocalizedString(@"Merge & Save video", nil);
        progressHUD.color                               =   [UIColor colorWithHexString:@"05A9F4" alpha:0.8f];
        progressHUD.yOffset                             =   0.f;
    }

    // Create the AVMutable composition to add tracks
    AVMutableComposition *composition                   =   [[AVMutableComposition alloc]init];
    
    // Create the mutable composition track with video media type
    AVMutableCompositionTrack *composedTrack            =   [composition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                                     preferredTrackID:kCMPersistentTrackID_Invalid];

    // Create assets URL's for videos snippets
    NSArray *allFolderFiles                             =   [[NSFileManager defaultManager] contentsOfDirectoryAtPath:videoFolderPath error:nil];
    NSPredicate *predicate                              =   [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", @"snippet"];
    NSMutableArray *allTempVideoSnippets                =   [NSMutableArray arrayWithArray:[allFolderFiles filteredArrayUsingPredicate:predicate]];

    // Sort array
    NSSortDescriptor *sortDescription                   =   [[NSSortDescriptor alloc] initWithKey:nil ascending:NO];
    allTempVideoSnippets                                =   [NSMutableArray arrayWithArray:
                                                             [allTempVideoSnippets sortedArrayUsingDescriptors:@[sortDescription]]];
    
    for (int i = 0; i < allTempVideoSnippets.count; i++) {
        NSString *videoSnippetFilePath                  =   [videoFolderPath stringByAppendingPathComponent:allTempVideoSnippets[i]];
        AVURLAsset *videoSnippet                        =   [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:videoSnippetFilePath] options:nil];

        // Set the video snippet time ranges in composition
        [composedTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoSnippet.duration)
                               ofTrack:[[videoSnippet tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                                atTime:kCMTimeZero
                                 error:nil];
        
        [composedTrack setPreferredTransform:videoSnippet.preferredTransform];
    }
    
    // Create the export session to merge and save the video
    AVAssetExportSession *videoExportSession            =   [[AVAssetExportSession alloc]initWithAsset:composition
                                                                                            presetName:AVAssetExportPresetHighestQuality];
    
    NSString *videoFileName                             =   [NSString stringWithFormat:@"attention_video_%li.mp4", (long)arc4random_uniform(1000)];
    
    NSURL *videoURL                                     =   [[NSURL alloc] initFileURLWithPath:
                                                             [videoFolderPath stringByAppendingPathComponent:videoFileName]];
    
    videoExportSession.outputURL                        =   videoURL;
    videoExportSession.outputFileType                   =   @"com.apple.quicktime-movie";
    videoExportSession.shouldOptimizeForNetworkUse      =   YES;
    
    [videoExportSession exportAsynchronouslyWithCompletionHandler:^{
        switch (videoExportSession.status) {
            case AVAssetExportSessionStatusFailed:
                NSLog(@"Failed to export video");
                break;
                
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"export cancelled");
                break;
                
            case AVAssetExportSessionStatusCompleted: {
                // Here you go you have got the merged video :)
                NSLog(@"Merging completed");
                [self exportDidFinish:videoExportSession];
            }
                break;
                
            default:
                break;
        }
    }];
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
                                                else
                                                    [self dismissViewControllerAnimated:YES
                                                                             completion:^{
                                                                                 [[NSNotificationCenter defaultCenter] postNotificationName:@"HRPVideoRecordViewControllerDismiss"
                                                                                                                                     object:nil
                                                                                                                                   userInfo:@{
                                                                                                                                                    @"videoURL"     :   assetURL,
                                                                                                                                                    @"videoImage"   :   videoImageOriginal
                                                                                                                                              }];
                                                                                 
                                                                                 [self removeAllTempVideoSnippets];
                                                                             }];
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
    if (self.controlButton.tag == 1) {
        if ([self countVideoSnippets] == 2) {
            [self removeFirstTempVideoSnippet];
            [self startStreamVideoRecord];
        }
        
        else
            [self startStreamVideoRecord];
    }
    
    // ATTENTION Button taped
    else if (self.controlButton.tag == 2) {
        if ([self countVideoSnippets] == 3)
            [self removeFirstTempVideoSnippet];
        
        [self startStreamVideoRecord];
        self.controlButton.tag++;
    }
    
    // Get video image
    else if (self.controlButton.tag == 3)
        [self extractFirstFrameFromVideoFilePath:outputFileURL];
}

@end
