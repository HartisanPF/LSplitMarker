//
//  MarkerAnalyzer.h
//  LMarker
//
//  Created by Hartisan on 15/3/22.
//  Copyright (c) 2015年 Hartisan. All rights reserved.
//

#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#endif

#import <Foundation/Foundation.h>
#import "MarkerRecognizer.h"

@interface MarkerAnalyzer : NSObject {

    int _i;
    
}

@property int _i;

-(cv::Mat) getExternalMatrixFromMarker:(Marker*) marker;
-(std::vector<int>) analyzeValidLPartsFromMarker:(Marker*) marker;
-(std::vector<cv::Point2f>) getFour2DPointsFromMarker:(Marker*) marker withPartsIndex:(std::vector<int>) index;
-(std::vector<cv::Point3f>) getFour3DPointsFromMarker:(Marker*) marker WithPartsIndex:(std::vector<int>) index;
-(cv::Mat) getCameraIntrinsicParamMatrix;
-(cv::Mat) getCameraDistCoeffs;
-(cv::Mat) matrixCombiningTrans:(cv::Mat)T andRot:(cv::Mat)R;


@end
