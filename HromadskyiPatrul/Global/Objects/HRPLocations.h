//
//  HRPLocations.h
//  HuntsPoynt
//
//  Created by msm72 on 07.07.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>


@interface HRPLocations : NSObject

@property (strong, nonatomic) CLLocationManager *manager;
@property (strong, nonatomic) CLGeocoder *geocoder;
@property (strong, nonatomic) CLPlacemark *placemark;
@property (assign, nonatomic) BOOL isLocationCorrect;

- (BOOL)isEnabled;

@end
