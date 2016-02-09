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
    self = [super init];
    
    if (self) {
        _isLabelFlashing = NO;
    }
    
    return self;
}


#pragma mark - Methods -
- (void)startFlashing {
    if (_isLabelFlashing)
        return;
    
    _isLabelFlashing = YES;
    self.alpha = 1.f;
    
    [UIView animateWithDuration:0.10f
                          delay:0.f
                        options:UIViewAnimationOptionCurveEaseInOut |
                                UIViewAnimationOptionRepeat         |
                                UIViewAnimationOptionAutoreverse    |
                                UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.alpha = 0.f;
                     }
                     completion:nil];
}

@end
