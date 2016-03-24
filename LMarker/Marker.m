//
//  Marker.m
//  LMarker
//
//  Created by Hartisan on 14-12-21.
//  Copyright (c) 2014年 Hartisan. All rights reserved.
//

#import "Marker.h"

@implementation Marker

@synthesize _upLeftPart, _upRightPart, _downRightPart, _downLeftPart, _ID, _points3D, _LParts;

-(void) dealloc{
    
    [_upLeftPart release];
    [_upRightPart release];
    [_downRightPart release];
    [_downLeftPart release];
    
    [super dealloc];
}


-(id) initWithVersion:(int)version {
    
    LPart* UL = [[LPart alloc] init];
    LPart* UR = [[LPart alloc] init];
    LPart* DR = [[LPart alloc] init];
    LPart* DL = [[LPart alloc] init];
    self._upLeftPart = UL;
    self._upRightPart = UR;
    self._downRightPart = DR;
    self._downLeftPart = DL;
    [UL release];
    [UR release];
    [DR release];
    [DL release];
    
    std::vector<LPart*> LParts;
    LParts.push_back(self._upLeftPart);
    LParts.push_back(self._upRightPart);
    LParts.push_back(self._downRightPart);
    LParts.push_back(self._downLeftPart);
    self._LParts = LParts;

    
    // 初始化标志位
    for (int i = 0; i < 4; ++i) {
        
        [self setFlag:FALSE atIndex:i];
    }
    
    //[self init3DPoints];
    if (version == 2) {
        
        [self init3DPointsStable];
        
    } else if (version == 3) {
        
        [self init3DPointsStableStable];
    }

    return [super init];
}


// 设置某标志位
-(void) setFlag:(BOOL)flag atIndex:(int)index {
    
    _partsFlag[index] = flag;
}


// 获得某标志位
-(BOOL) getFlagAtIndex:(int)index{
    
    return _partsFlag[index];
}


// 初始化所有角点的世界坐标
-(void) init3DPoints {
    
    // 左上角LPart
    cv::Point3f p00 = cv::Point3f(-0.5, 0.5, 0.0);
    cv::Point3f p01 = cv::Point3f(-0.198, 0.5, 0.0);
    cv::Point3f p02 = cv::Point3f(-0.198, 0.3995, 0.0);
    cv::Point3f p03 = cv::Point3f(-0.3995, 0.3995, 0.0);
    cv::Point3f p04 = cv::Point3f(-0.3995, 0.308, 0.0);
    cv::Point3f p05 = cv::Point3f(-0.5, 0.308, 0.0);
    
    // 右上角LPart
    cv::Point3f p10 = cv::Point3f(0.5, 0.5, 0.0);
    cv::Point3f p11 = cv::Point3f(0.5, 0.198, 0.0);
    cv::Point3f p12 = cv::Point3f(0.399, 0.198, 0.0);
    cv::Point3f p13 = cv::Point3f(0.399, 0.3995, 0.0);
    cv::Point3f p14 = cv::Point3f(0.289, 0.3995, 0.0);
    cv::Point3f p15 = cv::Point3f(0.289, 0.5, 0.0);
    
    // 右下角LPart
    cv::Point3f p20 = cv::Point3f(0.5, -0.5, 0.0);
    cv::Point3f p21 = cv::Point3f(0.198, -0.5, 0.0);
    cv::Point3f p22 = cv::Point3f(0.198, -0.399, 0.0);
    cv::Point3f p23 = cv::Point3f(0.399, -0.399, 0.0);
    cv::Point3f p24 = cv::Point3f(0.399, -0.326, 0.0);
    cv::Point3f p25 = cv::Point3f(0.5, -0.326, 0.0);
    
    // 左下角LPart
    cv::Point3f p30 = cv::Point3f(-0.5, -0.5, 0.0);
    cv::Point3f p31 = cv::Point3f(-0.5, -0.158, 0.0);
    cv::Point3f p32 = cv::Point3f(-0.3995, -0.158, 0.0);
    cv::Point3f p33 = cv::Point3f(-0.3995, -0.399, 0.0);
    cv::Point3f p34 = cv::Point3f(-0.29, -0.399, 0.0);
    cv::Point3f p35 = cv::Point3f(-0.29, -0.5, 0.0);
    
    std::vector<cv::Point3f> points3D;
    
    points3D.push_back(p00);
    points3D.push_back(p01);
    points3D.push_back(p02);
    points3D.push_back(p03);
    points3D.push_back(p04);
    points3D.push_back(p05);
    
    points3D.push_back(p10);
    points3D.push_back(p11);
    points3D.push_back(p12);
    points3D.push_back(p13);
    points3D.push_back(p14);
    points3D.push_back(p15);
    
    points3D.push_back(p20);
    points3D.push_back(p21);
    points3D.push_back(p22);
    points3D.push_back(p23);
    points3D.push_back(p24);
    points3D.push_back(p25);
    
    points3D.push_back(p30);
    points3D.push_back(p31);
    points3D.push_back(p32);
    points3D.push_back(p33);
    points3D.push_back(p34);
    points3D.push_back(p35);
    
    for (int i = 0; i < points3D.size(); ++i) {
        
        float x = points3D[i].x;
        float y = points3D[i].y;
        points3D[i].x = x * MARKER_WIDTH;
        points3D[i].y = y * MARKER_HEIGHT;
    }
    
    self._points3D = points3D;

}


// 初始化所有角点的世界坐标(稳定版)
-(void) init3DPointsStable {
    
    // 左上角LPart
    cv::Point3f p00 = cv::Point3f(-0.5, 0.5, 0.0);
    cv::Point3f p01 = cv::Point3f(-0.198, 0.5, 0.0);
    cv::Point3f p02 = cv::Point3f(-0.198, 0.3995, 0.0);
    cv::Point3f p03 = cv::Point3f(-0.3995, 0.3995, 0.0);
    cv::Point3f p04 = cv::Point3f(-0.3995, 0.305, 0.0);
    cv::Point3f p05 = cv::Point3f(-0.5, 0.305, 0.0);
    
    // 右上角LPart
    cv::Point3f p10 = cv::Point3f(0.5, 0.5, 0.0);
    cv::Point3f p11 = cv::Point3f(0.5, 0.198, 0.0);
    cv::Point3f p12 = cv::Point3f(0.399, 0.198, 0.0);
    cv::Point3f p13 = cv::Point3f(0.399, 0.3995, 0.0);
    cv::Point3f p14 = cv::Point3f(0.305, 0.3995, 0.0);
    cv::Point3f p15 = cv::Point3f(0.305, 0.5, 0.0);
    
    // 右下角LPart
    cv::Point3f p20 = cv::Point3f(0.5, -0.5, 0.0);
    cv::Point3f p21 = cv::Point3f(0.198, -0.5, 0.0);
    cv::Point3f p22 = cv::Point3f(0.198, -0.399, 0.0);
    cv::Point3f p23 = cv::Point3f(0.399, -0.399, 0.0);
    cv::Point3f p24 = cv::Point3f(0.399, -0.305, 0.0);
    cv::Point3f p25 = cv::Point3f(0.5, -0.305, 0.0);
    
    // 左下角LPart
    cv::Point3f p30 = cv::Point3f(-0.5, -0.5, 0.0);
    cv::Point3f p31 = cv::Point3f(-0.5, -0.158, 0.0);
    cv::Point3f p32 = cv::Point3f(-0.3995, -0.158, 0.0);
    cv::Point3f p33 = cv::Point3f(-0.3995, -0.399, 0.0);
    cv::Point3f p34 = cv::Point3f(-0.305, -0.399, 0.0);
    cv::Point3f p35 = cv::Point3f(-0.305, -0.5, 0.0);
    
    std::vector<cv::Point3f> points3D;
    
    points3D.push_back(p00);
    points3D.push_back(p01);
    points3D.push_back(p02);
    points3D.push_back(p03);
    points3D.push_back(p04);
    points3D.push_back(p05);
    
    points3D.push_back(p10);
    points3D.push_back(p11);
    points3D.push_back(p12);
    points3D.push_back(p13);
    points3D.push_back(p14);
    points3D.push_back(p15);
    
    points3D.push_back(p20);
    points3D.push_back(p21);
    points3D.push_back(p22);
    points3D.push_back(p23);
    points3D.push_back(p24);
    points3D.push_back(p25);
    
    points3D.push_back(p30);
    points3D.push_back(p31);
    points3D.push_back(p32);
    points3D.push_back(p33);
    points3D.push_back(p34);
    points3D.push_back(p35);
    
    for (int i = 0; i < points3D.size(); ++i) {
        
        float x = points3D[i].x;
        float y = points3D[i].y;
        points3D[i].x = x * MARKER_WIDTH;
        points3D[i].y = y * MARKER_HEIGHT;
    }
    
    self._points3D = points3D;
}


// 初始化所有角点的世界坐标(稳定加粗版)
-(void) init3DPointsStableStable {
    
    // 左上角LPart
    cv::Point3f p00 = cv::Point3f(-0.5, 0.5, 0.0);
    cv::Point3f p01 = cv::Point3f(-0.07625, 0.5, 0.0);
    cv::Point3f p02 = cv::Point3f(-0.07625, 0.35875, 0.0);
    cv::Point3f p03 = cv::Point3f(-0.35875, 0.35875, 0.0);
    cv::Point3f p04 = cv::Point3f(-0.35875, 0.22625, 0.0);
    cv::Point3f p05 = cv::Point3f(-0.5, 0.22625, 0.0);
    
    // 右上角LPart
    cv::Point3f p10 = cv::Point3f(0.5, 0.5, 0.0);
    cv::Point3f p11 = cv::Point3f(0.5, 0.07625, 0.0);
    cv::Point3f p12 = cv::Point3f(0.35875, 0.07625, 0.0);
    cv::Point3f p13 = cv::Point3f(0.35875, 0.35875, 0.0);
    cv::Point3f p14 = cv::Point3f(0.22625, 0.35875, 0.0);
    cv::Point3f p15 = cv::Point3f(0.22625, 0.5, 0.0);
    
    // 右下角LPart
    cv::Point3f p20 = cv::Point3f(0.5, -0.5, 0.0);
    cv::Point3f p21 = cv::Point3f(0.07625, -0.5, 0.0);
    cv::Point3f p22 = cv::Point3f(0.07625, -0.35875, 0.0);
    cv::Point3f p23 = cv::Point3f(0.35875, -0.35875, 0.0);
    cv::Point3f p24 = cv::Point3f(0.35875, -0.22625, 0.0);
    cv::Point3f p25 = cv::Point3f(0.5, -0.22625, 0.0);
    
    // 左下角LPart
    cv::Point3f p30 = cv::Point3f(-0.5, -0.5, 0.0);
    cv::Point3f p31 = cv::Point3f(-0.5, -0.02, 0.0);
    cv::Point3f p32 = cv::Point3f(-0.35875, -0.02, 0.0);
    cv::Point3f p33 = cv::Point3f(-0.35875, -0.35875, 0.0);
    cv::Point3f p34 = cv::Point3f(-0.22625, -0.35875, 0.0);
    cv::Point3f p35 = cv::Point3f(-0.22625, -0.5, 0.0);
    
    std::vector<cv::Point3f> points3D;
    
    points3D.push_back(p00);
    points3D.push_back(p01);
    points3D.push_back(p02);
    points3D.push_back(p03);
    points3D.push_back(p04);
    points3D.push_back(p05);
    
    points3D.push_back(p10);
    points3D.push_back(p11);
    points3D.push_back(p12);
    points3D.push_back(p13);
    points3D.push_back(p14);
    points3D.push_back(p15);
    
    points3D.push_back(p20);
    points3D.push_back(p21);
    points3D.push_back(p22);
    points3D.push_back(p23);
    points3D.push_back(p24);
    points3D.push_back(p25);
    
    points3D.push_back(p30);
    points3D.push_back(p31);
    points3D.push_back(p32);
    points3D.push_back(p33);
    points3D.push_back(p34);
    points3D.push_back(p35);
    
    for (int i = 0; i < points3D.size(); ++i) {
        
        float x = points3D[i].x;
        float y = points3D[i].y;
        points3D[i].x = x * MARKER_WIDTH;
        points3D[i].y = y * MARKER_HEIGHT;
    }
    
    self._points3D = points3D;
}


// 获得某个Part中的某个角点的世界坐标
-(cv::Point3f) get3DPointAt:(int)cornerIndex ofPart:(int)partIndex {
    
    cv::Point3f point3D;
    int index = partIndex * 6 + cornerIndex;
    
    point3D.x = self._points3D[index].x;
    point3D.y = self._points3D[index].y;
    point3D.z = 0.0f;
    
    return point3D;
}


@end
