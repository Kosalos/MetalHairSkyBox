#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

enum {
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    ATTRIB_TEXTURE,
    NUM_ATTRIBUTES,
    
    UNIFORM_MV_MATRIX = 0,
    UNIFORM_MVP_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    UNIFORM_TEXTURE,
    UNIFORM_COLOR,
    UNIFORM_DRAWSTYLE,
    NUM_UNIFORMS,
    
    NONE = -1,
    
    STYLE_WIREFRAME = 0,
    STYLE_TEXTURE,
    STYLE_COLORPICK
};

typedef struct VVertex {
    float x, y, z;
    float nx, ny, nz;
    float u, v;
} VVertex;

typedef struct VertexA {
    float pt[3];
} VertexA;

typedef struct {
    float pt[4];  //GLfloat x,y,z,w;
} Vertex4;


/*
 
 -(float4x4)convertToFloat4x4FromGLKMatrix:(GLKMatrix4)matrix
 2	{
 3	    return float4x4(
 4	                    float4 {matrix.m00,matrix.m01,matrix.m02,matrix.m03 },
 5	                    float4{ matrix.m10,matrix.m11,matrix.m12,matrix.m13 },
 6	                    float4{ matrix.m20,matrix.m21,matrix.m22,matrix.m23 },
 7	                    float4{ matrix.m30,matrix.m31,matrix.m32,matrix.m33 }
 8	                    );
 9	}
 
 */