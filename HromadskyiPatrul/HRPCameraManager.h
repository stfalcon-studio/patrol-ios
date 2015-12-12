//
//  HRPCameraManager.h
//  HromadskyiPatrul
//
//  Created by msm72 on 12.12.15.
//  Copyright © 2015 Monastyrskiy Sergey. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>


@interface HRPCameraManager : AVCaptureSession <AVCaptureFileOutputRecordingDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate>

@property (strong, nonatomic) NSUserDefaults *userApp;

@property (strong, nonatomic) AVCaptureMovieFileOutput *videoFileOutput;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (strong, nonatomic) NSString *mediaFolderPath;
@property (strong, nonatomic) NSArray *videoFilesNames;

@property (assign, nonatomic) NSInteger sessionDuration;
@property (assign, nonatomic) NSInteger snippetNumber;
@property (assign, nonatomic) BOOL isVideoSaving;

+ (HRPCameraManager *)sharedManager;

- (void)startVideoSession;
- (void)startStreamVideoRecording;
- (void)stopVideoSession;
- (void)stopAudioRecording;

- (void)readAllFolderFile;
- (void)removeMediaSnippets;
- (void)removeAllFolderMediaTempFiles;
- (void)extractFirstFrameFromVideoFilePath:(NSURL *)filePathURL;
    
@end
