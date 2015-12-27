//
//  HRPVideoPlayerViewController.m
//  HromadskyiPatrul
//
//  Created by msm72 on 15.10.15.
//  Copyright © 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPVideoPlayerViewController.h"
#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>


@interface HRPVideoPlayerViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) MPMoviePlayerController *videoController;
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *statusViewTopConstraint;

@end


@implementation HRPVideoPlayerViewController

#pragma mark - Constructors -
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title                   =   NSLocalizedString(@"Preview a Video", nil);
    
    if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait)
        self.statusViewTopConstraint.constant   =   0.f;
    else
        self.statusViewTopConstraint.constant   =   -20.f;
    
    [self.cancelButton setTitle:NSLocalizedString(@"Alert error button Cancel", nil)
                       forState:UIControlStateNormal];
    
    [self startPlayVideo];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //   // [self startPlayVideo];
    //        self.videoController = [[MPMoviePlayerController alloc] initWithContentURL:self.videoURL];
    //        [self.videoController prepareToPlay];
    //
    //        CGRect frame = self.view.frame;
    //        frame.origin = CGPointZero;
    //
    //        self.videoController.view.frame = frame;
    //
    //        self.videoController.allowsAirPlay         = NO;
    //        self.videoController.shouldAutoplay        = NO;
    //        self.videoController.movieSourceType       = MPMovieSourceTypeFile;
    //        self.videoController.scalingMode           = MPMovieScalingModeAspectFit;
    //        self.videoController.controlStyle          = MPMovieControlStyleEmbedded;
    //        self.videoController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    //
    //        dispatch_async(dispatch_get_main_queue(), ^{
    //            [self.view addSubview:self.videoController.view];
    //        });
    //
    //    [self.videoController play];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // Stop the video player and remove it from view
    [self.videoController stop];
    [self.videoController.view removeFromSuperview];
    self.videoController                        =   nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - Actions -
- (IBAction)actionCancelButtonTap:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Methods -
- (void)startPlayVideo {
    self.videoController                        =   [[MPMoviePlayerController alloc] initWithContentURL:self.videoURL];
    
    if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait)
        [self.videoController.view setFrame:CGRectMake(0.f, 20.f, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - 20.f)];
    else
        [self.videoController.view setFrame:CGRectMake(0.f, 0.f, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame))];
    
    [self.view addSubview:self.videoController.view];
    [self.view bringSubviewToFront:self.cancelButton];
    
    [self.videoController prepareToPlay];
    [self.videoController play];
}


#pragma mark - UIViewControllerRotation -
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait) {
        self.statusViewTopConstraint.constant       =   -20.f;
        [self.videoController.view setFrame:CGRectMake(0.f, 0.f, size.width, size.height)];
    } else {
        self.statusViewTopConstraint.constant       =   0.f;
        [self.videoController.view setFrame:CGRectMake(0.f, 20.f, size.width, size.height - 20.f)];
    }
}

@end















/*

//
//  HRPVideoPlayerViewController.m
//  HromadskyiPatrul
//
//  Created by msm72 on 15.10.15.
//  Copyright © 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPVideoPlayerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
//#import <MediaPlayer/MediaPlayer.h>
//#import <MobileCoreServices/MobileCoreServices.h>
#import "HRPCameraManager.h"


@interface HRPVideoPlayerViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

//@property (strong, nonatomic) MPMoviePlayerController *videoController;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *statusViewTopConstraint;

@end


@implementation HRPVideoPlayerViewController {
    BOOL _isVideoPlaying;
}

#pragma mark - Constructors -
-(id)initWithContentURL:(NSURL *)contentURL {
    UIStoryboard *storyboard                        =   [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    HRPVideoPlayerViewController *previewVC         =   [storyboard instantiateViewControllerWithIdentifier:@"VideoPlayerVC"];
    
    self                                            =   previewVC;

    if (self) {
        _playerItem                                 =   [[AVPlayerItem alloc] initWithURL:contentURL];
        _player                                     =   [AVPlayer playerWithPlayerItem:_playerItem];

        [_player addObserver:self forKeyPath:@"status" options:0 context:nil];

        AVPlayerLayer *playerLayer                  =   [AVPlayerLayer playerLayerWithPlayer:_player];
        playerLayer.frame                           =   self.view.bounds;
        playerLayer.videoGravity                    =   AVLayerVideoGravityResizeAspect;
        [self.view.layer addSublayer:playerLayer];
        
        playerLayer.needsDisplayOnBoundsChange      =   YES;
        self.view.layer.needsDisplayOnBoundsChange  =   YES;

        _isVideoPlaying                             =   NO;
    }
    
    return self;
}
/*

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title                       =   NSLocalizedString(@"Preview a Video", nil);

    if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait)
        _statusViewTopConstraint.constant           =   0.f;
    else
        _statusViewTopConstraint.constant           =   -20.f;
    
    [_cancelButton setTitle:NSLocalizedString(@"Alert error button Cancel", nil)
                   forState:UIControlStateNormal];

    [_player play];

    //[self startPlayVideo];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // Stop the video player and remove it from view
    [_player pause];

    
    /*
    [_player stop];
    [self.videoController.view removeFromSuperview];
    self.videoController                        =   nil;
     */
/*
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - Actions -
- (IBAction)actionCancelButtonTap:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Methods -
- (void)startPlayVideo {

  */

    /*
    _videoController                            =   [[MPMoviePlayerController alloc] initWithContentURL:_videoURL];
    
    if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait)
        [_videoController.view setFrame:CGRectMake(0.f, 20.f, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - 20.f)];
    
    else
        [_videoController.view setFrame:CGRectMake(0.f, 0.f, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame))];
    
    [self.view addSubview:_videoController.view];
    [self.view bringSubviewToFront:_cancelButton];
    
    [_videoController prepareToPlay];
    [_videoController play];
     */
/*
}


#pragma mark - UIViewControllerRotation -
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait) {
        _statusViewTopConstraint.constant       =   -20.f;
//        [_player setFrame:CGRectMake(0.f, 0.f, size.width, size.height)];
    } else {
        _statusViewTopConstraint.constant       =   0.f;
//        [self.videoController.view setFrame:CGRectMake(0.f, 20.f, size.width, size.height - 20.f)];
    }
}

@end
 */


