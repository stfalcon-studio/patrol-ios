//
//  HRPNetworkConnection.h
//  HromadskyiPatrul
//
//  Created by msm72 on 27.08.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ifaddrs.h>
#import <net/if.h>
#import <SystemConfiguration/CaptiveNetwork.h>


@interface HRPNetworkConnection : NSObject

- (BOOL)isWiFiEnabled;
- (BOOL)isWiFiConnected;
- (NSString *)BSSID;
- (NSString *)SSID;

@end
