//
//  HRPLabel.m
//  HromadskyiPatrul
//
//  Created by msm72 on 19.12.15.
//  Copyright © 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPLabel.h"

@implementation HRPLabel

#pragma mark - Constructors -
- (instancetype)init {
    self                    =   [super init];
    
    if (self) {
        _isLabelFlashing    =   NO;
    }
    
    return self;
}

@end
