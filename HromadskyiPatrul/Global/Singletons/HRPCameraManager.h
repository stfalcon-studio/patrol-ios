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
//  HRPCameraManager.h
//  HromadskyiPatrul
//
//  Created by msm72 on 12.12.15.
//  Copyright © 2015 Monastyrskiy Sergey. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>
#import "HRPLocations.h"


#if DEVELOPMENT
#define DebugLog(...) NSLog(__VA_ARGS__)
#else
#define DebugLog(...)
#endif

typedef NS_ENUM (NSInteger, HRPCameraManagerSetupResult) {
    HRPCameraManagerSetupResultSuccess,
    HRPCameraManagerSetupResultCameraNotAuthorized,
    HRPCameraManagerSetupResultSessionConfigurationFailed
};

typedef NS_ENUM (NSInteger, NSTimerVideoSessionMode) {
    NSTimerVideoSessionModeStream,
    NSTimerVideoSessionModeViolation,
    NSTimerVideoSessionModeMergeAndSave,
    NSTimerVideoSessionModeDismissed
};


@interface HRPCameraManager : AVCaptureSession <CLLocationManagerDelegate, AVCaptureFileOutputRecordingDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate>

@property (strong, nonatomic) NSUserDefaults *userApp;

@property (strong, nonatomic) HRPLocations *locationsService;

@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureMovieFileOutput *videoFileOutput;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *videoPreviewLayer;

@property (strong, nonatomic) NSMutableArray *violations;
@property (strong, nonatomic) NSMutableArray *images;
@property (strong, nonatomic) UIImage *videoImageOriginal;
@property (strong, nonatomic) AVAudioSession *audioSession;

@property (strong, nonatomic) NSURL *videoFileURL;
@property (strong, nonatomic) UILabel *timerLabel;

@property (assign, nonatomic) BOOL isVideoSaving;
@property (assign, nonatomic) int sessionDuration;
@property (assign, nonatomic) int violationTime;

+ (HRPCameraManager *)sharedManager;

- (void)createCaptureSession;
- (void)startStreamVideoRecording;
- (void)stopVideoSession;
- (void)stopVideoRecording;
- (void)removeMediaSnippets;
- (void)removeAllFolderMediaTempFiles;
//- (void)readPhotosCollectionFromFile;
- (int)getCurrentTimerValue;

// Orientation
- (void)setVideoPreviewLayerOrientation:(CGSize)newSize;
- (void)setVideoSessionOrientation;
- (void)restartStreamVideoRecording;


// Timer
@property (strong, nonatomic) NSTimer *timer;
@property (assign, nonatomic) NSTimerVideoSessionMode videoSessionMode;

- (void)timerTicked:(NSTimer *)timer;
- (void)createTimer; //WithLabel:(UILabel *)label;
//- (void)createTimerWithLabel:(UILabel *)label;

@end
