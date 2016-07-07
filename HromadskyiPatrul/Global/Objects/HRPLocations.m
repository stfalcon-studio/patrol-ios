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
