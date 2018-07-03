#import <UIKit/UIKit.h>

enum {
    EDIT_SELECT = 15
};

extern short editSelect[EDIT_SELECT];

@interface ManualControlView : UIView

@property (nonatomic,retain) IBOutlet UIButton  *allOnButton;
@property (nonatomic,retain) IBOutlet UIButton  *allOffButton;
@property (nonatomic,retain) IBOutlet UIButton  *hideButton;

-(IBAction)buttonPressed :(UIButton *)sender;

@end
