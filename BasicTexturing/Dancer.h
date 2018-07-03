#import "common.h"

enum {
    LOCK_LEVEL1 = 24,
    LOCK_LEVEL2 = LOCK_LEVEL1*14,
    
	S1_TORSO = 0,
	S1_HEAD,
	S1_LSHOULDER,
	S1_RSHOULDER,
	S1_LARM,    // 4
	S1_RARM,
	S1_LHAND,   // 6
	S1_RHAND,
	S1_LTHIGH,
	S1_RTHIGH,
	S1_LCALF,   // 10
	S1_RCALF,
	S1_LFOOT,
	S1_RFOOT,
    S1_HIP,     // 14
    S1_HAIR,
	SS_COUNT = S1_HAIR + LOCK_LEVEL1 + LOCK_LEVEL2 + 1,
	
    X=0,Y,Z,
    
    MAX_SEGMENT = SS_COUNT+1
};

typedef struct {
    int xFileIndex;
    int parentIndex;
    VVertex position;
    VVertex angle;
    GLuint textureID;
    char comment[32];
} SegmentData;

typedef struct {
    int meshCount;
    SegmentData data[MAX_SEGMENT];
} Actor;

extern const char *sName[];

@interface Dancer : NSObject

-(void)draw;
-(void)segmentAlter :(int)index :(float)dx :(float)dy;
-(bool)isLegalAngle :(int)segment :(int)axis :(float)angle;

@end

extern Dancer *dancer;
extern Actor actor,defaultActor;
extern int  sIndex;
