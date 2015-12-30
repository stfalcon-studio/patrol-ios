//
//  HRPViewController.m
//  HromadskyiPatrul
//
//  Created by msm72 on 21.08.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPLoginViewController.h"
#import "HRPCollectionViewController.h"
#import "HRPVideoRecordViewController.h"
#import "HRPButton.h"
#import "UIColor+HexColor.h"
#import <NSString+Email.h>
#import "HRPLoginViewModel.h"


@interface HRPLoginViewController () <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIView *contentView;

@property (strong, nonatomic) IBOutlet UIImageView *logoImageView;
@property (strong, nonatomic) IBOutlet UILabel *logoLabel;
@property (strong, nonatomic) IBOutlet UILabel *aboutLabel1;
@property (strong, nonatomic) IBOutlet UILabel *aboutLabel2;
@property (strong, nonatomic) IBOutlet UILabel *aboutLabel3;
@property (strong, nonatomic) IBOutlet UITextField *emailTextField;
@property (strong, nonatomic) IBOutlet HRPButton *loginButton;
@property (strong, nonatomic) IBOutlet UILabel *madeByLabel;
@property (strong, nonatomic) IBOutlet UIImageView *stfalconLogoImageView;
@property (strong, nonatomic) IBOutlet UILabel *versionLabel;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *contentViewWidthConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *statusBarTopConstarint;

@end

@implementation HRPLoginViewController {
    HRPLoginViewModel *_loginViewModel;
    
    CGSize _keyboardSize;
    CGSize _screenSize;
    BOOL _isKeyboardShow;
}

#pragma mark - Constructors -
- (void)viewDidLoad {
    [super viewDidLoad];
    
    _screenSize         =   CGSizeMake(CGRectGetWidth([[UIScreen mainScreen] bounds]),
                                       CGRectGetHeight([[UIScreen mainScreen] bounds]));

    [self hideNavigationBar];
    
    [self showLoaderWithText:NSLocalizedString(@"Launch text", nil)
          andBackgroundColor:BackgroundColorTypeBlack
                     forTime:3];

    // Create model
    _loginViewModel     =   [[HRPLoginViewModel alloc] init];
    
    // Set Logo text
    _logoLabel.text     =   NSLocalizedString(@"Public patrol", nil);
    _aboutLabel1.text   =   NSLocalizedString(@"About text 1", nil);
    _aboutLabel2.text   =   NSLocalizedString(@"About text 2", nil);
    _aboutLabel3.text   =   NSLocalizedString(@"About text 3", nil);
    
    // Set button title
    [_loginButton setTitle:NSLocalizedString(@"Login", nil) forState:UIControlStateNormal];
    
    // Set Notification Observers
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleUserLogout:)
                                                 name:@"HRPSettingsViewControllerUserLogout"
                                               object:nil];

    // Keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Set Scroll View constraints
    if (UIDeviceOrientationIsPortrait([[UIDevice currentDevice] orientation])) {
        _contentViewWidthConstraint.constant    =   _screenSize.width;
        _statusBarTopConstarint.constant        =   0.f;
    }
    
    else {
        _contentViewWidthConstraint.constant    =   _screenSize.width;
        _statusBarTopConstarint.constant        =   -20.f;
    }
    
    [self.view layoutIfNeeded];
    
    if ([_loginViewModel.userApp objectForKey:@"userAppEmail"])
        _emailTextField.text    =   [_loginViewModel.userApp objectForKey:@"userAppEmail"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Actions -
- (IBAction)actionLoginButtonTap:(HRPButton *)sender {
    // Email validation
    if ([self.emailTextField.text isEmail]) {
        // API
        if ([self isInternetConnectionAvailable]) {
            [sender setUserInteractionEnabled:NO];
            
            [self showLoaderWithText:NSLocalizedString(@"Authorization", nil)
                  andBackgroundColor:BackgroundColorTypeBlack
                             forTime:100];
            
            [_loginViewModel userLoginParameters:self.emailTextField.text
                                      onSuccess:^(NSDictionary *successResult) {
                                          [self. emailTextField resignFirstResponder];
                                          
                                          // Set NSUserDefaults item
                                          [_loginViewModel.userApp setObject:self.emailTextField.text forKey:@"userAppEmail"];
                                          [_loginViewModel.userApp setObject:successResult[@"id"] forKey:@"userAppID"];
                                          [_loginViewModel.userApp synchronize];

                                          // Transition to VideoRecord scene
                                          HRPVideoRecordViewController *videoRecordVC   =   [self.storyboard instantiateViewControllerWithIdentifier:@"VideoRecordVC"];
                                          
                                          [self.navigationController pushViewController:videoRecordVC animated:YES];
                                          [sender setUserInteractionEnabled:YES];
                                      }
                                      orFailure:^(AFHTTPRequestOperation *failureOperation) {
                                          [self showAlertViewWithTitle:NSLocalizedString(@"Alert error API title", nil)
                                                            andMessage:NSLocalizedString(@"Alert error API message", nil)];
                                          
                                          [self hideLoader];
                                          [sender setUserInteractionEnabled:YES];
                                      }];
        }
    }
    
    // Email error
    else
        [self showAlertViewWithTitle:NSLocalizedString(@"Alert error email title", nil)
                          andMessage:NSLocalizedString(@"Alert error email message", nil)];
}


#pragma mark - NSNotification -
- (void)handleUserLogout:(NSNotification *)notification {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)keyboardDidShow:(NSNotification *)notification {
    NSDictionary *info      =   [notification userInfo];
    _keyboardSize           =   [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    _isKeyboardShow         =   YES;
    
    [self moveContentViewAboveKeyboard];
}

- (void)keyboardDidHide:(NSNotification *)notification {
    _isKeyboardShow         =   NO;
    
    [self.scrollView setContentOffset:CGPointZero animated:YES];
}


#pragma mark - UIGestureRecognizer -
- (IBAction)handleGestureRecognizerTap:(UITapGestureRecognizer *)sender {
    [self. emailTextField resignFirstResponder];
}


#pragma mark - Methods -
- (void)moveContentViewAboveKeyboard {
    if (_isKeyboardShow) {
        CGFloat emailPositionY              =   CGRectGetMaxY(_emailTextField.frame);
        CGFloat keyboardPositionTop         =   _screenSize.height - _keyboardSize.height - 10.f;
        
        if (emailPositionY > keyboardPositionTop)
            [_scrollView setContentOffset:CGPointMake(0.f, emailPositionY - keyboardPositionTop) animated:YES];
    }
    
    else
        [_scrollView setContentOffset:CGPointZero];
}


#pragma mark - UIViewControllerRotation -
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    _screenSize                             =   size;
    _contentViewWidthConstraint.constant    =   size.width;
    _statusBarTopConstarint.constant        =   (size.width < size.height) ? 0.f : -20.f;
    
    [self.view layoutIfNeeded];
    [self moveContentViewAboveKeyboard];
}


#pragma mark - UITextFieldDelegate -
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return  YES;
}

@end
