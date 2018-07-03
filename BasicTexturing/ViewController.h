#import <UIKit/UIKit.h>
#import "Renderer.h"
#import "Shared.h"
#import "ManualControlView.h"
#import "Placement.h"

@interface ViewController : UIViewController <UIGestureRecognizerDelegate>

@property (nonatomic,retain) IBOutlet UIButton  *manualButton;
@property (nonatomic,retain) IBOutlet UIButton  *placementButton;

@property (nonatomic,retain) IBOutlet ManualControlView *manualV;
@property (nonatomic,retain) IBOutlet PlacementView *placementV;

-(IBAction)buttonPressed :(UIButton *)sender;

@end

extern float4x4 globalProjectionMatrix;

extern EyeData eye;

extern Light globalLight[NUM_LIGHT];

void abort(const char *filename,int line);

#define ABORT abort(__FILE__,__LINE__)

extern Material *globalMaterial;
extern bool touching;
