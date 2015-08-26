//
//  HRPCollectionViewController.m
//  HromadskyiPatrul
//
//  Created by msm72 on 21.08.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPCollectionViewController.h"
#import "UIColor+HexColor.h"
#import "HRPButton.h"
#import "HRPPhotoCell.h"
#import "HRPPhoto.h"
#import "HRPImage.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>

typedef void (^ALAssetsLibraryAssetForURLResultBlock)(ALAsset *asset);
typedef void (^ALAssetsLibraryAccessFailureBlock)(NSError *error);

@interface HRPCollectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (strong, nonatomic) UIImagePickerController *imagePickerController;
@property (strong, nonatomic) IBOutlet UICollectionView *photosCollectionView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *uploadActivityIndicator;

@end


@implementation HRPCollectionViewController {
    NSMutableArray *photosDataSource;
    NSUserDefaults *userApp;
    CGSize photoSize;
    NSInteger missingPhotosCount;
}

#pragma mark - Constructors -
- (void)viewDidLoad {
    [super viewDidLoad];

    self.uploadActivityIndicator.color          =   [UIColor colorWithHexString:@"05A9F4" alpha:1.f];
    [self.uploadActivityIndicator startAnimating];
    CGFloat cellSide                            =   (CGRectGetWidth(self.photosCollectionView.frame) - 4.f) / 2;
    photoSize                                   =   CGSizeMake(cellSide, cellSide);
    missingPhotosCount                          =   0;
    
    // Set Status Bar
    UIView *statusBarView                       =  [[UIView alloc] initWithFrame:CGRectMake(0.f, -20.f, CGRectGetWidth(self.view.frame), 20.f)];
    statusBarView.backgroundColor               =  [UIColor colorWithHexString:@"0477BD" alpha:1.f];
    [self.navigationController.navigationBar addSubview:statusBarView];
    
    // Set Data Source
    userApp                                     =   [NSUserDefaults standardUserDefaults];
    photosDataSource                            =   [NSMutableArray arrayWithArray:[userApp objectForKey:@"photosDataSource"]];
    
    // Tested data
    if (photosDataSource.count == 0) {
        for (int i = 0; i < 10; i++) {
            HRPPhoto *photo                         =   [[HRPPhoto alloc] init];
            photo.latitude                          =   -49.2563588;
            photo.longitude                         =   26.35485;
            photo.assetsURL                         =   (arc4random_uniform(2)) ? @"assets-library://45asset/asset.JPG?id=E066BC2F-BB23-4005-961F-54995667B79A&ext=JPG" : @"assets-library://asset/asset.JPG?id=E066BC2F-BB23-4005-961F-54995667B79A&ext=JPG";
            
            HRPImage *image                         =   [[HRPImage alloc] init];
            NSURL *assetsURL                        =   [NSURL URLWithString:photo.assetsURL];
            
            [self getPhotoFromAlbumAtURL:assetsURL
                               onSuccess:^(UIImage *newPhoto) {
                                   if (newPhoto) {
                                       photo.image      =   [image resizeImage:newPhoto toSize:photoSize andCropInCenter:YES];
                                       [photosDataSource addObject:photo];
                                   } else
                                       missingPhotosCount++;
                                   
                                   if (i == 9) {
                                       if (missingPhotosCount == 1)
                                           [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Alert info title", nil)
                                                                       message:[NSString stringWithFormat:@"%li %@",    (long)missingPhotosCount,
                                                                                                                        NSLocalizedString(@"Photo is missing", nil)]
                                                                      delegate:nil
                                                             cancelButtonTitle:nil
                                                            otherButtonTitles:NSLocalizedString(@"Alert error button Ok", nil), nil] show];

                                       else if (missingPhotosCount <= 4)
                                           [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Alert info title", nil)
                                                                       message:[NSString stringWithFormat:@"%li %@",    (long)missingPhotosCount,
                                                                                                                        NSLocalizedString(@"Photos 2-4 are missing", nil)]
                                                                      delegate:nil
                                                             cancelButtonTitle:nil
                                                             otherButtonTitles:NSLocalizedString(@"Alert error button Ok", nil), nil] show];

                                       else
                                           [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Alert info title", nil)
                                                                       message:[NSString stringWithFormat:@"%li %@",    (long)missingPhotosCount,
                                                                                                                        NSLocalizedString(@"Photos >5 are missing", nil)]
                                                                      delegate:nil
                                                             cancelButtonTitle:nil
                                                             otherButtonTitles:NSLocalizedString(@"Alert error button Ok", nil), nil] show];
                                       
                                       [self.photosCollectionView reloadData];
                                       [self.uploadActivityIndicator stopAnimating];
                                   }
                               }];
        }
    }

    // Set Notification Observers
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleUserLogout:)
                                                 name:@"HRPSettingsViewControllerUserLogout"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRepeatButtonTap:)
                                                 name:@"HRPPhotoCellStateButtonTap"
                                               object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithHexString:@"0477BD" alpha:1.f]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
}


#pragma mark - Actions -
- (IBAction)actionCameraButtonTap:(HRPButton *)sender {
    [UIView animateWithDuration:0.05f
                     animations:^{
                         sender.fillColor           =   [UIColor colorWithHexString:@"05A9F4" alpha:0.5f];
                     } completion:^(BOOL finished) {
                         sender.fillColor           =   [UIColor colorWithHexString:@"05A9F4" alpha:1.f];
                     }];
    
    // Use device camera
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            UIImagePickerController *cameraVC       =   [[UIImagePickerController alloc] init];
            cameraVC.sourceType                     =   UIImagePickerControllerSourceTypeCamera;
            cameraVC.mediaTypes                     =   [UIImagePickerController availableMediaTypesForSourceType:cameraVC.sourceType];
            cameraVC.allowsEditing                  =   YES;
            cameraVC.delegate                       =   self;
            
            cameraVC.modalPresentationStyle         =   UIModalPresentationCurrentContext;
            self.imagePickerController              =   cameraVC;
            
            if (![self.imagePickerController isBeingPresented])
                [self.navigationController presentViewController:self.imagePickerController animated:YES completion:nil];
        } else
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Alert error email title", nil)
                                        message:NSLocalizedString(@"Camera is not available", nil)
                                       delegate:nil
                              cancelButtonTitle:nil
                              otherButtonTitles:NSLocalizedString(@"Alert error button Ok", nil), nil] show];
    });
}


#pragma mark - NSNotification -
- (void)handleUserLogout:(NSNotification *)notification {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleRepeatButtonTap:(NSNotification *)notification {
//    NSLog(@"state = %li", (long)((HRPPhotoCell *)notification.userInfo[@"cell"]).photoStateButton.tag);
}


#pragma mark - Methods -
- (void)getPhotoFromAlbumAtURL:(NSURL *)assetsURL
                     onSuccess:(void(^)(UIImage *image))success {
    ALAssetsLibrary *library                =   [[ALAssetsLibrary alloc] init];
    [library assetForURL:assetsURL
             resultBlock:^(ALAsset *asset) {
                 UIImage  *copyOfOriginalImage      =   [UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage]
                                                                            scale:0.5
                                                                      orientation:UIImageOrientationUp];
                 
                 success(copyOfOriginalImage);
             }
            failureBlock:^(NSError *error) { }];
}


#pragma mark - UICollectionViewDataSource -
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return photosDataSource.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier             =   @"PhotoCell";
    HRPPhotoCell *cell                          =   [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier
                                                                                              forIndexPath:indexPath];
    
    cell.activityIndicator.color                =   [UIColor colorWithHexString:@"05A9F4" alpha:1.f];
    
    HRPPhoto *photo                             =   [photosDataSource objectAtIndex:indexPath.row];
    
    switch (photo.state) {
        // HRPPhotoStateDone
        case 0: {
            [cell.photoStateButton setImage:[UIImage imageNamed:@"icon-done"] forState:UIControlStateNormal];
            cell.photoStateButton.tag           =   0;
        }
            break;
            
        // HRPPhotoStateRepeat
        case 1: {
            [cell.photoStateButton setImage:[UIImage imageNamed:@"icon-repeat"] forState:UIControlStateNormal];
            cell.photoStateButton.tag           =   1;
        }
            break;

        // HRPPhotoStateUpload
        case 2: {
            [cell.photoStateButton setImage:[UIImage imageNamed:@"icon-upload"] forState:UIControlStateNormal];
            cell.photoStateButton.tag           =   2;
        }
            break;
    }
    
    cell.photoImageView.image                   =   photo.image;
    [cell.activityIndicator stopAnimating];

    return cell;
}


#pragma mark - UICollectionViewDelegate -
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
}


#pragma mark - UICollectionViewDelegateFlowLayout -
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return photoSize;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    // top, left, bottom, right
    return UIEdgeInsetsMake(0.f, 0.f, 0.f, 0.f);
}


#pragma mark - UIImagePickerControllerDelegate -
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *chosenImage                        =   [info objectForKey:UIImagePickerControllerOriginalImage];
    ALAssetsLibrary *assetsLibrary              =   [[ALAssetsLibrary alloc] init];
    [picker dismissViewControllerAnimated:YES completion:NULL];
    picker                                      =   nil;
    self.imagePickerController                  =   nil;
    
    HRPPhoto *photo                             =   [[HRPPhoto alloc] init];
    HRPImage *image                             =   [[HRPImage alloc] init];
    photo.image                                 =   [UIImage imageWithCGImage:[UIImage imageNamed:@"icon-no-image"].CGImage];
    
    HRPPhotoCell *newCell                       =   [[HRPPhotoCell alloc] initWithFrame:CGRectMake(0.f, 0.f, photoSize.width, photoSize.height)];
    newCell.activityIndicator.color             =   [UIColor colorWithHexString:@"05A9F4" alpha:1.f];
    
    [self.photosCollectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
    
    [assetsLibrary writeImageToSavedPhotosAlbum:chosenImage.CGImage
                                    orientation:(ALAssetOrientation)chosenImage.imageOrientation
                                completionBlock:^(NSURL *assetURL, NSError *error) {
                                    ALAssetsLibrary *libraryAssets = [[ALAssetsLibrary alloc] init];
                                    [libraryAssets assetForURL:assetURL
                                                   resultBlock:^(ALAsset *asset) {
                                                       photo.assetsURL                      =   [assetURL absoluteString];
                                                       newCell.photoImageView.image         =   [image resizeImage:chosenImage toSize:photoSize andCropInCenter:YES];
                                                       
                                                       [photosDataSource insertObject:photo atIndex:0];
                                                       [newCell.activityIndicator stopAnimating];
                                                   }
                                                  failureBlock:^(NSError *error) { }];
                                }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES
                               completion:^{ }];
    
    picker                                                                          =   nil;
    self.imagePickerController                                                      =   nil;
}


#pragma mark - UIStoryboardSegue -
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"SettingsTVCSegue"]) {
        self.navigationItem.backBarButtonItem   =   [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@" ", nil)
                                                                                     style:UIBarButtonItemStylePlain
                                                                                    target:nil
                                                                                    action:nil];
    }
}

@end
