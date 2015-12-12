//
//  HRPMainViewModel.h
//  HromadskyiPatrul
//
//  Created by msm72 on 12.12.15.
//  Copyright © 2015 Monastyrskiy Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AFHTTPRequestOperation;


@interface HRPMainViewModel : NSObject

@property (strong, nonatomic) NSUserDefaults *userApp;

- (void)userLoginParameters:(NSString *)email
                  onSuccess:(void(^)(NSDictionary *successResult))success
                  orFailure:(void(^)(AFHTTPRequestOperation *failureOperation))failure;

@end
