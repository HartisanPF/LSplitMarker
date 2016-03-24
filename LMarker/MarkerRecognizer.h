//
//  MarkerRecognizer.h
//  LMarker
//
//  Created by Hartisan on 14-12-18.
//  Copyright (c) 2014年 Hartisan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <opencv2/imgproc/types_c.h>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/imgproc.hpp>
#import <opencv2/highgui.hpp>
#import <opencv2/core/core.hpp>
#import "LPart.h"
#import "Marker.h"

@interface MarkerRecognizer : NSObject {
    
    int _version;
}

@property int _version;

/************************************************** 查找LPart **************************************************/
-(std::vector<LPart*>) findAllLPartsFromImg:(cv::Mat&)image;
-(BOOL) isParallelVerified:(std::vector<cv::Point>)poly;
-(std::vector<cv::Point2f>) clockwisePoly:(std::vector<cv::Point>)poly;
-(BOOL) isEqualBetweenPolyA:(std::vector<cv::Point2f>)polyA andPolyB:(std::vector<cv::Point2f>)polyB;
-(std::vector<LPart*>) deleteDuplicateLPartsOf:(std::vector<LPart*>)allLParts;
-(cv::Point2f) getIntersectionOfLinesDeterminedByPointA:(cv::Point2f)ptA andB:(cv::Point2f)ptB andC:(cv::Point2f)ptC andD:(cv::Point2f)ptD;
-(float) distanceBetweenPointA:(cv::Point2f)ptA andB:(cv::Point2f)ptB;
-(float) crossRatioOfPointA:(cv::Point2f)ptA andB:(cv::Point2f)ptB andC:(cv::Point2f)ptC andD:(cv::Point2f)ptD;
-(int) decodeSeqfromLPart:(LPart*)L;
-(int) decodeSeqfromStableLPart:(LPart*)L withImg:(cv::Mat&)grayImg;
-(int) decodeInfofromLPart:(LPart*)L withImg:(cv::Mat&)grayImg andSeq:(int)seqCode;
-(int) decodeInfofromStableLPart:(LPart*)L withImg:(cv::Mat&)grayImg andSeq:(int)seqCode;
-(UIImage*) UIImageFromCVMat:(cv::Mat)cvMat;
-(void) threshTest:(cv::Mat&)image;


/*********************************************** 组合LPart为Marker **********************************************/
-(std::vector<Marker*>) findMarkersFromLParts:(std::vector<LPart*>)allLParts;
-(cv::Point2d) findNextPartOfCurrentPos:(cv::Point2d)pos inSortedParts:(std::vector<std::vector<LPart*>>)sortedParts;
-(cv::Point2d) findPreviousPartOfCurrentPos:(cv::Point2d)pos inSortedParts:(std::vector<std::vector<LPart*>>)sortedParts;
-(bool) isPart:(LPart*)partNext NextOfPart:(LPart*)partPre;
-(BOOL) isPart:(LPart*)partPre PreOfPart:(LPart*)partNext;
-(float) distanceBetweenPoint:(cv::Point2f)pt andLineDeterminedByPoint:(cv::Point2f)ptA andPoint:(cv::Point2f)ptB;

@end
