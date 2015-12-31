//
//  HRPPhoto.m
//  HromadskyiPatrul
//
//  Created by msm72 on 26.08.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPPhoto.h"

@implementation HRPPhoto 

#pragma mark - Constructors -
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self                        =   [super init];
    
    if (self) {
        self.state              =   [[aDecoder decodeObjectForKey:@"stateKey"] integerValue];
        self.date               =   [aDecoder decodeObjectForKey:@"dateKey"];
        self.assetsPhotoURL     =   [aDecoder decodeObjectForKey:@"assetsPhotoURLKey"];
        self.assetsVideoURL     =   [aDecoder decodeObjectForKey:@"assetsVideoURLKey"];
        self.latitude           =   [[aDecoder decodeObjectForKey:@"latitudeKey"] floatValue];
        self.longitude          =   [[aDecoder decodeObjectForKey:@"longitudeKey"] floatValue];
        self.isVideo            =   [[aDecoder decodeObjectForKey:@"isVideoKey"] floatValue];
    }
    
    return self;
}

- (instancetype)init {
    self = [super init];
   
    if (self) {
        self.state              =   HRPPhotoStateUpload;
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:@(self.state) forKey:@"stateKey"];
    [aCoder encodeObject:self.date forKey:@"dateKey"];
    [aCoder encodeObject:self.assetsPhotoURL forKey:@"assetsPhotoURLKey"];
    [aCoder encodeObject:self.assetsVideoURL forKey:@"assetsVideoURLKey"];
    [aCoder encodeObject:@(self.latitude) forKey:@"latitudeKey"];
    [aCoder encodeObject:@(self.longitude) forKey:@"longitudeKey"];
    [aCoder encodeObject:@(self.isVideo) forKey:@"isVideoKey"];
}

@end
