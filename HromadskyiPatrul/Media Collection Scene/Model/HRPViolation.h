//
//  HRPViolation.h
//  HromadskyiPatrul
//
//  Created by msm72 on 19.02.16.
//  Copyright © 2016 Monastyrskiy Sergey. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


typedef NS_ENUM (NSInteger, HRPViolationState) {
    HRPViolationStateDone,
    HRPViolationStateRepeat,
    HRPViolationStateUpload
};

typedef NS_ENUM (NSInteger, HRPViolationType) {
    HRPViolationTypePhoto,
    HRPViolationTypeVideo
};


@interface HRPViolation : NSObject

@property (assign, nonatomic) HRPViolationState state;
@property (assign, nonatomic) HRPViolationType type;
@property (strong, nonatomic) NSString *assetsPhotoURL;
@property (strong, nonatomic) NSString *assetsVideoURL;
@property (strong, nonatomic) NSString *assetsVideoURLOriginal;
@property (strong, nonatomic) NSDate *date;
@property (assign, nonatomic) CGFloat latitude;
@property (assign, nonatomic) CGFloat longitude;
@property (assign, nonatomic) CGFloat duration;
@property (assign, nonatomic) BOOL isUploading;

@end
