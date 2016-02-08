//
//  HRPMainViewModel.m
//  HromadskyiPatrul
//
//  Created by msm72 on 12.12.15.
//  Copyright © 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPMainViewModel.h"
#import "HRPBaseViewController.h"

@class HRPVideoRecordViewController123;


@implementation HRPMainViewModel

#pragma mark - Constructors -
- (instancetype)init {
    self = [super init];
    
    if (self) {
        _userApp = [NSUserDefaults standardUserDefaults];
    }
    
    return self;
}


#pragma mark - Methods -
- (NSString *)getAppVersion {
    NSString *appVersion    =   [NSString stringWithFormat:@"%@ %@ (%@)", NSLocalizedString(@"Version", nil),
                                 [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],
                                 [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey]];
    
    return appVersion;
}

- (NSString *)selectNextSceneStoryboardID {
    NSString *selectedVC = @"VideoRecordVC";
    
    if (![_userApp objectForKey:@"userAppEmail"])
        selectedVC = @"LoginVC";
    
    return selectedVC;
}

@end
