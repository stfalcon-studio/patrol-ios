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

@end
