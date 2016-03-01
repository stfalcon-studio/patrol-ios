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
#import "HRPViolationCell.h"
#import "HRPPhoto.h"
#import "HRPImage.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <CoreLocation/CoreLocation.h>
#import "HRPLocations.h"
#import <AFHTTPRequestOperation.h>
#import "HRPPhotoPreviewViewController.h"
#import "HRPVideoPlayerViewController.h"
#import "UIViewController+NavigationBar.h"
#import "HRPSettingsViewController.h"
#import "HRPCameraManager.h"
#import "HRPViolationManager.h"
#import "HRPViolation.h"


typedef void (^ALAssetsLibraryAssetForURLResultBlock)(ALAsset *asset);
typedef void (^ALAssetsLibraryAccessFailureBlock)(NSError *error);

@interface HRPCollectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) HRPViolationManager *violationManager;
@property (strong, nonatomic) UIImagePickerController *imagePickerController;
@property (strong, nonatomic) IBOutlet HRPButton *cameraButton;
@property (strong, nonatomic) IBOutlet UICollectionView *violationsCollectionView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *userNameBarButton;

@end


@implementation HRPCollectionViewController {
    UIView *_statusView;
    NSMutableArray *_violationsDataSource;
}

#pragma mark - Constructors -
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self showLoaderWithText:NSLocalizedString(@"Launch text", nil)
          andBackgroundColor:BackgroundColorTypeBlack
                     forTime:300];

    _statusView = [self customizeStatusBar];

    // Create Manager & Violations data source
    _violationManager = [HRPViolationManager sharedManager];
    
    // Remove local file with violations array
    // Only for Debug mode
    //[_violationManager removeViolationsFromFile];
    
    _userNameBarButton.title = [_violationManager.userApp valueForKey:@"userAppEmail"];
    
    [self customizeNavigationBarWithTitle:nil
                     andLeftBarButtonText:_userNameBarButton.title
                        withActionEnabled:NO
                   andRightBarButtonImage:[UIImage imageNamed:@"icon-settings"]
                        withActionEnabled:YES];
    
    [_violationManager readViolationsFromFileSuccess:^(BOOL isFinished) {
        if (isFinished) {
            _violationsDataSource = [NSMutableArray arrayWithArray:_violationManager.violations];
            
            [_violationsCollectionView reloadData];
            [self hideLoader];
        }
        
        else
            [self hideLoader];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self setRightBarButtonEnable:YES];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

// DELETE AFTER CHECK IT IN BASEVC
//- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
//    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
//    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithHexString:@"0477BD" alpha:1.f]];
//    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
//    [[UINavigationBar appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName:[UIColor whiteColor] }];
//}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    UICollectionViewFlowLayout *flowLayout = (id)_violationsCollectionView.collectionViewLayout;
    flowLayout.itemSize = _violationManager.cellSize;
    
    [flowLayout invalidateLayout]; //force the elements to get laid out again with the new size
}

/*
#pragma mark - API -
- (void)uploadPhotoWithParameters:(NSDictionary *)parameters
                        onSuccess:(void(^)(NSDictionary *successResult))success
                        orFailure:(void(^)(AFHTTPRequestOperation *failureOperation))failure {
    AFHTTPRequestOperationManager *requestOperationDomainManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://xn--80awkfjh8d.com/"]];
    
    NSString *pathAPI = [NSString stringWithFormat:@"api/%@/violation/create", [userApp objectForKey:@"userAppID"]];
    
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

*/

#pragma mark - Actions -
- (void)handlerLeftBarButtonTap:(UIBarButtonItem *)sender {
    // E-mail button
}

- (void)handlerRightBarButtonTap:(UIBarButtonItem *)sender {
    // Settings button
    [self setRightBarButtonEnable:NO];
    HRPSettingsViewController *settingsTVC = [self.storyboard instantiateViewControllerWithIdentifier:@"SettingsTVC"];
    
    [self.navigationController pushViewController:settingsTVC animated:YES];
}

- (IBAction)actionCameraButtonTap:(HRPButton *)sender {
    [UIView animateWithDuration:0.05f
                     animations:^{
                         sender.fillColor = [UIColor colorWithHexString:@"05A9F4" alpha:0.5f];
                     } completion:^(BOOL finished) {
                         sender.fillColor = [UIColor colorWithHexString:@"05A9F4" alpha:1.f];
                     }];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Alert error button Cancel", nil)
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    

    // RECOMMENT IF NEED WORK WITH PHOTO
    /*
    UIAlertAction *actionTakePhoto          =   [UIAlertAction actionWithTitle:NSLocalizedString(@"Take a Photo", nil)
                                                                         style:UIAlertActionStyleDefault
                                                                       handler:^(UIAlertAction *action) {
                                                                           if (isLocationServiceEnabled) {
                                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                                   // Use device camera
                                                                                   if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                                                                                            UIImagePickerController *cameraVC       =   [[UIImagePickerController alloc] init];
                                                                                       
                                                                                            cameraVC.sourceType     =   UIImagePickerControllerSourceTypeCamera;
                                                                                       
                                                                                            cameraVC.mediaTypes     =   [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
                                                                                       
                                                                                            cameraVC.cameraCaptureMode  =   UIImagePickerControllerCameraCaptureModePhoto;
                                                                                       
                                                                                            cameraVC.allowsEditing  =   NO;
                                                                                            cameraVC.delegate       =   self;
                                                                                               
                                                                                            cameraVC.modalPresentationStyle         =   UIModalPresentationCurrentContext;
                                                                                       
                                                                                            self.imagePickerController  =   cameraVC;
                                                                                               
                                                                                            if (![self.imagePickerController isBeingPresented])
                                                                                                [self.navigationController presentViewController:self.imagePickerController animated:YES completion:nil];
                                                                                            }
                                                                                   
                                                                                            else
                                                                                                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Alert error email title", nil)
                                                                                                                            message:NSLocalizedString(@"Camera is not available", nil)
                                                                                                                          delegate:nil
                                                                                                                 cancelButtonTitle:nil
                                                                                                                 otherButtonTitles:NSLocalizedString(@"Alert error button Ok", nil), nil] show];
                                                                                            });
                                                                                        }
                                                                           
                                                                                        else if ([locationsService isEnabled]) {
                                                                                            locationsService.manager.delegate   =   self;
                                                                                            isLocationServiceEnabled            =   YES;
                                                                                       
                                                                                            [self actionCameraButtonTap:self.cameraButton];
                                                                                        }
                                                                                    }];
*/
    
    UIAlertAction *actionTakeVideo = [UIAlertAction actionWithTitle:NSLocalizedString(@"Take a Video", nil)
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction *action) {
                                                                [self.navigationController popViewControllerAnimated:YES];
                                                            }];
    
    [alertController addAction:actionTakeVideo];
//    [alertController addAction:actionTakePhoto];
    [alertController addAction:actionCancel];
    
    [self presentViewController:alertController animated:YES completion:nil];
}


#pragma mark - NSNotification -
//- (void)handlerViolationUploadSuccess:(NSNotification *)notification {
//    HRPViolation *violation = notification.userInfo[@"violation"];
//    _violationsDataSource = _violationManager.violations;
//    HRPViolationCell *cell = (HRPViolationCell *)[_violationsCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:[_violationsDataSource indexOfObject:violation] inSection:0]];
//    [cell.uploadStateButton setImage:[UIImage imageNamed:@"icon-done"] forState:UIControlStateNormal];
//
//    [cell hideLoader];
//}

//- (void)handlerViolationUploadError:(NSNotification *)notification {
//    HRPViolation *violation = notification.userInfo[@"violation"];
//    _violationsDataSource = _violationManager.violations;
//    HRPViolationCell *cell = (HRPViolationCell *)[_violationsCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:[_violationsDataSource indexOfObject:violation] inSection:0]];
//    [cell.uploadStateButton setImage:[UIImage imageNamed:@"icon-repeat"] forState:UIControlStateNormal];
//  
//    [cell hideLoader];
//}

#pragma mark - Methods -
- (void)removeViolationFromCollection:(NSIndexPath *)indexPath {
    [_violationsCollectionView performBatchUpdates:^{
        [_violationsDataSource removeObjectAtIndex:indexPath.row];
        [_violationsCollectionView deleteItemsAtIndexPaths:@[indexPath]];
    }
                                            completion:^(BOOL finished) {
                                                [_violationManager saveViolationsToFile:_violationsDataSource];
                                            }];
}

- (void)showAlertController:(NSIndexPath *)indexPath {
    HRPViolation *violation = _violationsDataSource[indexPath.row];
    HRPViolationCell *cell = (HRPViolationCell *)[_violationsCollectionView cellForItemAtIndexPath:indexPath];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Alert error button Cancel", nil)
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    UIAlertAction *actionOpenViolationPhoto = [UIAlertAction actionWithTitle:NSLocalizedString(@"Open a Photo", nil)
                                                                       style:UIAlertActionStyleDefault
                                                                     handler:^(UIAlertAction *action) {
                                                                         HRPPhotoPreviewViewController *photoPreviewVC = [self.storyboard instantiateViewControllerWithIdentifier:@"PhotoPreviewVC"];
                                                                                   
                                                                         photoPreviewVC.violation = violation;
                                                                                   
                                                                         [self presentViewController:photoPreviewVC animated:YES completion:nil];
                                                                     }];
    
    UIAlertAction *actionOpenViolationVideo = [UIAlertAction actionWithTitle:NSLocalizedString(@"Open a Video", nil)
                                                                       style:UIAlertActionStyleDefault
                                                                     handler:^(UIAlertAction *action) {
                                                                         HRPVideoPlayerViewController *videoPlayerVC = [self.storyboard instantiateViewControllerWithIdentifier:@"VideoPlayerVC"];

                                                                         videoPlayerVC.videoURL = [NSURL URLWithString:violation.assetsVideoURL];
                                                                                   
                                                                         [self presentViewController:videoPlayerVC animated:YES completion:^{}];
                                                                     }];
    
    UIAlertAction *actionRemoveViolation = [UIAlertAction actionWithTitle:NSLocalizedString((violation.type == HRPViolationTypeVideo) ? @"Remove a Video" : @"Remove a Photo", nil)
                                                                    style:UIAlertActionStyleDestructive
                                                                  handler:^(UIAlertAction *action) {
                                                                      [self removeViolationFromCollection:indexPath];
                                                                  }];

    UIAlertAction *actionUploadViolation = [UIAlertAction actionWithTitle:NSLocalizedString((violation.type == HRPViolationTypeVideo) ? @"Upload a Video" : @"Upload a Photo", nil)
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction *action) {
                                                                      if (violation.state != HRPViolationStateDone) {
                                                                          [_violationManager uploadViolation:violation
                                                                                                    fromCell:cell
                                                                                                  inAutoMode:NO
                                                                                                   onSuccess:^(BOOL isSuccess) {
                                                                                                       _violationsDataSource = _violationManager.violations;
                                                                                                   }];
                                                                      }
                                                                  }];

    // ADD WHEN NEED
    /*
    UIAlertAction *actionUploadViolations = [UIAlertAction actionWithTitle:NSLocalizedString((violation.type == HRPViolationTypeVideo) ? @"Upload Videos" : @"Upload Photos", nil)
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction *action) {
                                                                       [_violationManager uploadViolations:_violationsCollectionView];
                                                                   }];
     */
    
    if (violation.type == HRPViolationTypeVideo)
        [alertController addAction:actionOpenViolationVideo];
    else
        [alertController addAction:actionOpenViolationPhoto];
    
    if (violation.state != HRPViolationStateDone)
        [alertController addAction:actionUploadViolation];
    
    // ADD WHEN NEED
    /*
    if (_violationManager.violationsNeedUpload.count > 0 && violation.type == HRPViolationTypePhoto)
        [alertController addAction:actionUploadViolations];
     */
    
    [alertController addAction:actionRemoveViolation];
    
    [alertController addAction:actionCancel];
    
    if (!violation.isUploading) {
        [self presentViewController:alertController animated:YES completion:nil];
    }
}


#pragma mark - UICollectionViewDataSource -
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _violationsDataSource.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"ViolationCell";
    HRPViolationCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    cell.violation = _violationsDataSource[indexPath.row];

    [cell customizeCellStyle];
    
    // SET USERACTIVITY IN STORYBOARD - NOW IT DISABLED
    /*
    [cell.uploadStateButton setDidButtonPress:^(id item) {
        [_violationManager uploadViolation:item];
    }];
     */
    
    
    // ADD PAGINATION IF IT NEED
    /*
    // Set pagination
    if (indexPath.row == _violationsDataSource.count - 2) {
        isPaginationRun = YES;
        
        [self showLoaderWithText:NSLocalizedString(@"Upload title", nil)
              andBackgroundColor:BackgroundColorTypeBlue
                         forTime:10];

        [_violationManager readViolationsFromFileSuccess:^(BOOL isFinished) {
            if (isFinished) {
                _violationsDataSource = [NSMutableArray arrayWithArray:_violationManager.violations];
                
                [_violationsCollectionView reloadData];
            }
        }];
    }
     */
    
    // Check need upload videos
    /*
    if (cell.violation.state != HRPPhotoStateDone) {
        [cell uploadVideoAuto:YES
                    onSuccess:^(BOOL isFinished) {
                        _violationsDataSource = _violationManager.violations;

                        [collectionView reloadData];
                    }];
    }
     */
    
    if (cell.violation.state != HRPViolationStateDone) {
        [_violationManager uploadViolation:cell.violation
                                  fromCell:cell
                                inAutoMode:YES
                                 onSuccess:^(BOOL isSuccess) {
                                     _violationsDataSource = _violationManager.violations;
                                 }];
    }
    
    return cell;
}


#pragma mark - UICollectionViewDelegate -
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self showAlertController:indexPath];
}


#pragma mark - UICollectionViewDelegateFlowLayout -
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return _violationManager.cellSize;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    // top, left, bottom, right
    return UIEdgeInsetsZero;
}


#pragma mark - UIViewControllerRotation -
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    _statusView.frame = CGRectMake(0.f, (size.width < size.height) ? 0.f : -20.f, size.width, 20.f);
    CGFloat cellNewSide = 0.f;
    
    if (size.height > size.width)
        cellNewSide = (size.width - 4.f) / 2;
    
    else
        cellNewSide = (size.width - 8.f) / 3;
    
    _violationManager.cellSize = CGSizeMake(cellNewSide, cellNewSide);
}


#pragma mark - UIImagePickerControllerDelegate -
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if (_violationsDataSource.count > 0)
        [_violationsCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                          atScrollPosition:UICollectionViewScrollPositionTop
                                                  animated:YES];
    
    UIImage *chosenImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
    [picker dismissViewControllerAnimated:YES completion:NULL];
    picker = nil;
    self.imagePickerController = nil;
    
    HRPViolation *violation = [[HRPViolation alloc] init];
    HRPImage *image = [[HRPImage alloc] init];
    image.imageAvatar = [UIImage imageWithCGImage:[UIImage imageNamed:@"icon-no-image"].CGImage];

    [_violationsCollectionView performBatchUpdates:^{
        NSMutableArray *arrayWithIndexPaths = [NSMutableArray array];

        for (int i = 0; i <= _violationsDataSource.count; i++) {
            [arrayWithIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        
        (_violationsDataSource.count == 0) ? [_violationsDataSource addObject:violation] : [_violationsDataSource insertObject:violation atIndex:0];
        
        [_violationsCollectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
    }
                                        completion:nil];
   
    if  (_violationsDataSource.count == 1)
        [_violationsCollectionView reloadData];
    
    HRPViolationCell *cell = [[HRPViolationCell alloc] initWithFrame:CGRectMake(0.f, 0.f, _violationManager.cellSize.width, _violationManager.cellSize.height)];
    cell = (HRPViolationCell *)[_violationsCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
   
    [cell showLoaderWithText:nil andBackgroundColor:CellBackgroundColorTypeBlue forTime:10];
    
    [assetsLibrary writeImageToSavedPhotosAlbum:chosenImage.CGImage
                                    orientation:(ALAssetOrientation)chosenImage.imageOrientation
                                completionBlock:^(NSURL *assetURL, NSError *error) {
                                    ALAssetsLibrary *libraryAssets = [[ALAssetsLibrary alloc] init];
                                    [libraryAssets assetForURL:assetURL
                                                   resultBlock:^(ALAsset *asset) {
                                                       violation.assetsPhotoURL = [assetURL absoluteString];
                                                       image.imageOriginalURL = [assetURL absoluteString];
                                                       image.imageAvatar = [image resizeImage:chosenImage
                                                                                       toSize:_violationManager.cellSize
                                                                              andCropInCenter:YES];
                                                       
                                                       [UIView transitionWithView:cell.photoImageView
                                                                         duration:0.5f
                                                                          options:UIViewAnimationOptionTransitionCrossDissolve
                                                                       animations:^{
                                                                           cell.photoImageView.image = image.imageAvatar;
                                                                       }
                                                                       completion:^(BOOL finished) {
                                                                           violation.type = HRPViolationTypePhoto;
                                                                           
                                                                           [_violationsDataSource replaceObjectAtIndex:0 withObject:violation];
                                                                           [_violationManager saveViolationsToFile:_violationsDataSource];
                                                                       }];
                                                   }
                                                  failureBlock:^(NSError *error) { }];
                                }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES
                               completion:^{ }];
    
    picker = nil;
    self.imagePickerController = nil;
}

@end
