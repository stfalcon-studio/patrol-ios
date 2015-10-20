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
#import "HRPLocations.h"
#import "AFNetworking.h"
#import <AFHTTPRequestOperation.h>
#import "HRPPhotoPreviewViewController.h"
#import "HRPVideoRecordViewController.h"
#import "HRPVideoPlayerViewController.h"


typedef void (^ALAssetsLibraryAssetForURLResultBlock)(ALAsset *asset);
typedef void (^ALAssetsLibraryAccessFailureBlock)(NSError *error);

@interface HRPCollectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) UIImagePickerController *imagePickerController;
@property (strong, nonatomic) IBOutlet HRPButton *cameraButton;
@property (strong, nonatomic) IBOutlet UICollectionView *photosCollectionView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *uploadActivityIndicator;

@end


@implementation HRPCollectionViewController {
    HRPLocations *locationsService;
    HRPPhoto *currentPhoto;
    HRPImage *currentImage;
    HRPPhotoCell *currentCell;
    NSIndexPath *currentIndexPath;
    NSUserDefaults *userApp;
    CLLocation *locationNew;
    ALAsset *myAsset;
    
    NSMutableArray *photosDataSource;
    NSMutableArray *imagesDataSource;
    CGSize photoSize;
    CGFloat cellSide;
    NSInteger missingPhotosCount;
    NSString *arrayPath;
    NSTimer *timer;
    NSInteger photosNeedUploadCount;
    NSInteger videosNeedUploadCount;
    NSInteger paginationOffset;
    NSMutableArray *imagesIndexPath;
    
    BOOL isUploadPhotosUsingWiFiAllowed;
    BOOL isUploadAutomaticallyAllowed;
    BOOL isLocationServiceEnabled;
    BOOL isUploadInProcess;
    BOOL isPaginationRun;
    BOOL isVideoPreviewStart;
}

#pragma mark - Constructors -
- (void)viewDidLoad {
    [super viewDidLoad];

    [self.uploadActivityIndicator startAnimating];

    // HSPLocations
    locationsService                            =   [[HRPLocations alloc] init];
    
    if ([locationsService isEnabled]) {
        locationsService.manager.delegate       =   self;
        isLocationServiceEnabled                =   YES;
    }
    
    if (CGRectGetHeight(self.view.frame) > CGRectGetWidth(self.view.frame))
        cellSide                                =   (CGRectGetWidth(self.view.frame) - 4.f) / 2;
    else
        cellSide                                =   (CGRectGetWidth(self.view.frame) - 8.f) / 3;

    photoSize                                   =   CGSizeMake(cellSide, cellSide);
    missingPhotosCount                          =   0;
    photosNeedUploadCount                       =   0;
    videosNeedUploadCount                       =   0;
    self.navigationItem.rightBarButtonItem.enabled      =   NO;
    self.photosCollectionView.userInteractionEnabled    =   NO;

    // Set network manager
    imagesIndexPath                             =   [NSMutableArray array];

    // Set Status Bar
    UIView *statusBarView                       =  [[UIView alloc] initWithFrame:CGRectMake(0.f, -20.f, CGRectGetWidth(self.view.frame), 20.f)];
    statusBarView.backgroundColor               =  [UIColor colorWithHexString:@"0477BD" alpha:1.f];
    [self.navigationController.navigationBar addSubview:statusBarView];
    
    // Set Data Source
    userApp                                     =   [NSUserDefaults standardUserDefaults];
    photosDataSource                            =   [NSMutableArray array];
    imagesDataSource                            =   [NSMutableArray array];
    isUploadInProcess                           =   NO;
    
    isPaginationRun                             =   NO;
    
    self.userNameBarButton.title                =   [userApp objectForKey:@"userAppEmail"];
//    [self createTestDataSource];
    
    
    [self createStoreDataPath];
//    [self savePhotosCollectionToFile];
//    [self removePhotosCollectionFromFile];
    [self readPhotosCollectionFromFile];
    
    // Set Notification Observers
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRepeatButtonTap:)
                                                 name:@"HRPPhotoCellStateButtonTap"
                                               object:nil];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(handleVideoRecord:)
//                                                 name:@"HRPVideoRecordViewControllerDismiss"
//                                               object:nil];
    
    // Set Reachability Observer
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityDidChange:)
                                                 name:AFNetworkingReachabilityDidChangeNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    isUploadPhotosUsingWiFiAllowed              =   [userApp boolForKey:@"networkStatus"];
    isUploadAutomaticallyAllowed                =   [userApp boolForKey:@"sendingTypeStatus"];
    isVideoPreviewStart                         =   NO;
    
    if (photosNeedUploadCount > 0 && !isUploadInProcess)
        [self startUploadPhotos];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [locationsService.manager stopUpdatingLocation];
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
    
    NSString *pathAPI                                               =   [NSString stringWithFormat:@"api/%@/violation/create",
                                                                                                    [userApp objectForKey:@"userAppID"]];
    
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

- (void)uploadVideoWithParameters:(NSDictionary *)parameters
                        onSuccess:(void(^)(NSDictionary *successResult))success
                        orFailure:(void(^)(AFHTTPRequestOperation *failureOperation))failure {
    AFHTTPRequestOperationManager *requestOperationDomainManager    =   [[AFHTTPRequestOperationManager alloc]
                                                                                initWithBaseURL:[NSURL URLWithString:@"http://xn--80awkfjh8d.com/"]];
    
    NSString *pathAPI                                               =   [NSString stringWithFormat:@"api/%@/violation-video/create",
                                                                                [userApp objectForKey:@"userAppID"]];
    
    AFHTTPRequestOperation *operationRequest    =   [requestOperationDomainManager POST:pathAPI
                                                                             parameters:parameters
                                                              constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                                                  [formData appendPartWithFileData:parameters[@"video"]
                                                                                              name:@"video"
                                                                                          fileName:@"video.mov"
                                                                                          mimeType:@"video/quicktime"];
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
                         sender.fillColor               =   [UIColor colorWithHexString:@"05A9F4" alpha:0.5f];
                     } completion:^(BOOL finished) {
                         sender.fillColor               =   [UIColor colorWithHexString:@"05A9F4" alpha:1.f];
                     }];
    
    UIAlertController *alertController              =   [UIAlertController alertControllerWithTitle:nil
                                                                                            message:nil
                                                                                     preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *actionCancel                     =   [UIAlertAction actionWithTitle:NSLocalizedString(@"Alert error button Cancel", nil)
                                                                                 style:UIAlertActionStyleCancel
                                                                               handler:^(UIAlertAction *action) {
                                                                               }];
    
    UIAlertAction *actionTakePhoto                  =   [UIAlertAction actionWithTitle:NSLocalizedString(@"Take a Photo", nil)
                                                                                 style:UIAlertActionStyleDefault
                                                                               handler:^(UIAlertAction *action) {
                                                                                   if (isLocationServiceEnabled) {
                                                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                                                           // Use device camera
                                                                                           if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                                                                                               UIImagePickerController *cameraVC       =   [[UIImagePickerController alloc] init];
                                                                                               cameraVC.sourceType                     =   UIImagePickerControllerSourceTypeCamera;
                                                                                               cameraVC.mediaTypes                     =   [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
                                                                                               cameraVC.cameraCaptureMode              =   UIImagePickerControllerCameraCaptureModePhoto;
                                                                                               cameraVC.allowsEditing                  =   NO;
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
                                                                                   
                                                                                   else if ([locationsService isEnabled]) {
                                                                                       locationsService.manager.delegate           =   self;
                                                                                       isLocationServiceEnabled                    =   YES;
                                                                                       
                                                                                       [self actionCameraButtonTap:self.cameraButton];
                                                                                   }
                                                                               }];
    
    UIAlertAction *actionTakeVideo                  =   [UIAlertAction actionWithTitle:NSLocalizedString(@"Take a Video", nil)
                                                                                 style:UIAlertActionStyleDefault
                                                                               handler:^(UIAlertAction *action) {
//                                                                                   HRPVideoRecordViewController *videoRecordVC      =   [self.storyboard instantiateViewControllerWithIdentifier:@"VideoRecordVC"];
//                                                                                   
//                                                                                   [self presentViewController:videoRecordVC animated:YES completion:nil];
                                                                                   [self.navigationController popToRootViewControllerAnimated:YES];
                                                                               }];
    
    [alertController addAction:actionTakeVideo];
    [alertController addAction:actionTakePhoto];
    [alertController addAction:actionCancel];
    
    [self presentViewController:alertController animated:YES completion:nil];
}


#pragma mark - NSNotification -
- (void)handleRepeatButtonTap:(NSNotification *)notification {
    currentCell                                     =   notification.userInfo[@"cell"];
    currentPhoto                                    =   currentCell.photo;
    currentImage                                    =   currentCell.image;
    
    if (currentPhoto.state != HRPPhotoStateDone && !isUploadInProcess) {
        [currentCell.activityIndicator startAnimating];
        [self uploadDataFromLoop:NO];
    }
}

/*
- (void)handleVideoRecord:(NSNotification *)notification {
    [self.uploadActivityIndicator startAnimating];

    // Get userInfo data
    NSURL *videoAssetURL                                    =   notification.userInfo[@"videoURL"];
    UIImage *videoImageOriginal                             =   notification.userInfo[@"videoImage"];
    
    HRPPhoto *photo                                         =   [[HRPPhoto alloc] init];
    HRPImage *image                                         =   [[HRPImage alloc] init];
    image.imageAvatar                                       =   [UIImage imageWithCGImage:[UIImage imageNamed:@"icon-no-image"].CGImage];
    
    [self.photosCollectionView performBatchUpdates:^{
        NSMutableArray *arrayWithIndexPaths                 =   [NSMutableArray array];
        
        for (int i = 0; i <= imagesDataSource.count; i++) {
            [arrayWithIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        
        (photosDataSource.count == 0) ? [photosDataSource addObject:photo] : [photosDataSource insertObject:photo atIndex:0];
        (imagesDataSource.count == 0) ? [imagesDataSource addObject:image] : [imagesDataSource insertObject:image atIndex:0];
        
        [self.photosCollectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
    }
                                        completion:nil];
    
    currentCell                                             =   [[HRPPhotoCell alloc] initWithFrame:CGRectMake(0.f, 0.f, photoSize.width, photoSize.height)];
    currentCell                                             =   (HRPPhotoCell *)[self.photosCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    
    [currentCell.activityIndicator startAnimating];
    
    ALAssetsLibrary *assetsLibrary                          =   [[ALAssetsLibrary alloc] init];
    
    [assetsLibrary writeImageToSavedPhotosAlbum:videoImageOriginal.CGImage
                                    orientation:(ALAssetOrientation)videoImageOriginal.imageOrientation
                                completionBlock:^(NSURL *assetURL, NSError *error) {
                                    photo.assetsVideoURL                                    =   [videoAssetURL absoluteString];
                                    photo.assetsPhotoURL                                    =   [assetURL absoluteString];
                                    image.imageOriginalURL                                  =   [assetURL absoluteString];
                                    image.imageAvatar                                       =   [image resizeImage:videoImageOriginal
                                                                                                            toSize:photoSize
                                                                                                   andCropInCenter:YES];
                                    
                                    [UIView transitionWithView:currentCell.photoImageView
                                                      duration:0.5f
                                                       options:UIViewAnimationOptionTransitionCrossDissolve
                                                    animations:^{
                                                        currentCell.photoImageView.image    =   image.imageAvatar;
                                                        currentCell.playVideoImageView.alpha=   1.f;
                                                    }
                                                    completion:^(BOOL finished) {
                                                        photo.latitude                      =   locationNew.coordinate.latitude;
                                                        photo.longitude                     =   locationNew.coordinate.longitude;
                                                        photo.isVideo                       =   YES;
                                                        
                                                        // API
                                                        currentPhoto                        =   photo;
                                                        currentImage                        =   image;
                                                        
                                                        [photosDataSource replaceObjectAtIndex:0 withObject:photo];
                                                        [imagesDataSource replaceObjectAtIndex:0 withObject:image];
                                                        
                                                        [self savePhotosCollectionToFile];
                                                        videosNeedUploadCount++;
                                                        
                                                        // API send video on server
                                                        
                                                        // temp debug
                                                        [currentCell.activityIndicator stopAnimating];
                                                        [self.uploadActivityIndicator stopAnimating];
//                                                        [self uploadPhotoFromLoop:NO];
                                                    }];
                                }];
}
*/

- (void)reachabilityDidChange:(NSNotification *)notification {
    if (notification.userInfo[@"AFNetworkingReachabilityNotificationStatusItem"] && photosNeedUploadCount > 0)
        [self uploadDatas];
}


#pragma mark - Methods -
- (void)getPhotoFromAlbumAtURL:(NSURL *)assetsURL
                     onSuccess:(void(^)(UIImage *image))success {
    ALAssetsLibrary *library                        =   [[ALAssetsLibrary alloc] init];
    [library assetForURL:assetsURL
             resultBlock:^(ALAsset *asset) {
                 myAsset                            =   asset;
                 
                 UIImage  *copyOfOriginalImage      =   [UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage]
                                                                            scale:0.5f
                                                                      orientation:UIImageOrientationUp];
                 
                 success(copyOfOriginalImage);
             }
            failureBlock:^(NSError *error) { }];
}

- (BOOL)canPhotosSendToServer {
    // Network is activity
    if ([[AFNetworkReachabilityManager sharedManager] isReachable]) {
        // Check WiFi network connection status
        if (isUploadPhotosUsingWiFiAllowed && [[AFNetworkReachabilityManager sharedManager] isReachableViaWiFi] && !isUploadInProcess)
            return YES;
        
        // Check WWAN network connection status
        else if (!isUploadPhotosUsingWiFiAllowed && [[AFNetworkReachabilityManager sharedManager] isReachableViaWWAN] && !isUploadInProcess)
            return YES;
    }
    
    // Network disconnect
    else
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Alert error email title", nil)
                                    message:NSLocalizedString(@"Alert error internet message", nil)
                                   delegate:nil
                          cancelButtonTitle:nil
                          otherButtonTitles:NSLocalizedString(@"Alert error button Ok", nil), nil] show];
    
    return NO;
}

- (void)startUploadPhotos {
    if (photosNeedUploadCount > 0 && [self canPhotosSendToServer])
        [self uploadDatas];
}

- (void)uploadDataFromLoop:(BOOL)inLoop {
    // Check network connection state
    if ((inLoop && isUploadAutomaticallyAllowed) ||
        (!inLoop && !isUploadAutomaticallyAllowed)) {
        if ([self canPhotosSendToServer]) {
            // Async queue
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                // Save to device
                [self savePhotosCollectionToFile];
                isUploadInProcess                                                       =   YES;
                __block UIImage *imageOriginal;
                
                [self getPhotoFromAlbumAtURL:[NSURL URLWithString:currentPhoto.assetsPhotoURL]
                                   onSuccess:^(UIImage *image) {
                                       NSDictionary *parameters;
                                       imageOriginal                                    =   image;
                                       
                                       if (currentPhoto.isVideo) {
                                           ALAssetRepresentation *representation        =   myAsset.defaultRepresentation;
                                           long long size                               =   representation.size;
                                           NSMutableData *rawData                       =   [[NSMutableData alloc] initWithCapacity:(int)size];
                                           void *buffer                                 =   [rawData mutableBytes];
                                           [representation getBytes:buffer fromOffset:0 length:(int)size error:nil];
                                           
                                           currentImage.imageData                       =   [[NSData alloc] initWithBytes:buffer length:(int)size];

                                           parameters                                   =   @{
                                                                                                    @"video"        :   currentImage.imageData,
                                                                                                    @"latitude"     :   @(currentPhoto.latitude),
                                                                                                    @"longitude"    :   @(currentPhoto.longitude)
                                                                                              };
                                       
                                           // API
                                           [self uploadVideoWithParameters:parameters
                                                                 onSuccess:^(NSDictionary *successResult) {
                                                                     currentPhoto.state     =   HRPPhotoStateDone;
                                                                     [currentCell.photoStateButton setImage:[UIImage imageNamed:@"icon-done"] forState:UIControlStateNormal];
                                                                     
                                                                     [self savePhotosCollectionToFile];
                                                                     [currentCell.activityIndicator stopAnimating];
                                                                     
                                                                     isUploadInProcess      =   NO;
                                                                     photosNeedUploadCount--;
                                                                     
                                                                     if (photosNeedUploadCount && inLoop)
                                                                         [self startUploadPhotos];
                                                                 }
                                                                 orFailure:^(AFHTTPRequestOperation *failureOperation) {
                                                                     currentPhoto.state     =   HRPPhotoStateRepeat;
                                                                     [currentCell.photoStateButton setImage:[UIImage imageNamed:@"icon-repeat"] forState:UIControlStateNormal];
                                                                     
                                                                     [self savePhotosCollectionToFile];
                                                                     [currentCell.activityIndicator stopAnimating];
                                                                     [self.uploadActivityIndicator stopAnimating];
                                                                     
                                                                     isUploadInProcess      =   NO;
                                                                 }];
                                       }
                                       
                                       else {
                                           if ([currentPhoto.assetsPhotoURL hasSuffix:@"JPG"])
                                               currentImage.imageData                   =   [[NSData alloc] initWithData:UIImageJPEGRepresentation(imageOriginal, 1.f)];
                                           else
                                               currentImage.imageData                   =   [[NSData alloc] initWithData:UIImagePNGRepresentation(imageOriginal)];

                                           parameters                                   =   @{
                                                                                                    @"photo"        :   currentImage.imageData,
                                                                                                    @"latitude"     :   @(currentPhoto.latitude),
                                                                                                    @"longitude"    :   @(currentPhoto.longitude)
                                                                                            };
                                       
                                           // API
                                           [self uploadPhotoWithParameters:parameters
                                                                 onSuccess:^(NSDictionary *successResult) {
                                                                     currentPhoto.state     =   HRPPhotoStateDone;
                                                                     [currentCell.photoStateButton setImage:[UIImage imageNamed:@"icon-done"] forState:UIControlStateNormal];
                                                                     
                                                                     [self savePhotosCollectionToFile];
                                                                     [currentCell.activityIndicator stopAnimating];
                                                                     // [self.uploadActivityIndicator stopAnimating];
                                                                     
                                                                     isUploadInProcess      =   NO;
                                                                     photosNeedUploadCount--;
                                                                     
                                                                     if (photosNeedUploadCount && inLoop)
                                                                         [self startUploadPhotos];
                                                                 }
                                                                 orFailure:^(AFHTTPRequestOperation *failureOperation) {
                                                                     currentPhoto.state     =   HRPPhotoStateRepeat;
                                                                     [currentCell.photoStateButton setImage:[UIImage imageNamed:@"icon-repeat"] forState:UIControlStateNormal];
                                                                     
                                                                     [self savePhotosCollectionToFile];
                                                                     [currentCell.activityIndicator stopAnimating];
                                                                     [self.uploadActivityIndicator stopAnimating];
                                                                     
                                                                     isUploadInProcess      =   NO;
                                                                 }];
                                       }
                                   }];
            });
        } else {
            [currentCell.activityIndicator stopAnimating];
            
            // Wait for next item upload
            if (isUploadInProcess && photosNeedUploadCount > 0)
                [self uploadDataFromLoop:inLoop];
        }
    }
}

- (void)uploadDatas {
    for (HRPPhoto *photo in photosDataSource) {
        if (photo.state != HRPPhotoStateDone) {
            currentPhoto                =   photo;
            
            // Find HRPImage custom object
            NSPredicate *predicate      =   [NSPredicate predicateWithFormat:@"SELF.imageOriginalURL == [cd] %@", currentPhoto.assetsPhotoURL];
            
            currentImage                =   [imagesDataSource filteredArrayUsingPredicate:predicate][0];
            
            // Find HRPPhotoCell custom object
            currentCell                 =   (HRPPhotoCell *)[self.photosCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:[imagesDataSource indexOfObject:currentImage] inSection:0]];
            
            if ([self.photosCollectionView.visibleCells containsObject:currentCell] && !isUploadInProcess) {
                [currentCell.activityIndicator startAnimating];
                [self uploadDataFromLoop:YES];

                break;
            }
        }
    }
}

- (void)createTestDataSource {
    NSArray *imageName                                          =   @[@"0.png", @"1.png", @"2.png", @"3.png", @"4.png", @"5.png", @"6.png", @"7.png"];
    
    for (int i = 0; i < 8; i++) {
        HRPPhoto *photo                                         =   [[HRPPhoto alloc] init];
        HRPImage *image                                         =   [[HRPImage alloc] init];
        
        image.imageAvatar                                       =   [image squareImageFromImage:[UIImage imageNamed:imageName[i]]
                                                                                   scaledToSize:photoSize.height];
        
        photo.state                                             =   arc4random_uniform(3);
        
        [imagesDataSource addObject:image];
        [photosDataSource addObject:photo];
    }
    
    [UIView animateWithDuration:0.7f
                     animations:^{
                         self.photosCollectionView.alpha     =   1.f;
                     }
                     completion:^(BOOL finished) {
                         [self.uploadActivityIndicator stopAnimating];
                     }];
}

- (void)createImagesDataSource {
    [UIView animateWithDuration:0.7f
                     animations:^{
                         self.photosCollectionView.alpha        =   (imagesDataSource.count == 0) ? 0.f : 0.8f;
                     }];
    
    paginationOffset                                            =   16;
    NSInteger indexStart                                        =   imagesDataSource.count;
    NSInteger indexFinish                                       =   ((indexStart + paginationOffset) < photosDataSource.count) ?    (indexStart + paginationOffset) :
                                                                                                                                    photosDataSource.count;
    NSArray *photosDataSourceCopy                               =   [NSMutableArray arrayWithArray:photosDataSource];
    
    for (NSInteger i = indexStart; i <= indexFinish - 1; i++) {
        HRPPhoto *photo                                         =   photosDataSourceCopy[i];
        HRPImage *image                                         =   [[HRPImage alloc] init];
        
        if (photo.assetsPhotoURL)
            [self getPhotoFromAlbumAtURL:[NSURL URLWithString:photo.assetsPhotoURL]
                               onSuccess:^(UIImage *photoFromAlbum) {
                                   if (photoFromAlbum) {
                                       image.imageOriginalURL   =   photo.assetsPhotoURL;
                                       image.imageAvatar        =   [image squareImageFromImage:photoFromAlbum scaledToSize:photoSize.width];
                                       
                                       if (photo.state != HRPPhotoStateDone) {
                                           if (photo.isVideo)
                                               videosNeedUploadCount++;
                                           else
                                               photosNeedUploadCount++;
                                       }
                                       
                                       [imagesDataSource addObject:image];
                                   } else {
                                       missingPhotosCount++;
                                       [photosDataSource removeObject:photo];
                                   }
                                   
                                   // Show count of missing photos
                                   if (i == indexFinish - 1) {
                                       if (missingPhotosCount == 1)
                                           [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Alert info title", nil)
                                                                       message:[NSString stringWithFormat:@"%li %@",    (long)missingPhotosCount,
                                                                                                                        NSLocalizedString(@"Photo is missing", nil)]
                                                                      delegate:nil
                                                             cancelButtonTitle:nil
                                                             otherButtonTitles:NSLocalizedString(@"Alert error button Ok", nil), nil] show];
                                       
                                       else if (missingPhotosCount > 0 && missingPhotosCount <= 4)
                                           [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Alert info title", nil)
                                                                       message:[NSString stringWithFormat:@"%li %@",    (long)missingPhotosCount,
                                                                                                                        NSLocalizedString(@"Photos 2-4 are missing", nil)]
                                                                      delegate:nil
                                                             cancelButtonTitle:nil
                                                             otherButtonTitles:NSLocalizedString(@"Alert error button Ok", nil), nil] show];
                                       
                                       else if (missingPhotosCount > 4)
                                           [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Alert info title", nil)
                                                                       message:[NSString stringWithFormat:@"%li %@",    (long)missingPhotosCount,
                                                                                                                        NSLocalizedString(@"Photos >5 are missing", nil)]
                                                                      delegate:nil
                                                             cancelButtonTitle:nil
                                                             otherButtonTitles:NSLocalizedString(@"Alert error button Ok", nil), nil] show];
                                       
                                       // Save modified photos array to local file
                                       [self savePhotosCollectionToFile];
                                       
                                       missingPhotosCount                                       =   0;
                                       imagesIndexPath                                          =   [NSMutableArray array];
                                       
                                       for (NSInteger i = indexStart; i <= imagesDataSource.count - 1; i++) {
                                           [imagesIndexPath addObject:[NSIndexPath indexPathForItem:i inSection:0]];
                                       }
                                       
                                       [self.photosCollectionView insertItemsAtIndexPaths:imagesIndexPath];
                                       
                                       [UIView animateWithDuration:0.7f
                                                        animations:^{
                                                            self.photosCollectionView.alpha     =   1.f;
                                                        }
                                                        completion:^(BOOL finished) {
                                                            [self.uploadActivityIndicator stopAnimating];
                                                            self.navigationItem.rightBarButtonItem.enabled      =   YES;
                                                            self.photosCollectionView.userInteractionEnabled    =   YES;
                                                        }];
                                       
                                       // Upload photos
                                       if (photosNeedUploadCount > 0)
                                           [self startUploadPhotos];
                                       
                                       if (isPaginationRun)
                                           isPaginationRun                                      =   NO;
                                   }
                               }];
    }
}

- (void)createStoreDataPath {
    NSError *error;
    NSArray *paths                                  =   NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    arrayPath                                       =   paths[0]; // [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Photos"];

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
    NSArray *paths                                  =   NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    arrayPath                                       =   paths[0]; // [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Photos"];
    arrayPath                                       =   [arrayPath stringByAppendingPathComponent:[userApp objectForKey:@"userAppEmail"]];
    
    [[NSFileManager defaultManager] createFileAtPath:arrayPath
                                            contents:arrayData
                                          attributes:nil];
}

- (void)removePhotosCollectionFromFile {
    NSArray *paths                                  =   NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    arrayPath                                       =   paths[0]; // [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Photos"];
    arrayPath                                       =   [arrayPath stringByAppendingPathComponent:[userApp objectForKey:@"userAppEmail"]];
    
    [[NSFileManager defaultManager] removeItemAtPath:arrayPath
                                               error:nil];
}

- (void)removeItemFromCollection {
    [self.photosCollectionView performBatchUpdates:^{
        [imagesDataSource removeObjectAtIndex:currentIndexPath.row];
        [self.photosCollectionView deleteItemsAtIndexPaths:@[currentIndexPath]];
    }
                                        completion:^(BOOL finished) {
                                            [photosDataSource removeObjectAtIndex:currentIndexPath.row];
                                            
                                            [self savePhotosCollectionToFile];
                                        }];
}

- (void)readPhotosCollectionFromFile {
    NSArray *paths                                  =   NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    arrayPath                                       =   paths[0]; // [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Photos"];
    arrayPath                                       =   [arrayPath stringByAppendingPathComponent:[userApp objectForKey:@"userAppEmail"]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:arrayPath]) {
        NSData *arrayData                           =   [[NSData alloc] initWithContentsOfFile:arrayPath];
        photosDataSource                            =   [NSMutableArray array];
        imagesDataSource                            =   [NSMutableArray array];

        if (arrayData) {
            photosDataSource                        =   [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithData:arrayData]];
        
            if (photosDataSource.count == 0)
                [self.uploadActivityIndicator stopAnimating];

            else
                [self createImagesDataSource];
        } else
            NSLog(@"File does not exist");
    } else
        imagesDataSource                            =   [NSMutableArray array];
}

- (void)showAlertController {
    UIAlertController *alertController              =   [UIAlertController alertControllerWithTitle:nil
                                                                                            message:nil
                                                                                     preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *actionCancel                     =   [UIAlertAction actionWithTitle:NSLocalizedString(@"Alert error button Cancel", nil)
                                                                                 style:UIAlertActionStyleCancel
                                                                               handler:^(UIAlertAction *action) {
                                                                               }];
    
    UIAlertAction *actionOpenPhoto                  =   [UIAlertAction actionWithTitle:NSLocalizedString(@"Open a Photo", nil)
                                                                                 style:UIAlertActionStyleDefault
                                                                               handler:^(UIAlertAction *action) {
                                                                                   HRPPhotoPreviewViewController *photoPreviewVC    =   [self.storyboard instantiateViewControllerWithIdentifier:@"PhotoPreviewVC"];
                                                                                   
                                                                                   photoPreviewVC.photo                             =   currentPhoto;
                                                                                   
                                                                                   [self presentViewController:photoPreviewVC animated:YES completion:nil];
                                                                               }];
    
    UIAlertAction *actionOpenVideo                  =   [UIAlertAction actionWithTitle:NSLocalizedString(@"Open a Video", nil)
                                                                                 style:UIAlertActionStyleDefault
                                                                               handler:^(UIAlertAction *action) {
                                                                                   if (!isVideoPreviewStart) {
                                                                                       HRPVideoPlayerViewController *videoPlayerVC  =   [self.storyboard instantiateViewControllerWithIdentifier:@"VideoPlayerVC"];
                                                                                       videoPlayerVC.videoURL                       =   [NSURL URLWithString:currentPhoto.assetsVideoURL];
                                                                                       
                                                                                       [self presentViewController:videoPlayerVC animated:YES completion:^{
                                                                                           isVideoPreviewStart                      =   YES;
                                                                                       }];
                                                                                   }
                                                                               }];
    
    UIAlertAction *actionRemoveItem                 =   [UIAlertAction actionWithTitle:NSLocalizedString((currentPhoto.isVideo) ?   @"Remove a Video" :
                                                                                                                                    @"Remove a Photo", nil)
                                                                                 style:UIAlertActionStyleDestructive
                                                                               handler:^(UIAlertAction *action) {
                                                                                   [self removeItemFromCollection];
                                                                               }];

    UIAlertAction *actionUploadData                =   [UIAlertAction actionWithTitle:NSLocalizedString((currentPhoto.isVideo) ?    @"Upload a Video" :
                                                                                                                                    @"Upload a Photo", nil)
                                                                                 style:UIAlertActionStyleDefault
                                                                               handler:^(UIAlertAction *action) {
                                                                                   if (currentPhoto.state != HRPPhotoStateDone) {
                                                                                       [currentCell.activityIndicator startAnimating];
                                                                                       
                                                                                       [self uploadDataFromLoop:NO];
                                                                                   }
                                                                               }];
    
    UIAlertAction *actionUploadDatas               =   [UIAlertAction actionWithTitle:NSLocalizedString((currentPhoto.isVideo) ?    @"Upload Videos" :
                                                                                                                                    @"Upload Photos", nil)
                                                                                 style:UIAlertActionStyleDefault
                                                                               handler:^(UIAlertAction *action) {
                                                                                   [self startUploadPhotos];
                                                                               }];
    
    if (currentPhoto.isVideo)
        [alertController addAction:actionOpenVideo];
    else
        [alertController addAction:actionOpenPhoto];
    
    if (currentPhoto.state != HRPPhotoStateDone)
        [alertController addAction:actionUploadData];
    
    if (photosNeedUploadCount > 0 && !currentPhoto.isVideo)
        [alertController addAction:actionUploadDatas];
    
    [alertController addAction:actionRemoveItem];
    
    [alertController addAction:actionCancel];
    
    [self presentViewController:alertController animated:YES completion:nil];
}


#pragma mark - UICollectionViewDataSource -
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return imagesDataSource.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier                 =   @"PhotoCell";
    HRPPhotoCell *cell                              =   [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier
                                                                                                  forIndexPath:indexPath];
    
    cell.activityIndicator.color                    =   [UIColor colorWithHexString:@"05A9F4" alpha:1.f];
    [cell.activityIndicator stopAnimating];
    
    HRPPhoto *photo                                 =   [photosDataSource objectAtIndex:indexPath.row];
    HRPImage *image                                 =   [imagesDataSource objectAtIndex:indexPath.row];
    
    switch (photo.state) {
        // HRPPhotoStateDone
        case 0: {
            [cell.photoStateButton setImage:[UIImage imageNamed:@"icon-done"] forState:UIControlStateNormal];
            cell.photoStateButton.tag               =   0;
        }
            break;
            
        // HRPPhotoStateRepeat
        case 1: {
            [cell.photoStateButton setImage:[UIImage imageNamed:@"icon-repeat"] forState:UIControlStateNormal];
            cell.photoStateButton.tag               =   1;
        }
            break;

        // HRPPhotoStateUpload
        case 2: {
            [cell.photoStateButton setImage:[UIImage imageNamed:@"icon-upload"] forState:UIControlStateNormal];
            cell.photoStateButton.tag               =   2;
        }
            break;
    }
    
//    PHImageRequestOptions *imageRequestOptions      =   [[PHImageRequestOptions alloc] init];
//    imageRequestOptions.resizeMode                  =   PHImageRequestOptionsResizeModeFast;
//    imageRequestOptions.normalizedCropRect          =   CGRectMake(0.f, 0.f, photoSize.width, photoSize.height);
    
    [UIView transitionWithView:cell
                      duration:0.7f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        cell.photoImageView.image       =   image.imageAvatar;
                        cell.playVideoImageView.alpha   =   (photo.isVideo) ? 1.f : 0.f;
                    }
                    completion:^(BOOL finished) {
                        cell.photo                  =   photo;
                        cell.image                  =   image;
                    }];
    
    // Set pagination
    if (indexPath.row == imagesDataSource.count - 2 &&
        indexPath.row != photosDataSource.count - 2) {
        isPaginationRun                             =   YES;
        [self.uploadActivityIndicator startAnimating];
        [self createImagesDataSource];
    }
    
    [cell.activityIndicator stopAnimating];

    return cell;
}


#pragma mark - UICollectionViewDelegate -
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    currentCell                                     =   (HRPPhotoCell *)[collectionView cellForItemAtIndexPath:indexPath];
    currentPhoto                                    =   currentCell.photo;
    currentImage                                    =   currentCell.image;
    currentIndexPath                                =   indexPath;
    
    [self showAlertController];
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


#pragma mark - UIViewControllerRotation -
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    if (size.height > size.width)
        cellSide                                    =   (size.width - 4.f) / 2;
    else
        cellSide                                    =   (size.width - 8.f) / 3;
    
    photoSize                                       =   CGSizeMake(cellSide, cellSide);
    
    [self.photosCollectionView reloadData];
}


#pragma mark - UIImagePickerControllerDelegate -
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if (imagesDataSource.count > 0)
        [self.photosCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                          atScrollPosition:UICollectionViewScrollPositionTop
                                                  animated:YES];
    
    UIImage *chosenImage                            =   [info objectForKey:UIImagePickerControllerOriginalImage];
    ALAssetsLibrary *assetsLibrary                  =   [[ALAssetsLibrary alloc] init];
    [picker dismissViewControllerAnimated:YES completion:NULL];
    picker                                          =   nil;
    self.imagePickerController                      =   nil;
    
    HRPPhoto *photo                                 =   [[HRPPhoto alloc] init];
    HRPImage *image                                 =   [[HRPImage alloc] init];
    image.imageAvatar                               =   [UIImage imageWithCGImage:[UIImage imageNamed:@"icon-no-image"].CGImage];

    [self.photosCollectionView performBatchUpdates:^{
        NSMutableArray *arrayWithIndexPaths         =   [NSMutableArray array];

        for (int i = 0; i <= imagesDataSource.count; i++) {
            [arrayWithIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        
        (photosDataSource.count == 0) ? [photosDataSource addObject:photo] : [photosDataSource insertObject:photo atIndex:0];
        (imagesDataSource.count == 0) ? [imagesDataSource addObject:image] : [imagesDataSource insertObject:image atIndex:0];
        
        [self.photosCollectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
    }
                                        completion:nil];
   
    if  (imagesDataSource.count == 1)
        [self.photosCollectionView reloadData];
    
    currentCell                                     =   [[HRPPhotoCell alloc] initWithFrame:CGRectMake(0.f, 0.f, photoSize.width, photoSize.height)];
    currentCell                                     =   (HRPPhotoCell *)[self.photosCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
   
    [currentCell.activityIndicator startAnimating];
    
    [assetsLibrary writeImageToSavedPhotosAlbum:chosenImage.CGImage
                                    orientation:(ALAssetOrientation)chosenImage.imageOrientation
                                completionBlock:^(NSURL *assetURL, NSError *error) {
                                    ALAssetsLibrary *libraryAssets = [[ALAssetsLibrary alloc] init];
                                    [libraryAssets assetForURL:assetURL
                                                   resultBlock:^(ALAsset *asset) {
                                                       photo.assetsPhotoURL                                 =   [assetURL absoluteString];
                                                       image.imageOriginalURL                               =   [assetURL absoluteString];
                                                       image.imageAvatar                                    =   [image resizeImage:chosenImage
                                                                                                                            toSize:photoSize
                                                                                                                   andCropInCenter:YES];
                                                       
                                                       [UIView transitionWithView:currentCell.photoImageView
                                                                         duration:0.5f
                                                                          options:UIViewAnimationOptionTransitionCrossDissolve
                                                                       animations:^{
                                                                           currentCell.photoImageView.image =   image.imageAvatar;
                                                                       }
                                                                       completion:^(BOOL finished) {
                                                                           photo.latitude                   =   locationNew.coordinate.latitude;
                                                                           photo.longitude                  =   locationNew.coordinate.longitude;
                                                                           photo.isVideo                    =   NO;
                                                                           
                                                                           // API
                                                                           currentPhoto                     =   photo;
                                                                           currentImage                     =   image;
                                                                           
                                                                           [photosDataSource replaceObjectAtIndex:0 withObject:photo];
                                                                           [imagesDataSource replaceObjectAtIndex:0 withObject:image];
                                                                           
                                                                           [self savePhotosCollectionToFile];
                                                                           photosNeedUploadCount++;
                                                                           
                                                                           [self uploadDataFromLoop:NO];
                                                                       }];
                                                   }
                                                  failureBlock:^(NSError *error) { }];
                                }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES
                               completion:^{ }];
    
    picker                          =   nil;
    self.imagePickerController      =   nil;
}


#pragma mark - CLLocationManagerDelegate -
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    currentPhoto.latitude           =   newLocation.coordinate.latitude;
    currentPhoto.longitude          =   newLocation.coordinate.longitude;
    
    locationNew                     =   newLocation;
    isLocationServiceEnabled        =   YES;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    isLocationServiceEnabled        =   NO;
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
