//
//  Material.m
//  BasicTexturing
//
//  Created by Warren Moore on 9/27/14.
//  Copyright (c) 2014 Metal By Example. All rights reserved.
//

#import "Material.h"

@implementation Material

- (instancetype)initWithVertexFunction:(id<MTLFunction>)vertexFunction
                      fragmentFunction:(id<MTLFunction>)fragmentFunction
                        diffuseTexture:(id<MTLTexture>)diffuseTexture
{
    if ((self = [super init]))
    {
        _vertexFunction = vertexFunction;
        _fragmentFunction = fragmentFunction;
        _diffuseTexture = diffuseTexture;
    }
    return self;
}

@end
