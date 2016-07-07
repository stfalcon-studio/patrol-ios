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
//
//  HRPSettingsViewModel.m
//  HromadskyiPatrul
//
//  Created by msm72 on 01.01.16.
//  Copyright © 2016 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPSettingsViewModel.h"

@implementation HRPSettingsViewModel

#pragma mark - Constructors -
- (instancetype)init {
    self = [super init];

    if (self) {
        _userApp = [NSUserDefaults standardUserDefaults];
    }
    
    return self;
}


#pragma mark - Methods -
- (void)logout {
    [_userApp removeObjectForKey:@"userAppEmail"];
    [_userApp removeObjectForKey:@"sendingTypeStatus"];
    [_userApp removeObjectForKey:@"networkStatus"];
    [_userApp removeObjectForKey:@"appStartStatus"];
}

- (void)changeSendingType:(BOOL)type {
    [_userApp setBool:type forKey:@"sendingTypeStatus"];
    
    [_userApp synchronize];
}

- (void)changeNetworkType:(BOOL)type {
    [_userApp setBool:type forKey:@"networkStatus"];
    
    [_userApp synchronize];
}

- (void)changeAppStartScene:(BOOL)type {
    [_userApp setBool:type forKey:@"appStartStatus"];
    
    [_userApp synchronize];
}

@end