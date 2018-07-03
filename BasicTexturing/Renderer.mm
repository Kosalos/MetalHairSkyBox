#import "Renderer.h"
#import "Material.h"
#import "Mesh.h"
#import "Transformations.h"
#import "OBJGroup.h"
#import <QuartzCore/CAMetalLayer.h>
#import "ViewController.h"
#import "SkyBox.h"

Renderer *renderer = nil;

@interface Renderer ()

@property (strong) UIView *view;
@property (weak) CAMetalLayer *layer;
@property (strong) id<MTLDevice> device;
@property (strong) id<MTLLibrary> library;
@property (strong) id<MTLRenderPipelineState> pipeline;
@property (strong) id<MTLCommandQueue> commandQueue;
@property (assign, getter=isPipelineDirty) BOOL pipelineDirty;
@property (strong) id<MTLTexture> depthTexture;
@property (strong) id<MTLSamplerState> sampler;
@property (strong) MTLRenderPassDescriptor *currentRenderPass;
@property (strong) id<CAMetalDrawable> currentDrawable;
@property (assign) float4x4 normalMatrix;

@property (strong) id<MTLCommandBuffer> commandBuffer;
@property (strong) id<MTLRenderCommandEncoder> commandEncoder;

@property (nonatomic, strong) id<MTLBuffer> uniformBuffer;

@end

@implementation Renderer

- (instancetype)initWithView:(UIView *)view
{
    if ((self = [super init]))
    {
        renderer = self;
        
        NSAssert([view.layer isKindOfClass:[CAMetalLayer class]], @"Layer type of view used for rendering must be CAMetalLayer");

        _view = view;
        _layer = (CAMetalLayer *)view.layer;
        _clearColor = [UIColor colorWithWhite:0.95 alpha:1];
        _pipelineDirty = YES;
        _device = MTLCreateSystemDefaultDevice();
        [self initializeDeviceDependentObjects];
    }
    
    return self;
}

- (void)initializeDeviceDependentObjects
{
    _library = [_device newDefaultLibrary];
    
    _commandQueue = [_device newCommandQueue];
    
    MTLSamplerDescriptor *samplerDescriptor = [MTLSamplerDescriptor new];
    samplerDescriptor.minFilter = MTLSamplerMinMagFilterNearest;
    samplerDescriptor.magFilter = MTLSamplerMinMagFilterLinear;
    _sampler = [_device newSamplerStateWithDescriptor:samplerDescriptor];
    
    // skybox -----------------------------
    skyBox.loadAssets(_device,_library);
    
    //0 	Positive X
    //1 	Negative X
    //2 	Positive Y
    //3 	Negative Y
    //4 	Positive Z
    //5 	Negative Z
    
//    NSArray *imageNames = @[
//                            @"jajsundown1_right.jpg",
//                            @"jajsundown1_left.jpg",
//                            @"jajsundown1_top.jpg",
//                            @"jajsundown1_top.jpg", // bottom
//                            @"jajsundown1_front.jpg",
//                            @"jajsundown1_back.jpg"];
    NSArray *imageNames = @[
            @"rt.png",@"lf.png",
            @"up.png",@"dn.png",
            @"bk.png",@"ft.png"];
    
    bool loaded = skyBox.load6Textures(_device,imageNames);
    
    //    bool loaded = skyBox.loadTexture(device,@"skybox");
    if (!loaded)
        NSLog(@"failed to load skybox texture");
}

- (id<MTLTexture>)textureForImage:(UIImage *)image
{
    CGImageRef imageRef = [image CGImage];
    
    // Create a suitable bitmap context for extracting the bits of the image
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    uint8_t *rawData = (uint8_t *)calloc(height * width * 4, sizeof(uint8_t));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);

    // Flip the context so the positive Y axis points down
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1, -1);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                                                 width:width
                                                                                                height:height
                                                                                             mipmapped:YES];
    id<MTLTexture> texture = [self.device newTextureWithDescriptor:textureDescriptor];
    
    MTLRegion region = MTLRegionMake2D(0, 0, width, height);
    [texture replaceRegion:region mipmapLevel:0 withBytes:rawData bytesPerRow:bytesPerRow];

    free(rawData);

    return texture;
}

- (Material *)newMaterialWithVertexFunctionNamed:(NSString *)vertexFunctionName
                           fragmentFunctionNamed:(NSString *)fragmentFunctionName
                             diffuseTextureNamed:(NSString *)diffuseTextureName
{
    id<MTLFunction> vertexFunction = [self.library newFunctionWithName:vertexFunctionName];
    
    if (!vertexFunction)
    {
        NSLog(@"Could not load vertex function named \"%@\" from default library", vertexFunctionName);
        return nil;
    }
    
    id<MTLFunction> fragmentFunction = [self.library newFunctionWithName:fragmentFunctionName];
    
    if (!fragmentFunction)
    {
        NSLog(@"Could not load fragment function named \"%@\" from default library", fragmentFunctionName);
        return nil;
    }

    UIImage *diffuseTextureImage = [UIImage imageNamed:diffuseTextureName];
    if (!diffuseTextureImage)
    {
        NSLog(@"Unable to find PNG image named \"%@\" in main bundle", diffuseTextureName);
        return nil;
    }
    
    id<MTLTexture> diffuseTexture = [self textureForImage:diffuseTextureImage];
    if (!diffuseTexture)
    {
        NSLog(@"Could not create a texture from an image");
    }

    Material *material = [[Material alloc] initWithVertexFunction:vertexFunction
                                                 fragmentFunction:fragmentFunction
                                                   diffuseTexture:diffuseTexture];

    return material;
}

- (Mesh *)newMeshWithOBJGroup:(OBJGroup *)group
{
    id<MTLBuffer> vertexBuffer = [self.device newBufferWithBytes:group.vertexData.bytes
                                                          length:group.vertexData.length
                                                         options:MTLResourceOptionCPUCacheModeDefault];
    
    id<MTLBuffer> indexBuffer = [self.device newBufferWithBytes:group.indexData.bytes
                                                         length:group.indexData.length
                                                        options:MTLResourceOptionCPUCacheModeDefault];

    Mesh *mesh = [[Mesh alloc] initWithVertexBuffer:vertexBuffer indexBuffer:indexBuffer];
    return mesh;
}

- (void)createDepthBuffer
{
    CGSize drawableSize = self.layer.drawableSize;
    MTLTextureDescriptor *depthTexDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float
                                                                                            width:drawableSize.width
                                                                                           height:drawableSize.height
                                                                                        mipmapped:NO];
    self.depthTexture = [self.device newTextureWithDescriptor:depthTexDesc];
}

- (void)configurePipelineWithMaterial:(Material *)material
{
    MTLVertexDescriptor *vertexDescriptor = [MTLVertexDescriptor vertexDescriptor];
    vertexDescriptor.attributes[0].format = MTLVertexFormatFloat4;
    vertexDescriptor.attributes[0].bufferIndex = 0;
    vertexDescriptor.attributes[0].offset = offsetof(MVertex, position);
    
    vertexDescriptor.attributes[1].format = MTLVertexFormatFloat3;
    vertexDescriptor.attributes[1].bufferIndex = 0;
    vertexDescriptor.attributes[1].offset = offsetof(MVertex, normal);
    
    vertexDescriptor.attributes[2].format = MTLVertexFormatFloat2;
    vertexDescriptor.attributes[2].bufferIndex = 0;
    vertexDescriptor.attributes[2].offset = offsetof(MVertex, texCoords);
    
    vertexDescriptor.layouts[0].stride = sizeof(MVertex);
    vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.vertexFunction = material.vertexFunction;
    pipelineDescriptor.fragmentFunction = material.fragmentFunction;
    pipelineDescriptor.vertexDescriptor = vertexDescriptor;
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    
    MTLRenderPipelineColorAttachmentDescriptor *cc = pipelineDescriptor.colorAttachments[0];
    cc.pixelFormat = MTLPixelFormatBGRA8Unorm;
    cc.blendingEnabled = YES;
    cc.rgbBlendOperation = MTLBlendOperationAdd;
    cc.alphaBlendOperation = MTLBlendOperationAdd;
    cc.sourceRGBBlendFactor = MTLBlendFactorOne;
    cc.sourceAlphaBlendFactor = MTLBlendFactorOne;
    cc.destinationRGBBlendFactor =   MTLBlendFactorOneMinusSourceAlpha;
    cc.destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    
    NSError *error = nil;
    self.pipeline = [self.device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    if (!self.pipeline) NSLog(@"Error occurred when creating render pipeline state: %@", error);
}

- (id<MTLBuffer>)newBufferWithBytes:(const void *)bytes length:(NSUInteger)length
{
    return [self.device newBufferWithBytes:bytes
                                    length:length
                                   options:MTLResourceOptionCPUCacheModeDefault];
}

float4x4 sbeyePositionMatrix()
{
    float4x4 mvm = RotationY(-eye.angle.y);
    mvm = mvm * RotationZ(-eye.angle.x);
    return mvm;
}

- (void)startFrame
{
    CGSize drawableSize = self.layer.drawableSize;

    if (!self.depthTexture || self.depthTexture.width != drawableSize.width || self.depthTexture.height != drawableSize.height)
        [self createDepthBuffer];
    
    id<CAMetalDrawable> drawable = [self.layer nextDrawable];  NSAssert(drawable != nil, @"Could not retrieve drawable from Metal layer");
    
    static MTLRenderPassDescriptor *renderPass = nil;
    static MTLDepthStencilDescriptor *depthStencilDescriptor = nil;
    static id<MTLDepthStencilState> depthStencilStateNO;
    static id<MTLDepthStencilState> depthStencilStateYES;
    
    if(!renderPass) {
        renderPass = [MTLRenderPassDescriptor renderPassDescriptor];

        renderPass.colorAttachments[0].loadAction = MTLLoadActionDontCare;
        renderPass.colorAttachments[0].storeAction = MTLStoreActionStore;
        
//        float cc = 100.0/256.0;
//        renderPass.colorAttachments[0].clearColor = MTLClearColorMake(cc,cc, 0,1);

        renderPass.depthAttachment.texture = self.depthTexture;
        renderPass.depthAttachment.loadAction = MTLLoadActionClear;
        renderPass.depthAttachment.storeAction = MTLStoreActionStore;
        renderPass.depthAttachment.clearDepth = 1;
        
        depthStencilDescriptor = [MTLDepthStencilDescriptor new];
        depthStencilDescriptor.depthCompareFunction = MTLCompareFunctionLess;
        depthStencilDescriptor.depthWriteEnabled = NO;
        depthStencilStateNO = [_device newDepthStencilStateWithDescriptor:depthStencilDescriptor];
        
        depthStencilDescriptor.depthWriteEnabled = YES;
        depthStencilStateYES = [_device newDepthStencilStateWithDescriptor:depthStencilDescriptor];
    }
    renderPass.colorAttachments[0].texture = drawable.texture;
    
    self.currentDrawable = drawable;
    self.currentRenderPass = renderPass;

    _commandBuffer = [self.commandQueue commandBuffer];
    
    _commandEncoder = [_commandBuffer renderCommandEncoderWithDescriptor:self.currentRenderPass];
    [_commandEncoder setCullMode:MTLCullModeBack];
    [_commandEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
    
    // sky -----------------------------------
    [_commandEncoder setDepthStencilState:depthStencilStateNO];

    Uniforms uniforms;
    uniforms.modelViewProjectionMatrix = globalProjectionMatrix * sbeyePositionMatrix();
    id<MTLBuffer> uniformBuffer = [renderer newBufferWithBytes:(void *)&uniforms length:sizeof(Uniforms)];
    skyBox.draw(uniformBuffer,_commandEncoder,_view);
    [_commandEncoder setDepthStencilState:depthStencilStateYES];
}

- (void)drawMesh:(Mesh *)mesh withMaterial:(Material *)material :(id<MTLBuffer>)uni
{
    [_commandEncoder setVertexBuffer:uni offset:0 atIndex:1];
    [_commandEncoder setFragmentBuffer:uni offset:0 atIndex:0];
    [_commandEncoder setVertexBuffer:mesh.vertexBuffer offset:0 atIndex:0];
    
    [_commandEncoder setFragmentTexture:material.diffuseTexture atIndex:0];
    [_commandEncoder setFragmentSamplerState:self.sampler atIndex:0];
    
    static bool first = true;
    if(first) {
        first = false;
        [self configurePipelineWithMaterial:material];
    }
    [_commandEncoder setRenderPipelineState:self.pipeline];
    
    [_commandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle // LineStrip
                               indexCount:mesh->count
                                indexType:MTLIndexTypeUInt16
                              indexBuffer:mesh.indexBuffer
                        indexBufferOffset:0];
}

- (void)drawTrianglesWithInterleavedBuffer:(id<MTLBuffer>)positionBuffer
                               indexBuffer:(id<MTLBuffer>)indexBuffer
                             uniformBuffer:(id<MTLBuffer>)uniformBuffer
                                indexCount:(size_t)indexCount
{
    [_commandEncoder setVertexBuffer:positionBuffer offset:0 atIndex:0];
    [_commandEncoder setVertexBuffer:uniformBuffer offset:0 atIndex:1];
    [_commandEncoder setFragmentBuffer:uniformBuffer offset:0 atIndex:0];
    
    [_commandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                                    indexCount:indexCount
                                     indexType:MTLIndexTypeUInt16
                                   indexBuffer:indexBuffer
                             indexBufferOffset:0];
}

- (void)endFrame
{
    [_commandEncoder endEncoding];
    [_commandBuffer presentDrawable:self.currentDrawable];
    [_commandBuffer commit];
}

@end
