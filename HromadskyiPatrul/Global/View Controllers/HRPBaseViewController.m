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

@end
