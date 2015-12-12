//
//  HRPBaseViewController.m
//  HromadskyiPatrul
//
//  Created by msm72 on 12.12.15.
//  Copyright © 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPBaseViewController.h"
#import "MBProgressHUD.h"


@implementation HRPBaseViewController {
    MBProgressHUD *_progressHUD;
}

#pragma mark - Constructors -
- (id)init {
    self                        =   [super init];
    
    if (self) {
        _progressHUD            =   [[MBProgressHUD alloc] init];
    }
    
    return self;
}


#pragma mark - Methods -
- (void)showLoaderWithText:(NSString *)text {
    if (!_progressHUD.alpha) {
        _progressHUD.labelText  =   text;
        _progressHUD.yOffset    =   0.f;
        _progressHUD            =   [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
}

- (void)hideLoader {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

@end
