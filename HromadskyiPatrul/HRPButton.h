//
//  HRPButton.h
//  HromadskyiPatrul
//
//  Created by msm72 on 21.08.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE


@interface HRPButton : UIButton

@property (strong, nonatomic) IBInspectable UIColor *fillColor;
@property (assign, nonatomic) IBInspectable CGFloat cornerRadius;

@end
