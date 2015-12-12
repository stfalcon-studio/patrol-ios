//
//  HRPBaseViewController.m
//  HromadskyiPatrul
//
//  Created by msm72 on 12.12.15.
//  Copyright © 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPBaseViewController.h"
#import "MBProgressHUD.h"
#import "UIColor+HexColor.h"
#import "AFNetworking.h"


@implementation HRPBaseViewController

#pragma mark - Methods -
- (void)showLoaderWithText:(NSString *)text andBackgroundColor:(BackgroundColorType)colorType {
    NSString *colorString   =   nil;
    
    switch (colorType) {
        case BackgroundColorTypeBlue:
            colorString     =   @"05A9F4";
            break;
            
        case BackgroundColorTypeBlack:
            colorString     =   @"000000";
            break;
    }
    
    MBProgressHUD *HUD      =   [[MBProgressHUD alloc] initWithView:self.view];
    HUD.labelText           =   text;
    HUD.yOffset             =   0.f;
    HUD.color               =   [UIColor colorWithHexString:colorString alpha:0.6f];

    [self.view addSubview:HUD];
    [HUD showWhileExecuting:@selector(sleepTask) onTarget:self withObject:nil animated:YES];
}

- (void)hideLoader {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
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
    sleep(3);
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

@end
