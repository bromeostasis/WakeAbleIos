//
//  NotificationController.m
//  Wakeable
//
//  Created by Evan Snyder on 10/12/17.
//  Copyright © 2017 Evan Snyder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIKit/UIKit.h"
#import "NotificationController.h"
#import "BluetoothManager.h"

static int notificationInterval = 5;
static int standardNotificationNumber = 60;
static int failsafeNotificationNumber = 12;
static int notificationCount = 0;
static NSString *failsafeMessage = @"You're disconnected from your Wakeable device. We'll shut off the alarm for you after one minute!";
static NSString *failsafeTitle = @"Disconnected!";
static NSString *standardTitle = @"Time to get up!";
static NSString *standardMessage = @"Press the physical Wakeable button to turn off your alarm.";
static NSString *notificationText;
static NSString *notificationTitle;

@implementation NotificationController

#define SYSTEM_VERSION_GREATERTHAN_OR_EQUALTO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
+ (int) getFailsafeNumber {
    return failsafeNotificationNumber;
}
+ (int) getNotificationInterval {
    return notificationInterval;
}
+ (NSString *) getNotificationText {
    return notificationText;
}
+ (void) resetPreviousNotifications:(NSDate *) dateSet {
    if (dateSet != nil) {
        NSDate * currentDate = [NSDate dateWithTimeIntervalSinceNow:0];
        
        NSDate * earlierDate = [currentDate earlierDate:dateSet];
        if (earlierDate == currentDate ) {
            NSLog(@"We had an alarm set that hasn't gone off yet. Reschedule notifications now that we're connected.");
            [self turnOffWakeableNotifications];
            [self scheduleLocalNotification:dateSet];
        }
        else{
            NSLog(@"Failsafe notifications already went off. Let's just reset");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"TurnOffAlarm" object:nil];
        }
    }
}


+ (void) turnOffWakeableNotifications {
    if(SYSTEM_VERSION_GREATERTHAN_OR_EQUALTO(@"10.0")){
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center removeAllDeliveredNotifications];
        [center removeAllPendingNotificationRequests];
    }
    else{
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
    }
}

+ (void) scheduleLocalNotification: (NSDate *) fireDate{
    int numberOfNotifications = 0;
    if ([BluetoothManager isConnected]) {
        notificationText = standardMessage;
        notificationTitle = standardTitle;
        numberOfNotifications = standardNotificationNumber;
    }
    else{
        notificationText = failsafeMessage;
        notificationTitle = failsafeTitle;
        numberOfNotifications = failsafeNotificationNumber;
        
    }
    
    if (SYSTEM_VERSION_GREATERTHAN_OR_EQUALTO(@"10.0")) {
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        content.title = [NSString localizedUserNotificationStringForKey:notificationTitle arguments:nil];
        content.body = [NSString localizedUserNotificationStringForKey:notificationText
                                                             arguments:nil];
        content.sound = [UNNotificationSound soundNamed:@"alarm_beep.wav"];
        
        for (int i=0; i<numberOfNotifications; i++){
            notificationCount = notificationCount + 1;
            
            NSDate *modDate = [fireDate dateByAddingTimeInterval:notificationInterval*i];
            NSCalendar *gregorian = [[NSCalendar alloc]
                                     initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            NSDateComponents *dateComponents = [gregorian components:(NSCalendarUnitSecond | NSCalendarUnitMinute |
                                                                      NSCalendarUnitHour| NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:modDate];
            UNCalendarNotificationTrigger *trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:dateComponents repeats:NO];
            UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:[NSString stringWithFormat:@"notification%d", notificationCount]
                                                                                  content:content trigger:trigger];
            UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
            [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {}];
            
        }
        
    }
    else {
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.alertBody = notificationText;
        notification.alertTitle = notificationTitle;
        notification.soundName = @"alarm_beep.wav";
        
        for (int i=0; i<numberOfNotifications; i++){
            NSDate *modDate = [fireDate dateByAddingTimeInterval:notificationInterval*(i+1)];
            notification.fireDate = modDate;
            [[UIApplication sharedApplication] scheduleLocalNotification:notification];
            
        }
    }
    
    
}
@end
