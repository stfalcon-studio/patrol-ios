/*
 Copyright (c) 2015 - 2016. Stepan Tanasiychuk
 This file is part of Gromadskyi Patrul is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by the Free Software Found ation, version 3 of the License, or any later version.
 If you would like to use any part of this project for commercial purposes, please contact us
 for negotiating licensing terms and getting permission for commercial use. Our email address: info@stfalcon.com
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.
 You should have received a copy of the GNU General Public License along with this program.
 If not, see http://www.gnu.org/licenses/.
 */
// https://github.com/stfalcon-studio/patrol-android/blob/master/app/build.gradle
//
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
