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
//  HRPViewController.m
//  HromadskyiPatrul
//
//  Created by msm72 on 21.08.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPMainViewController.h"
#import "HRPNavigationController.h"
#import "HRPMainViewModel.h"


@interface HRPMainViewController ()

@property (strong, nonatomic) IBOutlet UIView *contentView;

@property (strong, nonatomic) IBOutlet UIImageView *logoImageView;
@property (strong, nonatomic) IBOutlet UILabel *logoLabel;
@property (strong, nonatomic) IBOutlet UILabel *madeByLabel;
@property (strong, nonatomic) IBOutlet UIImageView *stfalconLogoImageView;
@property (strong, nonatomic) IBOutlet UILabel *versionLabel;

@end

@implementation HRPMainViewController {
    HRPMainViewModel *_mainViewModel;
    UIView *_statusView;
}

#pragma mark - Constructors -
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //    _statusView = [self customizeStatusBar];
    
    // Set Logo text
    _logoLabel.text = NSLocalizedString(@"Public patrol", nil);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self hideNavigationBar];
    
    // Create model
    _mainViewModel = [[HRPMainViewModel alloc] init];
    _versionLabel.text = [_mainViewModel getAppVersion];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Select Next Scene
    HRPBaseViewController *nextVC = [self.storyboard instantiateViewControllerWithIdentifier:
                                     [_mainViewModel selectNextSceneStoryboardID]];
    
    nextVC.isStartAsRecorder = YES;
    
    [self.navigationController pushViewController:nextVC animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - Actions -
-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
    
}


#pragma mark - UIViewControllerRotation -
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    //    _statusView.frame = CGRectMake(0.f, -20.f, /*(size.width < size.height) ? 0.f : -20.f,*/ size.width, 20.f);
    
    [self.view layoutIfNeeded];
}

@end
