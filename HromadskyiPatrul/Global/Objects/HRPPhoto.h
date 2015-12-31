//
//  HRPPhoto.h
//  HromadskyiPatrul
//
//  Created by msm72 on 26.08.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


typedef NS_ENUM (NSInteger, HRPPhotoState) {
    HRPPhotoStateDone,
    HRPPhotoStateRepeat,
    HRPPhotoStateUpload
};


@interface HRPPhoto : NSObject <NSCoding>

@property (assign, nonatomic) HRPPhotoState state;
@property (strong, nonatomic) NSString *assetsPhotoURL;
@property (strong, nonatomic) NSString *assetsVideoURL;
@property (strong, nonatomic) NSDate *date;
@property (assign, nonatomic) CGFloat latitude;
@property (assign, nonatomic) CGFloat longitude;
@property (assign, nonatomic) BOOL isVideo;

@end
