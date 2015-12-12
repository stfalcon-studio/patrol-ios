//
//  HRPBaseViewController.h
//  HromadskyiPatrul
//
//  Created by msm72 on 12.12.15.
//  Copyright © 2015 Monastyrskiy Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM (NSInteger, BackgroundColorType) {
    BackgroundColorTypeBlue,
    BackgroundColorTypeBlack
};


@interface HRPBaseViewController : UIViewController

- (void)showAlertViewWithTitle:(NSString *)titleText andMessage:(NSString *)messageText;
- (void)showLoaderWithText:(NSString *)text andBackgroundColor:(BackgroundColorType)colorType;
- (void)hideLoader;
- (BOOL)isInternetConnectionAvailable;

@end
