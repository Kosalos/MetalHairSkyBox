//
//  MetalView.h
//  BasicTexturing
//
//  Created by Warren Moore on 9/22/14.
//  Copyright (c) 2014 Metal By Example. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

@interface MetalView : UIView

@property (nonatomic, readonly) CAMetalLayer *metalLayer;

@end
