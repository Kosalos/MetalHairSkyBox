//
//  Mesh.m
//  BasicTexturing
//
//  Created by Warren Moore on 9/27/14.
//  Copyright (c) 2014 Metal By Example. All rights reserved.
//

#import "Mesh.h"
#import <QuartzCore/CAMetalLayer.h>

@implementation Mesh

- (instancetype)initWithVertexBuffer:(id<MTLBuffer>)vertexBuffer
                         indexBuffer:(id<MTLBuffer>)indexBuffer
{
    if ((self = [super init]))
    {
        _vertexBuffer = vertexBuffer;
        _indexBuffer = indexBuffer;
        
        count = [indexBuffer length] / sizeof(UInt16);
    }
    return self;
}

@end
