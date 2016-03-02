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
#import "HRPViolationManager.h"


@implementation HRPViolationCell {
    unsigned int _sleepDuration;
}

#pragma mark - Actions -
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
                                                   if (finished) {
                                                       _playVideoImageView.alpha = (_violation.type == HRPViolationTypeVideo) ? 1.f : 0.f;
                                                   }
                                               }];
                           }
                       }];
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
                                                      scale:1.f
                                                orientation:UIImageOrientationUp];
                 
                 success(image);
             }
            failureBlock:^(NSError *error) { }];
}

//- (void)uploadViolationAuto:(BOOL)isAutoUpload onSuccess:(void(^)(BOOL isFinished))finished {
//    HRPViolationManager *violationManager = [HRPViolationManager sharedManager];
//
//    if (!_violation.isUploading) {
////        _violation.isUploading = YES;
//
//        [self showLoaderWithText:nil
//              andBackgroundColor:CellBackgroundColorTypeBlue
//                         forTime:300];
//        
//        [violationManager uploadViolation:_violation
//                               inAutoMode:isAutoUpload
//                                onSuccess:^(BOOL isSuccess) {
//                                    [_uploadStateButton setImage:[UIImage imageNamed:(isSuccess) ? @"icon-done" : @"icon-repeat"] forState:UIControlStateNormal];
//                                    [self hideLoader];
//                                    
//                                    finished(YES);
//                                }];
//    }
//}

@end
