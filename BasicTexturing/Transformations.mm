//
//  Transformations.mm
//  BasicTexturing
//
//  Created by Warren Moore on 9/27/14.
//  Copyright (c) 2014 Metal By Example. All rights reserved.
//

#import "Transformations.h"

float4x4 Identity()
{
    float4 X = { 1, 0, 0, 0 };
    float4 Y = { 0, 1, 0, 0 };
    float4 Z = { 0, 0, 1, 0 };
    float4 W = { 0, 0, 0, 1 };
    
    float4x4 identity(X, Y, Z, W);
    
    return identity;
}

float4x4 RotationX(float angle)
{
    float c = cosf(angle);
    float s = sinf(angle);
    
    float4 X = { 1,0,0,0 };
    float4 Y = { 0,c,-s,0 };
    float4 Z = { 0,s,c,0 };
    float4 W = { 0,0,0,1 };
    
    float4x4 mat = { X, Y, Z, W };
    return mat;
}

float4x4 RotationY(float angle)
{
    float c = cosf(angle);
    float s = sinf(angle);
    
    float4 X = { c,0,s,0 };
    float4 Y = { 0,1,0,0 };
    float4 Z = { -s,0,c,0 };
    float4 W = { 0,0,0,1 };
    
    float4x4 mat = { X, Y, Z, W };
    return mat;
}

float4x4 RotationZ(float angle)
{
    float c = cosf(angle);
    float s = sinf(angle);
    
    float4 X = { c,-s,0,0 };
    float4 Y = { s,c,0,0 };
    float4 Z = { 0,0,1,0 };
    float4 W = { 0,0,0,1 };
    
    float4x4 mat = { X, Y, Z, W };
    return mat;
}

float4x4 PerspectiveProjection(float aspect, float fovy, float near, float far)
{
    float yScale = 1 / tan(fovy * 0.5);
    float xScale = yScale / aspect;
    float zRange = far - near;
    float zScale = -(far + near) / zRange;
    float wzScale = -2 * far * near / zRange;
    
    float4 P = { xScale, 0, 0, 0 };
    float4 Q = { 0, yScale, 0, 0 };
    float4 R = { 0, 0, zScale, -1 };
    float4 S = { 0, 0, wzScale, 0 };
    
    float4x4 mat = { P, Q, R, S };
    return mat;
}

float3x3 UpperLeft3x3(const float4x4 &mat4x4)
{
    return float3x3(mat4x4.columns[0].xyz, mat4x4.columns[1].xyz, mat4x4.columns[2].xyz);
}

float4x4 Translate(float dx,float dy,float dz)
{
    float4x4 mat = Identity();
    
    mat.columns[3].x = dx;
    mat.columns[3].y = dy;
    mat.columns[3].z = dz;
    
    return mat;
}
