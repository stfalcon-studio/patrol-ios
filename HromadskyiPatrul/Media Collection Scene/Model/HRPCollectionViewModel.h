//
//  HRPCollectionViewModel.h
//  HromadskyiPatrul
//
//  Created by msm72 on 19.12.15.
//  Copyright © 2015 Monastyrskiy Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface HRPCollectionViewModel : NSObject

@property (strong, nonatomic) NSUserDefaults *userApp;

@property (assign, nonatomic) NSInteger missingPhotosCount;
@property (assign, nonatomic) NSInteger photosNeedUploadCount;
@property (assign, nonatomic) NSInteger videosNeedUploadCount;

@property (strong, nonatomic) NSMutableArray *imagesIndexPath;

- (void)checkNeedUploadFiles;

@end
