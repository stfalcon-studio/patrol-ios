//
//  HRPPhotoCell.h
//  HromadskyiPatrul
//
//  Created by msm72 on 26.08.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HRPPhoto.h"
#import "HRPImage.h"
#import "MBProgressHUD.h"


typedef NS_ENUM (NSInteger, CellBackgroundColorType) {
    CellBackgroundColorTypeBlue,
    CellBackgroundColorTypeBlack
};


@interface HRPPhotoCell : UICollectionViewCell

@property (strong, nonatomic) HRPPhoto *photo;
@property (strong, nonatomic) HRPImage *image;
@property (strong, nonatomic) IBOutlet UIImageView *photoImageView;
@property (strong, nonatomic) IBOutlet UIImageView *playVideoImageView;
@property (strong, nonatomic) IBOutlet UIButton *photoStateButton;

@property (strong, nonatomic) MBProgressHUD *HUD;

- (void)showLoaderWithText:(NSString *)text andBackgroundColor:(CellBackgroundColorType)colorType;
- (void)hideLoader;

@end
