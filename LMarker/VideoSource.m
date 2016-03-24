//
//  VideoSource.m
//  LMarkerV2
//
//  Created by Hartisan on 15/5/9.
//  Copyright (c) 2015年 Hartisan. All rights reserved.
//

#import <ImageIO/ImageIO.h>
#import <CoreVideo/CoreVideo.h>
#import <UIKit/UIKit.h>
#import "VideoSource.h"


@implementation VideoSource

@synthesize _captureSession, _deviceInput, _delegate;


- (void)dealloc {
    
    [_captureSession release];
    [_deviceInput release];
    self._delegate = nil;
    [super dealloc];
}


- (id)init {
    
    if (self = [super init])
    {
        _captureSession = [[AVCaptureSession alloc] init];
        if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset640x480])
        {
            [_captureSession setSessionPreset:AVCaptureSessionPreset640x480];
            NSLog(@"Set capture session preset AVCaptureSessionPreset640x480");
        }else if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetLow])
        {
            [_captureSession setSessionPreset:AVCaptureSessionPresetLow];
            NSLog(@"Set capture session preset AVCaptureSessionPresetLow");
        }
    }
    return self;
}


// 外部调用，启动相机
- (bool) startWithDevicePosition:(AVCaptureDevicePosition)devicePosition {
    
    AVCaptureDevice* device = [self cameraWithPosition:devicePosition];
    if (!device) return FALSE;
    
    NSError* error = nil;
    AVCaptureDeviceInput* input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    self._deviceInput = input;
    
    if (!error)//初始化没有发生错误
    {
        if ([[self _captureSession] canAddInput:self._deviceInput])
        {
            [[self _captureSession] addInput:self._deviceInput];
        }else
        {
            NSLog(@"Couldn't add video input");
            return FALSE;
        }
    }else
    {
        NSLog(@"Couldn't create video input");
        return FALSE;
    }
    //添加输出
    [self addRawViewOutput];
    
    //开始视频捕捉
    [_captureSession startRunning];
    
    return TRUE;
}


// 获取相机
- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition)position {
    
    NSArray* devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == position)
        {
            return device;
        }
    }
    return nil;
}

// 获得图像尺寸
- (CGSize) getFrameSize
{
    if (![_captureSession isRunning])
        NSLog(@"Capture session is not running, getFrameSize will return invalid valies");
    
    NSArray *ports = [_deviceInput ports];
    AVCaptureInputPort *usePort = nil;
    for ( AVCaptureInputPort *port in ports )
    {
        if ( usePort == nil || [port.mediaType isEqualToString:AVMediaTypeVideo] )
        {
            usePort = port;
        }
    }
    
    if ( usePort == nil ) return CGSizeZero;
    
    CMFormatDescriptionRef format = [usePort formatDescription];
    CMVideoDimensions dim = CMVideoFormatDescriptionGetDimensions(format);
    
    CGSize cameraSize = CGSizeMake(dim.width, dim.height);
    
    return cameraSize;
}


// 添加输出
- (void)addRawViewOutput {
    
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    
    //同一时间只处理一帧，否则no
    output.alwaysDiscardsLateVideoFrames = YES;
    
    //创建操作队列
    dispatch_queue_t queue;
    queue = dispatch_queue_create("com.LMarker.VideoSource", nil);
    
    [output setSampleBufferDelegate:self queue:queue];
    dispatch_release(queue);
    
    NSString *keyString = (NSString *)kCVPixelBufferPixelFormatTypeKey;
    NSNumber *value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    
    NSDictionary *setting = [NSDictionary dictionaryWithObject:value forKey:keyString];
    [output setVideoSettings:setting];
    
    if ([self._captureSession canAddOutput:output])
    {
        [self._captureSession addOutput:output];
    }
    
    [output release];
}


#pragma -mark AVCaptureOutput delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    //给图像加把锁
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    size_t stride = CVPixelBufferGetBytesPerRow(imageBuffer);

    BGRAVideoFrame frame = {width, height, stride, baseAddress};
    [_delegate frameReady:frame];
    
    //解锁
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
}


- (NSUInteger) supportedInterfaceOrientations {
    
    return UIInterfaceOrientationMaskPortrait;
}

@end

