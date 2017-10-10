//
//  SetupViewController.m
//  alarm-1-0
//
//  Created by Evan Snyder on 11/8/16.
//  Copyright © 2016 Evan Snyder. All rights reserved.
//

#import "SetupViewController.h"
#import "BluetoothManager.h"
#import "RMUniversalAlert/RMUniversalAlert.h"

#define SYSTEM_VERSION_GREATERTHAN_OR_EQUALTO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)


@interface SetupViewController ()

@end

@implementation SetupViewController

- (id) initWithNibName:(NSString *)aNibName bundle:(NSBundle *)aBundle {
    self = [super initWithNibName:aNibName bundle:aBundle]; // The UIViewController's version of init
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self checkForNotificationPermission];
    [self setupVisualElements];
    [self setupInternalNotifications];
}

- (void)checkForNotificationPermission {
    if (SYSTEM_VERSION_GREATERTHAN_OR_EQUALTO(@"10.0")) {
        
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert)
                              completionHandler:^(BOOL granted, NSError * _Nullable error) {
                                  if (!error) {
                                      NSLog(@"request authorization succeeded!");
                                  }
                              }];
    }
}

- (void)setupVisualElements {
    
    [self setOneTwoLabel:self.OneLabel];
    [self setOneTwoLabel:self.TwoLabel];
    
    [self.ConnectButton.layer setBorderWidth:2.0];
    [self.ConnectButton.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    [self.ConnectButton.layer setCornerRadius:3.0];
    [self.ConnectButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0)];
    self.ConnectButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.ConnectButton.titleLabel.lineBreakMode = NSLineBreakByClipping;
}

- (void)setOneTwoLabel:(UILabel *)label {
    [label.layer setBorderWidth:5.0];
    [label.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    [label.layer setCornerRadius:3.0];
}

- (void)setupInternalNotifications {
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(onWakeableDeviceFound)
     name:@"FoundWakeable"
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(onWakeableConnected)
     name:@"ConnectedWakeable"
     object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)lookForWakeable:(id)sender {
    self.foundDevice = NO;
    [BluetoothManager connect];
    
    [self performSelector:@selector(alertNoDevices) withObject:nil afterDelay:5.0];
}

- (void) alertNoDevices {
    if (!self.foundDevice) {
        [BluetoothManager stopScan];
        [RMUniversalAlert showAlertInViewController:self withTitle:@"Oh dear" message:@"It looks like Wakeable had a problem connecting. try moving closer to the device and confirming that the bluetooth on your phone is on." cancelButtonTitle:@"OK" destructiveButtonTitle:nil otherButtonTitles:nil tapBlock:nil];
    }
    
    self.foundDevice = NO;
}

- (void) onWakeableDeviceFound {
    CBPeripheral *peripheral = [BluetoothManager getPeripheral];
    self.foundDevice = YES;
    
    [RMUniversalAlert showAlertInViewController:self
                  withTitle:@"Wakeable Found"
                  message:[NSString stringWithFormat:@"Found a Wakeable with identifier %@, want to connect?", peripheral.identifier.UUIDString]
                  cancelButtonTitle:@"OK"
                  destructiveButtonTitle:@"No thanks" otherButtonTitles:nil
                  tapBlock: ^(RMUniversalAlert *alert, NSInteger buttonIndex){
                      if (buttonIndex == alert.cancelButtonIndex) {
                          [BluetoothManager connectToPeripheral:peripheral];
                      }
                  }
     ];
}

- (void) onWakeableConnected {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
