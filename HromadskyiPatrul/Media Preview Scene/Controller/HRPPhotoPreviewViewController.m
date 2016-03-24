//
//  HRPPhotoPreviewViewController.m
//  HromadskyiPatrul
//
//  Created by msm72 on 28.08.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPPhotoPreviewViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "UIColor+HexColor.h"


@interface HRPPhotoPreviewViewController ()

@property (strong, nonatomic) IBOutlet UIImageView *photoImageView;
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end


@implementation HRPPhotoPreviewViewController

#pragma mark - Constructors -
- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"Preview a Photo", nil);

    [self.cancelButton setTitle:NSLocalizedString(@"Alert error button Cancel", nil)
                       forState:UIControlStateNormal];
    
    [self getPhotoFromAlbumAtURL:[NSURL URLWithString:_violation.assetsPhotoURL]
                       onSuccess:^(UIImage *image) {
                           [UIView transitionWithView:_photoImageView
                                             duration:0.5f
                                              options:UIViewAnimationOptionTransitionCrossDissolve
                                           animations:^{
                                               _photoImageView.image = image;
                                               [self.view bringSubviewToFront:_cancelButton];
                                           }
                                           completion:^(BOOL finished) {
                                               [self.activityIndicator stopAnimating];
                                           }];
                       }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Set Status Bar
    UIView *statusBarView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, CGRectGetWidth(self.view.frame), 20.f)];
    statusBarView.backgroundColor = [UIColor colorWithHexString:@"3AA6F4" alpha:1.f];
    [self.navigationController.navigationBar addSubview:statusBarView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - Actions -
- (IBAction)actionCancelButtonTap:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Methods -
- (void)getPhotoFromAlbumAtURL:(NSURL *)assetsURL
                     onSuccess:(void(^)(UIImage *image))success {
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library assetForURL:assetsURL
             resultBlock:^(ALAsset *asset) {
                 UIImage *originalImage = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage]
                                                              scale:0.5f
                                                        orientation:UIImageOrientationUp];
                 
                 success(originalImage);
             }
            failureBlock:^(NSError *error) { }];
}

@end
