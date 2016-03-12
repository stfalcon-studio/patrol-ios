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
        [self showActivityLoader];

        _uploadStateButton.didButtonPress(_violation);
    }
}


#pragma mark - Methods -
- (void)customizeCellStyle {
    if (_violation.isUploading) {
        [self showActivityLoader];
    }
    
    else {
        [self hideActivityLoader];
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
                             [UIView transitionWithView:self
                                               duration:0.1f
                                                options:UIViewAnimationOptionTransitionCrossDissolve
                                             animations:^{
                                                 _photoImageView.image = imageViolation;
                                             }
                                             completion:^(BOOL finished) {
                                                 _playVideoImageView.alpha = (_violation.type == HRPViolationTypeVideo) ? 1.f : 0.f;
                                                 
                                                 (images.count == 0) ?  [images addObject:imageViolation] :
                                                                        [images replaceObjectAtIndex:indexPath.row
                                                                                          withObject:imageViolation];
                                             }];
                         });
                     }
                    failureBlock:^(NSError *error) { }];
        });
    }
}

- (void)showActivityLoader {
    [UIView animateWithDuration:0.3f
                     animations:^{
                         _uploadStateButton.alpha = 0.f;
                     }
                     completion:^(BOOL finished) {
                         [_activityLoader startAnimating];
                     }];
}

- (void)hideActivityLoader {
    [UIView animateWithDuration:0.3f
                     animations:^{
                         _uploadStateButton.alpha = 1.f;
                     }
                     completion:^(BOOL finished) {
                         [_activityLoader stopAnimating];
                     }];
}

- (void)sleepTask {
    // Do something usefull in here instead of sleeping ...
    sleep(_sleepDuration);
}

@end
