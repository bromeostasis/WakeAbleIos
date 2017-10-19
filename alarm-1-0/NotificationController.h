//
//  NotificationController.h
//  Wakeable
//
//  Created by Evan Snyder on 10/12/17.
//  Copyright © 2017 Evan Snyder. All rights reserved.
//

#ifndef NotificationController_h
#define NotificationController_h
@import UserNotifications;

@interface NotificationController : NSObject

@property int failsafeNotificationNumber;
@property int standardNotificationNumber;
@property int notificationInterval;
@property int notificationCount;
@property (nonatomic, strong) NSString   *failsafeMessage;
@property (nonatomic, strong) NSString   *failsafeTitle;
@property (nonatomic, strong) NSString   *standardMessage;
@property (nonatomic, strong) NSString   *standardTitle;
@property (nonatomic, strong) NSString *notificationText;
@property (nonatomic, strong) NSString *notificationTitle;

+ (int) getFailsafeNumber;
+ (int) getNotificationInterval;
+ (NSString *) getNotificationText;
+ (void) resetPreviousNotifications:(NSDate *) dateSet;
+ (void) turnOffWakeableNotifications;
+ (void) scheduleLocalNotifications: (NSDate *)fireDate;

#endif /* NotificationController_h */

@end
