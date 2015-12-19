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
#import "HRPLabel.h"


@interface HRPVideoRecordViewController ()

@end


@implementation HRPVideoRecordViewController {
    HRPCameraManager *_cameraManager;

    __weak IBOutlet HRPLabel *_controlLabel;
    __weak IBOutlet UILabel *_timerLabel;
}

#pragma mark - Constructors -
- (void)viewDidLoad {
    [super viewDidLoad];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self showLoaderWithText:NSLocalizedString(@"Start a Video", nil)
          andBackgroundColor:BackgroundColorTypeBlue
                     forTime:2];

    [self customizeNavigationBarWithTitle:NSLocalizedString(@"Record a Video", nil)
                    andLeftBarButtonImage:[UIImage new]
                   andRightBarButtonImage:[UIImage imageNamed:@"icon-action-close"]];
    
    _cameraManager          =   [HRPCameraManager sharedManager];
    
    [self customizeViewStyle];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

}


#pragma mark - Actions -
- (void)handlerRightBarButtonTap:(UIBarButtonItem *)sender {
    // Stop Video Record Session
    
    // Transition to Collection Scene
    HRPCollectionViewController *collectionVC   =   [self.storyboard instantiateViewControllerWithIdentifier:@"CollectionVC"];
    
    // Prepare DataSource
    
    [self.navigationController pushViewController:collectionVC animated:YES];
}


#pragma mark - Methods -
- (void)customizeViewStyle {
    _controlLabel.hidden                        =   YES;
    
    [_cameraManager createTimerWithLabel:_timerLabel];
    _cameraManager.videoSessionMode             =   NSTimerVideoSessionModeStream;
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
                
        [_cameraManager.timer invalidate];
        
        [_cameraManager createTimerWithLabel:_timerLabel];
        [_cameraManager restartStreamVideoRecording];
    }
}

@end
