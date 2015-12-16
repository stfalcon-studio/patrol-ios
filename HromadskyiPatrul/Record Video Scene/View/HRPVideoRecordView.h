//
//  HRPVideoRecordView.h
//  HromadskyiPatrul
//
//  Created by msm72 on 16.12.15.
//  Copyright © 2015 Monastyrskiy Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>


@class AVCaptureSession;


@interface HRPVideoRecordView : UIView

@property (strong, nonatomic) AVCaptureSession *session;

@end