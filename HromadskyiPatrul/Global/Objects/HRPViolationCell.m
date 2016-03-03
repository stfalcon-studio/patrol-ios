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
- (void)customizeCellStyle:(NSCache *)cache {
//- (void)customizeCellStyle:(UIImage *)photo onSuccess:(void (^)(BOOL))isFinished {
    if (_violation.isUploading) {
        [self showLoaderWithText:nil andBackgroundColor:CellBackgroundColorTypeBlue forTime:300];
    }
    
    else  /*if (!_violation.isUploading && _HUD.alpha) */ {
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
        
        [self getPhotoFromAlbumAtURL:[NSURL URLWithString:_violation.assetsPhotoURL]
                           onSuccess:^(UIImage *photoFromAlbum) {
                               if (photoFromAlbum) {
                                   [UIView transitionWithView:self
                                                     duration:0.3f
                                                      options:UIViewAnimationOptionTransitionCrossDissolve
                                                   animations:^{
                                                       _photoImageView.image = [photoFromAlbum squareImageFromImage:photoFromAlbum scaledToSize:self.frame.size.width];
                                                   }
                                                   completion:^(BOOL finished) {
                                                       _playVideoImageView.alpha = (_violation.type == HRPViolationTypeVideo) ? 1.f : 0.f;
                                                       
                                                       [cache setObject:_photoImageView.image forKey:photoName];
                                                   }];

                                   /*
                                   [UIView transitionWithView:self
                                                     duration:0.3f
                                                      options:UIViewAnimationOptionTransitionCrossDissolve
                                                   animations:^{
                                                       _photoImageView.image = [photoFromAlbum squareImageFromImage:photoFromAlbum scaledToSize:self.frame.size.width];
                                                   }
                                                   completion:^(BOOL finished) {
                                                       _playVideoImageView.alpha = (_violation.type == HRPViolationTypeVideo) ? 1.f : 0.f;
                                                           
                                                        [cache setObject:_photoImageView.image forKey:photoName];
                                                   }];
                                    */
                               }
                           }];
    }
}

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
                                                      scale:0.5f
                                                orientation:UIImageOrientationUp];
                 
                 success(image);
             }
            failureBlock:^(NSError *error) { }];
}

@end
