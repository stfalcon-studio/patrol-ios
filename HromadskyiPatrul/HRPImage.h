//
//  HRPImage.h
//  HuntsPoynt
//
//  Created by msm72 on 27.06.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>


@interface HRPImage : NSObject

@property (strong, nonatomic) UIImage *imageAvatar;
@property (strong, nonatomic) NSData *imageData;
@property (strong, nonatomic) NSString *imageOriginalURL;

@property (assign, nonatomic) CGSize newSize;

- (UIImage *)downloadImageFromURL:(NSString *)stringURL;
- (UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)newSize andCropInCenter:(BOOL)isCenterCrop;
- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;
- (UIImage *)grabImageFromAsset:(PHAsset *)asset withSize:(CGSize)newSize;
- (UIImage *)squareImageFromImage:(UIImage *)image scaledToSize:(CGFloat)newSize;

@end
