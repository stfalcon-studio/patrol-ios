//
//  HRPSettingsViewController.m
//  HromadskyiPatrul
//
//  Created by msm72 on 21.08.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPSettingsViewController.h"


@interface HRPSettingsViewController () 

@end


@implementation HRPSettingsViewController

#pragma mark - Constructors -
- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title                   =   NSLocalizedString(@"Settings", nil);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - Actions -
- (IBAction)actionLogoutButtonTap:(UIButton *)sender {
    NSUserDefaults *userApp                     =   [NSUserDefaults standardUserDefaults];
    [userApp removeObjectForKey:@"userAppEmail"];

    [self.navigationController popToRootViewControllerAnimated:YES];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"HRPSettingsViewControllerUserLogout"
                                                        object:nil
                                                      userInfo:nil];
}

@end
