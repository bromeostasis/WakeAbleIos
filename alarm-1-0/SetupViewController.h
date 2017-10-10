//
//  SetupViewController.h
//  alarm-1-0
//
//  Created by Evan Snyder on 11/8/16.
//  Copyright © 2016 Evan Snyder. All rights reserved.
//

#import <UIKit/UIKit.h>

@import CoreBluetooth;
@import QuartzCore;

@import UserNotifications;


#define HM10_SERVICE_UUID @"FFE0";
#define HM10_CHAR_UUID @"FFE1";

@class SetupViewController;

@protocol SetupViewControllerDelegate <NSObject>

@end

@interface SetupViewController : UIViewController

- (IBAction)lookForWakeable:(id)sender;
- (void)onWakeableDeviceFound;
- (void)onWakeableConnected;

@property (weak, nonatomic) IBOutlet UILabel *TwoLabel;
@property (weak, nonatomic) IBOutlet UILabel *OneLabel;
@property (weak, nonatomic) IBOutlet UIButton *ConnectButton;
@property BOOL foundDevice;

@end
