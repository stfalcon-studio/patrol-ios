//
//  HRPVideoRecordViewController.m
//  HromadskyiPatrul
//
//  Created by msm72 on 19.12.15.
//  Copyright © 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPVideoRecordViewController.h"
#import "HRPCollectionViewController.h"
//#import "HRPVideoRecordView.h"
#import "HRPCameraManager.h"
#import "HRPLabel.h"


@interface HRPVideoRecordViewController ()

@end


@implementation HRPVideoRecordViewController {
    HRPCameraManager *_cameraManager;

//    __weak IBOutlet UIView *_videoRecordPreview;
    __weak IBOutlet HRPLabel *_controlLabel;
    __weak IBOutlet UILabel *_timerLabel;
}

#pragma mark - Constructors -
- (void)viewDidLoad {
    [super viewDidLoad];

    // Set Notification Observers
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handlerStartVideoSession:)
                                                 name:@"startVideoSession"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handlerMergeAndSaveVideo:)
                                                 name:@"showMergeAndSaveAlertMessage"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handlerFinishRecordingVideoFile:)
                                                 name:@"didFinishRecordingToOutputFileAtURL"
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self showLoaderWithText:NSLocalizedString(@"Start a Video", nil)
          andBackgroundColor:BackgroundColorTypeBlue
                     forTime:2];

    [self customizeNavigationBarWithTitle:NSLocalizedString(@"Record a Video", nil)
                    andLeftBarButtonImage:[UIImage new]
                   andRightBarButtonImage:[UIImage imageNamed:@"icon-action-close"]];
    
    _cameraManager                      =   [HRPCameraManager sharedManager];
    [_cameraManager createCaptureSession];

    //Preview Layer
    _cameraManager.videoPreviewLayer    =   [[AVCaptureVideoPreviewLayer alloc] initWithSession:_cameraManager.captureSession];
    
    [_cameraManager.videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [_cameraManager.videoPreviewLayer setFrame:self.view.layer.bounds];
    [_cameraManager setPreviewLayerVideoOrientation];
    
    [self.view.layer insertSublayer:_cameraManager.videoPreviewLayer below:_controlLabel.layer];
    
    [self customizeViewStyle];

    [_cameraManager.captureSession startRunning];
    _cameraManager.videoSessionMode     =   NSTimerVideoSessionModeStream;
    [_cameraManager startStreamVideoRecording];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Actions -
- (void)handlerRightBarButtonTap:(UIBarButtonItem *)sender {
    // Stop Video Record Session
    
    // Transition to Collection Scene
    HRPCollectionViewController *collectionVC   =   [self.storyboard instantiateViewControllerWithIdentifier:@"CollectionVC"];
    
    // Prepare DataSource
    
    [self.navigationController pushViewController:collectionVC animated:YES];
}


#pragma mark - NSNotification -
- (void)handlerStartVideoSession:(NSNotification *)notification {
    if (self.HUD.alpha)
        [self hideLoader];
        
    _cameraManager.videoSessionMode                     =   NSTimerVideoSessionModeStream;

    [_cameraManager startStreamVideoRecording];
    [_cameraManager createTimerWithLabel:_timerLabel];
    
    self.navigationItem.rightBarButtonItem.enabled      =   YES;
    _cameraManager.isVideoSaving                        =   NO;
    _controlLabel.isLabelFlashing                       =   NO;
}

- (void)handlerMergeAndSaveVideo:(NSNotification *)notification {
    _controlLabel.text      =   nil;
    
    [self showLoaderWithText:NSLocalizedString(@"Merge & Save video", nil)
          andBackgroundColor:BackgroundColorTypeBlue
                     forTime:300];
}

- (void)handlerFinishRecordingVideoFile:(NSNotification *)notification {
    if (self.HUD.alpha)
        [self hideLoader];
}


#pragma mark - UIGestureRecognizer -
- (IBAction)tapGesture:(id)sender {
    if (_cameraManager.videoSessionMode == NSTimerVideoSessionModeStream) {
        _controlLabel.hidden                                =   NO;
        _controlLabel.text                                  =   NSLocalizedString(@"Violation", nil);
        _cameraManager.isVideoSaving                        =   YES;
        self.navigationItem.rightBarButtonItem.enabled      =   NO;
        
        [_controlLabel startFlashing];
        _cameraManager.videoSessionMode                     =   NSTimerVideoSessionModeAttention;
        [_cameraManager startAttentionVideoRecording];
    }
}


#pragma mark - Methods -
- (void)customizeViewStyle {
    _controlLabel.hidden                        =   YES;
    
    [_cameraManager createTimerWithLabel:_timerLabel];
}


#pragma mark - UIViewControllerRotation -
- (BOOL)shouldAutorotate {
    // Disable autorotation of the interface when recording is in progress.
    return !_cameraManager.videoFileOutput.isRecording;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    // Restart Timer only in Stream Video mode
    if (_cameraManager.videoSessionMode == NSTimerVideoSessionModeStream) {
        [self showLoaderWithText:NSLocalizedString(@"Start a Video", nil)
              andBackgroundColor:BackgroundColorTypeBlue
                         forTime:2];

        [_cameraManager setPreviewLayerVideoOrientation];
        
        [_cameraManager.timer invalidate];
        
        [_cameraManager createTimerWithLabel:_timerLabel];
        _cameraManager.videoSessionMode     =   NSTimerVideoSessionModeStream;
        [_cameraManager restartStreamVideoRecording];
    }
}

@end
