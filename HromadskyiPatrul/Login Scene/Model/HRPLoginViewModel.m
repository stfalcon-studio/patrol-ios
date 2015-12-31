//
//  HRPLoginViewModel.m
//  HromadskyiPatrul
//
//  Created by msm72 on 19.12.15.
//  Copyright © 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPLoginViewModel.h"
#import "AFNetworking.h"
#import <AFHTTPRequestOperation.h>


@implementation HRPLoginViewModel

#pragma mark - Constructors -
- (instancetype)init {
    self            =   [super init];
    
    if (self) {
        _userApp    =   [NSUserDefaults standardUserDefaults];
    }
    
    return self;
}


#pragma mark - API -
- (void)userLoginParameters:(NSString *)email
                  onSuccess:(void(^)(NSDictionary *successResult))success
                  orFailure:(void(^)(AFHTTPRequestOperation *failureOperation))failure {
    NSString *urlString     =   ([self isServerURLLocal]) ? @"http://192.168.0.29/app_dev.php/" : @"http://patrol.stfalcon.com/";
    
    AFHTTPRequestOperationManager *requestOperationDomainManager    =   [[AFHTTPRequestOperationManager alloc]
                                                                         initWithBaseURL:[NSURL URLWithString:urlString]];
    
    NSString *pathAPI                                               =   @"api/register";
    AFHTTPRequestSerializer *userRequestSerializer                  =   [AFHTTPRequestSerializer serializer];
    
    [userRequestSerializer setValue:@"application/json" forHTTPHeaderField:@"CONTENT_TYPE"];
    
    [requestOperationDomainManager POST:pathAPI
                             parameters:@{ @"email" : email }
                                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                    if (operation.response.statusCode == 200) {
                                        // Set NSUserDefaults item
                                        [_userApp setObject:email forKey:@"userAppEmail"];
                                        [_userApp setObject:responseObject[@"id"] forKey:@"userAppID"];
                                        [_userApp synchronize];

                                        success(responseObject);
                                    }
                                }
                                failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                    if (operation.response.statusCode == 400)
                                        failure(operation);
                                }];
}


#pragma mark - Methods -
- (BOOL)isServerURLLocal {
    return [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"isLocalServerURL"] boolValue];
}

@end
