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

    [self.cancelButton setTitle:NSLocalizedString(@"Alert error button Cancel", nil) forState:UIControlStateNormal];
    
    [self getPhotoFromAlbumAtURL:[NSURL URLWithString:self.photo.assetsURL]
                       onSuccess:^(UIImage *image) {
                           [UIView transitionWithView:self.photoImageView
                                             duration:0.5f
                                              options:UIViewAnimationOptionTransitionCrossDissolve
                                           animations:^{
                                               self.photoImageView.image    =   image;
                                           }
                                           completion:^(BOOL finished) {
                                               [self.activityIndicator stopAnimating];
                                           }];
                       }];
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
    ALAssetsLibrary *library                    =   [[ALAssetsLibrary alloc] init];
    [library assetForURL:assetsURL
             resultBlock:^(ALAsset *asset) {
                 UIImage  *copyOfOriginalImage  =   [UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage]
                                                                        scale:0.5f
                                                                  orientation:UIImageOrientationUp];
                 
                 success(copyOfOriginalImage);
             }
            failureBlock:^(NSError *error) { }];
}

@end
