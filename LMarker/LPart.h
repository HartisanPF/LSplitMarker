
//
//  LPart.h
//  LMarker
//
//  Created by Hartisan on 14-12-21.
//  Copyright (c) 2014年 Hartisan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <opencv2/imgcodecs/ios.h>

@interface LPart : NSObject {
    
    std::vector<cv::Point2f> _corners;  // 6个角点顺时针排列
    int _seqCode;                       // 顺序码，标识此LPart是marker中的第几个Part
    int _infoCode;                      // 此Part中的信息码，用于后续组合marker的ID
}

@property std::vector<cv::Point2f> _corners;
@property int _seqCode;
@property int _infoCode;

@end
