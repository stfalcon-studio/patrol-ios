//
//  HRPSettingsViewModel.h
//  HromadskyiPatrul
//
//  Created by msm72 on 01.01.16.
//  Copyright © 2016 Monastyrskiy Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface HRPSettingsViewModel : NSObject

@property (strong, nonatomic) NSUserDefaults *userApp;

- (void)logout;
- (void)changeSendingType:(BOOL)type;
- (void)changeNetworkType:(BOOL)type;
- (void)changeAppStartScene:(BOOL)type;

@end
