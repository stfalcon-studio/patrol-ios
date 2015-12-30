//
//  HRPVideoRecordViewModel.h
//  HromadskyiPatrul
//
//  Created by msm72 on 27.12.15.
//  Copyright © 2015 Monastyrskiy Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>


typedef NS_ENUM ( NSInteger, HRPCameraManagerSetupResult ) {
    HRPCameraManagerSetupResultSuccess,
    HRPCameraManagerSetupResultCameraNotAuthorized,
    HRPCameraManagerSetupResultSessionConfigurationFailed
};

typedef NS_ENUM (NSInteger, NSTimerVideoSessionMode) {
    NSTimerVideoSessionModeStream,
    NSTimerVideoSessionModeAttention,
    NSTimerVideoSessionModeDismissed
};


@interface HRPVideoRecordViewModel : AVCaptureSession <CLLocationManagerDelegate, AVCaptureFileOutputRecordingDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate>

@property (strong, nonatomic) NSUserDefaults *userApp;

@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (strong, nonatomic) AVCaptureMovieFileOutput *videoFileOutput;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (assign, nonatomic) AVCaptureVideoOrientation videoOrientation;
@property (strong, nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (assign, nonatomic) HRPCameraManagerSetupResult setupResult;

// ???
@property (strong, nonatomic) AVCaptureConnection *videoConnection;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSString *mediaFolderPath;
@property (strong, nonatomic) NSArray *videoFilesNames;

@property (assign, nonatomic) BOOL isVideoSaving;
@property (assign, nonatomic, getter = isSessionRunning) BOOL sessionRunning;

- (void)createCaptureSession;
- (void)startStreamVideoRecording;
- (void)startAttentionVideoRecording;
- (void)stopVideoSession;
- (void)stopAudioRecording;
- (void)readAllFolderFile;
- (void)removeMediaSnippets;
- (void)removeAllFolderMediaTempFiles;
- (void)extractFirstFrameFromVideoFilePath:(NSURL *)filePathURL;

// Orientation
- (void)setVideoSessionOrientation;
- (void)restartStreamVideoRecording;

// Timer
@property (strong, nonatomic) NSTimer *timer;
@property (assign, nonatomic) NSTimerVideoSessionMode videoSessionMode;

- (void)createTimerWithLabel:(UILabel *)label;
@end
