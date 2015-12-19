//
//  HRPMainViewModel.h
//  HromadskyiPatrul
//
//  Created by msm72 on 12.12.15.
//  Copyright © 2015 Monastyrskiy Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface HRPMainViewModel : NSObject

@property (strong, nonatomic) NSUserDefaults *userApp;

- (NSString *)getAppVersion;
- (NSString *)selectNextSceneStoryboardID;

@end
