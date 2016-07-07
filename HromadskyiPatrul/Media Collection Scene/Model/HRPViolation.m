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
//  HRPViolation.m
//  HromadskyiPatrul
//
//  Created by msm72 on 19.02.16.
//  Copyright © 2016 Monastyrskiy Sergey. All rights reserved.
//


#import "HRPViolation.h"


@implementation HRPViolation

#pragma mark - Constructors -
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    
    if (self) {
        _state = [[aDecoder decodeObjectForKey:@"stateKey"] integerValue];
        _type = [[aDecoder decodeObjectForKey:@"typeKey"] integerValue];
        _date = [aDecoder decodeObjectForKey:@"dateKey"];
        _assetsPhotoURL = [aDecoder decodeObjectForKey:@"assetsPhotoURLKey"];
        _assetsVideoURL = [aDecoder decodeObjectForKey:@"assetsVideoURLKey"];
        _assetsVideoURLOriginal = [aDecoder decodeObjectForKey:@"assetsVideoURLOriginalKey"];
        _latitude = [[aDecoder decodeObjectForKey:@"latitudeKey"] floatValue];
        _longitude = [[aDecoder decodeObjectForKey:@"longitudeKey"] floatValue];
        _duration = [[aDecoder decodeObjectForKey:@"durationKey"] floatValue];
        _isUploading = [[aDecoder decodeObjectForKey:@"uploadingKey"] boolValue];
    }
    
    return self;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _state = HRPViolationStateUpload;
        _isUploading = NO;
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:@(_state) forKey:@"stateKey"];
    [aCoder encodeObject:@(_type) forKey:@"typeKey"];
    [aCoder encodeObject:_date forKey:@"dateKey"];
    [aCoder encodeObject:_assetsPhotoURL forKey:@"assetsPhotoURLKey"];
    [aCoder encodeObject:_assetsVideoURL forKey:@"assetsVideoURLKey"];
    [aCoder encodeObject:_assetsVideoURLOriginal forKey:@"assetsVideoURLOriginalKey"];
    [aCoder encodeObject:@(_latitude) forKey:@"latitudeKey"];
    [aCoder encodeObject:@(_longitude) forKey:@"longitudeKey"];
    [aCoder encodeObject:@(_duration) forKey:@"durationKey"];
    [aCoder encodeObject:@(_isUploading) forKey:@"uploadingKey"];
}

@end
