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
- (instancetype)init {
    self = [super init];
   
    if (self) {
        self.state  =   HRPPhotoStateUpload;
        //self.image  =   [UIImage imageNamed:@"test-image.JPG"];
    }
    
    return self;
}

@end
