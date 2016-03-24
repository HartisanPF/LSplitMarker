//
//  UIView+EAGLView.h
//  LMarkerV2
//
//  Created by Hartisan on 15/5/11.
//  Copyright (c) 2015年 Hartisan. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@class EAGLContext;

// This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.
// The view content is basically an EAGL surface you render your OpenGL scene into.
// Note that setting the view non-opaque will only work if the EAGL surface has an alpha channel.
@interface EAGLView : UIView
{
    
@private
    EAGLContext* _context;
    GLuint _defaultFramebuffer;
    GLuint _colorRenderbuffer;
    GLuint _depthRenderbuffer;
    GLint _framebufferWidth;
    GLint _framebufferHeight;
}

@property (nonatomic, retain) EAGLContext* _context;
@property (readonly) GLint _framebufferWidth;
@property (readonly) GLint _framebufferHeight;

- (void)setFramebuffer;
- (BOOL)presentFramebuffer;
- (void)initContext;

@end
