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
        self.modifiedImage          =   [UIImage imageNamed:@"icon-no-image"];
    }
    
    return self;
}


#pragma mark - Methods -
- (UIImage *)downloadImageFromURL:(NSString *)stringURL {
    self.originalImage              =   [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:stringURL]]];
    
    return self.originalImage;
}

- (UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)newSize andCropInCenter:(BOOL)isCenterCrop {
//    if (image.size.width > image.size.height) {
//        float scale             =   image.size.width / image.size.height;
//        UIImage imageNew        =   [UIImage alloc] ini CGSizeMake(image.size.width / scale, 158.f);
//    }
//    
//    else {
//        float scale             =   self.modifiedImage.size.height / self.modifiedImage.size.width;
//        self.newSize            =   CGSizeMake(158.f, self.modifiedImage.size.height / scale);
//    }
//
    UIImage *imageAvatar            =   (image) ? image : [UIImage imageNamed:@"icon-no-image"];
    
    return [imageAvatar resizeProportionalWithCropToSize:newSize center:isCenterCrop];
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
