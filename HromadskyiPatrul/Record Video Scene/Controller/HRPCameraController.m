//
//  HRPCameraController.m
//  HromadskyiPatrul
//
//  Created by msm72 on 24.03.16.
//  Copyright © 2016 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPCameraController.h"

@interface HRPCameraController ()

@end

@implementation HRPCameraController {
    UIDeviceOrientation _startOrientation;
    CGRect _frame;
}

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    
    [HRPCameraController attemptRotationToDeviceOrientation];
    _startOrientation = [[UIDevice currentDevice] orientation];
    _frame = self.view.bounds;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - Methods -
- (void)checkDeviceOrientation:(BOOL)isStateChange {
    CGAffineTransform rotate = CGAffineTransformMakeRotation(0);

    if (isStateChange) {
        if (_startOrientation == [[UIDevice currentDevice] orientation]) {
            self.view.frame = _frame;
            rotate = CGAffineTransformMakeRotation(UIDeviceOrientationIsLandscape(_startOrientation) ? M_PI_2 : -M_PI_2);

        } else {
            self.view.frame = CGRectMake(0.f, 0.f, CGRectGetHeight(_frame), CGRectGetWidth(_frame));
            rotate = CGAffineTransformMakeRotation(UIDeviceOrientationIsLandscape(_startOrientation) ? -M_PI_2 : M_PI_2);
        }
    } else {
        if (UIDeviceOrientationIsLandscape(_startOrientation)) {
            rotate = CGAffineTransformMakeRotation(M_PI_2);
        }
    }

    CGAffineTransform transform = rotate;
    self.cameraViewTransform = transform;
}

- (void)startUpdateLocations {
    // HSPLocations
    _locationsService = [[HRPLocations alloc] init];
    
    if ([_locationsService isEnabled]) {
        _locationsService.manager.delegate = self;
    }
}

//- (BOOL)shouldAutorotate {
//    //[self checkDeviceOrientation:(_startOrientation != [[UIDevice currentDevice] orientation])];
//    
//    return YES;
//}

//- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
//    return UIInterfaceOrientationMaskLandscape | UIInterfaceOrientationMaskPortrait;
//}


#pragma mark - CLLocationManagerDelegate -
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    _latitude = newLocation.coordinate.latitude;
    _longitude = newLocation.coordinate.longitude;
}

- (void)requestAlwaysAuthorization {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    // If the status is denied or only granted for when in use, display an alert
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusDenied) {
        NSString *titleText = NSLocalizedString(@"Alert error location title background", nil);
        
        NSString *messageText = (status == kCLAuthorizationStatusDenied) ?  NSLocalizedString(@"Alert error location message off", nil) :
        NSLocalizedString(@"Alert error location message background", nil);
        
        [[[UIAlertView alloc] initWithTitle:titleText
                                    message:messageText
                                   delegate:nil
                          cancelButtonTitle:nil
                          otherButtonTitles:NSLocalizedString(@"Alert error button Ok", nil), nil] show];
    }
    
    // The user has not enabled any location services. Request background authorization.
    else if (status == kCLAuthorizationStatusNotDetermined) {
        [_locationsService.manager requestAlwaysAuthorization];
    }
}

@end
