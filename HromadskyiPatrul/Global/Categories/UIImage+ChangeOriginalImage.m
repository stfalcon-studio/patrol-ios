//
//  UIImage+ChangeOriginalImage.m
//  HuntsPoynt
//
//  Created by msm72 on 08.05.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "UIImage+ChangeOriginalImage.h"

@implementation UIImage (ChangeOriginalImage)

#pragma mark - Methods -
- (UIImage *)resizeProportionalWithCropToSize:(CGSize)newSize center:(BOOL)center {
    UIImage *resizedImage   =   [self resizeToSize:newSize];
    UIImage *result;
    
    if (center)
        result              =   [resizedImage cropToSize:newSize];
    else
        result              =   [resizedImage cropLeftTopToSize:newSize];

    return result;
}

- (UIImage *)resizeToSize:(CGSize)newSize {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [self drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage       =   UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (UIImage *)cropToSize:(CGSize)newSize {
    CGRect cropRect         =   CGRectMake((self.size.width - newSize.width) / 2, (self.size.height - newSize.height) / 2,
                                            newSize.width, newSize.height);
    
    if (self.scale > 1.f)
        cropRect            =   CGRectMake(cropRect.origin.x     *   self.scale,
                                           cropRect.origin.y     *   self.scale,
                                           cropRect.size.width   *   self.scale,
                                           cropRect.size.height  *   self.scale);

    CGImageRef sgImage      =   [self CGImage];
    CGImageRef imageRef     =   CGImageCreateWithImageInRect(sgImage, cropRect);
    UIImage *image          =   [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(imageRef);
    
    return image;
}

- (UIImage *)cropLeftTopToSize:(CGSize)newSize {
    CGRect cropRect         =   CGRectMake(0.f, 0.f, newSize.width, newSize.height);
    
    if (self.scale > 1.f)
        cropRect            =   CGRectMake(cropRect.origin.x     *   self.scale,
                                           cropRect.origin.y     *   self.scale,
                                           cropRect.size.width   *   self.scale,
                                           cropRect.size.height  *   self.scale);
    
    CGImageRef sgImage      =   [self CGImage];
    CGImageRef imageRef     =   CGImageCreateWithImageInRect(sgImage, cropRect);
    UIImage *image          =   [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(imageRef);
    
    return image;
}

- (UIImage *)squareImageFromImage:(UIImage *)image scaledToSize:(CGFloat)newSize {
    CGAffineTransform scaleTransform;
    CGPoint origin;
    
    if (image.size.width > image.size.height) {
        CGFloat scaleRatio = newSize / image.size.height;
        scaleTransform = CGAffineTransformMakeScale(scaleRatio, scaleRatio);
        
        origin = CGPointMake(-(image.size.width - image.size.height) / 2.0f, 0);
    } else {
        CGFloat scaleRatio = newSize / image.size.width;
        scaleTransform = CGAffineTransformMakeScale(scaleRatio, scaleRatio);
        
        origin = CGPointMake(0, -(image.size.height - image.size.width) / 2.0f);
    }
    
    CGSize size = CGSizeMake(newSize, newSize);
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(size, YES, 0);
    } else {
        UIGraphicsBeginImageContext(size);
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextConcatCTM(context, scaleTransform);
    
    [image drawAtPoint:origin];
    
    image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

@end
