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
    NSCache *_cache;
    UIView *_statusView;
}

#pragma mark - Constructors -
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self showLoaderWithText:NSLocalizedString(@"Launch text", nil)
          andBackgroundColor:BackgroundColorTypeBlack
                     forTime:300];

    _statusView = [self customizeStatusBar];

    // Create Cache
    // Get violation photo from device Album
    _cache = [[NSCache alloc] init];

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

    
    // DELETE AFTER TESTING
    /*
    [_violationManager readViolationsFromFileSuccess:^(BOOL isFinished) {
        if (isFinished) {
            _violationsDataSource = _violationManager.violations;
            
            [_violationsCollectionView reloadData];
            [self hideLoader];
        }
        
        else
            [self hideLoader];
    }];
     */
    
    // Add Notification Observers
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handlerViolationSuccessUpload:)
                                                 name:@"violation_upload_success"
                                               object:nil];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    _violationManager.isCollectionShow = YES;
    [self setRightBarButtonEnable:YES];
    CGSize size = [[UIScreen mainScreen] bounds].size;
    [_violationManager modifyCellSize:size];
    
    [self hideLoader];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    _violationManager.isCollectionShow = NO;
    [_cache removeAllObjects];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    UICollectionViewFlowLayout *flowLayout = (id)_violationsCollectionView.collectionViewLayout;
    flowLayout.itemSize = _violationManager.cellSize;
    
    [flowLayout invalidateLayout]; //force the elements to get laid out again with the new size
}


#pragma mark - Actions -
- (void)handlerLeftBarButtonTap:(UIBarButtonItem *)sender {
    // E-mail button
}

- (void)handlerRightBarButtonTap:(UIBarButtonItem *)sender {
    // Settings button
    [self setRightBarButtonEnable:NO];
    HRPSettingsViewController *settingsTVC = [self.storyboard instantiateViewControllerWithIdentifier:@"SettingsTVC"];
    
    // Handler change Auto upload item
    [settingsTVC setDidChangeAutoUploadItem:^(id item) {
        if ([item boolValue] == YES) {
            [_violationsCollectionView reloadData];
        }
    }];
    
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
- (void)handlerViolationSuccessUpload:(NSNotification *)notification {
    HRPViolation *violation = notification.userInfo[@"violation"];
//    _violationsArray = _violationManager.violations;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_violationManager.violations indexOfObject:violation]
                                                inSection:0];
    
    [_violationManager.violations replaceObjectAtIndex:indexPath.row withObject:violation];

    HRPViolationCell *cell = (HRPViolationCell *)[_violationsCollectionView cellForItemAtIndexPath:indexPath];
//    NSString *photoName = [NSString stringWithFormat:@"photo-%li", (long)indexPath.row];
//    UIImage *photoFromCash = [_cache objectForKey:photoName];

    [cell customizeCellStyle:_cache];
    
    
//    [cell customizeCellStyle:photoFromCash
//                   onSuccess:^(BOOL isFinished) {
//                       if (!photoFromCash)
//                           [_cache setObject:cell.photoImageView.image forKey:photoName];
//                   }];
    
    [cell hideLoader];
}


#pragma mark - Methods -
- (void)removeViolationFromCollection:(NSIndexPath *)indexPath {
    [_violationsCollectionView performBatchUpdates:^{
        [_violationManager.violations removeObjectAtIndex:indexPath.row];
        [_violationsCollectionView deleteItemsAtIndexPaths:@[indexPath]];
    }
                                            completion:^(BOOL finished) {
                                                [_violationManager saveViolationsToFile:_violationManager.violations];
                                            }];
}

- (void)showAlertController:(NSIndexPath *)indexPath {
    HRPViolation *violation = _violationManager.violations[indexPath.row];
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
//                                                                                                       _violationsArray = _violationManager.violations;
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
    return _violationManager.violations.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"ViolationCell";
    HRPViolationCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    HRPViolation *violation = _violationManager.violations[indexPath.row];
    cell.violation = violation;

    DebugLog(@"Row = %li", (long)indexPath.row);
    
    [cell customizeCellStyle:_cache];
    
//    [cell customizeCellStyle:photoFromCash
//                   onSuccess:^(BOOL isFinished) {
//                       if (!photoFromCash)
//                           [_cache setObject:cell.photoImageView.image forKey:photoName];
//                   }];
    
    
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
    
    if (cell.violation.state != HRPViolationStateDone && !cell.violation.isUploading) {
        [_violationManager uploadViolation:cell.violation
                                  fromCell:cell
                                inAutoMode:YES
                                 onSuccess:^(BOOL isSuccess) {
//                                     _violationsArray = _violationManager.violations;
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
    
    [_violationManager modifyCellSize:size];
}


#pragma mark - UIImagePickerControllerDelegate -
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if (_violationManager.violations.count > 0)
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

        for (int i = 0; i <= _violationManager.violations.count; i++) {
            [arrayWithIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        
        (_violationManager.violations.count == 0) ? [_violationManager.violations addObject:violation] :
                                                    [_violationManager.violations insertObject:violation atIndex:0];
        
        [_violationsCollectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
    }
                                        completion:nil];
   
    if  (_violationManager.violations.count == 1)
        [_violationsCollectionView reloadData];
    
    HRPViolationCell *cell = (HRPViolationCell *)[_violationsCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
   
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
                                                                           
                                                                           [_violationManager.violations replaceObjectAtIndex:0 withObject:violation];
                                                                           [_violationManager saveViolationsToFile:_violationManager.violations];
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
