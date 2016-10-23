//
//  AppDelegate.h
//  alarm-1-0
//
//  Created by Evan Snyder on 4/3/16.
//  Copyright (c) 2016 Evan Snyder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

@import UserNotifications;

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    
    SystemSoundID soundId;
}


@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UIAlertView *notificationAlert;
@property BOOL soundPlaying;

@end

