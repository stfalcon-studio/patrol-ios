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


typedef NS_ENUM (NSInteger, HRPCameraManagerSetupResult) {
    HRPCameraManagerSetupResultSuccess,
    HRPCameraManagerSetupResultCameraNotAuthorized,
    HRPCameraManagerSetupResultSessionConfigurationFailed
};

typedef NS_ENUM (NSInteger, NSTimerVideoSessionMode) {
    NSTimerVideoSessionModeStream,
    NSTimerVideoSessionModeViolation,
    NSTimerVideoSessionModeDismissed
};


@interface HRPCameraManager : AVCaptureSession <CLLocationManagerDelegate, AVCaptureFileOutputRecordingDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate>

@property (strong, nonatomic) NSUserDefaults *userApp;

@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureMovieFileOutput *videoFileOutput;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *videoPreviewLayer;

@property (assign, nonatomic) BOOL isVideoSaving;
@property (assign, nonatomic) int sessionDuration;
@property (assign, nonatomic) int violationTime;

+ (HRPCameraManager *)sharedManager;

- (void)createCaptureSession;
- (void)startStreamVideoRecording;
- (void)stopVideoSession;
- (void)removeMediaSnippets;
- (void)readPhotosCollectionFromFile;
- (int)getCurrentTimerValue;

// Orientation
- (void)setVideoPreviewLayerOrientation:(CGSize)newSize;
- (void)setVideoSessionOrientation;
- (void)restartStreamVideoRecording;


// Timer
@property (strong, nonatomic) NSTimer *timer;
@property (assign, nonatomic) NSTimerVideoSessionMode videoSessionMode;

- (void)createTimerWithLabel:(UILabel *)label;

@end
