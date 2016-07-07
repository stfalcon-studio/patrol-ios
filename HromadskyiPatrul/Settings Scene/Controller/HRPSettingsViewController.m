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
//  HRPSettingsViewController.m
//  HromadskyiPatrul
//
//  Created by msm72 on 21.08.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPSettingsViewController.h"
#import "UIViewController+NavigationBar.h"
#import "HRPSettingsViewModel.h"


@interface HRPSettingsViewController () 

@property (strong, nonatomic) IBOutlet UISwitch *sendingSwitch;
@property (strong, nonatomic) IBOutlet UILabel *sendingTypeLabel;
@property (strong, nonatomic) IBOutlet UISwitch *networkSwitch;
@property (strong, nonatomic) IBOutlet UILabel *networkLabel;
@property (weak, nonatomic) IBOutlet UISwitch *startSwitch;
@property (weak, nonatomic) IBOutlet UILabel *startLabel;
@property (strong, nonatomic) IBOutlet UIButton *logoutButton;

@end


@implementation HRPSettingsViewController {
    HRPSettingsViewModel *_settingsViewModel;
}

#pragma mark - Constructors -
- (void)viewDidLoad {
    [super viewDidLoad];

    _settingsViewModel = [[HRPSettingsViewModel alloc] init];
    
    [self customizeNavigationBarWithTitle:NSLocalizedString(@"Settings", nil)
                    andLeftBarButtonImage:[UIImage imageNamed:@"icon-arrow-left"]
                        withActionEnabled:YES
                   andRightBarButtonImage:[UIImage new]
                        withActionEnabled:NO];
    
    // Set titles
    _sendingSwitch.on = [_settingsViewModel.userApp boolForKey:@"sendingTypeStatus"];
    _sendingTypeLabel.text = NSLocalizedString(@"Switch sending title", nil);
    _networkSwitch.on = [_settingsViewModel.userApp boolForKey:@"networkStatus"];
    _networkLabel.text = NSLocalizedString(@"Switch network title", nil);
    _startSwitch.on = [_settingsViewModel.userApp boolForKey:@"appStartStatus"];
    _startLabel.text = NSLocalizedString(@"Start from Recorder", nil);
    
    [_logoutButton setTitle:NSLocalizedString(@"Logout", nil) forState:UIControlStateNormal];
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
    [_settingsViewModel logout];

    [self hideNavigationBar];
}

- (IBAction)actionSendingTypeSwitchChangeValue:(UISwitch *)sender {
    [_settingsViewModel changeSendingType:sender.on];
    
    if (_didChangeAutoUploadItem) {
        _didChangeAutoUploadItem(@(sender.on));
    }
}

- (IBAction)actionNetworkSwitchChangeValue:(UISwitch *)sender {
    [_settingsViewModel changeNetworkType:sender.on];
}

- (IBAction)actionStartSwitchChangeValue:(UISwitch *)sender {
    [_settingsViewModel changeAppStartScene:sender.on];
}


#pragma mark - UITableViewDataSource -
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return [_settingsViewModel.userApp valueForKey:@"userAppEmail"];
    }
    
    return nil;
}


#pragma mark - UITableViewDelegate -
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return (section == 1) ? 54.f : 0.f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return (section == 0) ? 0.f: 0.001f;
}

@end
