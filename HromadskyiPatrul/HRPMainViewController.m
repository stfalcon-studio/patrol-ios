//
//  HRPViewController.m
//  HromadskyiPatrul
//
//  Created by msm72 on 21.08.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPMainViewController.h"
#import "HRPCollectionViewController.h"
#import "HRPButton.h"


@interface HRPMainViewController () <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *logoImageView;
@property (strong, nonatomic) IBOutlet UILabel *aboutLabel;
@property (strong, nonatomic) IBOutlet UITextField *emailTextField;
@property (strong, nonatomic) IBOutlet HRPButton *loginButton;
@property (strong, nonatomic) IBOutlet UILabel *versionLabel;

@end

@implementation HRPMainViewController

#pragma mark - Constructors -
- (void)viewDidLoad {
    [super viewDidLoad];

    self.versionLabel.text                              =   [NSString stringWithFormat:@"%@ %@ (%@)",    NSLocalizedString(@"Version", nil),
                                                             [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],
                                                             [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey]];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [UIView animateWithDuration:1.3f
                     animations:^{
                         self.versionLabel.alpha        =   0.f;
                     } completion:^(BOOL finished) { }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - Actions -
- (IBAction)actionLoginButtonTap:(HRPButton *)sender {
    if (YES) {
        UINavigationController *collectionNC            =   [self.storyboard instantiateViewControllerWithIdentifier:@"CollectionNC"];
        HRPCollectionViewController *collectionVC       =   collectionNC.viewControllers[0];
        [collectionVC.userNameBarButton setTitle:@"Sergey M."];

        [self presentViewController:collectionNC animated:YES completion:nil];
    }
}


#pragma mark - UIGestureRecognizer -
- (IBAction)handleGestureRecognizerTap:(UITapGestureRecognizer *)sender {
    [self. emailTextField resignFirstResponder];
}


#pragma mark - UITextFieldDelegate -
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self actionLoginButtonTap:self.loginButton];
    
    return  YES;
}


@end
