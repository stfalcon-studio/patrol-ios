//
//  UIImage+ChangeOriginalImage.h
//  HuntsPoynt
//
//  Created by msm72 on 08.05.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIImage (ChangeOriginalImage)

- (UIImage *)cropToSize:(CGSize)newSize;
- (UIImage *)resizeProportionalWithCropToSize:(CGSize)newSize center:(BOOL)center;
- (UIImage *)squareImageFromImage:(UIImage *)image scaledToSize:(CGFloat)newSize;

@end
