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
#import "UIColor+HexColor.h"
#import <NSString+Email.h>
#import "AFNetworking.h"
#import <AFHTTPRequestOperation.h>


@interface HRPMainViewController () <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *logoImageView;
@property (strong, nonatomic) IBOutlet UILabel *logoLabel;
@property (strong, nonatomic) IBOutlet UILabel *aboutLabel1;
@property (strong, nonatomic) IBOutlet UILabel *aboutLabel2;
@property (strong, nonatomic) IBOutlet UITextField *emailTextField;
@property (strong, nonatomic) IBOutlet HRPButton *loginButton;
@property (strong, nonatomic) IBOutlet UILabel *madeByLabel;
@property (strong, nonatomic) IBOutlet UIImageView *stfalconLogoImageView;
@property (strong, nonatomic) IBOutlet UILabel *versionLabel;

@end

@implementation HRPMainViewController {
    NSUserDefaults *userApp;
}

#pragma mark - Constructors -
- (void)viewDidLoad {
    [super viewDidLoad];

    // Set Status Bar
    UIView *statusBarView                               =  [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, CGRectGetWidth(self.view.frame), 20.f)];
    statusBarView.backgroundColor                       =  [UIColor colorWithHexString:@"0477BD" alpha:1.f];
    [self.view addSubview:statusBarView];
    
    self.versionLabel.text                              =   [NSString stringWithFormat:@"%@ %@ (%@)",    NSLocalizedString(@"Version", nil),
                                                             [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],
                                                             [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey]];
    
    // Set Logo text
    self.logoLabel.text                                 =   NSLocalizedString(@"Public patrol", nil);
    self.aboutLabel1.text                               =   NSLocalizedString(@"About text 1", nil);
    self.aboutLabel2.text                               =   NSLocalizedString(@"About text 2", nil);
    
    // Set button title
    [self.loginButton setTitle:NSLocalizedString(@"Login", nil) forState:UIControlStateNormal];
    
    // Get NSUserDefaults item
    userApp                                             =   [NSUserDefaults standardUserDefaults];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([userApp objectForKey:@"userAppEmail"]) {
        UINavigationController *collectionNC            =   [self.storyboard instantiateViewControllerWithIdentifier:@"CollectionNC"];
        HRPCollectionViewController *collectionVC       =   collectionNC.viewControllers[0];
        [collectionVC.userNameBarButton setTitle:[userApp objectForKey:@"userAppEmail"]];
        self.emailTextField.text                        =   [userApp objectForKey:@"userAppEmail"];
        
        [self presentViewController:collectionNC animated:YES completion:nil];
    } else {
        [UIView animateWithDuration:1.3f
                         animations:^{
                             self.versionLabel.alpha                                =   0.f;
                         } completion:^(BOOL finished) {
                             [UIView animateWithDuration:0.7f
                                              animations:^{
                                                  self.stfalconLogoImageView.alpha  =   1.f;
                                                  self.madeByLabel.alpha            =   1.f;
                                              }];
                         }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - API -
- (void)userLoginParameters:(NSString *)email
                  onSuccess:(void(^)(NSDictionary *successResult))success
                  orFailure:(void(^)(AFHTTPRequestOperation *failureOperation))failure {
    AFHTTPRequestOperationManager *requestOperationDomainManager    =   [[AFHTTPRequestOperationManager alloc]
                                                                                    initWithBaseURL:[NSURL URLWithString:@"http://xn--80awkfjh8d.com/"]];
    
    NSString *pathAPI                                               =   @"api/register";

    AFHTTPRequestSerializer *userRequestSerializer                  =   [AFHTTPRequestSerializer serializer];
    [userRequestSerializer setValue:@"application/json" forHTTPHeaderField:@"CONTENT_TYPE"];
    
    [requestOperationDomainManager POST:pathAPI
                             parameters:@{ @"email" : email }
                                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                    if (operation.response.statusCode == 200)
                                        success(responseObject);
                                }
                                failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                    if (operation.response.statusCode == 400)
                                        failure(operation);
                                }];
}


#pragma mark - Actions -
- (IBAction)actionLoginButtonTap:(HRPButton *)sender {
    if ([self.emailTextField.text isEmail])
        // API
        [self userLoginParameters:self.emailTextField.text
                        onSuccess:^(NSDictionary *successResult) {
                            UINavigationController *collectionNC            =   [self.storyboard instantiateViewControllerWithIdentifier:@"CollectionNC"];
                            HRPCollectionViewController *collectionVC       =   collectionNC.viewControllers[0];
                            [collectionVC.userNameBarButton setTitle:self.emailTextField.text];
                            
                            [self presentViewController:collectionNC animated:YES completion:nil];
                            
                            // Set NSUserDefaults item
                            [userApp setObject:self.emailTextField.text forKey:@"userAppEmail"];
                            [userApp synchronize];
                        }
                        orFailure:^(AFHTTPRequestOperation *failureOperation) {
                            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Alert error API title", nil)
                                                        message:NSLocalizedString(@"Alert error API message", nil)
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:NSLocalizedString(@"Alert error button Ok", nil), nil] show];
                        }];
    else
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Alert error email title", nil)
                                    message:NSLocalizedString(@"Alert error email message", nil)
                                   delegate:nil
                          cancelButtonTitle:nil
                          otherButtonTitles:NSLocalizedString(@"Alert error button Ok", nil), nil] show];
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
