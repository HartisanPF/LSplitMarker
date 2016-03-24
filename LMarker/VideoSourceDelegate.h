//
//  VideoSourceDelegate.h
//  LMarkerV2
//
//  Created by Hartisan on 15/5/9.
//  Copyright (c) 2015年 Hartisan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>

struct BGRAVideoFrame
{
    size_t width;
    size_t height;
    size_t stride;
    
    unsigned char* data;
};

@protocol VideoSourceDelegate <NSObject>

-(void)frameReady:(BGRAVideoFrame) frame;

@end
