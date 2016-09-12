//
//  AppDelegate.m
//  alarm-1-0
//
//  Created by Evan Snyder on 4/3/16.
//  Copyright (c) 2016 Evan Snyder. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

@synthesize notificationAlert = _notificationAlert;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
//    UIUserNotificationType types = (UIUserNotificationType) (UIUserNotificationTypeBadge |
//                                                             UIUserNotificationTypeSound | UIUserNotificationTypeAlert);
//    
//    UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
//    
//    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]){
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
    }
    // Override point for customization after application launch.
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    
    if (soundId) {
        AudioServicesDisposeSystemSoundID(soundId);
    }
}


- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    
    NSLog(@"Received local notification");
    if ([application applicationState] == UIApplicationStateActive) {
        
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Info"
                              message:@"Go turn off your alarm!!"
                              delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        if (!soundId) {
            NSURL *soundURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"alarm_beep" ofType:@"wav"]];
            AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundURL, &soundId);
            
        }
        
        if (!_notificationAlert) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                            message:nil
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
            [self setNotificationAlert:alert];
        }
        
        
        AudioServicesPlaySystemSound(soundId);
//        if (!alert.visible) {
//            [alert show];
//        }

        
    }
}

@end
