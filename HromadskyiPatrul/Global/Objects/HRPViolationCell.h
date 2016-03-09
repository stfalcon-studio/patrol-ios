//
//  HRPViolationCell.h
//  HromadskyiPatrul
//
//  Created by msm72 on 26.08.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HRPViolation.h"
#import "HRPButton.h"
#import "MBProgressHUD.h"


typedef NS_ENUM (NSInteger, CellBackgroundColorType) {
    CellBackgroundColorTypeBlue,
    CellBackgroundColorTypeBlack
};


@interface HRPViolationCell : UICollectionViewCell

@property (strong, nonatomic) HRPViolation *violation;
@property (strong, nonatomic) IBOutlet UIImageView *photoImageView;
@property (strong, nonatomic) IBOutlet UIImageView *playVideoImageView;
@property (strong, nonatomic) IBOutlet HRPButton *uploadStateButton;

@property (strong, nonatomic) MBProgressHUD *HUD;

//- (void)customizeCellStyle:(NSCache *)cache;
- (void)customizeCellStyle;
- (void)uploadImage:(NSIndexPath *)indexPath inImages:(NSMutableArray *)images;
//- (void)uploadImage:(NSIndexPath *)indexPath withCache:(NSCache *)cache;


//- (void)customizeCellStyle:(UIImage *)photo onSuccess:(void(^)(BOOL isFinished))isFinished;
- (void)showLoaderWithText:(NSString *)text andBackgroundColor:(CellBackgroundColorType)colorType forTime:(unsigned int)duration;
- (void)hideLoader;

//- (void)uploadViolationAuto:(BOOL)isAutoUpload onSuccess:(void(^)(BOOL isFinished))finished;

@end
