//
//  HRPVideoPlayerViewController.h
//  HromadskyiPatrul
//
//  Created by msm72 on 15.10.15.
//  Copyright © 2015 Monastyrskiy Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>


@class AVPlayer, HRPVideoPreview;


@interface HRPVideoPlayerViewController : AVPlayerViewController

@property (strong, nonatomic) NSURL *videoURL;
//@property (strong, nonatomic) AVPlayer *player;
@property (weak, nonatomic) IBOutlet HRPVideoPreview *playerView;

@end
