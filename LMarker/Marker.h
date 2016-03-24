//
//  Marker.h
//  LMarker
//
//  Created by Hartisan on 14-12-21.
//  Copyright (c) 2014年 Hartisan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LPart.h"

#define MARKER_WIDTH 1.0
#define MARKER_HEIGHT 1.0

@interface Marker : NSObject {
    
    // 一个完整marker的4个L型部分
    LPart* _upLeftPart;
    LPart* _upRightPart;
    LPart* _downRightPart;
    LPart* _downLeftPart;
    std::vector<LPart*> _LParts;
    
    // 成功检测到的LPart标识数组
    BOOL _partsFlag[4];

    int _ID;    // marker的ID，由四个part的infoCode组合得到
    
    std::vector<cv::Point3f> _points3D;   // 所有角点在世界坐标系下的坐标,按照Part0~3，角点0~5的顺序存储
}

@property (nonatomic, retain) LPart* _upLeftPart;
@property (nonatomic, retain) LPart* _upRightPart;
@property (nonatomic, retain) LPart* _downRightPart;
@property (nonatomic, retain) LPart* _downLeftPart;
@property std::vector<LPart*> _LParts;
@property int _ID;
@property std::vector<cv::Point3f> _points3D;


-(id) initWithVersion:(int)version;
-(void) init3DPoints;
-(void) init3DPointsStable;
-(cv::Point3f) get3DPointAt:(int)cornerIndex ofPart:(int)partIndex;
-(void) setFlag:(BOOL)flag atIndex:(int)index;
-(BOOL) getFlagAtIndex:(int)index;
-(void) init3DPointsStableStable;

@end
