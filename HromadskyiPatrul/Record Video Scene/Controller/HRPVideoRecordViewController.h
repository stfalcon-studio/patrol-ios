//
//  HRPVideoRecordViewController.h
//  HromadskyiPatrul
//
//  Created by msm72 on 19.12.15.
//  Copyright © 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPBaseViewController.h"
#import "HRPCameraManager.h"
#import "HRPLabel.h"


@interface HRPVideoRecordViewController : HRPBaseViewController

@property (strong, nonatomic) HRPCameraManager *cameraManager;
@property (weak, nonatomic) IBOutlet HRPLabel *violationLabel;

- (void)startVideoRecord;

@end
