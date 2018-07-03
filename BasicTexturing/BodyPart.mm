#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import "Renderer.h"
#import "BodyPart.h"
#import "Shared.h"
#import "Transformations.h"
#import "ViewController.h"
#import "OBJModel.h"
#import "Mesh.h"

@interface BodyPart ()
@property (nonatomic, strong) Mesh *mesh;
@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;
@property (nonatomic, strong) id<MTLBuffer> indexBuffer;
@property (nonatomic, strong) id<MTLBuffer> uniformBuffer;
@end

@implementation BodyPart

-(instancetype)initWithOBJfile:(NSString *)filename
{
    if((self = [super init])) {
        [self loadObj:filename];
        
        // default Material ---
        colorData.ambientColor = { 1,1,1 };
        colorData.diffuseColor = { 1,1,1 };
        colorData.specularColor = { 1, 1, 0.8 };
        colorData.alpha = 1;
    }
    
    return self;
}

-(void)update:(float4x4)modelView :(bool)highlight
{
    Uniforms uniforms;
    uniforms.modelViewMatrix = modelView;
    
    float4x4 modelViewProj = globalProjectionMatrix * modelView;
    uniforms.modelViewProjectionMatrix = modelViewProj;
    
    float3x3 normalMatrix = { modelView.columns[0].xyz, modelView.columns[1].xyz, modelView.columns[2].xyz };
    uniforms.normalMatrix = transpose(inverse(normalMatrix));
    
    colorData.ambientColor.x = highlight ? 1 : 0.8;
    colorData.ambientColor.y = highlight ? 1 : 0.8;
    colorData.ambientColor.z = highlight ? 1 : 0.8;
    uniforms.material = colorData;
    
    for(int i=0;i<NUM_LIGHT;++i)
        uniforms.light[i] = globalLight[i];
    
    uniforms.scale = 1.0;
    
    _uniformBuffer = [renderer newBufferWithBytes:(void *)&uniforms length:sizeof(Uniforms)];
}

-(void)update:(float4x4)modelView :(bool)highlight :(float)scale
{
    Uniforms uniforms;
    uniforms.modelViewMatrix = modelView;
    
    float4x4 modelViewProj = globalProjectionMatrix * modelView;
    uniforms.modelViewProjectionMatrix = modelViewProj;
    
    float3x3 normalMatrix = { modelView.columns[0].xyz, modelView.columns[1].xyz, modelView.columns[2].xyz };
    uniforms.normalMatrix = transpose(inverse(normalMatrix));
    
    colorData.ambientColor.x = highlight ? 1 : 0.8;
    colorData.ambientColor.y = highlight ? 1 : 0.8;
    colorData.ambientColor.z = highlight ? 1 : 0.8;
    uniforms.material = colorData;
    
    for(int i=0;i<NUM_LIGHT;++i)
        uniforms.light[i] = globalLight[i];
    
    uniforms.scale = scale;
    
    _uniformBuffer = [renderer newBufferWithBytes:(void *)&uniforms length:sizeof(Uniforms)];
}

-(void)updateA:(float4x4)modelView :(float)sscale :(float)aalpha
{
    Uniforms uniforms;
    uniforms.modelViewMatrix = modelView;
    
    float4x4 modelViewProj = globalProjectionMatrix * modelView;
    uniforms.modelViewProjectionMatrix = modelViewProj;
    
    float3x3 normalMatrix = { modelView.columns[0].xyz, modelView.columns[1].xyz, modelView.columns[2].xyz };
    uniforms.normalMatrix = transpose(inverse(normalMatrix));
    
    colorData.ambientColor.x = 0.8;
    colorData.ambientColor.y = 0.8;
    colorData.ambientColor.z = 0.8;
    
    colorData.alpha = aalpha;
    uniforms.material = colorData;
    
    for(int i=0;i<NUM_LIGHT;++i)
        uniforms.light[i] = globalLight[i];
    
    uniforms.scale = sscale;
    
    _uniformBuffer = [renderer newBufferWithBytes:(void *)&uniforms length:sizeof(Uniforms)];
}


-(void)draw
{
    [renderer drawMesh:_mesh withMaterial:globalMaterial : _uniformBuffer];
}

-(Mesh *)loadMesh:(NSString *)objName
{
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:objName withExtension:@"obj"];
    if(!modelURL) ABORT;
    
    OBJModel *model = [[OBJModel alloc] initWithContentsOfURL:modelURL generateNormals:NO];
    if(!model) ABORT;
    
    return [renderer newMeshWithOBJGroup:[model.groups objectAtIndex:1]];
}


-(void)loadObj:(NSString *)filename
{
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:filename withExtension:@"obj"];
    if(!modelURL) ABORT;
    
    OBJModel *model = [[OBJModel alloc] initWithContentsOfURL:modelURL generateNormals:NO];
    if(!model) ABORT;
    
    _mesh = [renderer newMeshWithOBJGroup:[model.groups objectAtIndex:1]];
}

@end
