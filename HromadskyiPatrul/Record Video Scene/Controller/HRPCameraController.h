//
//  HRPCameraController.h
//  HromadskyiPatrul
//
//  Created by msm72 on 24.03.16.
//  Copyright © 2016 Monastyrskiy Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "HRPLocations.h"


@interface HRPCameraController : UIImagePickerController <CLLocationManagerDelegate>

@property (strong, nonatomic) HRPLocations *locationsService;
@property (assign, nonatomic) CGFloat latitude;
@property (assign, nonatomic) CGFloat longitude;

- (void)startUpdateLocations;

@end
