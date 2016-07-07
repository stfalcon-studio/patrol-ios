/*
 Copyright (c) 2015 - 2016. Stepan Tanasiychuk
 This file is part of Gromadskyi Patrul is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by the Free Software Found ation, version 3 of the License, or any later version.
 If you would like to use any part of this project for commercial purposes, please contact us
 for negotiating licensing terms and getting permission for commercial use. Our email address: info@stfalcon.com
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.
 You should have received a copy of the GNU General Public License along with this program.
 If not, see http://www.gnu.org/licenses/.
 */
// https://github.com/stfalcon-studio/patrol-android/blob/master/app/build.gradle
//
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
    self = [super init];
    
    if (self) {
        _userApp = [NSUserDefaults standardUserDefaults];
    }
    
    return self;
}


#pragma mark - API -
- (void)userLoginParameters:(NSString *)email
                  onSuccess:(void(^)(NSDictionary *successResult))success
                  orFailure:(void(^)(AFHTTPRequestOperation *failureOperation))failure {
    NSString *urlString = ([self isServerURLLocal]) ? @"http://192.168.0.29/app_dev.php/" : @"http://patrol.stfalcon.com/";
    AFHTTPRequestOperationManager *requestOperationDomainManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:urlString]];
    NSString *pathAPI = @"api/register";
    AFHTTPRequestSerializer *userRequestSerializer = [AFHTTPRequestSerializer serializer];
    [userRequestSerializer setValue:@"application/json" forHTTPHeaderField:@"CONTENT_TYPE"];
    
    [requestOperationDomainManager POST:pathAPI
                             parameters:@{ @"email" : email }
                                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                    if (operation.response.statusCode == 200 || operation.response.statusCode == 201) {
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
