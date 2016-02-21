//
//  HRPLocations.m
//  HuntsPoynt
//
//  Created by msm72 on 07.07.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//


#import "HRPLocations.h"


@implementation HRPLocations

#pragma mark - Constructors -
- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.geocoder = [[CLGeocoder alloc] init];
        self.isLocationCorrect = YES;
    }
    
    return self;
}


#pragma mark - Methods -
- (void)showAlertViewWithTitle:(NSString *)titleText andMessage:(NSString *)messageText {
    [[[UIAlertView alloc] initWithTitle:titleText
                                message:messageText
                               delegate:nil
                      cancelButtonTitle:nil
                      otherButtonTitles:NSLocalizedString(@"Alert error button Ok", nil), nil] show];
}

- (BOOL)isEnabled {
    if ([CLLocationManager locationServicesEnabled]) {
        self.manager = [[CLLocationManager alloc] init];
        
        if ([self.manager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            // Request for foreground location use
            [self.manager requestWhenInUseAuthorization];
            
            /*
             // Request for background location use
             [self.manager requestAlwaysAuthorization];
             */
        }
        
        [self.manager startUpdatingLocation];
        
        return YES;
    } else {
        self.isLocationCorrect = NO;
        [self showAlertViewWithTitle:NSLocalizedString(@"Alert error location title", nil)
                          andMessage:NSLocalizedString(@"Alert error location message off", nil)];
    }
    
    return NO;
}

@end
