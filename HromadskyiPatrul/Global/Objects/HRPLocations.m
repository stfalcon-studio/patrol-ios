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
        _manager = [[CLLocationManager alloc] init];
        
        if ([_manager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            // Request for foreground location use
            [_manager requestWhenInUseAuthorization];
            
            /*
             // Request for background location use
             [self.manager requestAlwaysAuthorization];
             */
        }
        
        [_manager startUpdatingLocation];
        
        return YES;
    }
    
    else {
        _isLocationCorrect = NO;
        
        [self showAlertViewWithTitle:NSLocalizedString(@"Alert info title", nil)
                          andMessage:NSLocalizedString(@"Alert GPS error message", nil)];
    }
    
    return NO;
}

@end
