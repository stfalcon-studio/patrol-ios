//
//  HRPVideoRecordViewController.m
//  HromadskyiPatrul
//
//  Created by msm72 on 04.09.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//


#import "HRPVideoRecordViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "UIColor+HexColor.h"
#import "HRPButton.h"


@interface HRPVideoRecordViewController () <AVCaptureFileOutputRecordingDelegate>

@property (strong, nonatomic) IBOutlet UIView *videoView;
@property (strong, nonatomic) IBOutlet HRPButton *controlButton;
@property (strong, nonatomic) IBOutlet UILabel *controlLabel;

@property (strong, nonatomic) AVCaptureSession *videoSession;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (strong, nonatomic) AVCaptureMovieFileOutput *videoFileOutput;
@property (strong, nonatomic) IBOutlet UILabel *timerLabel;

- (void)startStreamVideoRecord;
- (void)startAttentionVideoRecord;

@end


@implementation HRPVideoRecordViewController {
    NSTimer *timerVideo;
    NSString *videoFolderPath;
    NSInteger timerSeconds;
    NSInteger snippetNumber;
}

#pragma mark - Constructors -
- (void)viewDidLoad {
    [super viewDidLoad];

    // App Folder
    videoFolderPath                                     =   [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];

//    [self deleteFolder];
    [self readVideoFile];
    
    // Set items
    self.controlButton.tag                              =   0;
    self.controlLabel.text                              =   NSLocalizedString(@"Start", nil);
    self.timerLabel.text                                =   @"00:00:00";
    snippetNumber                                       =   0;
    
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
    
//    [[NSURLCache sharedURLCache] removeAllCachedResponses];
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
    if (self.controlButton.tag) {
        self.controlLabel.text                          =   NSLocalizedString(@"Attention", nil);
        
        [self startStreamVideoRecord];
    }
    
    // Start record attention video session
    else
        [self startAttentionVideoRecord];
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
    
    NSLog(@"STREAM: name = %@", videoFileName);
    
    [self.videoFileOutput startRecordingToOutputFileURL:videoFileURL recordingDelegate:self];
}

- (void)startAttentionVideoRecord {
    // Stop video capture and make the capture session object nil
    timerSeconds                                        =   0;
    self.controlButton.userInteractionEnabled           =   NO;
    
    [self.videoFileOutput stopRecording];
    [self startStreamVideoRecord];
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
    
    if (timerSeconds == 4) {
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
    NSMutableArray *videoFiles                          =   [NSMutableArray arrayWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:videoFolderPath error:nil]];

    return videoFiles.count;
}

- (void)removeFirstVideoSnippet {
    NSMutableArray *videoFiles                          =   [NSMutableArray arrayWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:videoFolderPath error:nil]];

    NSString *videoFileName                             =   [videoFolderPath stringByAppendingPathComponent:videoFiles[0]];
    
    if ([[NSFileManager defaultManager] removeItemAtPath:videoFileName error:nil])
        NSLog(@"DELETE: array = %@", videoFiles);
    else
        NSLog(@"NOT DELETE");
}

- (void)deleteFolder {
    if ([[NSFileManager defaultManager] removeItemAtPath:videoFolderPath error:nil])
        NSLog(@"DELETE");
    else
        NSLog(@"NOT DELETE");
}

- (void)readVideoFile {
    NSArray *videoFiles                                 =   [[NSFileManager defaultManager] contentsOfDirectoryAtPath:videoFolderPath error:nil];
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
    if (self.controlButton.tag == 1) {
        if ([self countVideoSnippets] == 2) {
            [self removeFirstVideoSnippet];
            [self startStreamVideoRecord];
        }
        
        else
            [self startStreamVideoRecord];
    }
}

@end
