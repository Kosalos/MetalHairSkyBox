//
//  OBJModel.mm
//  UpAndRunning3D
//
//  Created by Warren Moore on 9/11/14.
//  Copyright (c) 2014 Metal By Example. All rights reserved.
//

#import "OBJModel.h"
#import "OBJGroup.h"
#import "Shared.h"

#include <map>
#include <vector>
#include <functional>

// "Face vertices" are tuples of indices into file-wide lists of positions, normals, and texture coordinates.
// We maintain a mapping from these triples to the indices they will eventually occupy in the group that
// is currently being constructed.
struct FaceVertex
{
    FaceVertex() :
        vi(0), ti(0), ni(0)
    {
    }
    
    uint16_t vi, ti, ni;
};

static bool operator <(const FaceVertex &v0, const FaceVertex &v1)
{
    if (v0.vi < v1.vi)
        return true;
    else if (v0.vi > v1.vi)
        return false;
    else if (v0.ti < v1.ti)
        return true;
    else if (v0.ti > v1.ti)
        return false;
    else if (v0.ni < v1.ni)
        return true;
    else if (v0.ni > v1.ni)
        return false;
    else
        return false;
}

@interface OBJModel ()
{
    std::vector<float4> vertices;
    std::vector<float3> normals;
    std::vector<float2> texCoords;
    std::vector<MVertex> groupVertices;
    std::vector<IndexType> groupIndices;
    std::map<FaceVertex, IndexType> vertexToGroupIndexMap;
}

@property (nonatomic, strong) NSMutableArray *mutableGroups;
@property (nonatomic, weak) OBJGroup *currentGroup;
@property (nonatomic, assign) BOOL shouldGenerateNormals;

@end

@implementation OBJModel

- (instancetype)initWithContentsOfURL:(NSURL *)fileURL generateNormals:(BOOL)generateNormals
{
    if ((self = [super init]))
    {
        _shouldGenerateNormals = generateNormals;
        _mutableGroups = [NSMutableArray array];
        [self parseModelAtURL:fileURL];
    }
    return self;
}

- (NSArray *)groups
{
    return [_mutableGroups copy];
}

- (void)parseModelAtURL:(NSURL *)url
{
    NSError *error = nil;
    NSString *contents = [NSString stringWithContentsOfURL:url
                                                  encoding:NSASCIIStringEncoding
                                                     error:&error];
    if (!contents)
    {
        return;
    }
    
    NSScanner *scanner = [NSScanner scannerWithString:contents];
    
    NSCharacterSet *skipSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSCharacterSet *consumeSet = [skipSet invertedSet];
    
    scanner.charactersToBeSkipped = skipSet;
    
    NSCharacterSet *endlineCharacters = [NSCharacterSet newlineCharacterSet];
    
    [self beginGroupWithName:@"(unnamed)"];
    
    while (![scanner isAtEnd])
    {
        NSString *token = nil;
        if (![scanner scanCharactersFromSet:consumeSet intoString:&token])
        {
            break;
        }
        
        if ([token isEqualToString:@"v"])
        {
            float x, y, z;
            [scanner scanFloat:&x];
            [scanner scanFloat:&y];
            [scanner scanFloat:&z];
            
            float4 v = { x, y, z, 1 };
            vertices.push_back(v);
        }
        else if ([token isEqualToString:@"vt"])
        {
            float u = 0, v = 0;
            [scanner scanFloat:&u];
            [scanner scanFloat:&v];
            
            float2 vt = { u, v };
            texCoords.push_back(vt);
        }
        else if ([token isEqualToString:@"vn"])
        {
            float nx = 0, ny = 0, nz = 0;
            [scanner scanFloat:&nx];
            [scanner scanFloat:&ny];
            [scanner scanFloat:&nz];
            
            float3 vn = { nx, ny, nz };
            normals.push_back(vn);
        }
        else if ([token isEqualToString:@"f"])
        {
            std::vector<FaceVertex> faceVertices;
            faceVertices.reserve(4);
            
            while (1)
            {
                int32_t vi = 0, ti = 0, ni = 0;
                if(![scanner scanInt:&vi])
                {
                    break;
                }

                if ([scanner scanString:@"/" intoString:NULL])
                {
                    [scanner scanInt:&ti];
                    
                    if ([scanner scanString:@"/" intoString:NULL])
                    {
                        [scanner scanInt:&ni];
                    }
                }
                
                FaceVertex faceVertex;
                
                // OBJ format allows relative vertex references in the form of negative indices, and
                // dictates that indices are 1-based. Below, we simultaneously fix up negative indices
                // and offset everything by -1 to allow 0-based indexing later on.
                
                faceVertex.vi = (vi < 0) ? (vertices.size() + vi - 1) : (vi - 1);
                faceVertex.ti = (ti < 0) ? (texCoords.size() + ti - 1) : (ti - 1);
                faceVertex.ni = (ni < 0) ? (vertices.size() + ni - 1) : (ni - 1);

                faceVertices.push_back(faceVertex);
            }
            
            [self addFaceWithFaceVertices:faceVertices];
        }
        else if ([token isEqualToString:@"g"])
        {
            NSString *groupName = nil;
            if ([scanner scanUpToCharactersFromSet:endlineCharacters intoString:&groupName])
            {
                [self beginGroupWithName:groupName];
            }
        }
    }
    
    [self endCurrentGroup];
}

- (void)beginGroupWithName:(NSString *)name
{
    [self endCurrentGroup];
    
    OBJGroup *newGroup = [[OBJGroup alloc] initWithName:name];
    [self.mutableGroups addObject:newGroup];
    self.currentGroup = newGroup;
}

- (void)endCurrentGroup
{
    if (!self.currentGroup)
    {
        return;
    }
    
    if (self.shouldGenerateNormals)
    {
        [self generateNormalsForCurrentGroup];
    }
    
    // Once we've read a complete group, we copy the packed vertices that have been referenced by the group
    // into the current group object. Because it's fairly uncommon to have cross-group shared vertices, this
    // essentially divides up the vertices into disjoint sets by group.

    NSData *vertexData = [NSData dataWithBytes:groupVertices.data() length:sizeof(MVertex) * groupVertices.size()];
    self.currentGroup.vertexData = vertexData;

//     [self adjustNormals:vertexData :groupVertices.size()];
    
    
    NSData *indexData = [NSData dataWithBytes:groupIndices.data() length:sizeof(IndexType) * groupIndices.size()];
    self.currentGroup.indexData = indexData;

    groupVertices.clear();
    groupIndices.clear();
    vertexToGroupIndexMap.clear();

    self.currentGroup = nil;
}

- (void)generateNormalsForCurrentGroup
{
    static const float3 ZERO3 = { 0, 0, 0 };
    
    size_t i;
    size_t vertexCount = groupVertices.size();
    for (i = 0; i < vertexCount; ++i)
    {
        groupVertices[i].normal = ZERO3;
    }

    size_t indexCount = groupIndices.size();
    for (i = 0; i < indexCount; i += 3)
    {
        uint16_t i0 = groupIndices[i];
        uint16_t i1 = groupIndices[i + 1];
        uint16_t i2 = groupIndices[i + 2];
        
        MVertex *v0 = &groupVertices[i0];
        MVertex *v1 = &groupVertices[i1];
        MVertex *v2 = &groupVertices[i2];
        
        float3 p0 = v0->position.xyz;
        float3 p1 = v1->position.xyz;
        float3 p2 = v2->position.xyz;
        
        float3 vcross = cross((p1 - p0), (p2 - p0));

        v0->normal += vcross;
        v1->normal += vcross;
        v2->normal += vcross;
    }

    for (i = 0; i < vertexCount; ++i)
    {
        groupVertices[i].normal = normalize(groupVertices[i].normal);
    }
}

- (void)addFaceWithFaceVertices:(const std::vector<FaceVertex> &)faceVertices
{
    // Transform polygonal faces into "fans" of triangles, three vertices at a time
    for (size_t i = 0; i < faceVertices.size() - 2; ++i)
    {
        [self addVertexToCurrentGroup:faceVertices[0]];
        [self addVertexToCurrentGroup:faceVertices[i + 1]];
        [self addVertexToCurrentGroup:faceVertices[i + 2]];
    }
}

- (void)addVertexToCurrentGroup:(FaceVertex)fv
{
    static const float3 UP = { 0, 1, 0 };
    static const float2 ZERO2 = { 0, 0 };
    static const uint16_t INVALID_INDEX = 0xffff;
    
    uint16_t groupIndex;
    auto it = vertexToGroupIndexMap.find(fv);
    if (it != vertexToGroupIndexMap.end())
    {
        groupIndex = (*it).second;
    }
    else
    {
        MVertex vertex;
        vertex.position = vertices[fv.vi];
        vertex.normal = (fv.ni != INVALID_INDEX) ? normals[fv.ni] : UP;
        vertex.texCoords = (fv.ti != INVALID_INDEX) ? texCoords[fv.ti] : ZERO2;

        groupVertices.push_back(vertex);
        groupIndex = groupVertices.size() - 1;
        vertexToGroupIndexMap[fv] = groupIndex;
    }
    
    groupIndices.push_back(groupIndex);
}

// ========================================================

int vCount;
MVertex *vData;

bool hasMatched[60000] = { false };

int mCount;
int match[12];

void addMatch(int index)
{
    if(mCount == 12) return;
    
    match[mCount++] = index;
}

float v1,v2;

bool isSamePoint(int i,int j)
{
    for(int c=0;c<3;++c) {
        if(fabs(vData[i].position[c] - vData[j].position[c]) > 0.001)
            return false;
    }
    
    return true;
}

void averageMatchedNormals()
{
    if(mCount < 2) return;
    
    float total[3] = { 0 };
    float txt[2] = { 0 };
    
    for(int i=0;i<mCount;++i) {
        for(int c=0;c<3;++c)
            total[c] += vData[match[i]].normal[c];
        for(int c=0;c<2;++c)
            txt[c] += vData[match[i]].texCoords[c];
    }
    
    for(int c=0;c<3;++c)
        total[c] /= (float)mCount;
    
    for(int c=0;c<2;++c)
        txt[c] /= (float)mCount;
    
    for(int i=0;i<mCount;++i) {
        for(int c=0;c<3;++c)
            vData[match[i]].normal[c] = total[c];
//        for(int c=0;c<2;++c)
//            vData[match[i]].texCoords[c] = txt[c];
    }
}

-(void)adjustNormals:(NSData *)vv :(int)count
{
    if(!vv) return;
    
    vCount = count;
    vData = (MVertex *)vv.bytes;

    for(int i=0;i<vCount;++i)
        hasMatched[i] = false;
    
    for(int i=0;i<vCount;++i) {
        if(hasMatched[i]) continue;
        
        mCount = 0;
        addMatch(i);
        
        for(int j=i+1;j<vCount;++j) {
            if(hasMatched[j]) continue;
            if(isSamePoint(i,j))
                addMatch(j);
        }
        
        averageMatchedNormals();
        
        for(int k=0;k<mCount;++k)
            hasMatched[match[k]] = true;
    }
}

@end
