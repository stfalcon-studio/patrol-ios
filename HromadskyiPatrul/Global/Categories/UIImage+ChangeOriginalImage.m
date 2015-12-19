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
//    CGSize originalSize     =   self.size;
//    CGSize firstSize;
    
//    if (originalSize.width / originalSize.height > newSize.width / newSize.height)
//        firstSize           =   CGSizeMake(newSize.height / originalSize.height * originalSize.width, newSize.height);
//    else
//        firstSize           =   CGSizeMake(newSize.width, newSize.height);

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

@end
