//
//  UIColor+HexColor.h
//  HuntsPoynt
//
//  Created by msm72 on 23.02.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (HexColor)

+ (UIColor *)colorWithHexString:(NSString *)hex alpha:(CGFloat)alpha;

@end
