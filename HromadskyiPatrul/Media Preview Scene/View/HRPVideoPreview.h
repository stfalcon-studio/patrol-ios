//
//  HRPVideoPreview.h
//  HromadskyiPatrul
//
//  Created by msm72 on 30.12.15.
//  Copyright © 2015 Monastyrskiy Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class AVPlayer;


@interface HRPVideoPreview : UIView

@property (strong, nonatomic) AVPlayer *player;

- (void)setMovieToPlayer:(AVPlayer *)player;

@end
