//
//  CameraViewController.m
//  LMarker
//
//  Created by Hartisan on 14-12-18.
//  Copyright (c) 2014年 Hartisan. All rights reserved.
//

#import "CameraViewController.h"
#import "LPart.h"
#import "Marker.h"

@interface CameraViewController ()

@end

@implementation CameraViewController

@synthesize _videoSource, _markerRecognizer, _startBtn, _stopBtn, _detectionOn, _markerAnalyzer, _glView, _visualizationController, _versionBtn;


- (void)dealloc {
    
    [_videoSource release];
    [_markerRecognizer release];
    [_markerAnalyzer release];
    [_glView release];
    [_visualizationController release];
    [_startBtn release];
    [_stopBtn release];
    [_versionBtn release];
    
    [super dealloc];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //设置进程停止3秒,延长LaunchImage的显示时间
    [NSThread sleepForTimeInterval:2.0];
    
    // 状态初始化
    self._detectionOn = FALSE;
    
    // 初始化识别器
    MarkerRecognizer* markerRecognizer = [[MarkerRecognizer alloc] init];
    self._markerRecognizer = markerRecognizer;
    [markerRecognizer release];
    
    // 初始化分析器
    MarkerAnalyzer* markerAnalyzer = [[MarkerAnalyzer alloc] init];
    self._markerAnalyzer = markerAnalyzer;e:
    [markerAnalyzer release];
    
    // 初始化GL环境
    [self._glView initContext];
    CGSize size = CGSizeMake(480.0, 640.0);
    VisualizationController* vsc = [[VisualizationController alloc] initWithEAGLView:self._glView andFrameSize:size];
    self._visualizationController = vsc;
    [vsc release];
    
    // 摄像头
    VideoSource* videoSource = [[VideoSource alloc] init];
    self._videoSource = videoSource;
    [videoSource release];
    self._videoSource._delegate = self;
    [self._videoSource startWithDevicePosition:AVCaptureDevicePositionBack];
}


// 计时器
/*
 NSDate* tmpStartData = [NSDate date];
 double deltaTime = [[NSDate date] timeIntervalSinceDate:tmpStartData];
 NSLog(@"cost time = %f", deltaTime);
*/


#pragma mark - VideoSourceDelegate
// 对每一帧图像进行处理
-(void)frameReady:(BGRAVideoFrame)frame {
    
    dispatch_sync( dispatch_get_main_queue(), ^{
        
        [self._visualizationController updateBackground:frame];
    });
    
    // 处理图像
    cv::Mat image(frame.height, frame.width, CV_8UC4, frame.data, frame.stride);

    if (!image.empty() && self._detectionOn) {
        
        std::vector<LPart*> allLParts;
        std::vector<Marker*> allMarkers;
        
        // 存放所有marker的变换矩阵和对应的ID
        std::vector<struct TransformationWithID> transformationsWithID;
        
        // 先找是否存在LPart
        allLParts = [self._markerRecognizer findAllLPartsFromImg:image];
        
        // 如果存在LPart，判断是否能组合为Marker
        if (!allLParts.empty()) {

            allMarkers = [self._markerRecognizer findMarkersFromLParts:allLParts];
            
            // 如果存在Marker
            if (!allMarkers.empty()) {
                
                // 对每个marker进行处理
                for (int i = 0; i < allMarkers.size(); ++i) {
                    
                    // 先分析计算投影变换矩阵
                    cv::Mat exMatrix;
                    exMatrix = [self._markerAnalyzer getExternalMatrixFromMarker:allMarkers[i]];
                    
                    // 再把矩阵和ID同时传给GLView
                    int markerID = allMarkers[i]._ID;
                    TransformationWithID t;
                    t.externalMatrix = exMatrix;
                    t.markerID = markerID;
                    transformationsWithID.push_back(t);
                }
            }
        }
        
        // 把变换矩阵和ID传给GL
        self._visualizationController._transformationsWithID = transformationsWithID;
    }
    
    // 绘制
    dispatch_async( dispatch_get_main_queue(), ^{
        
        [self._visualizationController drawFrame];
    });
}


/******************************按钮事件***********************************/
-(IBAction) startBtnPressed:(id)sender {
    
    self._detectionOn = TRUE;
}


-(IBAction) stopBtnPressed:(id)sender {
    
    self._detectionOn = FALSE;
}


-(IBAction) versionBtnPressed:(id)sender {
    
    if (self._markerRecognizer._version == 3) {
        
        self._markerRecognizer._version = 2;
        [self._versionBtn setTitle:@"V3" forState:UIControlStateNormal];
        
    } else {
        
        self._markerRecognizer._version = 3;
        [self._versionBtn setTitle:@"V2" forState:UIControlStateNormal];
    }
}


/******************************系统自带***********************************/
- (NSUInteger) supportedInterfaceOrientations {
    
    // Only portrait orientation
    return UIInterfaceOrientationMaskPortrait;
}


- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
