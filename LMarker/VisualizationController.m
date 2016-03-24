//
//  UIViewController+VisualizationController.m
//  LMarkerV2
//
//  Created by Hartisan on 15/5/11.
//  Copyright (c) 2015年 Hartisan. All rights reserved.
//

#import "VisualizationController.h"
#import "Marker.h"
#import "axisOBJ.h"
#import "axisMTL.h"

@implementation VisualizationController

@synthesize _glView, _transformationsWithID;


-(void)dealloc {
    
    [_glView release];
    [super dealloc];
}


// 由EAGLView初始化
-(id)initWithEAGLView:(EAGLView*)eaglView andFrameSize:(CGSize)size {
    
    if ((self = [super init]))
    {
        self._glView = eaglView;
        
        glGenTextures(1, &_backgroundTextureId);
        glBindTexture(GL_TEXTURE_2D, _backgroundTextureId);
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        // This is necessary for non-power-of-two textures
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        glEnable(GL_DEPTH_TEST);
        
        /*
        GLfloat lightPosition0[]= { 0.0, 0.0, -3.0f, 1.0f };
        GLfloat lightColor0[] = { 1.0f, 1.0f, 1.0f, 1.0f };
        //光源位置
        glLightfv(GL_LIGHT0, GL_POSITION, lightPosition0);
        //光源颜色
        glLightfv(GL_LIGHT0, GL_DIFFUSE, lightColor0);
        glEnable(GL_LIGHTING);
        glEnable(GL_LIGHT0);*/

        _frameSize = size;
    }
    
    return self;
}

// 更新背景纹理
-(void)updateBackground:(BGRAVideoFrame) frame {
    
    [_glView setFramebuffer];
    
    glPixelStorei(GL_PACK_ALIGNMENT, 1);
    glBindTexture(GL_TEXTURE_2D, _backgroundTextureId);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, frame.width, frame.height, 0, GL_BGRA, GL_UNSIGNED_BYTE, frame.data);
    
    int glErCode = glGetError();
    if (glErCode != GL_NO_ERROR)
    {
        std::cout << glErCode << std::endl;
    }
}


// 画背景纹理
- (void)drawBackground {
    
    GLfloat w = _glView.bounds.size.width;
    GLfloat h = _glView.bounds.size.height;
    
    GLfloat squareVertices[] = {
        
        0, 0,
        w, 0,
        0, h,
        w, h
    };
    
    GLfloat textureVertices[] = {
        
        1, 0,
        1, 1,
        0, 0,
        0, 1
    };
    
    GLfloat proj[] = {
        
        0, -2.f/w, 0, 0,
        -2.f/h, 0, 0, 0,
        0, 0, 1, 0,
        1, 1, 0, 1
    };
    
    glMatrixMode(GL_PROJECTION);
    glLoadMatrixf(proj);
    
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    glDepthMask(FALSE);
    glDisable(GL_COLOR_MATERIAL);
    
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, _backgroundTextureId);
    
    // Update attribute values.
    glVertexPointer(2, GL_FLOAT, 0, squareVertices);
    glEnableClientState(GL_VERTEX_ARRAY);
    glTexCoordPointer(2, GL_FLOAT, 0, textureVertices);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
    glColor4f(1,1,1,1);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisable(GL_TEXTURE_2D);
    
}


// 根据摄像头内参、分辨率等参数计算projectionMatrix
-(void) getProjectionMatrix:(float*)projectionMatrix withFx:(double)fx  Fy:(double)fy
                         Cx:(double)cx  Cy:(double)cy
                          W:(float)width H:(float)height
                          N:(float)near  F:(float)far {
    
    projectionMatrix[0] = 2.0 * fx / width;
    projectionMatrix[1] = 0.0f;
    projectionMatrix[2] = 0.0f;
    projectionMatrix[3] = 0.0f;
    
    projectionMatrix[4] = 0.0f;
    projectionMatrix[5] = 2.0 * fy / height;
    projectionMatrix[6] = 0.0f;
    projectionMatrix[7] = 0.0f;
    
    projectionMatrix[8] = 1.0 - 2.0 * cx / width;
    projectionMatrix[9] = 2.0 * cy / height - 1.0;
    projectionMatrix[10] = - (far + near) / (far - near);
    projectionMatrix[11] = - 1.0;
    
    projectionMatrix[12] = 0.0f;
    projectionMatrix[13] = 0.0f;
    projectionMatrix[14] = - 2.0f * far * near / (far - near);
    projectionMatrix[15] = 0.0f;
}


// 把mat转换为GL格式的矩阵
-(void)getModelViewMatrix:(float*)matrix fromExternalMat:(cv::Mat)mat {
    
    // 绕x轴转180°
    double d[] =
    {
        1,  0,  0,
        0, -1,  0,
        0,  0, -1
    };
    cv::Mat m = cv::Mat(3,3,CV_64FC1,d);
    mat = m * mat;
    
    // 读数据
    matrix[0] = mat.at<double>(0, 0);
    matrix[1] = mat.at<double>(1, 0);
    matrix[2] = mat.at<double>(2, 0);
    matrix[3] = 0.0f;
    
    matrix[4] = mat.at<double>(0, 1);
    matrix[5] = mat.at<double>(1, 1);
    matrix[6] = mat.at<double>(2, 1);
    matrix[7] = 0.0f;
    
    matrix[8] = mat.at<double>(0, 2);
    matrix[9] = mat.at<double>(1, 2);
    matrix[10] = mat.at<double>(2, 2);
    matrix[11] = 0.0f;
    
    matrix[12] = mat.at<double>(0, 3) / MARKER_WIDTH;
    matrix[13] = mat.at<double>(1, 3) / MARKER_WIDTH;
    matrix[14] = mat.at<double>(2, 3) / MARKER_WIDTH;
    matrix[15] = 1.0f;
}


// 画物体
-(void)drawModels {
    
    float projectionMatrix[16];
    [self getProjectionMatrix:projectionMatrix withFx:551.99029541015625 Fy:553.164794921875 Cx:240.441925048828125 Cy:320.7960205078125 W:480.0 H:640.0 N:0.001 F:100.0];
    
    glMatrixMode(GL_PROJECTION);
    glLoadMatrixf(projectionMatrix);
    
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    glDepthMask(TRUE);
    glEnable(GL_DEPTH_TEST);
    
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_NORMAL_ARRAY);
    glEnableClientState(GL_COLOR_MATERIAL);
    
    glPushMatrix();
    
    for (int i = 0; i < self._transformationsWithID.size(); i++) {
        
        TransformationWithID transformation = self._transformationsWithID[i];
        int markerID = transformation.markerID;
        if (markerID == 84317) {
            
            float modelViewMatrix[16];
            [self getModelViewMatrix:modelViewMatrix fromExternalMat:transformation.externalMatrix];
            glLoadMatrixf(modelViewMatrix);
            
            // 简单画线
            /*
            float scale = 0.5;
            glScalef(scale, scale, scale);
             
            glTranslatef(0, 0, 0.1f);
            glLineWidth(5.0f);
             
            float lineX[] = {0,0,0,1,0,0};
            float lineY[] = {0,0,0,0,1,0};
            float lineZ[] = {0,0,0,0,0,1};
             
            glColor4f(1.0f, 0.0f, 0.0f, 1.0f);
            glVertexPointer(3, GL_FLOAT, 0, lineX);
            glDrawArrays(GL_LINES, 0, 2);
             
            glColor4f(0.0f, 1.0f, 0.0f, 1.0f);
            glVertexPointer(3, GL_FLOAT, 0, lineY);
            glDrawArrays(GL_LINES, 0, 2);
             
            glColor4f(0.0f, 0.0f, 1.0f, 1.0f);
            glVertexPointer(3, GL_FLOAT, 0, lineZ);
            glDrawArrays(GL_LINES, 0, 2);
            */
            
            // 加载坐标轴模型
            float scale = 0.5;
            glScalef(scale, scale, scale);
            
            glVertexPointer(3, GL_FLOAT, 0, axisOBJVerts);
            glNormalPointer(GL_FLOAT, 0, axisOBJNormals);
            
            for(int i = 0; i < axisMTLNumMaterials; i++) {
                
                if (i == 1) {
                    
                    glColor4f(1.0f, 0.0f, 0.0f, 1.0f);
                    
                } else if (i == 2){
                    
                    glColor4f(0.0f, 1.0f, 0.0f, 1.0f);
                    
                } else if (i == 3){
                    
                    glColor4f(0.0f, 0.0f, 1.0f, 1.0f);
                    
                } else if (i == 0){
                    
                    glColor4f(1.0f, 1.0f, 0.0f, 1.0f);
                }
                
                /*
                float ambient[] = {axisMTLAmbient[i][0], axisMTLAmbient[i][1], axisMTLAmbient[i][2], 1.0f};
                float diffuse[] = {axisMTLDiffuse[i][0], axisMTLDiffuse[i][1], axisMTLDiffuse[i][2], 1.0f};
                float specular[] = {axisMTLSpecular[i][0], axisMTLSpecular[i][1], axisMTLSpecular[i][2], 1.0f};
                
                glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, ambient);
                glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, diffuse);
                glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, specular);
                glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, axisMTLExponent[i]);
                */
                
                // Draw scene by material group
                glDrawArrays(GL_TRIANGLES, axisMTLFirst[i], axisMTLCount[i]);
            }
        }
    }
    
    glPopMatrix();
    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_NORMAL_ARRAY);
    glDisableClientState(GL_COLOR_MATERIAL);
    
}


// 重绘场景
- (void)drawFrame {
    
    // Set the active framebuffer
    [self._glView setFramebuffer];
    
    // 画背景
    [self drawBackground];
    
    // 画物体
    
    if (!self._transformationsWithID.empty()) {
        
        [self drawModels];
    }
    
    // Present framebuffer
    bool ok = [self._glView presentFramebuffer];
    
    int glErCode = glGetError();
    if (!ok || glErCode != GL_NO_ERROR)
    {
        //std::cerr << "GL error detected. Error code:" << glErCode << std::endl;
    }
}


@end
