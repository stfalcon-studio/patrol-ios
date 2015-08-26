//
//  HRPPhotoCell.m
//  HromadskyiPatrul
//
//  Created by msm72 on 26.08.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPPhotoCell.h"

@implementation HRPPhotoCell

#pragma mark - Actions -
- (IBAction)actionPhotoStateButtonTap:(UIButton *)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"HRPPhotoCellStateButtonTap"
                                                        object:nil
                                                      userInfo:@{ @"cell" : self }];
}

@end
