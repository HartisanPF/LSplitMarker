//
//  NSObject+MarkerAnalyzer.m
//  LMarker
//
//  Created by Hartisan on 15/3/22.
//  Copyright (c) 2015年 Hartisan. All rights reserved.
//

#import "MarkerAnalyzer.h"

@implementation MarkerAnalyzer

@synthesize _i;

-(void) dealloc {
    
    [super dealloc];
}

-(id) init {
    
    return [super init];
}


// 从指定Marker中利用solvePNP方法求解出单应性矩阵
-(cv::Mat) getExternalMatrixFromMarker:(Marker*) marker {
    
    cv::Mat rVector;
    cv::Mat tVector;
    cv::Mat rMatrix;
    
    // 先选择marker中的有效LParts
    std::vector<int> index;
    index = [self analyzeValidLPartsFromMarker:marker];
    
    // 从marker中获得4个图像平面对应点
    std::vector<cv::Point2f> points_2D;
    points_2D = [self getFour2DPointsFromMarker:marker withPartsIndex:index];
    
    // 获得世界坐标系中4个三维对应点
    std::vector<cv::Point3f> points_3D;
    points_3D = [self getFour3DPointsFromMarker:marker WithPartsIndex:index];
    
    /*
    if (_i == 1) {
        
        points_3D[1].x = 0.604;
        points_3D[1].y = 0.0;
        points_3D[2].x = 0.604;
        points_3D[2].y = -0.201;
        points_3D[3].x = 0.0;
        points_3D[3].y = -0.39;
        points_3D[0].x = 0.0;
        points_3D[0].y = 0.0;
    } else if (_i == 2) {
        
        points_3D[1].x = 0.0;
        points_3D[1].y = -0.604;
        points_3D[2].x = -0.202;
        points_3D[2].y = -0.604;
        points_3D[3].x = -0.39;
        points_3D[3].y = 0.0;
        points_3D[0].x = 0.0;
        points_3D[0].y = 0.0;
    } else if (_i == 3) {
        
        points_3D[1].x = -0.604;
        points_3D[1].y = 0.0;
        points_3D[2].x = -0.604;
        points_3D[2].y = 0.202;
        points_3D[3].x = 0.0;
        points_3D[3].y = 0.39;
        points_3D[0].x = 0.0;
        points_3D[0].y = 0.0;
    } else if (_i == 4) {
        
        points_3D[1].x = 0.0;
        points_3D[1].y = 0.684;
        points_3D[2].x = 0.201;
        points_3D[2].y = 0.684;
        points_3D[3].x = 0.39;
        points_3D[3].y = 0.0;
        points_3D[0].x = 0.0;
        points_3D[0].y = 0.0;
    }
    */
    // 摄像头内参矩阵
    cv::Mat camera_K;
    camera_K = [self getCameraIntrinsicParamMatrix].clone();
    
    // 摄像头畸变
    cv::Mat distCoeffs;
    distCoeffs = [self getCameraDistCoeffs].clone();
    
    // 利用solvePNP方法求解旋转与平移向量
    cv::solvePnP(points_3D, points_2D, camera_K, distCoeffs, rVector, tVector);
    
    // 利用罗德里格斯方法把旋转向量等效为矩阵
    cv::Rodrigues(rVector, rMatrix);
    
    // 把平移和旋转组合为一个3x4(R|T)矩阵
    cv::Mat externalMatrix = [self matrixCombiningTrans:tVector andRot:rMatrix].clone();

    return externalMatrix;
}


// 从Marker中分析出有效的LParts,以决定注册时利用哪些Part的角点
-(std::vector<int>) analyzeValidLPartsFromMarker:(Marker*) marker {
    
    std::vector<int> validIndex;
    std::vector<int> detectedIndex;
    
    // 先筛选出真正检测到的Parts
    for (int i = 0; i < 4; ++i) {
        
        if ([marker getFlagAtIndex:i]) {
            
            detectedIndex.push_back(i);
        }
    }
    /*
    // 获得每个Part的法向矢量
    std::vector<cv::Point3f> normalVectors;
    
    for (int i = 0; i < detectedIndex.size(); ++i) {
        
        int index = detectedIndex[i];
        std::vector<int> singleIndex;
        singleIndex.push_back(index);
        
        std::vector<cv::Point2f> points_2D = [self getFour2DPointsFromMarker:marker withPartsIndex:singleIndex];
        std::vector<cv::Point3f> points_3D = [self getFour3DPointsFromMarker:marker WithPartsIndex:singleIndex];
        cv::Mat camera_K = [self getCameraIntrinsicParamMatrix].clone();
        cv::Mat distCoeffs = [self getCameraDistCoeffs].clone();
        cv::Mat rVector;
        cv::Mat tVector;
        cv::Mat rMatrix;
        cv::solvePnP(points_3D, points_2D, camera_K, distCoeffs, rVector, tVector);
        cv::Rodrigues(rVector, rMatrix);
        
        cv::Point3f normalVec;
        normalVec.x = rMatrix.at<double>(0, 2);
        normalVec.y = rMatrix.at<double>(1, 2);
        normalVec.z = rMatrix.at<double>(2, 2);
        
        normalVectors.push_back(normalVec);
    }
    */
    
    // 再根据法矢方向（夹角）对检测到的Parts进行弯曲分析,需要根据实际需求订制分析，暂时懒得分析了
    validIndex = detectedIndex;
    
    //validIndex.push_back(_i);
    //_i ++;
    return validIndex;
}


// 从指定Marker中获得4个图像平面对应点（同时指定用到的LParts索引）
-(std::vector<cv::Point2f>) getFour2DPointsFromMarker:(Marker*) marker withPartsIndex:(std::vector<int>) index {
    
    std::vector<cv::Point2f> imgPoints;
    cv::Point2f pt0;
    cv::Point2f pt1;
    cv::Point2f pt2;
    cv::Point2f pt3;
    
    if (index.size() == 1) {
    
        // 如果只用到其中1个LPart,则用其0，1，2，5号角点
        pt0 = marker._LParts[index[0]]._corners[0];
        pt1 = marker._LParts[index[0]]._corners[1];
        pt2 = marker._LParts[index[0]]._corners[2];
        pt3 = marker._LParts[index[0]]._corners[5];
        
    } else if (index.size() == 2) {
        
        // 如果用到其中2个LPart，则用每个LPart的0，2角点
        pt0 = marker._LParts[index[0]]._corners[0];
        pt1 = marker._LParts[index[0]]._corners[2];
        pt2 = marker._LParts[index[1]]._corners[0];
        pt3 = marker._LParts[index[1]]._corners[2];
        
    } else if (index.size() == 3) {
        
        // 如果用到其中3个LPart，则用第一个Part的0，2角点，以及其余两个的0角点
        pt0 = marker._LParts[index[0]]._corners[0];
        pt1 = marker._LParts[index[0]]._corners[2];
        pt2 = marker._LParts[index[1]]._corners[0];
        pt3 = marker._LParts[index[2]]._corners[0];
        
    } else {
        
        // 如果用到其中4个LPart，则用每个Part的0角点
        pt0 = marker._LParts[index[0]]._corners[0];
        pt1 = marker._LParts[index[1]]._corners[0];
        pt2 = marker._LParts[index[2]]._corners[0];
        pt3 = marker._LParts[index[3]]._corners[0];
    }
    
    imgPoints.push_back(pt0);
    imgPoints.push_back(pt1);
    imgPoints.push_back(pt2);
    imgPoints.push_back(pt3);
    
    return imgPoints;
}


// 获得世界坐标系下4个对应点（根据指定的LParts索引）
-(std::vector<cv::Point3f>) getFour3DPointsFromMarker:(Marker*) marker WithPartsIndex:(std::vector<int>) index {
    
    std::vector<cv::Point3f> worldPoints;
    cv::Point3f pt0;
    cv::Point3f pt1;
    cv::Point3f pt2;
    cv::Point3f pt3;
    
    if (index.size() == 1) {
        
        // 如果只用到其中1个LPart,则用其0，1，2，5号角点
        pt0 = [marker get3DPointAt:0 ofPart:index[0]];
        pt1 = [marker get3DPointAt:1 ofPart:index[0]];
        pt2 = [marker get3DPointAt:2 ofPart:index[0]];
        pt3 = [marker get3DPointAt:5 ofPart:index[0]];
        
    } else if (index.size() == 2) {
        
        // 如果用到其中2个LPart，则用每个LPart的0，2角点
        pt0 = [marker get3DPointAt:0 ofPart:index[0]];
        pt1 = [marker get3DPointAt:2 ofPart:index[0]];
        pt2 = [marker get3DPointAt:0 ofPart:index[1]];
        pt3 = [marker get3DPointAt:2 ofPart:index[1]];
        
    } else if (index.size() == 3) {
        
        // 如果用到其中3个LPart，则用第一个Part的0，2角点，以及其余两个的0角点
        pt0 = [marker get3DPointAt:0 ofPart:index[0]];
        pt1 = [marker get3DPointAt:2 ofPart:index[0]];
        pt2 = [marker get3DPointAt:0 ofPart:index[1]];
        pt3 = [marker get3DPointAt:0 ofPart:index[2]];
        
    } else {
        
        // 如果用到其中4个LPart，则用每个Part的0角点
        pt0 = [marker get3DPointAt:0 ofPart:index[0]];
        pt1 = [marker get3DPointAt:0 ofPart:index[1]];
        pt2 = [marker get3DPointAt:0 ofPart:index[2]];
        pt3 = [marker get3DPointAt:0 ofPart:index[3]];
    }
    
    worldPoints.push_back(pt0);
    worldPoints.push_back(pt1);
    worldPoints.push_back(pt2);
    worldPoints.push_back(pt3);
    
    return worldPoints;
}


// 获得摄像头内参矩阵
-(cv::Mat) getCameraIntrinsicParamMatrix {
    
    cv::Mat K(3, 3, CV_64F, 0.0f);
    
    // iphone6
    double fy = 553.164794921875;
    double fx = 551.99029541015625;
    double cy = 320.7960205078125;
    double cx = 240.441925048828125;
    
    K.at<double>(0, 0) = fx;
    K.at<double>(1, 1) = fy;
    K.at<double>(0, 2) = cx;
    K.at<double>(1, 2) = cy;
    K.at<double>(2, 2) = 1.0f;
    
    return K;
}


// 获得摄像头畸变矩阵
-(cv::Mat) getCameraDistCoeffs {
    
    // iphone6
    cv::Mat distCoeffs(1, 4, CV_64F, 0.0f);
    
    return distCoeffs;
}


// 把平移和旋转组合为一个3*4(R|T)矩阵
-(cv::Mat) matrixCombiningTrans:(cv::Mat)T andRot:(cv::Mat)R {
    
    cv::Mat matrix(3, 4, CV_64F);
    
    for (int i = 0; i < 3; ++i) {
        
        for (int j = 0; j < 4; ++j) {
            
            if (j < 3) {
                
                matrix.at<double>(i, j) = R.at<double>(i, j);
                
            } else {
                
                matrix.at<double>(i, j) = T.at<double>(i, 0);
            }
        }
    }
    
    return matrix;
}

@end
