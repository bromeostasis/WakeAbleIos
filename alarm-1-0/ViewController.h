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
#import "SetupViewController.h"
#import "MuteChecker.h"

#define HM10_SERVICE_UUID @"FFE0";
#define HM10_CHAR_UUID @"FFE1";



@import CoreBluetooth;

@interface ViewController : UIViewController<SetupViewControllerDelegate>
{
    
    IBOutlet UIDatePicker *dateTimePicker;
    SystemSoundID soundId;
}

@property (nonatomic, strong) MuteChecker *muteChecker;
@property (nonatomic, strong) UIImage *btImage;
@property (nonatomic, strong) UIImage *exclamationImage;
@property BOOL alarmSet;
@property BOOL foundDevice;
@property BOOL soundPlaying;
@property (nonatomic, strong) NSDate *dateSet;

- (IBAction)Reconnect:(id)sender;
- (IBAction)SendLogs:(id)sender;
- (IBAction)SetAlarm:(id)sender;

- (void) setConnectionButton;
- (void) handlePhysicalButtonPress;
- (void) handleConnectionChange;

@property (weak, nonatomic) IBOutlet UIImageView *StatusImage;
@property (weak, nonatomic) IBOutlet UIButton *AlarmSetButton;
@property (weak, nonatomic) IBOutlet UIButton *StatusButton;
@property (weak, nonatomic) IBOutlet UIButton *ReconnectButton;
@property (weak, nonatomic) IBOutlet UIButton *LogButton;

@end
