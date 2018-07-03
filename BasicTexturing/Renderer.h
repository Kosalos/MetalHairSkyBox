//
//  Renderer.h
//  BasicTexturing
//
//  Created by Warren Moore on 9/25/14.
//  Copyright (c) 2014 Metal By Example. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import "Shared.h"

@class Mesh, Material, OBJGroup;

@interface Renderer : NSObject

@property (strong) UIColor *clearColor;

- (instancetype)initWithView:(UIView *)view;

/// Creates a new material with the specified pair of vertex/fragment functions and
/// the specified diffuse texture name. The texture name must refer to a PNG resource
/// in the main bundle in order to be loaded successfully.
- (Material *)newMaterialWithVertexFunctionNamed:(NSString *)vertexFunctionName
                           fragmentFunctionNamed:(NSString *)fragmentFunctionName
                             diffuseTextureNamed:(NSString *)diffuseTextureName;

/// Creates a new mesh object from the specified OBJ group
- (Mesh *)newMeshWithOBJGroup:(OBJGroup *)group;
- (id<MTLBuffer>)newBufferWithBytes:(const void *)bytes length:(NSUInteger)length;

- (void)startFrame;

- (void)drawMesh:(Mesh *)drawable withMaterial:(Material *)material : (id<MTLBuffer>)uni;

- (void)endFrame;

- (void)drawTrianglesWithInterleavedBuffer:(id<MTLBuffer>)positionBuffer
                               indexBuffer:(id<MTLBuffer>)indexBuffer
                             uniformBuffer:(id<MTLBuffer>)uniformBuffer
                                indexCount:(size_t)indexCount;

@end

extern Renderer *renderer;
