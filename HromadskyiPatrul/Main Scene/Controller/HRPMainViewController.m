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
    
    _statusView = [self customizeStatusBar];

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
    
//    HRPNavigationController *navBar = [[HRPNavigationController alloc] initWithRootViewController:nextVC];
  
    [self.navigationController pushViewController:nextVC animated:YES];
//    [self.navigationController presentViewController:navBar animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - Actions -
-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {

}


#pragma mark - UIViewControllerRotation -
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    _statusView.frame = CGRectMake(0.f, (size.width < size.height) ? 0.f : -20.f, size.width, 20.f);

    [self.view layoutIfNeeded];
}

@end
