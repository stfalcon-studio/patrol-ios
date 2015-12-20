//
//  HRPCollectionViewModel.m
//  HromadskyiPatrul
//
//  Created by msm72 on 19.12.15.
//  Copyright © 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPCollectionViewModel.h"
#import "HRPPhotoCell.h"
#import "HRPPhoto.h"
#import "HRPImage.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "AFNetworking.h"
#import <AFHTTPRequestOperation.h>


@implementation HRPCollectionViewModel {
    HRPPhoto *_currentPhoto;
    HRPImage *_currentImage;
    HRPPhotoCell *_currentCell;
    NSIndexPath *_currentIndexPath;
    ALAsset *_myAsset;

    NSMutableArray *_photosDataSource;
    NSMutableArray *_imagesDataSource;

    NSString *_arrayPath;
    NSTimer *_timer;

    NSInteger _paginationOffset;

    BOOL _isUploadPhotosUsingWiFiAllowed;
    BOOL _isUploadAutomaticallyAllowed;
    BOOL _isLocationServiceEnabled;
    BOOL _isUploadInProcess;
    BOOL _isPaginationRun;
    BOOL _isVideoPreviewStart;

}

#pragma mark - Constructors -
- (instancetype)init {
    self            =   [super init];
    
    if (self) {
        _userApp    =   [NSUserDefaults standardUserDefaults];
        
        //[self setDataSource];
    }
    
    return self;
}


#pragma mark - Methods -
- (void)setDataSource {/*
    // Set Data Source
    _photosDataSource                   =   [NSMutableArray array];
    _imagesDataSource                   =   [NSMutableArray array];
    _isUploadInProcess                  =   NO;
    
    _isPaginationRun                    =   NO;
    
    
    [self createStoreDataPath];
    //    [self savePhotosCollectionToFile];
    //    [self removePhotosCollectionFromFile];
    [self readPhotosCollectionFromFile];*/
}

- (void)checkNeedUploadFiles {
    _isUploadPhotosUsingWiFiAllowed     =   [_userApp boolForKey:@"networkStatus"];
    _isUploadAutomaticallyAllowed       =   [_userApp boolForKey:@"sendingTypeStatus"];
    _isVideoPreviewStart                =   NO;
    
    if (_photosNeedUploadCount > 0 && !_isUploadInProcess)
        [self startUploadPhotos];
}

- (void)startUploadPhotos {
    if (_photosNeedUploadCount > 0 && [self canPhotosSendToServer])
        [self uploadDatas];
}

- (BOOL)canPhotosSendToServer {
    // Network is activity
    if ([[AFNetworkReachabilityManager sharedManager] isReachable]) {
        // Check WiFi network connection status
        if (_isUploadPhotosUsingWiFiAllowed && [[AFNetworkReachabilityManager sharedManager] isReachableViaWiFi] && !_isUploadInProcess)
            return YES;
        
        // Check WWAN network connection status
        else if (!_isUploadPhotosUsingWiFiAllowed && [[AFNetworkReachabilityManager sharedManager] isReachableViaWWAN] && !_isUploadInProcess)
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

- (void)createStoreDataPath {
    NSError *error;
    NSArray *paths      =   NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    _arrayPath          =   paths[0]; // [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Photos"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:_arrayPath]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:_arrayPath
                                       withIntermediateDirectories:NO
                                                        attributes:nil
                                                             error:&error])
            NSLog(@"Create directory error: %@", error);
    }
}

- (void)uploadDatas {
/*    for (HRPPhoto *photo in _photosDataSource) {
        if (photo.state != HRPPhotoStateDone) {
            _currentPhoto               =   photo;
            
            // Find HRPImage custom object
            NSPredicate *predicate      =   [NSPredicate predicateWithFormat:@"SELF.imageOriginalURL == [cd] %@", _currentPhoto.assetsPhotoURL];
            
            _currentImage               =   [_imagesDataSource filteredArrayUsingPredicate:predicate][0];
            
            // Find HRPPhotoCell custom object
            _currentCell                =   (HRPPhotoCell *)[self.photosCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:[imagesDataSource indexOfObject:currentImage] inSection:0]];
            
            if ([_photosCollectionView.visibleCells containsObject:currentCell] && !isUploadInProcess) {
                [currentCell showLoaderWithText:NSLocalizedString(@"Upload title", nil)
                             andBackgroundColor:CellBackgroundColorTypeBlue
                                        forTime:300];
                
                [self uploadDataFromLoop:YES];
                
                break;
            }
        }
    }*/
}

- (void)uploadDataFromLoop:(BOOL)inLoop {
    // Check network connection state
/*    if ((inLoop && _isUploadAutomaticallyAllowed) ||
        (!inLoop && !_isUploadAutomaticallyAllowed)) {
        if ([self canPhotosSendToServer]) {
            // Async queue
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                // Save to device
                [self savePhotosCollectionToFile];
                _isUploadInProcess                                   =   YES;
                __block UIImage *imageOriginal;
                __block NSDictionary *parameters;
                
                // Upload Video
                if (_currentPhoto.isVideo) {
                    [self getVideoFromAlbumAtURL:[NSURL URLWithString:currentPhoto.assetsVideoURL]
                                       onSuccess:^(NSData *videoData) {
                                           _currentImage.imageData   =   videoData;
                                           
                                           parameters               =   @{
                                                                          @"video"        :   videoData,
                                                                          @"latitude"     :   @(_currentPhoto.latitude),
                                                                          @"longitude"    :   @(_currentPhoto.longitude)
                                                                          };
                                           
                                           // API
                                           [self uploadVideoWithParameters:parameters
                                                                 onSuccess:^(NSDictionary *successResult) {
                                                                     _currentPhoto.state     =   HRPPhotoStateDone;
                                                                     [_currentCell.photoStateButton setImage:[UIImage imageNamed:@"icon-done"] forState:UIControlStateNormal];
                                                                     
                                                                     [self savePhotosCollectionToFile];
                                                                     [_currentCell hideLoader];
                                                                     
                                                                     _isUploadInProcess      =   NO;
                                                                     _photosNeedUploadCount--;
                                                                     
                                                                     if (_photosNeedUploadCount && inLoop)
                                                                         [self startUploadPhotos];
                                                                 }
                                                                 orFailure:^(AFHTTPRequestOperation *failureOperation) {
                                                                     _currentPhoto.state     =   HRPPhotoStateRepeat;
                                                                     [_currentCell.photoStateButton setImage:[UIImage imageNamed:@"icon-repeat"] forState:UIControlStateNormal];
                                                                     
                                                                     [self savePhotosCollectionToFile];
                                                                     [_currentCell hideLoader];
                                                                     [self hideLoader];
                                                                     
                                                                     _isUploadInProcess      =   NO;
                                                                     
                                                                     [self showAlertViewWithTitle:NSLocalizedString(@"Alert error API title", nil)
                                                                                       andMessage:NSLocalizedString(@"Alert API Upload error message", nil)];
                                                                 }];
                                       }];
                }
                
                // Upload Photo
                else {
                    [self getPhotoFromAlbumAtURL:[NSURL URLWithString:currentPhoto.assetsPhotoURL]
                                       onSuccess:^(UIImage *image) {
                                           imageOriginal                                    =   image;
                                           
                                           if ([_currentPhoto.assetsPhotoURL hasSuffix:@"JPG"])
                                               _currentImage.imageData                       =   [[NSData alloc] initWithData:UIImageJPEGRepresentation(imageOriginal, 1.f)];
                                           else
                                               _currentImage.imageData                       =   [[NSData alloc] initWithData:UIImagePNGRepresentation(imageOriginal)];
                                           
                                           parameters                                       =   @{
                                                                                                  @"photo"        :   _currentImage.imageData,
                                                                                                  @"latitude"     :   @(_currentPhoto.latitude),
                                                                                                  @"longitude"    :   @(_currentPhoto.longitude)
                                                                                                  };
                                           
                                           // API
                                           [self uploadPhotoWithParameters:parameters
                                                                 onSuccess:^(NSDictionary *successResult) {
                                                                     _currentPhoto.state     =   HRPPhotoStateDone;
                                                                     [_currentCell.photoStateButton setImage:[UIImage imageNamed:@"icon-done"] forState:UIControlStateNormal];
                                                                     
                                                                     [self savePhotosCollectionToFile];
                                                                     [_currentCell hideLoader];
                                                                     
                                                                     _isUploadInProcess      =   NO;
                                                                     _photosNeedUploadCount--;
                                                                     
                                                                     if (photosNeedUploadCount && inLoop)
                                                                         [self startUploadPhotos];
                                                                 }
                                                                 orFailure:^(AFHTTPRequestOperation *failureOperation) {
                                                                     currentPhoto.state     =   HRPPhotoStateRepeat;
                                                                     [currentCell.photoStateButton setImage:[UIImage imageNamed:@"icon-repeat"] forState:UIControlStateNormal];
                                                                     
                                                                     [self savePhotosCollectionToFile];
                                                                     [currentCell hideLoader];
                                                                     [self hideLoader];
                                                                     
                                                                     isUploadInProcess      =   NO;
                                                                 }];
                                       }
                     ];
                }
            });
        } else {
            [currentCell hideLoader];
            
            // Wait for next item upload
            if (isUploadInProcess && photosNeedUploadCount > 0)
                [self uploadDataFromLoop:inLoop];
        }
    }*/
}

- (void)savePhotosCollectionToFile {/*
    NSData *arrayData   =   [NSKeyedArchiver archivedDataWithRootObject:photosDataSource];
    NSArray *paths      =   NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    arrayPath           =   paths[0]; // [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Photos"];
    arrayPath           =   [arrayPath stringByAppendingPathComponent:[userApp objectForKey:@"userAppEmail"]];
    
    [[NSFileManager defaultManager] createFileAtPath:arrayPath
                                            contents:arrayData
                                          attributes:nil];*/
}

- (void)readPhotosCollectionFromFile {/*
    NSArray *paths      =   NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    arrayPath           =   paths[0]; // [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Photos"];
    arrayPath           =   [arrayPath stringByAppendingPathComponent:[userApp objectForKey:@"userAppEmail"]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:arrayPath]) {
        NSData *arrayData       =   [[NSData alloc] initWithContentsOfFile:arrayPath];
        photosDataSource        =   [NSMutableArray array];
        imagesDataSource        =   [NSMutableArray array];
        
        if (arrayData) {
            photosDataSource    =   [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithData:arrayData]];
            
            if (photosDataSource.count == 0) {
                [self.navigationItem.rightBarButtonItem setEnabled:YES];
                [self.photosCollectionView setUserInteractionEnabled:YES];
                
                [self hideLoader];
            } else
                [self createImagesDataSource];
        } else
            NSLog(@"File does not exist");
    }
    
    else {
        photosDataSource        =   [NSMutableArray array];
        imagesDataSource        =   [NSMutableArray array];
        
        [self hideLoader];
    }*/
}

@end
