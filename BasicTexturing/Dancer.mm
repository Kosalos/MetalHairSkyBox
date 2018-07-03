#import "Shared.h"
#import "Dancer.h"
#import "BodyPart.h"
#import "ViewController.h"
#import "Transformations.h"

#define RAD(angle) ((angle) / 180.0 * M_PI)

Dancer *dancer = NULL;
Actor actor,defaultActor;

int sIndex = NONE;

enum {
	XFILE_FOOT = 0,
	XFILE_CALF,
	XFILE_THIGH,
	XFILE_TORSO,
	XFILE_HIP,
	XFILE_SHOULDER,
	XFILE_ARM,
	XFILE_HAND,
	XFILE_HEAD,
    XFILE_HAIR,
    XFILE_HAIRLOCK,
	BLENDER_COUNT,
};

const char *sName[] =
{
	"Torso",
	"Head",
	"Left Shoulder",
	"Right Shoulder",
	"Left Arm",
	"Right Arm",
	"Left Hand",
	"Right Hand",
	"Left Thigh",
	"Right Thigh",
	"Left Calf",
	"Right Calf",
	"Left Foot",
	"Right Foot",
    "Hip",
    "Hair",
    "Lock",
	
	"Torso",
	"Head",
	"Left Shoulder",
	"Right Shoulder",
	"Left Arm",
	"Right Arm",
	"Left Hand",
	"Right Hand",
	"Left Thigh",
	"Right Thigh",
	"Left Calf",
	"Right Calf",
	"Left Foot",
	"Right Foot",
	"Hip"
};

BodyPart *head = nil;
BodyPart *arm = nil;
BodyPart *foot = nil;
BodyPart *hand = nil;
BodyPart *hip = nil;
BodyPart *calf = nil;
BodyPart *thigh = nil;
BodyPart *shoulder = nil;
BodyPart *torso = nil;
BodyPart *hair = nil;
BodyPart *hairlock = nil;

@implementation Dancer

-(id)init
{
    self = [super init];
    if(!self) return nil;
    
    dancer = self;
    head =      [[BodyPart alloc] initWithOBJfile:@"head5"];
    arm =       [[BodyPart alloc] initWithOBJfile:@"arm"];
    foot =      [[BodyPart alloc] initWithOBJfile:@"foot"];
    hand =      [[BodyPart alloc] initWithOBJfile:@"hand"];
    hip =       [[BodyPart alloc] initWithOBJfile:@"hip"];
    calf =      [[BodyPart alloc] initWithOBJfile:@"calf"];
    thigh =     [[BodyPart alloc] initWithOBJfile:@"thigh"];
    shoulder =  [[BodyPart alloc] initWithOBJfile:@"shoulder"];
    torso =     [[BodyPart alloc] initWithOBJfile:@"torso"];
    hair =      [[BodyPart alloc] initWithOBJfile:@"hair"];
    hairlock =  [[BodyPart alloc] initWithOBJfile:@"hairlock"];
    
	return self;
}

#pragma mark -

-(void)SegmentDataInit
:(int)segmentIndex
:(int)pxFileIndex
:(int)parentSegmentIndex
:(VVertex)pposition
:(VVertex)pangle
{
    SegmentData *p	= &defaultActor.data[segmentIndex];
    p->xFileIndex	= pxFileIndex;
    p->parentIndex	= parentSegmentIndex;
    p->position		= pposition;
    p->angle		= pangle;
    
    p->angle.x = RAD(p->angle.x);
    p->angle.y = RAD(p->angle.y);
    p->angle.z = RAD(p->angle.z);
}

int DEG(float a)
{
    return (int)(180.0 * a / M_PI);
}


-(void)SegmentsInit
{
    {   // torso 0
        VVertex p = { 0,0,0 }; // { -6.368,8.333,-7.735 };
        VVertex a = { 0,4.5, 0 };
        [self SegmentDataInit:S1_TORSO:XFILE_TORSO:NONE:p:a];
    }
    
    const float headZ = -7.56;

    {   // head 1
        VVertex p = { 0,0,headZ };
        VVertex a = { 0,0,-90 };
        [self SegmentDataInit:S1_HEAD:XFILE_HEAD:S1_TORSO:p:a];
    }
    
    {   // hair 15
        VVertex p = { -0.5,0,-9.05 };
        VVertex a = { 0,0,0 };
        [self SegmentDataInit:S1_HAIR:XFILE_HAIR:S1_HEAD:p:a];
    }

    const float shoulderX = 7.2;
    const float shoulderZ = -4.8;
    const float shoulderAY = -18;
 
    {   // lshoulder 2
        VVertex p = { shoulderX,0,shoulderZ };
        VVertex a = { 0,shoulderAY,90 };
        [self SegmentDataInit:S1_LSHOULDER:XFILE_SHOULDER:S1_TORSO:p:a];
    }

    {   // rshoulder 3
        VVertex p = { -shoulderX,0,shoulderZ };
        VVertex a = { 0,-shoulderAY,-90 };
        [self SegmentDataInit:S1_RSHOULDER:XFILE_SHOULDER:S1_TORSO:p:a];
    }

    const float armZ = 13.3;

    {   // larm 4
        VVertex p = { 0,0,armZ };
        VVertex a = { 0,0,0 };
        [self SegmentDataInit:S1_LARM:XFILE_ARM:S1_LSHOULDER:p:a];
    }

    {   // rarm 5
        VVertex p = { 0,0,armZ };
        VVertex a = { 0,0,0 };
        [self SegmentDataInit:S1_RARM:XFILE_ARM:S1_RSHOULDER:p:a];
    }

    const float handZ = 9.3;
    const float handAZ = 117;

    {   // lhand 6
        VVertex p = { 0,0,handZ };
        VVertex a = { 0,0,handAZ };
        [self SegmentDataInit:S1_LHAND:XFILE_HAND:S1_LARM:p:a];
    }
    
    {   // lhand 7
        VVertex p = { 0,0,handZ };
        VVertex a = { 0,0,handAZ };
        [self SegmentDataInit:S1_RHAND:XFILE_HAND:S1_RARM:p:a];
    }
    
    const float thighX = 4.1;
    const float thighZ = 5.4;
    
    {   // lthigh 8
        VVertex p = { thighX,0,thighZ };
        VVertex a = { 0,0,-90 };
        [self SegmentDataInit:S1_LTHIGH:XFILE_THIGH:S1_HIP:p:a];
    }
    
    {   // rthigh 9
        VVertex p = { -thighX,0,thighZ };
        VVertex a = { 0,0,90 };
        [self SegmentDataInit:S1_RTHIGH:XFILE_THIGH:S1_HIP:p:a];
    }
    
    const float calfZ = 17.48;
    
    {   // lcalf 10
        VVertex p = { 0,0,calfZ };
        VVertex a = { 0,0,90 };
        [self SegmentDataInit:S1_LCALF:XFILE_CALF:S1_LTHIGH:p:a];
    }
    
    {   // rcalf 11
        VVertex p = { 0,0,calfZ };
        VVertex a = { 0,0,90 };
        [self SegmentDataInit:S1_RCALF:XFILE_CALF:S1_RTHIGH:p:a];
    }
    
    const float footZ = 10.24;
    
    {   // lfoot 12
        VVertex p = { 0,0,footZ };
        VVertex a = { 0,0,-90 };
        [self SegmentDataInit:S1_LFOOT:XFILE_FOOT:S1_LCALF:p:a];
    }
    
    {   // rfoot 13
        VVertex p = { 0,0,footZ };
        VVertex a = { 0,0,90 };
        [self SegmentDataInit:S1_RFOOT:XFILE_FOOT:S1_RCALF:p:a];
    }
    
    {   // hip 14
        VVertex p = { 0,0,14 };
        VVertex a = { 0, 0,0 };
        [self SegmentDataInit:S1_HIP:XFILE_HIP:S1_TORSO:p:a];
    }
    
    // =============================================================
    const float ll1xs = 4;
    const float ll1zs = 3.9;
    VVertex p,a;
    int baseIndex = S1_HAIR+1;
    float angle = M_PI/2;
    
    for(int i=0;i<LOCK_LEVEL1;++i) {
        p.x = cosf(angle) * ll1xs;
        p.y = sinf(angle) * ll1zs;
        p.z = 2.8;
        a.x = 0;
        a.y = 0;
        a.z = -(float)i * (180)/(float)LOCK_LEVEL1;
        angle += M_PI/(float)LOCK_LEVEL1;

        [self SegmentDataInit:baseIndex+i:XFILE_HAIRLOCK:S1_HAIR:p:a];
    }

    // =============================================================
    float ll2xs = .7;
    float ll2zs = .7;
    a.x = 0;
    a.y = 0;
    a.z = 0;

    angle = M_PI/2;
    p.x = cosf(angle) * ll2xs;
    p.y = sinf(angle) * ll2zs;
    p.z = 1.97;
    
    for(int i=0;i<LOCK_LEVEL2;i += LOCK_LEVEL1) {
        baseIndex += LOCK_LEVEL1;
        for(int j=0;j<LOCK_LEVEL1;++j) {
        
            [self SegmentDataInit:baseIndex+j:XFILE_HAIRLOCK:baseIndex-LOCK_LEVEL1+j:p:a];
        }
    }

    // =============================================================
    defaultActor.meshCount = SS_COUNT;
    memcpy(&actor,&defaultActor,sizeof(actor));
}

#pragma mark -

#define COUNT 100
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

int parentList[20];
int pCount;

-(void)draw
{
	static bool first = true;
	if(first) {
		first = false;
		[self SegmentsInit];
	}

    static float hx = 0;
    static float hz = 0;
    static float hxt = 0;
    static float hzt = 0;
    float hscale = 0.05;
    float pscale = 1;
    VVertex ptmp,tmp;
    
	for(int i=0;i<actor.meshCount;++i) { 
		pCount = 0;
		parentList[pCount++] = i;

		SegmentData *me = &actor.data[i];
		int pIndex = me->parentIndex;
        
		while(pIndex != NONE) {
			parentList[pCount++] = pIndex;
			pIndex = actor.data[pIndex].parentIndex;
		}

        float4x4 mvm = Identity();
        float4x4 ang;

        ang = Translate(eye.position.x,eye.position.y,eye.position.z);
        mvm = mvm * ang;    
        mvm = mvm * RotationX(eye.angle.x);
        mvm = mvm * RotationZ(eye.angle.y);
        
        for(int j=pCount-1;j>=0;--j) {
			SegmentData *p = &actor.data[parentList[j]];
            ptmp = p->position;
            tmp = p->angle;
            
            if(i > S1_HAIR) {
                ptmp.z *= pscale;
                pscale *= 1.0001;
            }
            
            mvm = mvm * Translate(ptmp.x,ptmp.y,ptmp.z);
            
            if(i > S1_HAIR) {
                tmp.x -= hxt * hscale;  // forward back
                tmp.z += hzt * hscale;  // side to side

                float ltrt = (i&1) ? 1 : -1;
                tmp.y += hzt * hscale * ltrt / 3;  // twisted

                hscale *= 1.0004;
            }
            
            if(tmp.x) mvm = mvm * RotationX(tmp.x);
            if(tmp.y) mvm = mvm * RotationY(tmp.y);
            if(tmp.z) mvm = mvm * RotationZ(tmp.z);
        }

        static float p00 = 99;
        static float p01 = 99;
        
        if(i == S1_HEAD) {
//            printf("\n%08.3f, %08.3f, %08.3f, %08.3f\n",mvm.columns[0][0],mvm.columns[1][0],mvm.columns[2][0],mvm.columns[3][0]);
//            printf("%08.3f, %08.3f, %08.3f, %08.3f\n",mvm.columns[0][1],mvm.columns[1][1],mvm.columns[2][1],mvm.columns[3][1]);
//            printf("%08.3f, %08.3f, %08.3f, %08.3f\n",mvm.columns[0][2],mvm.columns[1][2],mvm.columns[2][2],mvm.columns[3][2]);
//            printf("%08.3f, %08.3f, %08.3f, %08.3f\n",mvm.columns[0][3],mvm.columns[1][3],mvm.columns[2][3],mvm.columns[3][3]);
            
            // raw movement affects total deflection
            if(p00 != 99) hzt -= (mvm.columns[0][0] - p00) * 5;
            p00 = mvm.columns[0][0];
            if(p01 != 99) hxt -= (mvm.columns[0][1] - p01) * 3;
            p01 = mvm.columns[0][1];
            
            static float accel = 0.14;   // smaller = wild twisting
            hx = fabs(hxt) * accel;
            hz = fabs(hzt) * accel;
            
            static float deaccel = 0.998;
            hxt *= deaccel;
            hzt *= deaccel;

            static float amt = 0.91;     // larger = no swing
            if(hxt < 0) hxt += hx*amt; else hxt -= hx*amt;
            if(hzt < 0) hzt += hz*amt; else hzt -= hz*amt;
            
     //       printf("T%d: %+08.3f %+08.3f   Dx %08.3f %08.3f\n",touching,hxt,hzt,hx,hz);
        }
        
        float scale = 1;
        if(i >= S1_HAIR) {
//            globalLight[0].specularPower = 5;
//            globalLight[0].diffuseColor.x = fabs(p00);
//            globalLight[0].specularColor.x = fabs(p01);
            scale = 1 + (float)(i-S1_HAIR) * 0.005;
        }
//        else {
//            globalLight[0].diffuseColor.x = 1;
//            globalLight[0].specularColor.x = 1;
//            globalLight[0].specularPower = 150;
//        }
        
        bool highlight = editSelect[i];
        
        switch(me->xFileIndex) {
            case XFILE_FOOT :   [foot update:mvm:highlight];      [foot draw];    break;
            case XFILE_CALF :   [calf update:mvm:highlight];      [calf draw];    break;
            case XFILE_THIGH:   [thigh update:mvm:highlight];     [thigh draw];   break;
            case XFILE_TORSO:   [torso update:mvm:highlight];     [torso draw];   break;
            case XFILE_HIP:     [hip update:mvm:highlight];       [hip draw];     break;
            case XFILE_SHOULDER:[shoulder update:mvm:highlight];  [shoulder draw];break;
            case XFILE_ARM:     [arm update:mvm:highlight];       [arm draw];     break;
            case XFILE_HAND:    [hand update:mvm:highlight];      [hand draw];    break;
            case XFILE_HEAD:    [head update:mvm:highlight];      [head draw];    break;
            case XFILE_HAIR:    [hair update:mvm:highlight];      [hair draw];    break;
            case XFILE_HAIRLOCK:
                [hairlock update:mvm:highlight:scale];
                [hairlock draw];
                break;
        }
 	}
}

#pragma mark =========== isLegalAngle

int iAngle;

-(bool)angleRange:(int)min :(int)max
{
    while(iAngle < 0)    iAngle += 360;
    while(iAngle >= 360) iAngle -= 360;
    
    if(min > max)
        return (iAngle >= min) || (iAngle <= max);
    
    return (iAngle >= min) && (iAngle <= max);
}

-(bool)isLegalAngle :(int)csegment :(int)axis :(float)angle
{
    if(defaultActor.data[csegment].parentIndex == NONE)   // torso
        return true;
    
    iAngle = (int)(180.0 * angle / M_PI);
    
    switch(csegment) {
        case S1_HEAD :
            switch(axis) {
                case X : return [self angleRange:312:30];
                case Y : return [self angleRange:315:45];
            }
            break;
            
        case S1_LSHOULDER :
            switch(axis) {
                case X : return [self angleRange:340:180];
                case Y : return [self angleRange:190:350];
            }
            break;

        case S1_RSHOULDER :
            switch(axis) {
                case X : return [self angleRange:0:180];
                case Y : return [self angleRange:0:180];
            }
            break;
            
        case S1_LARM :
            switch(axis) {
                case Y : return [self angleRange:0:160];
            }
            break;

        case S1_RARM :
            switch(axis) {
                case Y : return [self angleRange:200:359];
            }
            break;
            
        case S1_LHAND :
        case S1_RHAND :
            return true;

        case S1_LTHIGH :
            switch(axis) {
                case X : return [self angleRange:340:140];
                case Y : return [self angleRange:270:359];
            }
            break;
            
        case S1_RTHIGH :
            switch(axis) {
                case X : return [self angleRange:340:140];
                case Y : return [self angleRange:0:90];
            }
            break;
            
        case S1_LCALF :
            switch(axis) {
                case Y : return [self angleRange:0:140];
            }
            break;
            
        case S1_RCALF :
            switch(axis) {
                case Y : return [self angleRange:210:359];
            }
            break;

        case S1_LFOOT :
            switch(axis) {
                case X : return [self angleRange:310:50];
                case Z : return [self angleRange:260:330];
            }
            break;
            
        case S1_RFOOT :
            switch(axis) {
                case X : return [self angleRange:310:50];
                case Z : return [self angleRange:60:120];
            }
            break;
            
		case S1_HIP :
			switch(axis) {
                case X : return [self angleRange:340:30];
                case Y : return [self angleRange:330:30];
			}
			break;
	}
	
	return false;
}

typedef struct {
	Byte activeAxis[2];
	float direction[2];
} SegmentAlterData;

SegmentAlterData segmentAlterData[SS_COUNT+1] = {
	2,0, -1,1, 	//S1_TORSO = 0,
	
	1,0, 1,1,   //S1_HEAD,
	
    1,0, 1,1, // S1_LSHOULDER,
    1,0, -1,1, //S1_RSHOULDER,
	
	2,1,  1,1,	//S1_LARM,
	2,1,  1,-1,	//S1_RARM,
	
	2,1,  1, 1,	//S1_LHAND,
	2,1,  1, -1,	//S1_RHAND,
	
	1,0, 0.5,1,	//S1_LTHIGH,
	1,0, -0.5,1,	//S1_RTHIGH,
	
	1,1, 1,1,	//S1_LCALF,
	1,1, -1,-1,	//S1_RCALF,
	
	0,2, 1,1,	//S1_LFOOT,
	0,2, -1,-1,	//S1_RFOOT,
	
    1,0, 0.3,-0.3, 	//S1_HIP,
};

#pragma mark =========== SegmentAlter

-(void)segmentAlter :(int)index :(float)dx :(float)dy
{
	if(index == NONE) return;

    float diff[2] = { dx/100,dy/100 }; // suppress change amount
    SegmentAlterData *sd = &segmentAlterData[index];
    
    VertexA *vptr = (VertexA *)&actor.data[index].angle;
    
    for(int i=0;i<2;++i) {
        int aindex = sd->activeAxis[i];
        float curAngle = vptr->pt[aindex];
        float newAngle = curAngle + diff[i] * sd->direction[i];
        
        //printf("I %d  axis %d A %f -> %f\n",index,aindex,curAngle,newAngle);
        
        while(newAngle < 0)    newAngle += M_PI *2;
        while(newAngle >= M_PI *2) newAngle -= M_PI *2;
        
        if([self isLegalAngle:index:aindex:newAngle])
            vptr->pt[aindex] = newAngle;
        
        //		printf("Angle %d: %7.2f %7.2f %7.2f\n",sIndex,actor.data[sIndex].angle.pt[0],actor.data[sIndex].angle.pt[1],actor.data[sIndex].angle.pt[2]);
    }
}

@end
