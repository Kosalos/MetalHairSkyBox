//
//  Mesh.h
//  BasicTexturing
//
//  Created by Warren Moore on 9/27/14.
//  Copyright (c) 2014 Metal By Example. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

@interface Mesh : NSObject {
    @public unsigned long count;
}

@property (strong) id<MTLBuffer> vertexBuffer;
@property (strong) id<MTLBuffer> indexBuffer;

- (instancetype)initWithVertexBuffer:(id<MTLBuffer>)vertexBuffer
                         indexBuffer:(id<MTLBuffer>)indexBuffer;

@end
