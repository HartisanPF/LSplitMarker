//
//  UIViewController+VisualizationController.h
//  LMarkerV2
//
//  Created by Hartisan on 15/5/11.
//  Copyright (c) 2015年 Hartisan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EAGLView.h"
#import "VideoSourceDelegate.h"

struct TransformationWithID {
    
    cv::Mat externalMatrix;
    int markerID;
};

@interface VisualizationController : UIViewController {
    
    EAGLView* _glView;
    GLuint _backgroundTextureId;
    CGSize _frameSize;
    std::vector<struct TransformationWithID> _transformationsWithID;
}

@property (nonatomic, retain) EAGLView* _glView;
@property std::vector<struct TransformationWithID> _transformationsWithID;

-(id)initWithEAGLView:(EAGLView*)eaglView andFrameSize:(CGSize)size;
-(void)updateBackground:(BGRAVideoFrame)frame;
-(void)drawBackground;
-(void)drawFrame;
-(void)drawModels;
-(void)getProjectionMatrix:(float*)projectionMatrix withFx:(double)fx  Fy:(double)fy
                         Cx:(double)cx  Cy:(double)cy
                          W:(float)width H:(float)height
                          N:(float)near  F:(float)far;
-(void)getModelViewMatrix:(float*)matrix fromExternalMat:(cv::Mat)mat;

@end
