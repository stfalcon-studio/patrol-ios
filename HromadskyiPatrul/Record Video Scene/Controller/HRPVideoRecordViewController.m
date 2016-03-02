//
//  HRPVideoRecordViewController.m
//  HromadskyiPatrul
//
//  Created by msm72 on 19.12.15.
//  Copyright © 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPVideoRecordViewController.h"
#import "HRPCollectionViewController.h"
#import "HRPCameraManager.h"
#import "HRPViolationManager.h"
#import "HRPLabel.h"


@interface HRPVideoRecordViewController ()

@end


@implementation HRPVideoRecordViewController {
    HRPCameraManager *_cameraManager;
    UIView *_statusView;
    
    __weak IBOutlet HRPLabel *_violationLabel;
    __weak IBOutlet UILabel *_timerLabel;
}

#pragma mark - Constructors -
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Create violations array
    [HRPViolationManager sharedManager];
    
    // Set Notification Observers
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handlerStartVideoSession:)
                                                 name:@"startVideoSession"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handlerMergeAndSaveVideo:)
                                                 name:@"showMergeAndSaveAlertMessage"
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [_cameraManager removeMediaSnippets];
    [_cameraManager.locationsService.manager startUpdatingLocation];

    // Set View frame
    self.view.frame = [UIScreen mainScreen].bounds;
    
    [self showLoaderWithText:NSLocalizedString(@"Start a Video", nil)
          andBackgroundColor:BackgroundColorTypeBlue
                     forTime:2];

    [self customizeNavigationBarWithTitle:NSLocalizedString(@"Record a Video", nil)
                    andLeftBarButtonImage:[UIImage new]
                        withActionEnabled:NO
                   andRightBarButtonImage:[UIImage imageNamed:@"icon-action-close"]
                        withActionEnabled:YES];
    
    _cameraManager = [HRPCameraManager sharedManager];
    
//    [_cameraManager readPhotosCollectionFromFile];
    _cameraManager.violations = [HRPViolationManager sharedManager].violations;
    [_cameraManager createCaptureSession];

    //Preview Layer
    _cameraManager.videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_cameraManager.captureSession];
    [_cameraManager.videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [_cameraManager setVideoPreviewLayerOrientation:self.view.frame.size];
    
    [self.view.layer setMasksToBounds:YES];
    [self.view layoutIfNeeded];

    [self.view.layer insertSublayer:_cameraManager.videoPreviewLayer below:_violationLabel.layer];
    
    _statusView = [self customizeStatusBar];
    [self customizeViewStyle];

    _cameraManager.videoSessionMode = NSTimerVideoSessionModeStream;

    [_cameraManager.captureSession startRunning];
    [_cameraManager startStreamVideoRecording];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [_cameraManager.locationsService.manager stopUpdatingLocation];
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
    [_cameraManager stopVideoSession];
    [_cameraManager.videoPreviewLayer removeFromSuperlayer];
   
    // Transition to Collection Scene
    HRPCollectionViewController *collectionVC = [self.storyboard instantiateViewControllerWithIdentifier:@"CollectionVC"];
    collectionVC.violationsDataSource = [HRPViolationManager sharedManager].violations;
    
    [self.navigationController pushViewController:collectionVC animated:YES];
}


#pragma mark - NSNotification -
- (void)handlerStartVideoSession:(NSNotification *)notification {
    self.navigationItem.rightBarButtonItem.enabled = YES;
    _cameraManager.isVideoSaving = NO;
    
    [_cameraManager startStreamVideoRecording];
    [_cameraManager createTimerWithLabel:_timerLabel];
    
    if (self.HUD.alpha)
        [self hideLoader];
}

- (void)handlerMergeAndSaveVideo:(NSNotification *)notification {
    _violationLabel.text = nil;
    _violationLabel.isLabelFlashing = NO;
    
    [self showLoaderWithText:NSLocalizedString(@"Merge & Save video", nil)
          andBackgroundColor:BackgroundColorTypeBlue
                     forTime:300];
}


#pragma mark - UIGestureRecognizer -
- (IBAction)tapGesture:(id)sender {
    if ([_cameraManager.locationsService isEnabled]) {
        _cameraManager.locationsService.manager.delegate = _cameraManager;

        [_cameraManager.locationsService.manager startUpdatingLocation];
        
        if (_cameraManager.videoSessionMode == NSTimerVideoSessionModeStream && !_cameraManager.isVideoSaving) {
            _violationLabel.hidden = NO;
            _violationLabel.text = NSLocalizedString(@"Violation", nil);
            _cameraManager.isVideoSaving = YES;
            _cameraManager.videoSessionMode = NSTimerVideoSessionModeViolation;
            _cameraManager.violationTime = [_cameraManager getCurrentTimerValue];
            _cameraManager.sessionDuration = _cameraManager.violationTime + 10;
            self.navigationItem.rightBarButtonItem.enabled = NO;
            
            [_violationLabel startFlashing];
        }
    }
}


#pragma mark - Methods -
- (void)customizeViewStyle {
    _violationLabel.hidden = YES;
    
    [_cameraManager createTimerWithLabel:_timerLabel];
}


#pragma mark - UIViewControllerRotation -
- (BOOL)shouldAutorotate {
    return (_cameraManager.videoSessionMode == NSTimerVideoSessionModeStream);
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    _statusView.frame = CGRectMake(0.f, (size.width < size.height) ? 0.f : -20.f, size.width, 20.f);
    
    [_cameraManager setVideoPreviewLayerOrientation:size];
    
    // Restart Timer only in Stream Video mode
    if (_cameraManager.videoSessionMode == NSTimerVideoSessionModeStream && !_cameraManager.isVideoSaving) {
        _cameraManager.videoSessionMode = NSTimerVideoSessionModeStream;
    }
}

@end
