//
//  HRPSettingsViewController.m
//  HromadskyiPatrul
//
//  Created by msm72 on 21.08.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPSettingsViewController.h"


@interface HRPSettingsViewController () 

@property (strong, nonatomic) IBOutlet UISwitch *networkSwitch;
@property (strong, nonatomic) IBOutlet UILabel *networkLabel;
@property (strong, nonatomic) IBOutlet UIButton *logoutButton;

@end


@implementation HRPSettingsViewController {
    NSUserDefaults *userApp;
}

#pragma mark - Constructors -
- (void)viewDidLoad {
    [super viewDidLoad];

    userApp                                     =   [NSUserDefaults standardUserDefaults];
    self.navigationItem.title                   =   NSLocalizedString(@"Settings", nil);
    
    // Set titles
    self.networkSwitch.on                       =   [userApp boolForKey:@"networkStatus"];
    self.networkLabel.text                      =   NSLocalizedString(@"Switch title", nil);
    [self.logoutButton setTitle:NSLocalizedString(@"Logout", nil) forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - Actions -
- (IBAction)actionLogoutButtonTap:(UIButton *)sender {
    [userApp removeObjectForKey:@"userAppEmail"];
    [userApp removeObjectForKey:@"networkStatus"];

    [self.navigationController popToRootViewControllerAnimated:YES];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"HRPSettingsViewControllerUserLogout"
                                                        object:nil
                                                      userInfo:nil];
}

- (IBAction)actionNetworkSwitchChangeValue:(UISwitch *)sender {
    [userApp setBool:sender.on forKey:@"networkStatus"];
}


#pragma mark - UITableViewDelegate -
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.001f;
}

@end
