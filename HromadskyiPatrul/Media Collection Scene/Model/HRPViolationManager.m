//
//  HRPViolationManager.m
//  HromadskyiPatrul
//
//  Created by msm72 on 19.02.16.
//  Copyright © 2016 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPViolationManager.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "AFNetworking.h"
#import "HRPImage.h"
#import "HRPViolationCell.h"
#import "UIColor+HexColor.h"


#if DEVELOPMENT
#define DebugLog(...) NSLog(__VA_ARGS__)
#else
#define DebugLog(...)
#endif

@implementation HRPViolationManager {
    BOOL _isUploading;
}

#pragma mark - Constructors -
+ (HRPViolationManager *)sharedManager {
    static HRPViolationManager *singletonManager = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        singletonManager = [[HRPViolationManager alloc] init];
    });
    
    return singletonManager;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _isNetworkAvailable = YES;
        _uploadingCount = 0;
        _isUploading = NO;
        
        // Set Reachability Observer
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityDidChange:)
                                                     name:AFNetworkingReachabilityDidChangeNotification
                                                   object:nil];
    }
    
    return self;
}


#pragma mark - Methods -
- (void)customizeManagerSuccess:(void(^)(BOOL isSuccess))success {
    _userApp = [NSUserDefaults standardUserDefaults];
    _isAllowedStartAsRecorder = [_userApp boolForKey:@"appStartStatus"];    
    CGRect viewFrame = [[UIScreen mainScreen] bounds];
    CGFloat side = 0.f;
    
    if (viewFrame.size.height > viewFrame.size.width)
        side = (viewFrame.size.width - 4.f) / 2;
    
    else
        side = (viewFrame.size.width - 8.f) / 3;
    
    _cellSize = CGSizeMake(side, side);
    
    // Create violations array
    [self readViolationsFromFileSuccess:^(BOOL isSuccess) {
        success(isSuccess);
    }];
}

- (void)getViolationPhotoByURL:(NSURL *)assetsURL
                     onSuccess:(void(^)(UIImage *image))success {
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    [library assetForURL:assetsURL
             resultBlock:^(ALAsset *asset) {
                 UIImage *photo = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage]
                                                      scale:0.5f
                                                orientation:UIImageOrientationUp];
                 
                 success(photo);
             } failureBlock:^(NSError *error) {
                 DebugLog(@"Get photo error: %@", error.localizedDescription);
             }];
}

- (void)getVideoSizeFromInfo:(NSDictionary *)info {
    NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
    
    //Error Container
    NSError *attributesError;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[videoURL path] error:&attributesError];
    NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
    _videoFileSize = [fileSizeNumber longLongValue] / 1024 / 1024;
}

- (void)checkVideoFileSize {
    if (_videoFileSize > 200.0) {
//        CGFloat frameDuration = 60.f; // sec
        
    }
}

- (void)readViolationsFromFileSuccess:(void(^)(BOOL isSuccess))success {
    _violations = [NSMutableArray array];
    _images = [NSMutableArray array];

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *arrayPath = paths[0];
    arrayPath = [arrayPath stringByAppendingPathComponent:[_userApp objectForKey:@"userAppEmail"]];
    
    // Violations exist
    if ([[NSFileManager defaultManager] fileExistsAtPath:arrayPath]) {
        NSData *arrayData = [[NSData alloc] initWithContentsOfFile:arrayPath];
        
        if (arrayData) {
            NSArray *arrayRead = [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithData:arrayData]];
            
            for (HRPViolation *violation in arrayRead) {
                if (violation.assetsPhotoURL)
                    [self getViolationPhotoByURL:[NSURL URLWithString:violation.assetsPhotoURL]
                                       onSuccess:^(UIImage *photoFromAlbum) {
                                           if (photoFromAlbum) {
                                               [_violations addObject:violation];
                                               [_images addObject:photoFromAlbum];
                                           }
                                           
                                           if ([arrayRead indexOfObject:violation] == arrayRead.count - 1) {
                                               [self saveViolationsToFile:_violations];
                                               
                                               // Return success
                                               success(YES);
                                           }
                                       }];
            }
            
            if (arrayRead.count == 0)
                success(YES);
        }
        
        else
            DebugLog(@"File does not exist");
    }
    
    else
        success(NO);
}

- (void)saveViolationsToFile:(NSMutableArray *)violations {
    NSData *arrayData = [NSKeyedArchiver archivedDataWithRootObject:violations];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *arrayPath = paths[0];
    arrayPath = [arrayPath stringByAppendingPathComponent:[_userApp objectForKey:@"userAppEmail"]];
    
    [[NSFileManager defaultManager] createFileAtPath:arrayPath
                                            contents:arrayData
                                          attributes:nil];
}

- (void)removeViolationsFromFile {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *arrayPath = paths[0];
    arrayPath = [arrayPath stringByAppendingPathComponent:[_userApp objectForKey:@"userAppEmail"]];
    
    [[NSFileManager defaultManager] removeItemAtPath:arrayPath
                                               error:nil];
}

- (void)modifyCellSize:(CGSize)size {
    CGFloat cellNewSide = 0.f;
    
    if (size.height > size.width)
        cellNewSide = (size.width - 4.f) / 2;
    
    else
        cellNewSide = (size.width - 8.f) / 3;
    
    _cellSize = CGSizeMake(cellNewSide, cellNewSide);
}

- (void)uploadViolation:(HRPViolation *)violation inAutoMode:(BOOL)isAutoMode onSuccess:(void(^)(BOOL isSuccess))success {
    if (!violation.isUploading && violation.type == HRPViolationTypeVideo) {
        if ([self canViolationUploadAuto:isAutoMode] && _uploadingCount < 2) {
            _uploadingCount++;

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void) {
                ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                
                [library assetForURL:[NSURL URLWithString:violation.assetsVideoURL]
                         resultBlock:^(ALAsset *asset) {
                             NSError *error = nil;
                             ALAssetRepresentation *representation = asset.defaultRepresentation;
                             Byte *buffer = (Byte *)malloc((NSUInteger)representation.size);
                             
                             NSUInteger buffered = [representation getBytes:buffer
                                                                 fromOffset:0.0
                                                                     length:(NSUInteger)representation.size
                                                                      error:&error];
                             
                             // Get the data
                             NSData *data = (!error) ? [NSData dataWithBytesNoCopy:buffer
                                                                            length:buffered
                                                                      freeWhenDone:YES] : nil;
                             
                             if (data) {
                                 dispatch_sync(dispatch_get_main_queue(), ^(void) {
                                     NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                                     [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                                     
                                     if (violation.latitude == 0 || violation.longitude == 0) {
                                         [self showAlertViewWithMessage:NSLocalizedString(@"Alert Location error message", nil)];
                                         [self handlerUploadViolation:violation onSuccess:NO];
                                     }
                                     
                                     else {
                                         violation.isUploading = YES;
                                         _isUploading = YES;
                                         
                                         NSDictionary *parameters = @{
                                                                        @"video" : data,
                                                                        @"latitude" : @(violation.latitude),
                                                                        @"longitude" : @(violation.longitude),
                                                                        @"date" : [formatter stringFromDate:violation.date]
                                                                      };
                                         
                                         // API
                                         [self uploadVideoWithParameters:parameters
                                                               onSuccess:^(NSDictionary *successResult) {
                                                                   [self handlerUploadViolation:violation onSuccess:YES];
                                                                   
                                                                   success(YES);
                                                               }
                                                               orFailure:^(NSError *error) {
                                                                   [self showAlertViewWithMessage:error.localizedDescription];
                                                                   [self handlerUploadViolation:violation onSuccess:NO];
                                                                   
                                                                   success(NO);
                                                               }];
                                     }
                                 });
                             }
                         }
                        failureBlock:^(NSError *error) {
                            DebugLog(@"Get video error: %@", error.localizedDescription);
                        }];
            });
        }
        
        else
            success(NO);
    }

    else
        success(NO);
}

- (void)uploadVideoWithParameters:(NSDictionary *)parameters
                        onSuccess:(void(^)(NSDictionary *successResult))success
                        orFailure:(void(^)(NSError *error))failure {
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    NSError *error = nil;
//    NSDate *start = [NSDate date];
    NSString *stringURL = [NSString stringWithFormat:@"http://patrol.stfalcon.com/api/%@/violation-video/create", [_userApp objectForKey:@"userAppID"]];
    
    NSMutableURLRequest *request = [serializer multipartFormRequestWithMethod:@"POST"
                                                                    URLString:stringURL
                                                                   parameters:parameters
                                                    constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                                                        [formData appendPartWithFileData:parameters[@"video"]
                                                                                    name:@"video"
                                                                                fileName:@"video.mov"
                                                                                mimeType:@"video/quicktime"];
                                                    }
                                                                        error:&error];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request
                                                                         success:^(AFHTTPRequestOperation *operation, id responseObject) {
//                                                                             NSLog(@"API run time = %f sec", -([start timeIntervalSinceNow]));
                                                                             success(responseObject);
                                                                         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                                             failure(error);
                                                                         }];
    
    
    [operation setUploadProgressBlock:^(NSUInteger __unused bytesWritten,
                                        long long totalBytesWritten,
                                        long long totalBytesExpectedToWrite) {
//        NSLog(@"Wrote %lld/%lld", totalBytesWritten, totalBytesExpectedToWrite);
    }];
    
    [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:^{
        // Handle iOS shutting you down (possibly make a note of where you stopped so you can resume later)
    }];
    
    [manager.operationQueue addOperation:operation];
}

- (void)handlerUploadViolation:(HRPViolation *)violation onSuccess:(BOOL)success {
    _uploadingCount--;
    violation.isUploading = NO;
    violation.state = (success) ? HRPViolationStateDone : HRPViolationStateRepeat;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.assetsVideoURL contains[cd] %@", violation.assetsVideoURL];
    NSUInteger violationIndex = [_violations indexOfObject:[[_violations filteredArrayUsingPredicate:predicate] lastObject]];
    NSLog(@"violationIndex = %li", (long)violationIndex);
    
    [_violations replaceObjectAtIndex:violationIndex withObject:violation];
    [self saveViolationsToFile:_violations];
    
    HRPViolation *violationNext = [self searchViolationForUpload];
    NSDictionary *params = (violationNext) ? @{ @"violation" : violation, @"violationNext" : violationNext } : @{ @"violation" : violation };
    
    if (_isCollectionShow)
        [[NSNotificationCenter defaultCenter] postNotificationName:@"violation_upload_success"
                                                            object:nil
                                                          userInfo:params];

    if (_uploadingCount == 0)
        _isUploading = NO;
}

- (HRPViolation *)searchViolationForUpload {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.state !=  %li && SELF.isUploading == %li", (long)HRPViolationStateDone, (long)0];
    NSMutableArray *violationsForUpload = [NSMutableArray arrayWithArray:[_violations filteredArrayUsingPredicate:predicate]];

    return [violationsForUpload firstObject];
}

- (BOOL)canViolationUploadAuto:(BOOL)isAutoUpload {
    _isAllowedUploadViolationsWithWiFi = [_userApp boolForKey:@"networkStatus"];
    _isAllowedUploadViolationsAutomatically = [_userApp boolForKey:@"sendingTypeStatus"];
    _isAllowedStartAsRecorder = [_userApp boolForKey:@"appStartStatus"];
    
    // Network is activity
    if ([[AFNetworkReachabilityManager sharedManager] isReachable]) {
        _isNetworkAvailable = YES;
        
        if (isAutoUpload && _uploadingCount > 4)
            return  NO;
        
        // Check WiFi network connection status
        if (_isAllowedUploadViolationsWithWiFi && [[AFNetworkReachabilityManager sharedManager] isReachableViaWiFi]) {
            return (isAutoUpload == _isAllowedUploadViolationsAutomatically) ? YES : NO;
        }
        
        // Check Manual or Auto upload mode
        if (!isAutoUpload || (isAutoUpload && _isAllowedUploadViolationsAutomatically))
            return YES;
        
        else
            return NO;
    }
    
    // Network disconnect
    else {
        _isNetworkAvailable = NO;
        [self showAlertViewWithMessage:NSLocalizedString(@"Alert error internet message", nil)];
    }
    
    return NO;
}

- (void)reachabilityDidChange:(NSNotification *)notification {
    if (notification.userInfo[@"AFNetworkingReachabilityNotificationStatusItem"]) {
        _isNetworkAvailable = [self canViolationUploadAuto:_isAllowedUploadViolationsAutomatically];
    }
}

- (void)showAlertViewWithMessage:(NSString *)message {
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Alert error email title", nil)
                                message:message
                               delegate:nil
                      cancelButtonTitle:nil
                      otherButtonTitles:NSLocalizedString(@"Alert error button Ok", nil), nil] show];
}

@end
