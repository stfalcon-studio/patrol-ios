//
//  HRPSettingsViewController.m
//  HromadskyiPatrul
//
//  Created by msm72 on 21.08.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPSettingsViewController.h"
#import "UIViewController+NavigationBar.h"


@interface HRPSettingsViewController () 

@property (strong, nonatomic) IBOutlet UISwitch *sendingSwitch;
@property (strong, nonatomic) IBOutlet UILabel *sendingTypeLabel;
@property (strong, nonatomic) IBOutlet UISwitch *networkSwitch;
@property (strong, nonatomic) IBOutlet UILabel *networkLabel;
@property (strong, nonatomic) IBOutlet UIButton *logoutButton;

@end


@implementation HRPSettingsViewController {
    NSUserDefaults *_userApp;
}

#pragma mark - Constructors -
- (void)viewDidLoad {
    [super viewDidLoad];

    _userApp    =   [NSUserDefaults standardUserDefaults];
    
    [self customizeNavigationBarWithTitle:NSLocalizedString(@"Settings", nil)
                    andLeftBarButtonImage:[UIImage imageNamed:@"icon-arrow-left"]
                        withActionEnabled:YES
                   andRightBarButtonImage:[UIImage new]
                        withActionEnabled:NO];
    
    // Set titles
    self.sendingSwitch.on       =   [_userApp boolForKey:@"sendingTypeStatus"];
    self.sendingTypeLabel.text  =   NSLocalizedString(@"Switch sending title", nil);
    self.networkSwitch.on       =   [_userApp boolForKey:@"networkStatus"];
    self.networkLabel.text      =   NSLocalizedString(@"Switch network title", nil);
    
    [self.logoutButton setTitle:NSLocalizedString(@"Logout", nil) forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - Actions -
- (void)handlerLeftBarButtonTap:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)handlerRightBarButtonTap:(UIBarButtonItem *)sender {
    
}

- (IBAction)actionLogoutButtonTap:(UIButton *)sender {
    [_userApp removeObjectForKey:@"userAppEmail"];
    [_userApp removeObjectForKey:@"sendingTypeStatus"];
    [_userApp removeObjectForKey:@"networkStatus"];

    [self.navigationController popToRootViewControllerAnimated:YES];
    [self hideNavigationBar];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"HRPSettingsViewControllerUserLogout"
                                                        object:nil
                                                      userInfo:nil];
}

- (IBAction)actionSendingTypeSwitchChangeValue:(UISwitch *)sender {
    [_userApp setBool:sender.on forKey:@"sendingTypeStatus"];
}

- (IBAction)actionNetworkSwitchChangeValue:(UISwitch *)sender {
    [_userApp setBool:sender.on forKey:@"networkStatus"];
}


#pragma mark - UITableViewDelegate -
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.001f;
}

@end
