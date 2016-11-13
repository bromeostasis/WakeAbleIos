//
//  ViewController.h
//  alarm-1-0
//
//  Created by Evan Snyder on 4/3/16.
//  Copyright (c) 2016 Evan Snyder. All rights reserved.
//

@import CoreBluetooth;
@import QuartzCore;
@import UserNotifications;
@import AVFoundation;
@import MediaPlayer;

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "SetupViewController.h"
#import "MuteChecker.h"

#define HM10_SERVICE_UUID @"FFE0";
#define HM10_CHAR_UUID @"FFE1";



@import CoreBluetooth;

@interface ViewController : UIViewController<CBCentralManagerDelegate, CBPeripheralDelegate, MFMailComposeViewControllerDelegate, SetupViewControllerDelegate>
{
    
    IBOutlet UIDatePicker *dateTimePicker;
    SystemSoundID soundId;
}

@property (nonatomic, strong) MuteChecker *muteChecker;
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *hm10Peripheral;
@property BOOL connected;
@property BOOL bluetoothCapable;
@property BOOL alarmSet;
@property BOOL first;
@property int notificationCount;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSString   *bodyData;
@property (nonatomic, strong) NSString   *manufacturer;
@property (nonatomic, strong) NSString   *hm10Device;
@property (nonatomic, strong) NSDate *dateSet;
@property (assign) uint16_t heartRate;

- (IBAction)Reconnect:(id)sender;
- (IBAction)SendLogs:(id)sender;
- (IBAction)Connect:(id)sender;
- (IBAction)SetAlarm:(id)sender;
- (void) scheduleLocalNotification: (NSDate *)fireDate forMessage:(NSString*)message howMany:(int)numberOfNotifications;
- (void) getStringPackage:(CBCharacteristic *)characteristic;
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification;
- (void) turnOffWakeableNotifications;
- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error;


- (IBAction)PlaySound:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *AlarmSetButton;
@property (weak, nonatomic) IBOutlet UIButton *StatusButton;
@property (weak, nonatomic) IBOutlet UIButton *ReconnectButton;
@property (weak, nonatomic) IBOutlet UIView *mpVolumeViewParentView;

@end
