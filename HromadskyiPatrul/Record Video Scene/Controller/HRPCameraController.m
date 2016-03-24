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

@implementation HRPCameraController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Methods -
- (void)startUpdateLocations {
    // HSPLocations
    _locationsService = [[HRPLocations alloc] init];
    
    if ([_locationsService isEnabled]) {
        _locationsService.manager.delegate = self;
    }
}


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
