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
//  HRPAppDelegate.m
//  HromadskyiPatrul
//
//  Created by msm72 on 21.08.15.
//  Copyright (c) 2015 Monastyrskiy Sergey. All rights reserved.
//

#import "HRPAppDelegate.h"
#import "AFNetworking.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import "HRPVideoRecordViewController.h"
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>


#if TARGET_IPHONE_SIMULATOR
NSString const *DeviceMode = @"Simulator";
#else
NSString const *DeviceMode = @"Device";
#endif


@interface HRPAppDelegate ()

@end


@implementation HRPAppDelegate {
    UIViewController *_presentedVC;
    HRPVideoRecordViewController *_videoRecordVC;
    CTCallCenter *_callCenter;
    
    int _modeVC;
}

#pragma mark - Constructors -
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    // Start Monitoring Network
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
    [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    
    // Sleep mode
    [UIApplication sharedApplication].idleTimerDisabled = YES;

    // Crashlytics SDK
//    [Fabric with:@[CrashlyticsKit]];
    [Fabric with:@[[Crashlytics class]]];

    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

    // Incoming Call Handler
    _callCenter = [[CTCallCenter alloc] init];
    __weak __typeof(self)weakSelf = self;
    
    [_callCenter setCallEventHandler:^(CTCall *call) {
        if ([call.callState isEqualToString: CTCallStateIncoming]) {
            [weakSelf appDidHide];
        }

        else if (/*[call.callState isEqualToString: CTCallStateConnected] ||*/
                 [call.callState isEqualToString: CTCallStateDisconnected]) {
             [weakSelf appDidShow];
         }
     }];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [self appDidHide];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [self appDidShow];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}


#pragma mark - Methods -
- (void)appDidHide {
    _presentedVC = self.window.rootViewController;
    
    // HRPVideoRecordViewController
    if ([[((UINavigationController *)_presentedVC).viewControllers lastObject] isKindOfClass:[HRPVideoRecordViewController class]]) {
        _videoRecordVC = [((UINavigationController *)_presentedVC).viewControllers lastObject];
        _modeVC = _videoRecordVC.cameraManager.videoSessionMode;
        
        [_videoRecordVC.cameraManager stopVideoSession];
    }
    
    else
        _videoRecordVC = nil;
}

- (void)appDidShow {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_videoRecordVC isKindOfClass:[HRPVideoRecordViewController class]]) {
            _videoRecordVC.cameraManager.videoSessionMode = _modeVC;
            
            if (!_videoRecordVC.cameraManager.videoImageOriginal && _modeVC == NSTimerVideoSessionModeStream && !_callCenter) {
                [_videoRecordVC startVideoRecord];
            }
            
            else {
                _videoRecordVC.violationLabel.text = nil;
                _videoRecordVC.violationLabel.isLabelFlashing = NO;
                _videoRecordVC.navigationItem.rightBarButtonItem.enabled = YES;
                _videoRecordVC.cameraManager.isVideoSaving = NO;
                _videoRecordVC.cameraManager.videoSessionMode = NSTimerVideoSessionModeStream;
                _videoRecordVC.cameraManager.videoImageOriginal = nil;
                
                [_videoRecordVC.cameraManager removeAllFolderMediaTempFiles];
                [_videoRecordVC hideLoader];
                [_videoRecordVC startVideoRecord];
        }
            
            
                // DELETE AFTER TESTING
                /*
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Alert info title", nil)
                                                                               message:NSLocalizedString(@"Alert error sleep message", nil)
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *actionOk = [UIAlertAction actionWithTitle:NSLocalizedString(@"Alert error button Ok", nil)
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction *action) {
                                                                     //if (_videoRecordVC.cameraManager.videoImageOriginal) {
                                                                         _videoRecordVC.violationLabel.text = nil;
                                                                         _videoRecordVC.violationLabel.isLabelFlashing = NO;
                                                                         _videoRecordVC.navigationItem.rightBarButtonItem.enabled = YES;
                                                                         _videoRecordVC.cameraManager.isVideoSaving = NO;
                                                                         //_videoRecordVC.cameraManager.timer = nil;
                                                                         _videoRecordVC.cameraManager.videoSessionMode = NSTimerVideoSessionModeStream;
                                                                         _videoRecordVC.cameraManager.videoImageOriginal = nil;
                                                                         
                                                                         [_videoRecordVC.cameraManager removeAllFolderMediaTempFiles];
                                                                         [_videoRecordVC hideLoader];
                                                                     //}
                                                                     
                                                                     [_videoRecordVC startVideoRecord];
                                                                 }];
                
                [alert addAction:actionOk];
                
                [_videoRecordVC presentViewController:alert animated:YES completion:nil];
                 
            }
            */
        }
    });
}


#pragma mark - Core Data stack
@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.stfalcon.HromadskyiPatrul" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"HromadskyiPatrul" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"HromadskyiPatrul.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        DebugLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    
    return _managedObjectContext;
}


#pragma mark - Core Data Saving support
- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
   
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            DebugLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end
