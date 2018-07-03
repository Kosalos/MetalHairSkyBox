#import "ManualControlView.h"

short editSelect[EDIT_SELECT];

@implementation ManualControlView

@synthesize allOnButton,allOffButton,hideButton;

enum {
    XC = 128,
    Y1 = 20,
    YH = 6,
    
    HXS = 50,
    HYS = 50,
    TXS = 100,
    TYS = 80,
    PXS = 80,
    PYS = 60,
    SXS = 36,
    SYS = 80,
    AXS = 35,
    AYS = 80,
    DXS = 40,
    DYS = 36,
    GXS = 44,
    GYS = 100,
    CXS = 40,
    CYS = 90,
    FXS = 40,
    FYS = 36
};

CGRect man[EDIT_SELECT] = {
    { { XC-TXS/2,Y1+60 }, { TXS,TYS } },        // torso
    { { XC-HXS/2,Y1}, { HXS,HYS } },            // head
    { { XC+70,Y1+HXS+YH+10 }, {SXS,SYS } },     // rt sh
    { { XC-106,Y1+HXS+YH+10 }, {SXS,SYS } },    // left sh
    { { XC+70,Y1+HXS+105 }, {AXS,AYS } },       // rt arm
    { { XC-104,Y1+HXS+105 }, {AXS,AYS } },      // lt arm
    { { XC+70,Y1+HXS+200 }, {DXS,DYS } },       // rt hand
    { { XC-104,Y1+HXS+200 }, {DXS,DYS } },      // lt hand
    { { XC+6,Y1+HXS+176 }, {GXS,GYS } },        // rt thigh
    { { XC-46,Y1+HXS+176 }, {GXS,GYS } },       // lt thigh
    { { XC+6,Y1+HXS+290 }, {CXS,CYS } },        // rt calf
    { { XC-46,Y1+HXS+290 }, {CXS,CYS } },       // lt calf
    { { XC+6,Y1+HXS+393 }, {FXS,FYS } },        // rt foot
    { { XC-46,Y1+HXS+393 }, {FXS,FYS } },       // lt foot
    { { XC-PXS/2,Y1+HXS+103 }, {PXS,PYS} },     // hip
};

static CGContextRef context;

#define SCOUNT (sizeof(man)/sizeof(man[0]))

-(void)drawFilledRectangle :(CGFloat)x1 :(CGFloat)y1 :(CGFloat)xs :(CGFloat)ys
{
    CGContextFillRect(context,CGRectMake(x1,y1,xs,ys));
}

-(IBAction)buttonPressed :(UIButton *)sender
{
    if(sender == allOffButton) {
        for(int i=0;i<EDIT_SELECT;++i)
            editSelect[i] = 0;
        [self setNeedsDisplay];
    }
    
    if(sender == allOnButton) {
        for(int i=0;i<EDIT_SELECT;++i)
            editSelect[i] = 1;
        [self setNeedsDisplay];
    }
    
    if(sender == hideButton)
        self.hidden = YES;
}

- (void)drawRect:(CGRect)rect
{
    context = UIGraphicsGetCurrentContext();
    
    [[UIColor redColor]set];
    
    for(int i=0;i<SCOUNT;++i) {
        switch(editSelect[i]) {
            case 0 : [[UIColor grayColor]set]; break;
            case 1 : [[UIColor whiteColor]set];   break;
        }
        CGContextFillRect(context,man[i]);
    }
}

-(void)touchesBegan :(NSSet *)touches withEvent :(UIEvent *)event
{
    UITouch *u1 = [[touches allObjects] objectAtIndex:0];
    CGPoint pt = [u1 locationInView:[u1 view]];
    
    for(int i=0;i<EDIT_SELECT;++i) {
        if(CGRectContainsPoint(man[i],pt)) {
            if(++editSelect[i] > 1) editSelect[i] = 0;
            [self setNeedsDisplay];
            return;
        }
    }
}

@end
