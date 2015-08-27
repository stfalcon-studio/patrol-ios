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
#import <CoreLocation/CoreLocation.h>
#import "HRPNetworkConnection.h"
#import "HRPLocations.h"
#import "AFNetworking.h"
#import <AFHTTPRequestOperation.h>


typedef void (^ALAssetsLibraryAssetForURLResultBlock)(ALAsset *asset);
typedef void (^ALAssetsLibraryAccessFailureBlock)(NSError *error);

@interface HRPCollectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) UIImagePickerController *imagePickerController;
@property (strong, nonatomic) IBOutlet UICollectionView *photosCollectionView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *uploadActivityIndicator;

@end


@implementation HRPCollectionViewController {
    HRPNetworkConnection *networkManager;
    HRPLocations *locationsService;
    HRPPhoto *currentPhoto;
    HRPPhotoCell *currentCell;
    NSUserDefaults *userApp;
    CLLocation *locationNew;
    
    NSMutableArray *photosDataSource;
    CGSize photoSize;
    NSInteger missingPhotosCount;
    NSString *arrayPath;
    
    BOOL isUploadPhotosUsingWiFiAllowed;

    NSString* score;
    BOOL bGenuine;
    NSInteger errorCode;
}

#pragma mark - Constructors -
- (void)viewDidLoad {
    [super viewDidLoad];

    self.uploadActivityIndicator.color          =   [UIColor colorWithHexString:@"05A9F4" alpha:1.f];
//    [self.uploadActivityIndicator startAnimating];
    [self.uploadActivityIndicator stopAnimating];
    
    CGFloat cellSide                            =   (CGRectGetWidth(self.photosCollectionView.frame) - 4.f) / 2;
    photoSize                                   =   CGSizeMake(cellSide, cellSide);
    missingPhotosCount                          =   0;
    
    // Set network manager
    networkManager                              =   [[HRPNetworkConnection alloc] init];
    
    // Set Status Bar
    UIView *statusBarView                       =  [[UIView alloc] initWithFrame:CGRectMake(0.f, -20.f, CGRectGetWidth(self.view.frame), 20.f)];
    statusBarView.backgroundColor               =  [UIColor colorWithHexString:@"0477BD" alpha:1.f];
    [self.navigationController.navigationBar addSubview:statusBarView];
    
    // Set Data Source
    userApp                                     =   [NSUserDefaults standardUserDefaults];
    
    
    
//    [self createStoreDataPath];
//    [self savePhotosCollectionToFile];
//    [self readPhotosCollectionFromFile];
    
    // Tested data
    /*
    if (photosDataSource.count == 0) {
        photosDataSource = [NSMutableArray array];
        
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
                                       photo.imageAvatar    =   [image resizeImage:newPhoto toSize:photoSize andCropInCenter:YES];
                                       photo.imageOriginal  =   newPhoto;
                                       
                                       [photosDataSource addObject:photo];
                                   } else
                                       //missingPhotosCount++;
                                   
                                   //
                                   
                                   [photosDataSource addObject:photo];
                                   
                                   [self savePhotosCollectionToFile];
                                   [self readPhotosCollectionFromFile];

                                   
                                   
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
     */

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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    isUploadPhotosUsingWiFiAllowed                  =   [userApp boolForKey:@"networkStatus"];
    
    if (isUploadPhotosUsingWiFiAllowed && [networkManager isWiFiConnected]) {
        /*
            NSLog(@"Wifi Enabled   : %@", [networkManager isWiFiEnabled  ] ? @"Yes" : @"No");
            NSLog(@"Wifi Connected : %@", [networkManager isWiFiConnected] ? @"Yes" : @"No");
            NSLog(@"Wifi BSSID     : %@", [networkManager BSSID]);
            NSLog(@"Wifi SSID      : %@", [networkManager SSID ]);
        */
        
        // API - upload photos to server
    }
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


#pragma mark - API -
- (void)uploadPhotoWithParameters:(NSDictionary *)parameters
                        onSuccess:(void(^)(NSDictionary *successResult))success
                        orFailure:(void(^)(AFHTTPRequestOperation *failureOperation))failure {
    AFHTTPRequestOperationManager *requestOperationDomainManager    =   [[AFHTTPRequestOperationManager alloc]
                                                                         initWithBaseURL:[NSURL URLWithString:@"http://xn--80awkfjh8d.com/"]];
    
    NSString *pathAPI                                               =   [NSString stringWithFormat:@"api/9/violation/create"
                                                                                /*[userApp objectForKey:@"userAppID"]*/];
    
    AFHTTPRequestOperation *operationRequest    =   [requestOperationDomainManager POST:pathAPI
                                                                             parameters:parameters
                                                              constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                                                  [formData appendPartWithFileData:parameters[@"photo"]
                                                                                              name:@"photo"
                                                                                          fileName:@"photo.jpg"
                                                                                          mimeType:@"image/jpeg"];
                                                              }
                                                                                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                                                    if (operation.response.statusCode != 200)
                                                                                        success(responseObject);
                                                                                }
                                                                                failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                                                    failure(operation);
                                                                                }];
    
    [operationRequest start];
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
            cameraVC.allowsEditing                  =   NO;
            cameraVC.delegate                       =   self;
            
            cameraVC.modalPresentationStyle         =   UIModalPresentationFullScreen;
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
    currentCell                                     =   notification.userInfo[@"cell"];
    currentPhoto                                    =   currentCell.photo;

    [currentCell.activityIndicator startAnimating];
    [self.uploadActivityIndicator startAnimating];
    
    [self uploadOnePhoto:YES];
}


#pragma mark - Methods -
- (void)getPhotoFromAlbumAtURL:(NSURL *)assetsURL
                     onSuccess:(void(^)(UIImage *image))success {
    ALAssetsLibrary *library                        =   [[ALAssetsLibrary alloc] init];
    [library assetForURL:assetsURL
             resultBlock:^(ALAsset *asset) {
                 UIImage  *copyOfOriginalImage      =   [UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage]
                                                                            scale:0.5
                                                                      orientation:UIImageOrientationUp];
                 
                 success(copyOfOriginalImage);
             }
            failureBlock:^(NSError *error) { }];
}

- (BOOL)canPhotosSendToServet {
    NSURL *scriptUrl                                =   [NSURL URLWithString:@"http://stfalcon.com/team"];
    NSData *data                                    =   [NSData dataWithContentsOfURL:scriptUrl];
    
    if (data && !isUploadPhotosUsingWiFiAllowed)
        return YES;
    /*else
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Alert error email title", nil)
                                    message:NSLocalizedString(@"Alert error internet message", nil)
                                   delegate:nil
                          cancelButtonTitle:nil
                          otherButtonTitles:NSLocalizedString(@"Alert error button Ok", nil), nil] show];
         */
    
    return NO;
}

//-(void)uploadPhoto{
//    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://xn--80awkfjh8d.com/"]];
//    
//    UIImage *image = [UIImage imageNamed:@"test.JPG"];
//    NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
//    
//    NSDictionary *parameters                    =   @{
//                                                              @"photo"        :   imageData,
//                                                              @"latitude"     :   @(46.22),
//                                                              @"longitude"    :   @(22.46)
//                                                      };
//
//    
//    AFHTTPRequestOperation *op = [manager POST:@"api/9/violation/create" parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
//        //do not put image inside parameters dictionary as I did, but append it!
//        [formData appendPartWithFileData:imageData name:@"photo" fileName:@"photo.jpg" mimeType:@"image/jpeg"];
//    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSLog(@"Success: %@ ***** %@", operation.responseString, responseObject);
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        NSLog(@"Error: %@ ***** %@", operation.responseString, error);
//    }];
//    
//    [op start];
//}


- (void)uploadOnePhoto:(BOOL)uploadOnePhoto {
    // Upload one photo
    if (uploadOnePhoto) {
        // Save to device
        [self savePhotosCollectionToFile];
        
        if ([currentPhoto.assetsURL hasSuffix:@"JPG"])
            currentPhoto.imageData                      =   [[NSData alloc] initWithData:UIImageJPEGRepresentation(currentPhoto.imageOriginal, 1.f)];
        else
            currentPhoto.imageData                      =   [[NSData alloc] initWithData:UIImagePNGRepresentation(currentPhoto.imageOriginal)];
        
        // API
        currentPhoto.latitude                           =   locationNew.coordinate.latitude;
        currentPhoto.longitude                          =   locationNew.coordinate.longitude;
        
        NSDictionary *parameters                        =   @{
                                                                    @"photo"        :   currentPhoto.imageData,
                                                                    @"latitude"     :   @(currentPhoto.latitude),
                                                                    @"longitude"    :   @(currentPhoto.longitude)
                                                            };
        
        [self uploadPhotoWithParameters:parameters
                              onSuccess:^(NSDictionary *successResult) {
                                  currentPhoto.state    =   HRPPhotoStateDone;
                    
                                  [self.photosCollectionView reloadData];
                                  [self savePhotosCollectionToFile];
                                  [currentCell.activityIndicator stopAnimating];
                                  [self.uploadActivityIndicator stopAnimating];
                              }
                              orFailure:^(AFHTTPRequestOperation *failureOperation) {
                                  currentPhoto.state    =   HRPPhotoStateRepeat;
                    
                                  [self.photosCollectionView reloadData];
                                  [self savePhotosCollectionToFile];
                                  [currentCell.activityIndicator stopAnimating];
                                  [self.uploadActivityIndicator stopAnimating];
                              }];
    }
    
    // Upload some photos in loop
    else {
        for (HRPPhoto *photo in photosDataSource) {
            if (photo.state != HRPPhotoStateDone) {
                currentPhoto                            =   photo;
                
                if ([currentPhoto.assetsURL hasSuffix:@"JPG"])
                    currentPhoto.imageData              =   [[NSData alloc] initWithData:UIImageJPEGRepresentation(currentPhoto.imageOriginal, 1.f)];
                else
                    currentPhoto.imageData              =   [[NSData alloc] initWithData:UIImagePNGRepresentation(currentPhoto.imageOriginal)];
                
                NSDictionary *parameters                =   @{
                                                                  @"photo"        :   currentPhoto.imageData,
                                                                  @"latitude"     :   @(currentPhoto.latitude),
                                                                  @"longitude"    :   @(currentPhoto.longitude)
                                                            };
                
                [self uploadPhotoWithParameters:parameters
                                      onSuccess:^(NSDictionary *successResult) {
                                          currentPhoto.state              =   HRPPhotoStateDone;
                                          
                                          [self.photosCollectionView reloadData];
                                          [self savePhotosCollectionToFile];
                                          [currentCell.activityIndicator stopAnimating];
                                          [self.uploadActivityIndicator stopAnimating];
                                      }
                                      orFailure:^(AFHTTPRequestOperation *failureOperation) {
                                          currentPhoto.state              =   HRPPhotoStateRepeat;
                                          
                                          [self.photosCollectionView reloadData];
                                          [self savePhotosCollectionToFile];
                                          [currentCell.activityIndicator stopAnimating];
                                          [self.uploadActivityIndicator stopAnimating];
                                      }];
            }
        }
    }
    
    [locationsService.manager stopUpdatingLocation];
}

- (void)createStoreDataPath {
    NSError *error;
    NSArray *paths                                  =   NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    arrayPath                                       =   [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Patrul"];

    if (![[NSFileManager defaultManager] fileExistsAtPath:arrayPath]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:arrayPath
                                       withIntermediateDirectories:NO
                                                        attributes:nil
                                                             error:&error])
            NSLog(@"Create directory error: %@", error);
    }
}

- (void)savePhotosCollectionToFile {
    NSData *arrayData                               =   [NSKeyedArchiver archivedDataWithRootObject:photosDataSource];
//    NSArray *paths                                  =   NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    arrayPath                                       =   [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Patrul"];
//    arrayPath                                       =   [arrayPath stringByAppendingPathComponent:@"photosDataSource"];
//    
//    [[NSFileManager defaultManager] createFileAtPath:arrayPath
//                                            contents:arrayData
//                                          attributes:nil];
    
    if ([NSKeyedArchiver archiveRootObject:arrayData toFile:@"photos"])
        NSLog(@"YES");
    else
        NSLog(@"NO");
        
}

- (void)readPhotosCollectionFromFile {
    NSArray *paths                                  =   NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    arrayPath                                       =   [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Patrul"];
    arrayPath                                       =   [arrayPath stringByAppendingPathComponent:@"photosDataSource"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:arrayPath]) {
        //File exists
        NSData *arrayData                           =   [[NSData alloc] initWithContentsOfFile:arrayPath];
        
        if (arrayData)
            photosDataSource                        =   [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithData:arrayData]];
        else
            NSLog(@"File does not exist");
    }
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
    
    cell.photoImageView.image                   =   photo.imageAvatar;
    cell.photo                                  =   photo;
    
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
    [self.uploadActivityIndicator startAnimating];
    
    // HSPLocations
    locationsService                            =   [[HRPLocations alloc] init];
    
    if ([locationsService isEnabled])
        locationsService.manager.delegate       =   self;

    UIImage *chosenImage                        =   [info objectForKey:UIImagePickerControllerOriginalImage];
    ALAssetsLibrary *assetsLibrary              =   [[ALAssetsLibrary alloc] init];
    [picker dismissViewControllerAnimated:YES completion:NULL];
    picker                                      =   nil;
    self.imagePickerController                  =   nil;
    
    HRPPhoto *photo                             =   [[HRPPhoto alloc] init];
    HRPImage *image                             =   [[HRPImage alloc] init];
    photo.imageAvatar                           =   [UIImage imageWithCGImage:[UIImage imageNamed:@"icon-no-image"].CGImage];
    photo.imageOriginal                         =   chosenImage;
    
    [photosDataSource insertObject:photo atIndex:0];
    [self.photosCollectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
    
    currentCell                                 =   [[HRPPhotoCell alloc] initWithFrame:CGRectMake(0.f, 0.f, photoSize.width, photoSize.height)];
    currentCell                                 =   (HRPPhotoCell *)[self.photosCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    currentCell.activityIndicator.color         =   [UIColor colorWithHexString:@"05A9F4" alpha:1.f];
    [currentCell.activityIndicator startAnimating];
    
    [assetsLibrary writeImageToSavedPhotosAlbum:chosenImage.CGImage
                                    orientation:(ALAssetOrientation)chosenImage.imageOrientation
                                completionBlock:^(NSURL *assetURL, NSError *error) {
                                    ALAssetsLibrary *libraryAssets = [[ALAssetsLibrary alloc] init];
                                    [libraryAssets assetForURL:assetURL
                                                   resultBlock:^(ALAsset *asset) {
                                                       photo.assetsURL                                      =   [assetURL absoluteString];
                                                       photo.imageAvatar                                    =   [image resizeImage:chosenImage
                                                                                                                            toSize:photoSize
                                                                                                                   andCropInCenter:YES];

                                                       [UIView transitionWithView:currentCell.photoImageView
                                                                         duration:0.5f
                                                                          options:UIViewAnimationOptionTransitionCrossDissolve
                                                                       animations:^{
                                                                           currentCell.photoImageView.image =   photo.imageAvatar;
                                                                       }
                                                                       completion:^(BOOL finished) {
                                                                           [photosDataSource replaceObjectAtIndex:0 withObject:photo];
                                                                           
                                                                           // API
                                                                           currentPhoto                     =   photo;
                                                                           [self uploadOnePhoto:YES];
                                                                       }];
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


#pragma mark - CLLocationManagerDelegate -
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    currentPhoto.latitude           =   newLocation.coordinate.latitude;
    currentPhoto.longitude          =   newLocation.coordinate.longitude;
    
    locationNew                     =   newLocation;
}

//- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
//    currentPhoto.latitude           =   
//}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {

}

- (void)requestAlwaysAuthorization {
    CLAuthorizationStatus status    =   [CLLocationManager authorizationStatus];
    
    // If the status is denied or only granted for when in use, display an alert
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusDenied) {
        NSString *titleText         =   NSLocalizedString(@"Alert error location title background", nil);
        
        NSString *messageText       =   (status == kCLAuthorizationStatusDenied) ?  NSLocalizedString(@"Alert error location message off", nil) :
                                                                                    NSLocalizedString(@"Alert error location message background", nil);
        
        [[[UIAlertView alloc] initWithTitle:titleText
                                    message:messageText
                                   delegate:nil
                          cancelButtonTitle:nil
                          otherButtonTitles:NSLocalizedString(@"Alert error button Ok", nil), nil] show];
    }
    
    // The user has not enabled any location services. Request background authorization.
    else if (status == kCLAuthorizationStatusNotDetermined) {
        [locationsService.manager requestAlwaysAuthorization];
    }
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
