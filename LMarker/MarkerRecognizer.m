//
//  MarkerRecognizer.m
//  LMarker
//
//  Created by Hartisan on 14-12-18.
//  Copyright (c) 2014年 Hartisan. All rights reserved.
//

#import "MarkerRecognizer.h"


#define MIN_CONTOUR_SIZE_THRESH 100.0
#define MAX_CONTOUR_SIZE_THRESH 400.0
#define PARALLEL_K_THRESH 0.25
#define CROSSRATIO_0 2.28
#define CROSSRATIO_1 1.87
#define CROSSRATIO_2 3.32
#define CROSSRATIO_3 1.63
#define CROSSRATIO_ERROR 0.14
#define LPART_WIDTH_INFO 36
#define LPART_HEIGHT_INFO 12.0
#define LPART_WIDTH_SEQ 13.0
#define LPART_HEIGHT_SEQ 12.0
#define DISTANCE_TO_LINE_THRESH 5.0

@implementation MarkerRecognizer

@synthesize _version;


-(void) dealloc {
    
    [super dealloc];
}

-(id) init {
    
    self._version = 3;
    return [super init];
}

/************************************************** 查找LPart **************************************************/

// 在图像中寻找所有可能的LPart
-(std::vector<LPart*>) findAllLPartsFromImg:(cv::Mat&)image {
    
    cv::Mat gray;
    cv::Mat edges;
    cv::Mat image_copy = image;

    // 灰度化
    cv::cvtColor(image_copy, gray, CV_BGR2GRAY);
    
    // 阈值化
    cv::adaptiveThreshold(gray, edges, 255, CV_ADAPTIVE_THRESH_MEAN_C, CV_THRESH_BINARY, 51, 0);
    //cv::threshold(gray, edges, 50, 255, cv::THRESH_OTSU);
    
    // 查找轮廓
    std::vector<std::vector<cv::Point>> allContours;
    cv::findContours(edges, allContours, CV_RETR_LIST, CV_CHAIN_APPROX_NONE);

    // 筛选轮廓
    std::vector<cv::Point> approxPoly;
    std::vector<LPart*> allLParts;
    std::vector<LPart*> allLParts_unique;

    
    for (int i = 0; i < allContours.size(); ++i) {
        
        // 剔除过小的轮廓
        if (allContours[i].size() < MIN_CONTOUR_SIZE_THRESH) {
            
            continue;
        }
        
        // 多边形近似，顶点数为6才有可能是marker
        cv::approxPolyDP(allContours[i], approxPoly, cv::arcLength(allContours[i], true) * 0.02, true);
        if (approxPoly.size() != 6) {
            
            continue;
        }

        // 并且是凹多边形
        if (cv::isContourConvex(allContours[i])) {
            
            continue;
        }
        
        // 并且对边近似平行
        if (![self isParallelVerified:approxPoly]) {
            
            continue;
        }

        // 将6个顶点重新排序后保存到allLParts容器中
        std::vector<cv::Point2f> clockwisedPoly = [self clockwisePoly:approxPoly];
        // 亚像素提取
        cv::cornerSubPix(gray, clockwisedPoly, cv::Size(5, 5), cv::Size(-1, -1), cv::TermCriteria(CV_TERMCRIT_ITER, 20, 0.1));
        
        LPart* L = [[[LPart alloc] init] retain];
        L._corners = clockwisedPoly;
        allLParts.push_back(L);
        [L release];
        
        // 画轮廓
        //cv::drawContours(image, allContours, i, cv::Scalar(255, 255, 0));
    }

    // 对所有检测到的L形状进行解码与校验
    if (!allLParts.empty()) {
        
        allLParts = [self deleteDuplicateLPartsOf:allLParts];
        
        // 解码
        int seqCode;
        int infoCode;
        for (int i = 0; i < allLParts.size(); i++) {

            // 先解顺序码
            //seqCode = [self decodeSeqfromLPart:allLParts[i]];
            seqCode = [self decodeSeqfromStableLPart:allLParts[i] withImg:gray];
            
            // 再解信息码同时校验
            if (seqCode != -1) {
                
                //infoCode = [self decodeInfofromLPart:allLParts[i] withImg:gray andSeq:seqCode];
                infoCode = [self decodeInfofromStableLPart:allLParts[i] withImg:gray andSeq:seqCode];
            }

            // 如果校验成功则把信息保存
            if (seqCode != -1 && infoCode != -1) {
                
                allLParts[i]._seqCode = seqCode;
                allLParts[i]._infoCode = infoCode;
                allLParts_unique.push_back(allLParts[i]);
            }
        }
    }
    
    return allLParts_unique;
}


// 判断六边形的对边是否近似平行
-(BOOL) isParallelVerified:(std::vector<cv::Point>)poly {
    
    BOOL result = NO;
    
    // 获得6条边的斜率绝对值的反正切值
    float k[6];
    
    for(int i = 0; i < 6; ++i) {
        
        if (i != 5) {
            
            if (poly[i+1].x - poly[i].x == 0) {
                
                k[i] = 1.57079;
                
            } else {
                
                k[i] = atanf(fabsf((float)( poly[i+1].y - poly[i].y ) / ( poly[i+1].x - poly[i].x )));
            }
            
        } else {
            
            if (poly[0].x - poly[i].x == 0) {
                
                k[i] = 1.57079;
                
            } else {
                
                k[i] = atanf(fabsf((float)( poly[0].y - poly[i].y ) / ( poly[0].x - poly[i].x )));
            }
        }
    }
    
    // 比较对边斜率
    int count = 0;
    for (int i = 0; i < 6; ++i) {
        
        if (i < 4) {
            
            if (fabsf(k[i] - k[i+2]) < PARALLEL_K_THRESH) {
                
                count++;
            }
            
        } else if (i == 4) {
            
            if (fabsf(k[i] - k[0]) < PARALLEL_K_THRESH) {
                
                count++;
            }
            
        } else if (i == 5) {
            
            if (fabsf(k[i] - k[1]) < PARALLEL_K_THRESH) {
                
                count++;
            }
        }
    }
    
    if (count == 6) {
        
        result = YES;
    }
    
    return result;
}


// 把6个点按照约定的顺时针方向重新排序
-(std::vector<cv::Point2f>) clockwisePoly:(std::vector<cv::Point>)poly {
    
    std::vector<cv::Point2f> newPoly;
    float rangeLeft;
    float rangeRight;
    float maxRangeLeft = 0.0;
    float maxRangeRight = 0.0;
    int index = 0;
    
    // 找"0"点
    for (int i = 0; i < 6; ++i) {
        
        if (i == 0) {
            
            rangeLeft = sqrtf( (poly[i].x - poly[5].x) * (poly[i].x - poly[5].x) + (poly[i].y - poly[5].y) * (poly[i].y - poly[5].y));
            rangeRight = sqrtf( (poly[i].x - poly[i+1].x) * (poly[i].x - poly[i+1].x) + (poly[i].y - poly[i+1].y) * (poly[i].y - poly[i+1].y));
            
        } else if (i == 5) {
            
            rangeLeft = sqrtf( (poly[i].x - poly[i-1].x) * (poly[i].x - poly[i-1].x) + (poly[i].y - poly[i-1].y) * (poly[i].y - poly[i-1].y));
            rangeRight = sqrtf( (poly[i].x - poly[0].x) * (poly[i].x - poly[0].x) + (poly[i].y - poly[0].y) * (poly[i].y - poly[0].y));
            
        } else {
            
            rangeLeft = sqrtf( (poly[i].x - poly[i-1].x) * (poly[i].x - poly[i-1].x) + (poly[i].y - poly[i-1].y) * (poly[i].y - poly[i-1].y));
            rangeRight = sqrtf( (poly[i].x - poly[i+1].x) * (poly[i].x - poly[i+1].x) + (poly[i].y - poly[i+1].y) * (poly[i].y - poly[i+1].y));
            
        }
        
        if (rangeLeft + rangeRight > maxRangeLeft + maxRangeRight) {
            
            maxRangeLeft = rangeLeft;
            maxRangeRight = rangeRight;
            index = i;
        }
    }
    
    // 根据"0"点左右两点距离关系，重新排序并返回
    if (maxRangeRight > maxRangeLeft) {
        
        for (int i = 0; i < 6; ++i) {
            
            if (index + i > 5 ) {
                
                newPoly.push_back(poly[index + i - 6]);
                
            } else {
                
                newPoly.push_back(poly[index + i]);
                
            }
        }
    } else {
        
        for (int i = 0; i < 6; ++i) {
            
            if (index - i < 0 ) {
                
                newPoly.push_back(poly[index - i + 6]);
                
            } else {
                
                newPoly.push_back(poly[index - i]);
                
            }
        }
    }
    
    return newPoly;
}


// 判断两组顶点是否一样，用于剔除重复轮廓
-(BOOL) isEqualBetweenPolyA:(std::vector<cv::Point2f>)polyA andPolyB:(std::vector<cv::Point2f>)polyB {
    
    BOOL result = FALSE;
    int sizeA = (int)polyA.size();
    int sizeB = (int)polyB.size();
    
    if (sizeA != sizeB) {
        
        return result;
    } else {
        
        int count = 0;
        for (int i = 0; i < sizeA; ++i) {
            
            if (fabsf(polyA[i].x - polyB[i].x) <= 5.0 && fabsf(polyA[i].y - polyB[i].y) <= 5.0) {

                count++;
            }
        }
        if (count == sizeA) {
            
            result = TRUE;
        }
    }
    
    return result;
}


// 在LParts集合中删除重复轮廓顶点
-(std::vector<LPart*>) deleteDuplicateLPartsOf:(std::vector<LPart*>)allLParts {
    
    std::vector<LPart*> finalLParts;
    
    for (int i = 0; i < allLParts.size() - 1; ++i) {
        
        int count = 0;
        for (int j = i + 1; j < allLParts.size(); ++j) {
            
            if ([self isEqualBetweenPolyA:allLParts[i]._corners andPolyB:allLParts[j]._corners]) {

                count = count + 1;
                break;
            }
        }
        
        if (count == 0) {

            finalLParts.push_back(allLParts[i]);
        }
    }
    
    finalLParts.push_back(allLParts[allLParts.size() - 1]);

    return finalLParts;
}


// 根据两对点求两直线的交点
-(cv::Point2f) getIntersectionOfLinesDeterminedByPointA:(cv::Point2f)ptA andB:(cv::Point2f)ptB andC:(cv::Point2f)ptC andD:(cv::Point2f)ptD {
    
    cv::Point2f intersection;
    float k1, k2, b1, b2;
    
    if (sqrtf(ptA.x - ptB.x) < 0.1) {
        
        k2 = (ptD.y - ptC.y) / (ptD.x - ptC.x);
        b2 = ptC.y - k2 * ptC.x;
        intersection.x = ptA.x;
        intersection.y = k2 * ptA.x + b2;
        
    } else if (sqrtf(ptC.x - ptD.x) < 0.1) {
        
        k1 = (ptB.y - ptA.y) / (ptB.x - ptA.x);
        b1 = ptA.y - k1 * ptA.x;
        intersection.x = ptC.x;
        intersection.y = k1 * ptC.x + b1;
        
    } else {
        
        k1 = (ptB.y - ptA.y) / (ptB.x - ptA.x);
        b1 = ptA.y - k1 * ptA.x;
        k2 = (ptD.y - ptC.y) / (ptD.x - ptC.x);
        b2 = ptC.y - k2 * ptC.x;
        
        intersection.x = (b2 - b1) / (k1 - k2);
        intersection.y = k1 * intersection.x + b1;
    }
    
    return intersection;
}


// 计算两点距离
-(float) distanceBetweenPointA:(cv::Point2f)ptA andB:(cv::Point2f)ptB {
    
    float distance;
    
    distance = sqrtf((ptA.x - ptB.x) * (ptA.x - ptB.x) + (ptA.y - ptB.y) * (ptA.y - ptB.y));
    
    return distance;
}


// 计算四点交比
-(float) crossRatioOfPointA:(cv::Point2f)ptA andB:(cv::Point2f)ptB andC:(cv::Point2f)ptC andD:(cv::Point2f)ptD {
    
    float AC = [self distanceBetweenPointA:ptA andB:ptC];
    float BC = [self distanceBetweenPointA:ptB andB:ptC];
    float AD = [self distanceBetweenPointA:ptA andB:ptD];
    float BD = [self distanceBetweenPointA:ptB andB:ptD];
    float crossRatio = AC * BD / BC / AD;
    
    return  crossRatio;
}


// 解码LPart，返回顺序码
-(int) decodeSeqfromLPart:(LPart*)L {
    
    // 获得6个图形角点及2个辅助交点
    cv::Point2f pt0 = L._corners[0];
    cv::Point2f pt1 = L._corners[1];
    cv::Point2f pt2 = L._corners[2];
    cv::Point2f pt3 = L._corners[3];
    cv::Point2f pt4 = L._corners[4];
    cv::Point2f pt5 = L._corners[5];
    cv::Point2f pt7 = [self getIntersectionOfLinesDeterminedByPointA:pt1 andB:pt5 andC:pt3 andD:pt4];
    cv::Point2f pt8 = [self getIntersectionOfLinesDeterminedByPointA:pt1 andB:pt5 andC:pt2 andD:pt3];
    
    // 根据交比判断是第几号LPart
    double crossRatio = [self crossRatioOfPointA:pt5 andB:pt7 andC:pt8 andD:pt1];
    
    //NSLog(@"cross:%f", crossRatio);
    
    if (fabs(crossRatio - CROSSRATIO_3) <= CROSSRATIO_ERROR) {
        
        return 3;
        
    } else if (fabs(crossRatio - CROSSRATIO_2) <= CROSSRATIO_ERROR + 0.4) {
        
        return 2;
        
    } else if (fabs(crossRatio - CROSSRATIO_1) <= CROSSRATIO_ERROR) {
        
        return 1;
        
    } else if (fabs(crossRatio - CROSSRATIO_0) <= CROSSRATIO_ERROR + 0.2) { // 左上角Part距离较远容易产生较大误差，进行适当补偿
        
        return 0;
        
    } else {
        
        // 如果交比都不匹配，认为是错误轮廓返回-1
        return -1;
    }
}


// 解码LPart，返回顺序码(稳定版)
-(int) decodeSeqfromStableLPart:(LPart*)L withImg:(cv::Mat&)grayImg {
    
    int seq = -1;
    
    // 获得6个图形角点及1个辅助交点
    cv::Point2f pt0 = L._corners[0];
    cv::Point2f pt2 = L._corners[2];
    cv::Point2f pt3 = L._corners[3];
    cv::Point2f pt4 = L._corners[4];
    cv::Point2f pt5 = L._corners[5];
    cv::Point2f pt6 = [self getIntersectionOfLinesDeterminedByPointA:pt0 andB:pt5 andC:pt2 andD:pt3];

    // 获得顺序码
    std::vector<cv::Point2f> imgCorners2D;
    std::vector<cv::Point2f> markerCorners2D;
    cv::Mat transformedImg;
    int seqCode[2] = {0, 0};
    
    imgCorners2D.push_back(pt6);
    imgCorners2D.push_back(pt3);
    imgCorners2D.push_back(pt4);
    imgCorners2D.push_back(pt5);
    markerCorners2D.push_back(cv::Point2f(0.0, 0.0));
    markerCorners2D.push_back(cv::Point2f(LPART_WIDTH_SEQ - 1.0, 0.0));
    markerCorners2D.push_back(cv::Point2f(LPART_WIDTH_SEQ - 1.0, LPART_HEIGHT_SEQ - 1.0));
    markerCorners2D.push_back(cv::Point2f(0.0, LPART_HEIGHT_SEQ - 1.0));
    
    cv::Mat transformMatrix = cv::getPerspectiveTransform(imgCorners2D, markerCorners2D);
    cv::warpPerspective(grayImg, transformedImg, transformMatrix, cvSize(LPART_WIDTH_SEQ, LPART_HEIGHT_SEQ));
    cv::threshold(transformedImg, transformedImg, 125, 255, CV_THRESH_OTSU);
    
    int x = LPART_WIDTH_SEQ / 2;
    int y1 = 141 * LPART_HEIGHT_SEQ / (189 * 4);
    int y2 = 141 * 3 * LPART_HEIGHT_SEQ / (189 * 4);
    
    if (transformedImg.at<uchar>(y1, x) == 255) {
        
        seqCode[0] = 0;
        
    } else if (transformedImg.at<uchar>(y1, x) == 0) {
        
        seqCode[0] = 1;
    }
    
    if (transformedImg.at<uchar>(y2, x) == 255) {
        
        seqCode[1] = 0;
        
    } else if (transformedImg.at<uchar>(y2, x) == 0) {
        
        seqCode[1] = 1;
    }
    
    seq = powf(2, 0) * seqCode[1] + powf(2, 1) * seqCode[0];
    
    return seq;
}


// 解码LPart，返回信息码
-(int) decodeInfofromLPart:(LPart*)L withImg:(cv::Mat&)grayImg andSeq:(int)seqCode {
    
    int info = -1;
    
    // 获得角点及2个辅助交点
    cv::Point2f pt0 = L._corners[0];
    cv::Point2f pt1 = L._corners[1];
    cv::Point2f pt2 = L._corners[2];
    cv::Point2f pt3 = L._corners[3];
    cv::Point2f pt4 = L._corners[4];
    cv::Point2f pt5 = L._corners[5];
    cv::Point2f pt6 = [self getIntersectionOfLinesDeterminedByPointA:pt2 andB:pt3 andC:pt0 andD:pt5];
    cv::Point2f ptV = [self getIntersectionOfLinesDeterminedByPointA:pt3 andB:pt5 andC:pt4 andD:pt6];
    
    
    // 获得校验码
    int veriCode = -1;
    cv::threshold(grayImg, grayImg, 125, 255, CV_THRESH_BINARY);
    if (grayImg.at<uchar>((int)ptV.y, (int)ptV.x) == 255) {
        
        veriCode = 0;
        
    } else {
        
        veriCode = 1;
    }
    
    // 获得信息码
    std::vector<cv::Point2f> possibleCorners2D;
    std::vector<cv::Point2f> markerCorners2D;
    cv::Mat transformedImg;
    int infoCode[7] = {0, 0, 0, 0, 0, 0, 0};
    int countWhite = 0;
    
    possibleCorners2D.push_back(pt0);
    possibleCorners2D.push_back(pt1);
    possibleCorners2D.push_back(pt2);
    possibleCorners2D.push_back(pt6);
    
    if (seqCode != 3 && seqCode != -1) {
        
        markerCorners2D.push_back(cv::Point2f(0.0, 0.0));
        markerCorners2D.push_back(cv::Point2f(LPART_WIDTH_INFO - 1.0, 0.0));
        markerCorners2D.push_back(cv::Point2f(LPART_WIDTH_INFO - 1.0, LPART_HEIGHT_INFO - 1.0));
        markerCorners2D.push_back(cv::Point2f(0.0, LPART_HEIGHT_INFO - 1.0));
        
        cv::Mat transformMatrix = cv::getPerspectiveTransform(possibleCorners2D, markerCorners2D);
        cv::warpPerspective(grayImg, transformedImg, transformMatrix, cvSize(LPART_WIDTH_INFO, LPART_HEIGHT_INFO));
        cv::threshold(transformedImg, transformedImg, 125, 255, CV_THRESH_OTSU);
        
        //UIImage * img = [self UIImageFromCVMat:transformedImg];
        //UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);
        
        // 读码
        for (int i = 0; i < 6; ++i) {
            
            int x = 5 * LPART_WIDTH_INFO / 6 - 2 * LPART_WIDTH_INFO * i / 15;
            int y = LPART_HEIGHT_INFO / 2;
            
            if (transformedImg.at<uchar>(y, x) == 255) {
                
                infoCode[i] = 0;
                countWhite++;
                
            } else {
                
                infoCode[i] = 1;
            }
        }
        
    } else {
        
        markerCorners2D.push_back(cv::Point2f(0.0, 0.0));
        markerCorners2D.push_back(cv::Point2f(LPART_WIDTH_INFO * 17.0 / 15.0 - 1.0, 0.0));
        markerCorners2D.push_back(cv::Point2f(LPART_WIDTH_INFO * 17.0 / 15.0 - 1.0, LPART_HEIGHT_INFO - 1.0));
        markerCorners2D.push_back(cv::Point2f(0.0, LPART_HEIGHT_INFO - 1.0));
        
        cv::Mat transformMatrix = cv::getPerspectiveTransform(possibleCorners2D, markerCorners2D);
        cv::warpPerspective(grayImg, transformedImg, transformMatrix, cvSize(LPART_WIDTH_INFO * 17.0 / 15.0, LPART_HEIGHT_INFO));
        cv::threshold(transformedImg, transformedImg, 125, 255, CV_THRESH_OTSU);
        
        // 读码
        for (int i = 0; i < 7; ++i) {
            
            int x = 29 * LPART_WIDTH_INFO / 30 - 2 * LPART_WIDTH_INFO * i / 15;
            int y = LPART_HEIGHT_INFO / 2;
            
            if (transformedImg.at<uchar>(y, x) == 255) {
                
                infoCode[i] = 0;
                countWhite++;
                
            } else {
                
                infoCode[i] = 1;
            }
        }
    }
    
    // 根据白色矩形的数量奇偶性进行校验，奇数对应白色校验块
    if (veriCode == 0 && countWhite % 2 == 0) {
        
        return -1;
        
    } else if (veriCode == 1 && countWhite % 2 != 0) {
        
        return -1;
        
    } else {
        
        // 通过验证解码
        info = powf(2, 0) * infoCode[0] + powf(2, 1) * infoCode[1] + powf(2, 2) * infoCode[2] +
               powf(2, 3) * infoCode[3] + powf(2, 4) * infoCode[4] + powf(2, 5) * infoCode[5] + powf(2, 6) * infoCode[6];
    }
    
    return info;
}


// 解码LPart，返回信息码(稳定版)
-(int) decodeInfofromStableLPart:(LPart*)L withImg:(cv::Mat&)grayImg andSeq:(int)seqCode {
    
    int info = -1;
    
    // 获得角点及2个辅助交点
    cv::Point2f pt0 = L._corners[0];
    cv::Point2f pt1 = L._corners[1];
    cv::Point2f pt2 = L._corners[2];
    cv::Point2f pt3 = L._corners[3];
    cv::Point2f pt4 = L._corners[4];
    cv::Point2f pt5 = L._corners[5];
    cv::Point2f pt6 = [self getIntersectionOfLinesDeterminedByPointA:pt2 andB:pt3 andC:pt0 andD:pt5];    
    
    // 获得信息码
    std::vector<cv::Point2f> possibleCorners2D;
    std::vector<cv::Point2f> markerCorners2D;
    cv::Mat transformedImg;
    int infoCode[7] = {0, 0, 0, 0, 0, 0, 0};
    
    possibleCorners2D.push_back(pt0);
    possibleCorners2D.push_back(pt1);
    possibleCorners2D.push_back(pt2);
    possibleCorners2D.push_back(pt6);
    
    if (seqCode != 3 && seqCode != -1) {
        
        markerCorners2D.push_back(cv::Point2f(0.0, 0.0));
        markerCorners2D.push_back(cv::Point2f(LPART_WIDTH_INFO - 1.0, 0.0));
        markerCorners2D.push_back(cv::Point2f(LPART_WIDTH_INFO - 1.0, LPART_HEIGHT_INFO - 1.0));
        markerCorners2D.push_back(cv::Point2f(0.0, LPART_HEIGHT_INFO - 1.0));
        
        cv::Mat transformMatrix = cv::getPerspectiveTransform(possibleCorners2D, markerCorners2D);
        cv::warpPerspective(grayImg, transformedImg, transformMatrix, cvSize(LPART_WIDTH_INFO, LPART_HEIGHT_INFO));
        cv::threshold(transformedImg, transformedImg, 125, 255, CV_THRESH_OTSU);
        
        //UIImage * img = [self UIImageFromCVMat:transformedImg];
        //UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);
        
        // 读码
        for (int i = 0; i < 6; ++i) {
            
            int x = 5 * LPART_WIDTH_INFO / 6 - 2 * LPART_WIDTH_INFO * i / 15;
            int y = LPART_HEIGHT_INFO / 2;
            
            if (transformedImg.at<uchar>(y, x) == 255) {
                
                infoCode[i] = 0;
                
            } else {
                
                infoCode[i] = 1;
            }
        }
        
    } else {
        
        markerCorners2D.push_back(cv::Point2f(0.0, 0.0));
        markerCorners2D.push_back(cv::Point2f(LPART_WIDTH_INFO * 17.0 / 15.0 - 1.0, 0.0));
        markerCorners2D.push_back(cv::Point2f(LPART_WIDTH_INFO * 17.0 / 15.0 - 1.0, LPART_HEIGHT_INFO - 1.0));
        markerCorners2D.push_back(cv::Point2f(0.0, LPART_HEIGHT_INFO - 1.0));
        
        cv::Mat transformMatrix = cv::getPerspectiveTransform(possibleCorners2D, markerCorners2D);
        cv::warpPerspective(grayImg, transformedImg, transformMatrix, cvSize(LPART_WIDTH_INFO * 17.0 / 15.0, LPART_HEIGHT_INFO));
        cv::threshold(transformedImg, transformedImg, 125, 255, CV_THRESH_OTSU);
        
        // 读码
        for (int i = 0; i < 7; ++i) {
            
            int x = 29 * LPART_WIDTH_INFO / 30 - 2 * LPART_WIDTH_INFO * i / 15;
            int y = LPART_HEIGHT_INFO / 2;
            
            if (transformedImg.at<uchar>(y, x) == 255) {
                
                infoCode[i] = 0;
                
            } else {
                
                infoCode[i] = 1;
            }
        }
    }
    

    // 解码
    info = powf(2, 0) * infoCode[0] + powf(2, 1) * infoCode[1] + powf(2, 2) * infoCode[2] +
    powf(2, 3) * infoCode[3] + powf(2, 4) * infoCode[4] + powf(2, 5) * infoCode[5] + powf(2, 6) * infoCode[6];
    
    return info;
}


// Mat转UIImage
-(UIImage *) UIImageFromCVMat:(cv::Mat)cvMat {
    
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                              //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}


// 测试二值化效果
-(void) threshTest:(cv::Mat&)image {
    
    cv::Mat gray;
    cv::Mat edges;
    
    // 灰度化
    cv::cvtColor(image, gray, CV_BGR2GRAY);
    
    // 高斯滤波去除微小线条
    cv::GaussianBlur(gray, gray, cv::Size(5, 5), 1.2, 1.2);
    
    // 阈值化
    //cv::adaptiveThreshold(gray, edges, 255, CV_ADAPTIVE_THRESH_MEAN_C, CV_THRESH_BINARY, 71, 0);
    cv::threshold(gray, edges, 100, 255, CV_THRESH_BINARY);
    //cv::Canny(gray, edges, 0, 250, 3, false);
    
    UIImage* pic = [self UIImageFromCVMat:edges];
    UIImageWriteToSavedPhotosAlbum(pic, nil, nil, nil);
}


/************************************************** 组合LPart为Marker **************************************************/

// 从若干个LPart中筛选、组合出所有的Marker
-(std::vector<Marker*>) findMarkersFromLParts:(std::vector<LPart*>)allLParts {
    
    std::vector<Marker*> markers;
    
    // 如果LPart的数量小于3个，直接认为无效Marker
    if (allLParts.size() <= 2) {
        
        return markers;
    }
    
    // 如果LPart的数量是3或4，默认为只有一个Marker
    if (allLParts.size() <= 4) {
        
        Marker* marker = [[[Marker alloc] initWithVersion:self._version] autorelease];
        
        int seq;
        
        // 挂载LPart
        for (int i = 0; i < allLParts.size(); ++i) {
            
            seq = allLParts[i]._seqCode;
            
            marker._LParts[seq]._corners = allLParts[i]._corners;
            marker._LParts[seq]._seqCode = seq;
            marker._LParts[seq]._infoCode = allLParts[i]._infoCode;
            
            // 更改标志位数组
            [marker setFlag:TRUE atIndex:seq];
        }
        
        // 计算并挂载Marker ID
        int infoCode[4] = {-1, -1, -1, -1};
        
        for (int i = 0; i < 4; ++i) {
            
            // 如果某个LPart有效，则直接取值，否则通过其它三个marker的信息计算出来
            if ([marker getFlagAtIndex:i]) {
                
                infoCode[i] = marker._LParts[i]._infoCode;
                
            } else {
                
                switch (i) {
                        
                    case 0:
                        infoCode[0] = marker._LParts[3]._infoCode - marker._LParts[2]._infoCode - marker._LParts[1]._infoCode;
                        break;
                        
                    case 1:
                        infoCode[1] = marker._LParts[3]._infoCode - marker._LParts[2]._infoCode - marker._LParts[0]._infoCode;
                        break;
                    
                    case 2:
                        infoCode[2] = marker._LParts[3]._infoCode - marker._LParts[1]._infoCode - marker._LParts[0]._infoCode;
                        break;
                        
                    case 3:
                        infoCode[3] = marker._LParts[0]._infoCode + marker._LParts[1]._infoCode + marker._LParts[2]._infoCode;
                        break;
                }
            }
        }
        
        // 如果信息校验通过则装载marker
        if (infoCode[3] == infoCode[0] + infoCode[1] + infoCode[2]) {
            
            marker._ID = infoCode[0] * powf(2, 12) + infoCode[1] * powf(2, 6) + infoCode[2];
            markers.push_back(marker);
            
        } else {
            
            return markers;
        }
    }
    
    // 如果LPart的数量大于4，则认为是多个Marker，需要判别
    if (allLParts.size() >= 5) {

        // 先按照位置进行分类
        std::vector<std::vector<LPart*>> sortedParts;
        std::vector<LPart*> parts0;
        std::vector<LPart*> parts1;
        std::vector<LPart*> parts2;
        std::vector<LPart*> parts3;
        
        for (int i = 0; i < allLParts.size(); ++i) {
            
            switch (allLParts[i]._seqCode) {
                    
                case 0:
                    parts0.push_back(allLParts[i]);
                    break;
                    
                case 1:
                    parts1.push_back(allLParts[i]);
                    break;
                    
                case 2:
                    parts2.push_back(allLParts[i]);
                    break;
                    
                case 3:
                    parts3.push_back(allLParts[i]);
                    break;
            }
        }
        sortedParts.push_back(parts0);
        sortedParts.push_back(parts1);
        sortedParts.push_back(parts2);
        sortedParts.push_back(parts3);
        
        // 找到包含Parts数量最多的位置作为后续迭代算法的初始位置
        int originIndex = 0;
        for (int i = 1; i < sortedParts.size(); ++i) {
            
            if (sortedParts[i].size() > sortedParts[originIndex].size()) {
                
                originIndex = i;
            }
        }

        // 以初始位置中的每个part为基准寻找该marker中的其他part并组合为marker
        for (int j = 0; j < sortedParts[originIndex].size(); ++j) {
            
            Marker* marker = [[[Marker alloc] initWithVersion:self._version] autorelease];
            
            // 先把基准Part挂载到marker里
            marker._LParts[originIndex]._corners = sortedParts[originIndex][j]._corners;
            marker._LParts[originIndex]._seqCode = originIndex;
            marker._LParts[originIndex]._infoCode = sortedParts[originIndex][j]._infoCode;
            [marker setFlag:TRUE atIndex:originIndex];

            // 再检测前后part
            cv::Point2d currentPos;
            currentPos.x = originIndex;
            currentPos.y = j;
            cv::Point2d nextPart = [self findNextPartOfCurrentPos:currentPos inSortedParts:sortedParts];

            cv::Point2d previousPart = [self findPreviousPartOfCurrentPos:currentPos inSortedParts:sortedParts];

            if (nextPart.x != -1 || previousPart.x != -1) {
                
                if (nextPart.x != -1) {
                    
                    marker._LParts[nextPart.x]._corners = sortedParts[nextPart.x][nextPart.y]._corners;
                    marker._LParts[nextPart.x]._seqCode = nextPart.x;
                    marker._LParts[nextPart.x]._infoCode = sortedParts[nextPart.x][nextPart.y]._infoCode;
                    [marker setFlag:TRUE atIndex:nextPart.x];
                }
                
                if (previousPart.x != -1) {

                    marker._LParts[previousPart.x]._corners = sortedParts[previousPart.x][previousPart.y]._corners;
                    marker._LParts[previousPart.x]._seqCode = previousPart.x;
                    marker._LParts[previousPart.x]._infoCode = sortedParts[previousPart.x][previousPart.y]._infoCode;
                    [marker setFlag:TRUE atIndex:previousPart.x];
                }
                
                // 再根据前后part检测对角part
                if (nextPart.x != -1) {
                    
                    cv::Point2d nextNextPart = [self findNextPartOfCurrentPos:nextPart inSortedParts:sortedParts];
                    if (nextNextPart.x != -1) {
                        
                        marker._LParts[nextNextPart.x]._corners = sortedParts[nextNextPart.x][nextNextPart.y]._corners;
                        marker._LParts[nextNextPart.x]._seqCode = nextNextPart.x;
                        marker._LParts[nextNextPart.x]._infoCode = sortedParts[nextNextPart.x][nextNextPart.y]._infoCode;
                        [marker setFlag:TRUE atIndex:nextNextPart.x];
                        
                    }
                    
                } else {
                    
                    cv::Point2d prePrePart = [self findPreviousPartOfCurrentPos:previousPart inSortedParts:sortedParts];
                    if (prePrePart.x != -1) {
                        
                        marker._LParts[prePrePart.x]._corners = sortedParts[prePrePart.x][prePrePart.y]._corners;
                        marker._LParts[prePrePart.x]._seqCode = prePrePart.x;
                        marker._LParts[prePrePart.x]._infoCode = sortedParts[prePrePart.x][prePrePart.y]._infoCode;
                        [marker setFlag:TRUE atIndex:prePrePart.x];
                    }
                }
            }
            
            // 检测marker是否含有足够数量的LPart并计算ID
            int count = 0;
            for (int i = 0; i < 4; ++i) {
                
                if ([marker getFlagAtIndex:i]) {
                    
                    count++;
                }
            }
            
            if (count >= 3) {
                
                // 计算并挂载Marker ID
                int infoCode[4] = {-1, -1, -1, -1};
                
                for (int i = 0; i < 4; ++i) {
                    
                    // 如果某个LPart有效，则直接取值，否则通过其它三个marker的信息计算出来
                    if ([marker getFlagAtIndex:i]) {
                        
                        infoCode[i] = marker._LParts[i]._infoCode;
                        
                    } else {
                        
                        switch (i) {
                                
                            case 0:
                                infoCode[0] = marker._LParts[3]._infoCode - marker._LParts[2]._infoCode - marker._LParts[1]._infoCode;
                                break;
                                
                            case 1:
                                infoCode[1] = marker._LParts[3]._infoCode - marker._LParts[2]._infoCode - marker._LParts[0]._infoCode;
                                break;
                                
                            case 2:
                                infoCode[2] = marker._LParts[3]._infoCode - marker._LParts[1]._infoCode - marker._LParts[0]._infoCode;
                                break;
                                
                            case 3:
                                infoCode[3] = marker._LParts[0]._infoCode + marker._LParts[1]._infoCode + marker._LParts[2]._infoCode;
                                break;
                        }
                    }
                }
                
                // 如果信息校验通过则装载marker
                if (infoCode[3] == infoCode[0] + infoCode[1] + infoCode[2]) {
                    
                    marker._ID = infoCode[0] * powf(2, 12) + infoCode[1] * powf(2, 6) + infoCode[2];
                    markers.push_back(marker);
                }
            }
        }
    }
    
    return markers;
}


// 检测某个Part的下一个Part，以在sortedParts中的索引形式返回(Point2d的xy坐标值分别表示顺序码和位置索引)
-(cv::Point2d) findNextPartOfCurrentPos:(cv::Point2d)pos inSortedParts:(std::vector<std::vector<LPart*>>)sortedParts {
    
    cv::Point2d next;
    next.x = -1;
    next.y = -1;

    // 对其下一组中的每个part进行判断
    if (pos.x != 3) {
        
        float minDistance = 100000.0f;
        for (int i = 0; i < sortedParts[pos.x + 1].size(); ++i) {
            
            if ([self isPart:sortedParts[pos.x + 1][i] NextOfPart:sortedParts[pos.x][pos.y]]) {
                
                float distance = [self distanceBetweenPointA:sortedParts[pos.x][pos.y]._corners[0] andB:sortedParts[pos.x + 1][i]._corners[0]];
                if (distance < minDistance) {
                    
                    minDistance = distance;
                    next.x = pos.x + 1;
                    next.y = i;
                }
            }
        }
        
    } else {
        
        float minDistance = 100000.0f;
        for (int i = 0; i < sortedParts[0].size(); ++i) {
            
            if ([self isPart:sortedParts[0][i] NextOfPart:sortedParts[pos.x][pos.y]]) {

                float distance = [self distanceBetweenPointA:sortedParts[pos.x][pos.y]._corners[0] andB:sortedParts[0][i]._corners[0]];
                if (distance < minDistance) {
                    
                    minDistance = distance;
                    next.x = 0;
                    next.y = i;
                }
            }
        }
    }
    
    return next;
}


// 判断某个part是否为另一个part的后续part(此处不考虑距离,只考虑相对位置)
-(bool) isPart:(LPart*)partNext NextOfPart:(LPart*)partPre {
    
    bool result = false;
    
    cv::Point2f prePt0 = partPre._corners[0];
    cv::Point2f prePt1 = partPre._corners[1];
    cv::Point2f nextPt0 = partNext._corners[0];
    cv::Point2f nextPt5 = partNext._corners[5];
    
    // 首先判断四点是否近似共线
    float distance0 = [self distanceBetweenPoint:nextPt0 andLineDeterminedByPoint:prePt0 andPoint:prePt1];
    float distance5 = [self distanceBetweenPoint:nextPt5 andLineDeterminedByPoint:prePt0 andPoint:prePt1];

    if (distance0 < DISTANCE_TO_LINE_THRESH && distance5 < DISTANCE_TO_LINE_THRESH) {
        
        // 其次判断相对位置
        float distance00 = [self distanceBetweenPointA:prePt0 andB:nextPt0];
        float distance05 = [self distanceBetweenPointA:prePt0 andB:nextPt5];
        if (distance00 > distance05) {

            // 最后判断方向
            float diffPreX = prePt1.x - prePt0.x;
            float diffPreY = prePt1.y - prePt0.y;
            float diffNextX = nextPt0.x - nextPt5.x;
            float diffNextY = nextPt0.y - nextPt5.y;
            
            if (fabsf(diffPreX) < 1.0f) {
                
                diffPreX = 0.0f;
            }
            if (fabsf(diffPreY) < 1.0f) {
                
                diffPreY = 0.0f;
            }
            if (fabsf(diffNextX) < 1.0f) {
                
                diffNextX = 0.0f;
            }
            if (fabsf(diffNextY) < 1.0f) {
                
                diffNextY = 0.0f;
            }
            
            if (diffPreX * diffNextX < 0.0f || diffPreY * diffNextY < 0.0f) {
                
                result = false;
                
            } else {
            
                result = true;
            }
        }
    }
    
    return result;
}


// 检测某个Part的上一个Part，以在sortedParts中的索引形式返回(Point2d的xy坐标值分别表示顺序码和位置索引)
-(cv::Point2d) findPreviousPartOfCurrentPos:(cv::Point2d)pos inSortedParts:(std::vector<std::vector<LPart*>>)sortedParts {
    
    cv::Point2d pre;
    pre.x = -1;
    pre.y = -1;

    // 对其上一组中的每个part进行判断
    if (pos.x != 0) {
        
        float minDistance = 100000.0f;
        for (int i = 0; i < sortedParts[pos.x - 1].size(); ++i) {
            
            if ([self isPart:sortedParts[pos.x - 1][i] PreOfPart:sortedParts[pos.x][pos.y]]) {
                
                float distance = [self distanceBetweenPointA:sortedParts[pos.x][pos.y]._corners[0] andB:sortedParts[pos.x - 1][i]._corners[0]];
                if (distance < minDistance) {
                    
                    minDistance = distance;
                    pre.x = pos.x - 1;
                    pre.y = i;
                }
            }
        }
        
    } else {
        
        float minDistance = 100000.0f;
        for (int i = 0; i < sortedParts[3].size(); ++i) {
            
            if ([self isPart:sortedParts[3][i] PreOfPart:sortedParts[0][pos.y]]) {
                
                float distance = [self distanceBetweenPointA:sortedParts[0][pos.y]._corners[0] andB:sortedParts[3][i]._corners[0]];
                if (distance < minDistance) {
                    
                    minDistance = distance;
                    pre.x = 3;
                    pre.y = i;
                }
            }
        }
    }
    
    return pre;
}


// 判断某个part是否为另一个part的先前part(此处不考虑距离,只考虑相对位置)
-(BOOL) isPart:(LPart*)partPre PreOfPart:(LPart*)partNext {
    
    BOOL result = [self isPart:partNext NextOfPart:partPre];
    return result;
}


// 计算点到直线的距离，其中直线方程由两点确定
-(float) distanceBetweenPoint:(cv::Point2f)pt andLineDeterminedByPoint:(cv::Point2f)ptA andPoint:(cv::Point2f)ptB {
    
    float distance = 0.0f;
    
    if (fabsf(ptA.x - ptB.x) < 0.1f) {
        
        distance = fabsf(pt.x - ptA.x);
        
    } else {
        
        float A = (ptB.y - ptA.y) / (ptB.x - ptA.x);
        float B = - 1.0f;
        float C = ptA.y - A * ptA.x;
        
        distance = fabsf(A * pt.x + B * pt.y + C) / sqrtf(A * A + B * B);
    }
    
    return distance;
}

@end
