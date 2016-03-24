//
//  CameraViewController.h
//  LMarker
//
//  Created by Hartisan on 14-12-18.
//  Copyright (c) 2014年 Hartisan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VideoSource.h"
#import "MarkerRecognizer.h"
#import "MarkerAnalyzer.h"
#import "EAGLView.h"
#import "VisualizationController.h"

@interface CameraViewController : UIViewController <VideoSourceDelegate> {
    
    // 摄像机
    VideoSource* _videoSource;
    
    // 控件
    IBOutlet UIButton* _startBtn;
    IBOutlet UIButton* _stopBtn;
    IBOutlet EAGLView* _glView;
    IBOutlet UIButton* _versionBtn;
    
    // 状态
    BOOL _cameraOn;
    BOOL _detectionOn;
    
    
    // 识别器、分析器、GL环境
    MarkerRecognizer* _markerRecognizer;
    MarkerAnalyzer* _markerAnalyzer;
    VisualizationController* _visualizationController;
}

@property (nonatomic, retain) VideoSource* _videoSource;
@property (nonatomic, retain) MarkerRecognizer* _markerRecognizer;
@property (nonatomic, retain) MarkerAnalyzer* _markerAnalyzer;
@property (nonatomic, retain) VisualizationController* _visualizationController;
@property (nonatomic, retain) IBOutlet EAGLView* _glView;
@property (nonatomic, retain) IBOutlet UIButton* _startBtn;
@property (nonatomic, retain) IBOutlet UIButton* _stopBtn;
@property (nonatomic, retain) IBOutlet UIButton* _versionBtn;
@property BOOL _detectionOn;


-(IBAction) startBtnPressed:(id)sender;
-(IBAction) stopBtnPressed:(id)sender;
-(IBAction) versionBtnPressed:(id)sender;

@end
