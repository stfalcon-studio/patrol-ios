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

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIView *contentView;

@property (strong, nonatomic) IBOutlet UIImageView *logoImageView;
@property (strong, nonatomic) IBOutlet UILabel *logoLabel;
@property (strong, nonatomic) IBOutlet UILabel *madeByLabel;
@property (strong, nonatomic) IBOutlet UIImageView *stfalconLogoImageView;
@property (strong, nonatomic) IBOutlet UILabel *versionLabel;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *contentViewWidthConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeightConstraint;

@end

@implementation HRPMainViewController {
    HRPMainViewModel *_mainViewModel;
}

#pragma mark - Constructors -
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set Scroll View constraints
    _contentViewWidthConstraint.constant    =   CGRectGetWidth(self.view.frame);
    _contentViewHeightConstraint.constant   =   CGRectGetHeight(self.view.frame);
    
    // Set Logo text
    _logoLabel.text                         =   NSLocalizedString(@"Public patrol", nil);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self hideNavigationBar];
    
    // Create model
    _mainViewModel                          =   [[HRPMainViewModel alloc] init];
    _versionLabel.text                      =   [_mainViewModel getAppVersion];

    // Select Next Scene
    HRPBaseViewController *nextVC           =   [self.storyboard instantiateViewControllerWithIdentifier:
                                                    [_mainViewModel selectNextSceneStoryboardID]];
    
    HRPNavigationController *navBar         =   [[HRPNavigationController alloc] initWithRootViewController:nextVC];
    
    [self.navigationController presentViewController:navBar animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - UIViewControllerRotation -
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    _contentViewWidthConstraint.constant    =   size.width;
    
    [self.view layoutIfNeeded];
}

@end
