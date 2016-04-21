//
//  HRPViolationManager.h
//  HromadskyiPatrul
//
//  Created by msm72 on 19.02.16.
//  Copyright © 2016 Monastyrskiy Sergey. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HRPViolation.h"
#import "HRPViolationCell.h"

@interface HRPViolationManager : NSObject

@property (strong, nonatomic) NSUserDefaults *userApp;
@property (strong, nonatomic) NSMutableArray *violations;
@property (strong, nonatomic) NSMutableArray *images;

@property (assign, nonatomic) CGSize cellSize;
@property (assign, nonatomic) NSInteger uploadingCount;
@property (assign, nonatomic) CGFloat videoFileSize;

@property (assign, nonatomic) BOOL isAllowedUploadViolationsWithWiFi;
@property (assign, nonatomic) BOOL isAllowedUploadViolationsAutomatically;
@property (assign, nonatomic) BOOL isAllowedStartAsRecorder;
@property (assign, nonatomic) BOOL isCollectionShow;
@property (assign, nonatomic) BOOL isNetworkAvailable;


+ (HRPViolationManager *)sharedManager;

- (void)customizeManagerSuccess:(void(^)(BOOL isSuccess))success;
- (void)modifyCellSize:(CGSize)size;

- (void)uploadViolation:(HRPViolation *)violation inAutoMode:(BOOL)isAutoMode onSuccess:(void(^)(BOOL isSuccess))success;
- (BOOL)canViolationUploadAuto:(BOOL)isAutoUpload;

- (void)saveViolationsToFile:(NSMutableArray *)violations;
- (void)readViolationsFromFileSuccess:(void(^)(BOOL isSuccess))success;

- (void)getVideoSizeFromInfo:(NSDictionary *)info;
- (void)checkVideoFileSize;

// Only for Debug mode
- (void)removeViolationsFromFile;

@end
