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

@end


@implementation HRPVideoPlayerViewController

#pragma mark - Constructors -
- (void)viewDidLoad {
    [super viewDidLoad];

    [self.cancelButton setTitle:NSLocalizedString(@"Alert error button Cancel", nil)
                       forState:UIControlStateNormal];

    [self startPlayVideo];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // Stop the video player and remove it from view
    [self.videoController stop];
    [self.videoController.view removeFromSuperview];
    self.videoController    =   nil;
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
    self.videoController    =   [[MPMoviePlayerController alloc] init];
    
    [self.videoController setContentURL:self.videoURL];
    [self.videoController.view setFrame:CGRectMake(0.f, 20.f, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - 20.f)];
    [self.view addSubview:self.videoController.view];
    [self.view bringSubviewToFront:self.cancelButton];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(videoPlayBackDidFinish:)
//                                                 name:MPMoviePlayerPlaybackDidFinishNotification
//                                               object:self.videoController];
    
    [self.videoController play];
}


#pragma mark - NSNotification -
- (void)videoPlayBackDidFinish:(NSNotification *)notification {
//    [[NSNotificationCenter defaultCenter] removeObserver:self
//                                                    name:MPMoviePlayerPlaybackDidFinishNotification
//                                                  object:nil];
//    
//    // Stop the video player and remove it from view
//    [self.videoController stop];
//    [self.videoController.view removeFromSuperview];
//    self.videoController    =   nil;
//    
//    // Display a message
//    UIAlertView *alert      =   [[UIAlertView alloc] initWithTitle:@"Video Playback"
//                                                           message:@"Just finished the video playback. The video is now removed."
//                                                          delegate:nil
//                                                 cancelButtonTitle:@"OK"
//                                                 otherButtonTitles:nil];
//    [alert show];
}

@end
