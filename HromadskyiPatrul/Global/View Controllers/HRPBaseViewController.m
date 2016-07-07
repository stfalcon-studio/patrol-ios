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
//  HRPBaseViewController.m
//  HromadskyiPatrul
//
//  Created by msm72 on 12.12.15.
//  Copyright © 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPBaseViewController.h"
#import "HRPNavigationController.h"
#import "UIColor+HexColor.h"
#import "AFNetworking.h"


@implementation HRPBaseViewController {
    unsigned int _sleepDuration;
}

#pragma mark - Constructors -
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (_HUD.alpha)
        [self hideLoader];
}


#pragma mark - Methods -
- (void)setRightBarButtonEnable:(BOOL)enable {
    self.navigationItem.rightBarButtonItem.enabled = enable;
}

- (void)showLoaderWithText:(NSString *)text andBackgroundColor:(BackgroundColorType)colorType forTime:(unsigned int)duration {
    NSString *colorString = nil;
    _sleepDuration = duration;
    
    switch (colorType) {
        case BackgroundColorTypeBlue:
            colorString = @"05A9F4";
            break;
            
        case BackgroundColorTypeBlack:
            colorString = @"000000";
            break;
    }
    
    _HUD = [[MBProgressHUD alloc] initWithView:self.view];
    _HUD.labelText = text;
    _HUD.yOffset = 0.f;
    _HUD.color = [UIColor colorWithHexString:colorString alpha:0.6f];
    
    [self.view addSubview:_HUD];
    [_HUD showWhileExecuting:@selector(sleepTask) onTarget:self withObject:nil animated:YES];
}

- (void)hideLoader {
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

- (void)showAlertViewWithTitle:(NSString *)titleText andMessage:(NSString *)messageText {
    [[[UIAlertView alloc] initWithTitle:titleText
                                message:messageText
                               delegate:nil
                      cancelButtonTitle:nil
                      otherButtonTitles:NSLocalizedString(@"Alert error button Ok", nil), nil] show];
}

- (void)sleepTask {
    // Do something usefull in here instead of sleeping ...
    sleep(_sleepDuration);
}

- (BOOL)isInternetConnectionAvailable {
    // Network activity
    if ([[AFNetworkReachabilityManager sharedManager] isReachable])
        return YES;
    
    else
        [self showAlertViewWithTitle:NSLocalizedString(@"Alert error email title", nil)
                          andMessage:NSLocalizedString(@"Alert error internet message", nil)];
    
    return NO;
}

- (BOOL)isServerURLLocal {
    return [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"isLocalServerURL"] boolValue];
}


#pragma mark - UIViewControllerRotation -
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([NSStringFromClass(viewController.class) isEqualToString:@"PUUIAlbumListViewController"]) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
        [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithHexString:@"3AA6F4" alpha:1.f]];
        [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
        [[UINavigationBar appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName:[UIColor whiteColor] }];
        
        UIView *statusView = [[UIView alloc] initWithFrame:CGRectMake(0.f, -20.f, CGRectGetWidth(self.view.frame), 20.f)];
        [statusView setBackgroundColor:[UIColor colorWithHexString:@"2774BD" alpha:1.f]];
        [navigationController.navigationBar addSubview:statusView];
    }
}

@end
