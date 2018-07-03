#pragma once

#include <simd/simd.h>

using namespace simd;

enum {
    NUM_LIGHT = 2
};

typedef struct
{
    float3 position;
    float2 angle;
    float2 delta;
} EyeData;

struct ColorData
{
    float3 ambientColor;
    float3 diffuseColor;
    float3 specularColor;
    float   alpha;
};

struct Light
{
    bool active;
    float3 direction;
    float3 ambientColor;
    float3 diffuseColor;
    float3 specularColor;
    float   specularPower;
};

typedef struct
{
    float4x4 modelViewProjectionMatrix;
    float4x4 modelViewMatrix;
    float3x3 normalMatrix;
    ColorData material;
    Light light[NUM_LIGHT];
    float scale;
} Uniforms;

struct MVertex
{
    float4 position;
    float3 normal;
    float2 texCoords;
};

typedef short IndexType;
