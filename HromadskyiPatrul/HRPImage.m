//
//  HRPImage.m
//  HuntsPoynt
//
//  Created by msm72 on 27.06.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//


#import "HRPImage.h"
#import "UIImage+ChangeOriginalImage.h"


@implementation HRPImage

#pragma mark - Constructors -
- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.imageAvatar            =   [UIImage imageNamed:@"icon-no-image"];
    }
    
    return self;
}


#pragma mark - Methods -
- (UIImage *)downloadImageFromURL:(NSString *)stringURL {
    UIImage *imageOriginal          =   [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:stringURL]]];
    
    return imageOriginal;
}

- (UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)newSize andCropInCenter:(BOOL)isCenterCrop {
    UIImage *imageAvatar            =   (image) ? image : [UIImage imageNamed:@"icon-no-image"];
    
    return [imageAvatar resizeProportionalWithCropToSize:newSize center:isCenterCrop];
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0.f, 0.f, newSize.width, newSize.height)];
    UIImage *newImage               =   UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
   
    return newImage;
}

- (UIImage *)grabImageFromAsset:(PHAsset *)asset withSize:(CGSize)newSize {
    __block UIImage *returnImage;
    
    PHImageRequestOptions *options  =   [[PHImageRequestOptions alloc] init];
    options.synchronous             =   YES;
   
    [[PHImageManager defaultManager] requestImageForAsset:asset
                                               targetSize:newSize
                                              contentMode:PHImageContentModeAspectFill
                                                  options:options
                                            resultHandler: ^(UIImage *result, NSDictionary *info) {
                                                returnImage = result;
                                            }];
    
    return returnImage;
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
