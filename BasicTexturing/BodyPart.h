#import <UIKit/UIKit.h>
#import "Shared.h"

@interface BodyPart : NSObject {
    @public ColorData colorData;
}

-(instancetype)initWithOBJfile:(NSString *)filename;
-(void)update:(float4x4)modelView :(bool)highlight;
-(void)update:(float4x4)modelView :(bool)highlight :(float)scale;
-(void)updateA:(float4x4)modelView :(float)scale :(float)alpha;

-(void)draw;

@end
