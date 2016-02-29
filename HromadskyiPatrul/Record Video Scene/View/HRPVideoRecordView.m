//
//  HRPVideoRecordView.m
//  HromadskyiPatrul
//
//  Created by msm72 on 16.12.15.
//  Copyright © 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPVideoRecordView.h"


@import AVFoundation;


@implementation HRPVideoRecordView

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureSession *)session {
    AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.layer;
    
    return previewLayer.session;
}

- (void)setSession:(AVCaptureSession *)session {
    AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.layer;
    
    previewLayer.session = session;
}

@end
