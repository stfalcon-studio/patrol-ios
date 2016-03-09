//
//  HRPViolationCell.m
//  HromadskyiPatrul
//
//  Created by msm72 on 26.08.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPViolationCell.h"
#import "UIColor+HexColor.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "UIImage+ChangeOriginalImage.h"
//#import "HRPViolationManager.h"


@implementation HRPViolationCell {
    unsigned int _sleepDuration;
}

#pragma mark - Actions -

// DELETE AFTER TESTING
- (IBAction)handlerUploadStateButtonTap:(HRPButton *)sender {
    if (_violation.state != HRPViolationStateDone) {
        [self showLoaderWithText:nil andBackgroundColor:CellBackgroundColorTypeBlue forTime:300];

        _uploadStateButton.didButtonPress(_violation);
    }
}


#pragma mark - Methods -
- (void)customizeCellStyle {
    if (_violation.isUploading) {
        [self showLoaderWithText:nil andBackgroundColor:CellBackgroundColorTypeBlue forTime:300];
    }
    
    else {
        [self hideLoader];
    }
    
    switch (_violation.state) {
        // HRPPhotoStateDone
        case 0: {
            [_uploadStateButton setImage:[UIImage imageNamed:@"icon-done"] forState:UIControlStateNormal];
            _uploadStateButton.tag = 0;
        }
            break;
            
        // HRPPhotoStateRepeat
        case 1: {
            [_uploadStateButton setImage:[UIImage imageNamed:@"icon-repeat"] forState:UIControlStateNormal];
            _uploadStateButton.tag = 1;
        }
            break;
            
        // HRPPhotoStateUpload
        case 2: {
            [_uploadStateButton setImage:[UIImage imageNamed:@"icon-upload"] forState:UIControlStateNormal];
            _uploadStateButton.tag = 2;
        }
            break;
    }
}

- (void)uploadImage:(NSIndexPath *)indexPath inImages:(NSMutableArray *)images {
    __block UIImage *imageViolation = [UIImage imageNamed:@"icon-no-image"];
    _photoImageView.image = imageViolation;
    
    id imageFromCache = images[indexPath.row];
    
    if (imageFromCache && ![imageFromCache isEqual:@"777"]) {
        [UIView transitionWithView:self
                          duration:0.1f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            _photoImageView.image = imageFromCache;
                        }
                        completion:^(BOOL finished) {
                            _playVideoImageView.alpha = (_violation.type == HRPViolationTypeVideo) ? 1.f : 0.f;
                        }];
    }
    
    else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void) {
            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
            
            [library assetForURL:[NSURL URLWithString:_violation.assetsPhotoURL]
                     resultBlock:^(ALAsset *asset) {
                         imageViolation = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage]
                                                              scale:1.f
                                                        orientation:UIImageOrientationUp];
                        
                         imageViolation = [imageViolation squareImageFromImage:imageViolation scaledToSize:self.frame.size.width];
                         
                         dispatch_sync(dispatch_get_main_queue(), ^(void) {
//                             _photoImageView.image = imageViolation;
//                             _playVideoImageView.alpha = (_violation.type == HRPViolationTypeVideo) ? 1.f : 0.f;
//                                           
//                             (images.count == 0) ?  [images addObject:imageViolation] :
//                                                    [images insertObject:imageViolation atIndex:indexPath.row];

                             [UIView transitionWithView:self
                                               duration:0.1f
                                                options:UIViewAnimationOptionTransitionCrossDissolve
                                             animations:^{
                                                 _photoImageView.image = imageViolation;
                                             }
                                             completion:^(BOOL finished) {
                                                 _playVideoImageView.alpha = (_violation.type == HRPViolationTypeVideo) ? 1.f : 0.f;
                                                 
                                                 (images.count == 0) ?  [images addObject:imageViolation] :
                                                                        [images insertObject:imageViolation
                                                                                     atIndex:indexPath.row];
                                             }];
                         });
                     }
                    failureBlock:^(NSError *error) { }];
        });
    }
}




/*
- (void)uploadImage:(NSIndexPath *)indexPath withCache:(NSCache *)cache {
    __block UIImage *imageViolation = [UIImage imageNamed:@"icon-no-image"];
    _photoImageView.image = imageViolation;

    NSString *imageName = [NSString stringWithFormat:@"photo-%li", (long)indexPath.row];
    UIImage *imageFromCache = [cache objectForKey:imageName];
    
    if (imageFromCache) {
        [UIView transitionWithView:self
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            _photoImageView.image = [imageFromCache squareImageFromImage:imageFromCache scaledToSize:self.frame.size.width];
                        }
                        completion:^(BOOL finished) {
                            _playVideoImageView.alpha = (_violation.type == HRPViolationTypeVideo) ? 1.f : 0.f;
                        }];
    }
    
    else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void) {

        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        
        [library assetForURL:[NSURL URLWithString:_violation.assetsPhotoURL]
                 resultBlock:^(ALAsset *asset) {
                     imageViolation = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage]
                                                          scale:0.5f
                                                    orientation:UIImageOrientationUp];
                     
                     dispatch_sync(dispatch_get_main_queue(), ^(void) {
                         [UIView transitionWithView:self
                                           duration:0.2f
                                            options:UIViewAnimationOptionTransitionCrossDissolve
                                         animations:^{
                                             _photoImageView.image = imageViolation;
                                         }
                                         completion:^(BOOL finished) {
                                             _playVideoImageView.alpha = (_violation.type == HRPViolationTypeVideo) ? 1.f : 0.f;
                                             
                                             if (!imageFromCache)
                                                 [cache setObject:imageViolation forKey:imageName];
                                         }];
                     });
                 }
                failureBlock:^(NSError *error) { }];
        });
    }
}

  */
   
/*
- (void)customizeCellStyle:(NSCache *)cache {
    if (_violation.isUploading) {
        [self showLoaderWithText:nil andBackgroundColor:CellBackgroundColorTypeBlue forTime:300];
    }
    
    else {
        [self hideLoader];
    }
    
    switch (_violation.state) {
        // HRPPhotoStateDone
        case 0: {
            [_uploadStateButton setImage:[UIImage imageNamed:@"icon-done"] forState:UIControlStateNormal];
            _uploadStateButton.tag = 0;
        }
            break;
            
        // HRPPhotoStateRepeat
        case 1: {
            [_uploadStateButton setImage:[UIImage imageNamed:@"icon-repeat"] forState:UIControlStateNormal];
            _uploadStateButton.tag = 1;
        }
            break;
            
        // HRPPhotoStateUpload
        case 2: {
            [_uploadStateButton setImage:[UIImage imageNamed:@"icon-upload"] forState:UIControlStateNormal];
            _uploadStateButton.tag = 2;
        }
            break;
    }
    
    // Get violation photo from device Album
    NSString *photoName = [NSString stringWithFormat:@"photo-%@", _violation.assetsPhotoURL];
    UIImage *photoFromCash = [cache objectForKey:photoName];

    if (photoFromCash) {
        _photoImageView.image = [photoFromCash squareImageFromImage:photoFromCash scaledToSize:self.frame.size.width];
        
//        isFinished(YES);
    }
    
    else {
        /*
//        dispatch_queue_t downloadQueue = dispatch_queue_create("image downloader", NULL);
//        
//        dispatch_async(downloadQueue, ^{
            [self getPhotoFromAlbumAtURL:[NSURL URLWithString:_violation.assetsPhotoURL]
                               onSuccess:^(UIImage *photoFromAlbum) {
                                   if (photoFromAlbum)
//                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           _photoImageView.image = [photoFromAlbum squareImageFromImage:photoFromAlbum scaledToSize:self.frame.size.width];
                                           _playVideoImageView.alpha = (_violation.type == HRPViolationTypeVideo) ? 1.f : 0.f;
                                           
                                           [self setNeedsDisplay];
                                           
                                           isFinished(YES);
//                                       });
                               }];
//        });

        
        // DELETE AFTER TESTING
         */

/*
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            //Background Thread
            [self getPhotoFromAlbumAtURL:[NSURL URLWithString:_violation.assetsPhotoURL]
                               onSuccess:^(UIImage *photoFromAlbum) {
                                   //Run UI Updates
                                   dispatch_async(dispatch_get_main_queue(), ^(void) {
                                       UIImage *image = [photoFromAlbum squareImageFromImage:photoFromAlbum scaledToSize:self.frame.size.width];

                                       /*
                                       UIImage *image = [photoFromAlbum squareImageFromImage:photoFromAlbum scaledToSize:self.frame.size.width];
                                       _photoImageView.image = image;
                                       _playVideoImageView.alpha = (_violation.type == HRPViolationTypeVideo) ? 1.f : 0.f;
                                                      
                                       [cache setObject:image forKey:photoName];
                                        */
                                       /*
                                       [UIView transitionWithView:self
                                                         duration:0.1f
                                                          options:UIViewAnimationOptionTransitionCrossDissolve
                                                       animations:^{
                                                           _photoImageView.image = image;
                                                       }
                                                       completion:^(BOOL finished) {
                                                           _playVideoImageView.alpha = (_violation.type == HRPViolationTypeVideo) ? 1.f : 0.f;
                                                           
                                                           [cache setObject:image forKey:photoName];
                                                       }];
                                       
                                   });
                               }];            
        });
        
        
        /*
        [self getPhotoFromAlbumAtURL:[NSURL URLWithString:_violation.assetsPhotoURL]
                           onSuccess:^(UIImage *photoFromAlbum) {
                               if (photoFromAlbum) {
                                   [UIView transitionWithView:self
                                                     duration:0.5f
                                                      options:UIViewAnimationOptionTransitionCrossDissolve
                                                   animations:^{
                                                       _photoImageView.image = [photoFromAlbum squareImageFromImage:photoFromAlbum scaledToSize:self.frame.size.width];
                                                   }
                                                   completion:^(BOOL finished) {
                                                       _playVideoImageView.alpha = (_violation.type == HRPViolationTypeVideo) ? 1.f : 0.f;
                                                       
                                                       [cache setObject:_photoImageView.image forKey:photoName];
                                                   }];
                               }
                           }];
         
    }
}
*/


- (void)showLoaderWithText:(NSString *)text andBackgroundColor:(CellBackgroundColorType)colorType forTime:(unsigned int)duration {
    NSString *colorString = nil;
    _sleepDuration = duration;
    
    switch (colorType) {
        case CellBackgroundColorTypeBlue:
            colorString = @"05A9F4";
            break;
            
        case CellBackgroundColorTypeBlack:
            colorString = @"000000";
            break;
    }
    
    _HUD = [[MBProgressHUD alloc] initWithView:self];
    _HUD.labelText = text;
    _HUD.yOffset = 0.f;
    _HUD.color = [UIColor colorWithHexString:colorString alpha:0.6f];
    
    [self addSubview:_HUD];
    [_HUD showWhileExecuting:@selector(sleepTask) onTarget:self withObject:nil animated:YES];
}

- (void)hideLoader {
    [MBProgressHUD hideAllHUDsForView:self animated:YES];
    _HUD = nil;
}

- (void)sleepTask {
    // Do something usefull in here instead of sleeping ...
    sleep(_sleepDuration);
}

- (void)getPhotoFromAlbumAtURL:(NSURL *)assetsURL
                     onSuccess:(void(^)(UIImage *image))success {
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    [library assetForURL:assetsURL
             resultBlock:^(ALAsset *asset) {
                 UIImage *image = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage]
                                                      scale:1.f
                                                orientation:UIImageOrientationUp];
                 
                 success(image);
             }
            failureBlock:^(NSError *error) { }];
}

@end
