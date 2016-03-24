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