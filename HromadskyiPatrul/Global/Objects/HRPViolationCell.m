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


@implementation HRPViolationCell {
    unsigned int _sleepDuration;
}

#pragma mark - Actions -
- (IBAction)handlerUploadStateButtonTap:(HRPButton *)sender {
    if (_violation.state != HRPViolationStateDone) {
        _uploadStateButton.didButtonPress(_violation);
     
        [self showLoaderWithText:nil andBackgroundColor:CellBackgroundColorTypeBlue forTime:300];
    }
}


#pragma mark - Methods -
- (void)customizeCellStyle {
    [self showLoaderWithText:nil andBackgroundColor:CellBackgroundColorTypeBlue forTime:300];

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
                                                 duration:0.7f
                                                  options:UIViewAnimationOptionTransitionCrossDissolve
                                               animations:^{
                                                   _photoImageView.image = [photoFromAlbum squareImageFromImage:photoFromAlbum scaledToSize:self.frame.size.width];
                                               }
                                               completion:^(BOOL finished) {
                                                   if (finished) {
                                                       _playVideoImageView.alpha = (_violation.type == HRPViolationTypeVideo) ? 1.f : 0.f;
                                                       
                                                       [self hideLoader];
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
