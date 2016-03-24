//
//  VideoSource.h
//  LMarkerV2
//
//  Created by Hartisan on 15/5/9.
//  Copyright (c) 2015年 Hartisan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import "VideoSourceDelegate.h"

@interface VideoSource : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>
{
    
}

@property (nonatomic, retain) AVCaptureSession* _captureSession;
@property (nonatomic, retain) AVCaptureDeviceInput* _deviceInput;
@property (nonatomic, assign) id<VideoSourceDelegate> _delegate;

- (bool) startWithDevicePosition:(AVCaptureDevicePosition)devicePosition;
- (CGSize) getFrameSize;

@end
