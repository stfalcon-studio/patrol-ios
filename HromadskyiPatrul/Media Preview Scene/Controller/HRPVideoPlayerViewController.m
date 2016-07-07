/*
 Copyright (c) 2015 - 2016. Stepan Tanasiychuk
 This file is part of Gromadskyi Patrul is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by the Free Software Found ation, version 3 of the License, or any later version.
 If you would like to use any part of this project for commercial purposes, please contact us
 for negotiating licensing terms and getting permission for commercial use. Our email address: info@stfalcon.com
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.
 You should have received a copy of the GNU General Public License along with this program.
 If not, see http://www.gnu.org/licenses/.
 */
// https://github.com/stfalcon-studio/patrol-android/blob/master/app/build.gradle
//
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

//@property (strong, nonatomic) IBOutlet NSLayoutConstraint *statusViewTopConstraint;

@end


@implementation HRPVideoPlayerViewController

#pragma mark - Constructors -
- (void)viewDidLoad {
    [super viewDidLoad];
    
//    if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait)
//        _statusViewTopConstraint.constant = -20.f;
//    
//    else
//        _statusViewTopConstraint.constant = 0.f;

    self.navigationItem.title = NSLocalizedString(@"Preview a Video", nil);
    
    self.player = [AVPlayer playerWithURL:_videoURL];
    self.player.volume = [[AVAudioSession sharedInstance] outputVolume];
    
    [self setAudioVolume];
    
    [self.playerView setMovieToPlayer:self.player];
    [self.player play];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(volumeChanged:)
                                                 name:@"AVSystemController_SystemVolumeDidChangeNotification"
                                               object:nil];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.player = nil;
    self.playerView = nil;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Nofifications -
- (void)volumeChanged:(NSNotification *)notification {
    self.player.volume = [notification.userInfo[@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
}


#pragma mark - Methods -
- (void)setAudioVolume {
    AVAsset *avAsset = [[self.player currentItem] asset] ;
    NSArray *audioTracks = [avAsset tracksWithMediaType:AVMediaTypeAudio] ;
    NSMutableArray *allAudioParams = [NSMutableArray array] ;
    
    for (AVAssetTrack *track in audioTracks) {
        AVMutableAudioMixInputParameters *audioInputParams = [AVMutableAudioMixInputParameters audioMixInputParameters] ;
        [audioInputParams setVolume:1.f atTime:kCMTimeZero] ;
        [audioInputParams setTrackID:[track trackID]] ;
        [allAudioParams addObject:audioInputParams];
    }
    
    AVMutableAudioMix *audioVolMix = [AVMutableAudioMix audioMix] ;
    [audioVolMix setInputParameters:allAudioParams];
    [[self.player currentItem] setAudioMix:audioVolMix];
}


#pragma mark - UIViewControllerRotation -
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
//    if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait)
//        _statusViewTopConstraint.constant = -20.f;
//    
//    else
//        _statusViewTopConstraint.constant = 0.f;
}

@end
