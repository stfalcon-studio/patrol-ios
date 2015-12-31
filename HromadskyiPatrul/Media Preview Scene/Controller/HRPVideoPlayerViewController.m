//
//  HRPVideoPlayerViewController.m
//  HromadskyiPatrul
//
//  Created by msm72 on 15.10.15.
//  Copyright © 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPVideoPlayerViewController.h"
#import "HRPVideoPreview.h"


@interface HRPVideoPlayerViewController ()

@property (strong, nonatomic) IBOutlet UIButton *cancelButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *statusViewTopConstraint;

@end


@implementation HRPVideoPlayerViewController

#pragma mark - Constructors -
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title           =   NSLocalizedString(@"Preview a Video", nil);
    
    _statusViewTopConstraint.constant   =   ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait) ?
                                                    0.f : -20.f;
    
    [_cancelButton setTitle:NSLocalizedString(@"Alert error button Cancel", nil)
                   forState:UIControlStateNormal];
    
//    NSURL *movieURL     =   [[NSBundle mainBundle] URLForResource:@"VolvoXC90" withExtension:@"mp4"];
//    _player             =   [AVPlayer playerWithURL:movieURL];
    _player                             =   [AVPlayer playerWithURL:_videoURL];
    
    [_playerView setMovieToPlayer:_player];
    [_player play];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - Actions -
- (IBAction)actionCancelButtonTap:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UIViewControllerRotation -
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait) {
        self.statusViewTopConstraint.constant       =   -20.f;
//        [self.videoController.view setFrame:CGRectMake(0.f, 0.f, size.width, size.height)];
    } else {
        self.statusViewTopConstraint.constant       =   0.f;
//        [self.videoController.view setFrame:CGRectMake(0.f, 20.f, size.width, size.height - 20.f)];
    }
}

@end
