#import "ViewController.h"
#import "OBJModel.h"
#import "Renderer.h"
#import "Transformations.h"
#import "Dancer.h"
#import "ManualControlView.h"
#import "BodyPart.h"

EyeData eye;
float4x4 globalProjectionMatrix;

Material *globalMaterial;

Light globalLight[NUM_LIGHT] = {
    {
        true,
        { .1,.1,0 },  // { 0.13, 0.72, 0.68 },   // direction
        { 0,0,0 },            // ambientColor
        { 1,1,1 },      // diffuseColor
        { 1,1,1 },             // specularColor
       300
    },
    {
        true,
        { .1,.1,.5 },  // { 0.13, 0.72, 0.68 },   // direction
        { 0,0,0 },            // ambientColor
        { 1,1,1 },      // diffuseColor
        { 1,1,1 },             // specularColor
        300
    },
    
};

void abort(const char *filename,int line)
{
    printf("****\nAbort at %s, line %d\n",filename,line);
    exit(0);
}

@interface ViewController ()
@property (nonatomic, strong) CADisplayLink *redrawTimer;
@property (nonatomic, assign) NSTimeInterval lastMooTime;
@property (nonatomic, assign) CGPoint angularVelocity;
@property (nonatomic, assign) CGPoint angle;
@property (nonatomic, assign) NSTimeInterval lastFrameTime;
@end

@implementation ViewController

@synthesize manualButton,placementButton;

- (void)dealloc
{
    [_redrawTimer invalidate];
}


-(BOOL)prefersStatusBarHidden{
    return YES;
}

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
    [self.view addGestureRecognizer:pinchRecognizer];
    
    renderer = [[Renderer alloc] initWithView:self.view];
    dancer = [[Dancer alloc]init];
    
    const float near = 0.1;
    const float far = 1000;
    const float aspect = self.view.bounds.size.width / self.view.bounds.size.height;
    globalProjectionMatrix = PerspectiveProjection(aspect, DEGREES_TO_RADIANS(75), near, far);

    globalMaterial = [renderer newMaterialWithVertexFunctionNamed:@"vertex_main"
                                            fragmentFunctionNamed:@"fragment_main"
                                              diffuseTextureNamed:@"calf"];
    
    [self initialAngle];

    _placementV.hidden = YES;
    _manualV.hidden = YES;
    for(int i=0;i<EDIT_SELECT;++i)
        editSelect[i] = 1;
    
    [self.view setOpaque:YES];
    [self.view setBackgroundColor:nil];
    [self.view setContentScaleFactor:[UIScreen mainScreen].scale];

}

- (void)pinch:(UIPinchGestureRecognizer *)recognizer
{
    CGFloat s = recognizer.scale;
    s = 1 + (s-1)/30.0;
    
    eye.position.z /= s;
    if(eye.position.z > -5) eye.position.z = -5; else
        if(eye.position.z < -400) eye.position.z = -400;
}

-(IBAction)buttonPressed :(UIButton *)sender
{
    CGRect bd = [self.view bounds];

    if(sender == manualButton) {
        const int xs = 256;
        const int ys = 520;
        [_manualV setFrame:CGRectMake(0,bd.size.height - ys,xs,ys)];

        _manualV.hidden = NO;
    }

    if(sender == placementButton) {
        const int xs = 560;
        const int ys = 190;
        [_placementV setFrame:CGRectMake(bd.size.width-xs,bd.size.height-ys,xs,ys)];
        
        [_placementV appear];
    }
}

-(void)initialAngle
{
    eye.angle.x = -1.9;
    eye.angle.y = 6.7;

    eye.delta.x = 0;
    eye.delta.y = 0;
    
    eye.position.x = 0;
    eye.position.y = 5;
    eye.position.z = -60;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.redrawTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(redrawTimerDidFire:)];
    [self.redrawTimer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.redrawTimer invalidate];
    self.redrawTimer = nil;
}

- (void)redrawTimerDidFire:(CADisplayLink *)sender
{
    [self redraw];
}

#pragma mark -

CGPoint lastPt;
bool touching = false;
float dx,dy;

-(void)touchesBegan :(NSSet *)touches withEvent :(UIEvent *)event
{

    
    NSArray *a = [touches allObjects];
    for(int i=0;i < (int)touches.count;++i) {
        UITouch *u1 = [a objectAtIndex:i];
        lastPt = [u1 locationInView:[u1 view]];
        
        if(lastPt.x < 50 && lastPt.y < 50) {
            [self initialAngle];
            memcpy(&actor,&defaultActor,sizeof(actor));
            return;
        }
        
        touching = true;
    }
}

-(void)touchesMoved :(NSSet *)touches withEvent :(UIEvent *)event
{
    if(!touching) return;
    
    static float DEN = 1000.0;
    NSArray *a = [touches allObjects];
    for(int i=0;i < (int)touches.count;++i) {
        UITouch *u1 = [a objectAtIndex:i];
        CGPoint pt = [u1 locationInView:[u1 view]];
        
        dx = (lastPt.x - pt.x);
        dy = (lastPt.y - pt.y);
        
        eye.delta.y = (lastPt.x - pt.x)/DEN;
        eye.delta.x = (lastPt.y - pt.y)/DEN;

        for(int j=0;j<EDIT_SELECT;++j) {
            if(editSelect[j] == 1)
               [dancer segmentAlter:j:dx:dy];
        }
        
        lastPt = pt;
    }
}

-(void)touchesEnded :(NSSet *)touches withEvent :(UIEvent *)event
{
    touching = false;
}

#pragma mark -

#define MINMOVE 0.5
#define MOVEDECAY 0.98

-(void)redraw
{
    static float slowDown = 0.999;
    eye.angle.x += eye.delta.x;
    eye.angle.y += eye.delta.y;
    eye.delta.x *= slowDown;
    eye.delta.y *= slowDown;
    
//    static float aa;
//    globalLight[0].direction.x = sinf(aa);
//    globalLight[0].direction.y = cosf(aa);
//    globalLight[0].direction.z = cosf(aa/2);
//    
//    globalLight[1].direction.x = -cosf(aa * 2);
//    globalLight[1].direction.y = sinf(aa * 2);
//    globalLight[1].direction.z = cosf(aa/2);
//
//    aa += 0.03;
//    
    [renderer startFrame];
    
    if(!touching) {
        if(fabs(dx) > MINMOVE) dx *= MOVEDECAY; else dx = 0;
        if(fabs(dy) > MINMOVE) dy *= MOVEDECAY; else dy = 0;
        
        if(fabs(dx)>0 || fabs(dy)>0) {
            for(int j=0;j<EDIT_SELECT;++j) {
                if(editSelect[j] == 1)
                    [dancer segmentAlter:j:dx:dy];
            }
            
        //    printf("Move %f %f\n",dx,dy);
        }
    }
    
    actor.data[0].position.x = 0;
    actor.data[0].position.y = 0;
    
    [dancer draw];
    
    [renderer endFrame];
}

@end

/*
 
 http://www.yelp.com/biz/mikes-auto-tops-and-upholstery-mission-viejo
 http://www.yelp.com/biz/willys-auto-upholstery-laguna-niguel
 http://www.yelp.com/biz/kennys-auto-upholstery-mission-viejo-2
 
*/
//Kee 330   // http://www.gomiata.com/keeautopmxmi11.html
// sierra 439 // http://www.gomiata.com/rosoto.html
// robbins 520
// gahh 534

// $390 http://www.topsonline.com/model/Convertible_Tops_And_Accessories/Mazda/1998_thru_2005_Mazda_Miata_MX5_And_MX5_Eunos.html

// do yourself $300
// https://www.convertibletopguys.com/convertible/746/1999-05-Mazda-Miata-Miata-MX-5-Shinsen-quot;Easy-Install-quot;-One-Piece-Convertible-Tops

// http://www.prestigemobileupholstery.com/convertible_top_install  come to you / anaheim
// http://www.aaaconvertible.com/contact.html                       costa mesa 17th
// http://www.ocroyalupholstery.com/g allery/auto-upholstery.aspx  laguna beach
