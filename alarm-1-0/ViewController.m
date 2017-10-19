//
//  ViewController.m
//  alarm-1-0
//
//  Created by Evan Snyder on 4/3/16.
//  Copyright (c) 2016 Evan Snyder. All rights reserved.
//

#import "ViewController.h"
#import "BluetoothManager.h"
#import "MailController.h"
#import "NotificationController.h"
#import "RMUniversalAlert/RMUniversalAlert.h"

@interface ViewController ()


@end

@implementation ViewController

#define SYSTEM_VERSION_GREATERTHAN_OR_EQUALTO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

// SETUP FUNCTIONS START HERE

- (id) initWithNibName:(NSString *)aNibName bundle:(NSBundle *)aBundle {
    self = [super initWithNibName:aNibName bundle:aBundle]; // The UIViewController's version of init
    if (self) {
        _soundPlaying = NO;
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) viewDidAppear:(BOOL)animated {
    [self checkIfBluetoothIsOn];
}

- (void)viewDidLayoutSubviews {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *address = [defaults objectForKey:@"address"];
    if (address == nil) {
        [self showSetupView];
    }
    else{
        if ([BluetoothManager isBluetoothCapable]) {
            NSLog(@"We have an address, bluetooth is on, and we're not currently connected. Let's scan for devices.");
            
            [BluetoothManager connect];
        }
    }
}

- (void) showSetupView {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    SetupViewController *setupController = [sb instantiateViewControllerWithIdentifier:@"SetupViewController"];
    setupController.delegate = self;
    [self presentViewController:setupController animated:NO completion:NULL];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupConstants];
    [self setupInternalNotifications];
    [self setupVisualElements];
    [self setupMuteChecker];
    [self setupSoundURL];
    [BluetoothManager connect];

    [self setConnectionButton];
    
}

- (void)setupConstants {
    self.btImage = [UIImage imageNamed:@"bluetooth.png"];
    self.exclamationImage = [UIImage imageNamed:@"exclamation.png"];
}

- (void)setupInternalNotifications {
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(checkForFailsafe)
     name:UIApplicationWillEnterForegroundNotification
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(foregroundNotification)
     name:@"ForegroundNotification"
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(handleConnectionChange)
     name:@"ConnectionChanged"
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(handlePhysicalButtonPress)
     name:@"ReceivedOne"
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(turnOffAlarm)
     name:@"TurnOffAlarm"
     object:nil];
}

- (void)setupVisualElements {
    dateTimePicker.datePickerMode = UIDatePickerModeTime;
    
    [self setupStandardButton:self.StatusButton];
    [self.StatusButton setEnabled:NO];
    self.StatusButton.titleLabel.numberOfLines = 1;
    
    [self setupStandardButton:self.AlarmSetButton];
    [self.AlarmSetButton.titleLabel setBaselineAdjustment:UIBaselineAdjustmentAlignCenters];
    self.AlarmSetButton.titleLabel.numberOfLines = 1;
    self.AlarmSetButton.titleLabel.lineBreakMode = NSLineBreakByClipping;
    
    [self setupStandardButton:self.LogButton];
    self.LogButton.titleLabel.numberOfLines = 1;
    
    [self setupStandardButton:self.ReconnectButton];
    [self.ReconnectButton setHidden:YES];
    self.ReconnectButton.titleLabel.lineBreakMode = NSLineBreakByClipping;
}

- (void) setupStandardButton:(UIButton *)button {
    [button.layer setBorderWidth:2.0];
    [button.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    [button.layer setCornerRadius:3.0];
    [button setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0)];
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
}

- (void)setupMuteChecker {
    self.muteChecker = [[MuteChecker alloc] initWithCompletionBlk:^(NSTimeInterval lapse, BOOL muted) {
        
        if(muted){
            [RMUniversalAlert showAlertInViewController:self
                                              withTitle:@"Your phone is silenced"
                                                message:@"Please turn off the silence switch to hear notifications."
                                      cancelButtonTitle:@"Thanks!" destructiveButtonTitle:nil otherButtonTitles:nil tapBlock:nil];
        }
    }];
    // Get the first one out of the way.
    [_muteChecker check];
}

- (void) setupSoundURL {
    NSURL *soundURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"alarm_beep" ofType:@"wav"]];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundURL, &soundId);
}

// BUTTON HANDLERS START HERE

- (IBAction)Reconnect:(id)sender {
    [self checkIfBluetoothIsOn];
    
    if ([BluetoothManager isBluetoothCapable]) {
        [BluetoothManager connect];
    }
    
    self.foundDevice = NO;
    [self performSelector:@selector(alertNoDevices) withObject:nil afterDelay:5.0];
}

- (void) checkIfBluetoothIsOn {
    CBCentralManager* testBluetooth = [[CBCentralManager alloc] initWithDelegate:nil queue: nil];
    [testBluetooth state];
}

- (void) alertNoDevices {
    [BluetoothManager stopScan];
    if (!self.foundDevice) {
        [RMUniversalAlert showAlertInViewController:self withTitle:@"Oh dear" message:@"It looks like Wakeable had a problem connecting. Try moving closer to the device and confirm that the bluetooth on your phone is on." cancelButtonTitle:@"OK" destructiveButtonTitle:nil otherButtonTitles:nil tapBlock:nil];
    }
    
    self.foundDevice = NO;
}

- (IBAction)SetAlarm:(id)sender {
    
    if(!self.alarmSet){
        [self setDateUsingComponents];
        [self setForTomorrowIfNecessary];
        
        if ([BluetoothManager isConnected]) {
            [self turnOnAlarm];
        }
        else{
            [RMUniversalAlert showAlertInViewController:self
                      withTitle:@"Head's up!"
                      message:@"You're not connected to Wakeable, but you just turned on your alarm."
                      cancelButtonTitle:@"Got it, I will try to reconnect first"
                      destructiveButtonTitle:@"Set my alarm anyway, I'll connect later" otherButtonTitles:nil
                      tapBlock: ^(RMUniversalAlert *alert, NSInteger buttonIndex){
                          if (buttonIndex == alert.cancelButtonIndex) {
                              [self turnOffAlarm];
                          } else if (buttonIndex == alert.destructiveButtonIndex) {
                              [self turnOnAlarm];
                          }
                      }
             ];
        }
    
    }
    else{
        [self turnOffAlarm];
    }
}

- (void) setDateUsingComponents {
    NSDate * currentDate = [NSDate dateWithTimeIntervalSinceNow:0];
    NSCalendar *theCalendar = [NSCalendar currentCalendar];

    // Base things off the current date just to be sure..
    NSDateComponents *currentComponents = [theCalendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:currentDate];
    NSDateComponents *timeComponents = [theCalendar components:NSCalendarUnitMinute | NSCalendarUnitHour fromDate:dateTimePicker.date];
    
    [currentComponents setHour:[timeComponents hour]];
    [currentComponents setMinute:[timeComponents minute]];
    [currentComponents setSecond:0];
    
    self.dateSet = [theCalendar dateFromComponents:currentComponents];
}

- (void) setForTomorrowIfNecessary {
    NSDate * currentDate = [NSDate dateWithTimeIntervalSinceNow:0];
    NSDate * result = [currentDate laterDate:self.dateSet];
    if (result == currentDate ) {
        NSLog(@"Current date is later than selected. Set for tomorrow");
        NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
        dayComponent.day = 1;
        
        self.dateSet = [[NSCalendar currentCalendar] dateByAddingComponents:dayComponent toDate:self.dateSet options:0];
    }
}


- (void) turnOnAlarm {
    NSString *dtString = [self getDateString:self.dateSet];
    
    [_muteChecker check];
    [NotificationController scheduleLocalNotification:self.dateSet];
    NSLog(@"The switch is on:  %@", dtString);
    [self setAlarmButton:YES];
}

- (NSString *) getDateString:(NSDate *) inputDate {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.timeZone = [NSTimeZone defaultTimeZone];
    dateFormatter.timeStyle = NSDateFormatterMediumStyle;
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    
    return [dateFormatter stringFromDate:inputDate];
}

- (void) turnOffAlarm {
    [NotificationController turnOffWakeableNotifications];
    self.dateSet = nil;
    NSLog(@"The switch is off");
    [self setAlarmButton:NO];
    
    AudioServicesDisposeSystemSoundID(soundId);
    [self dismissViewControllerAnimated:NO completion:^{}];
}

- (IBAction)SendLogs:(id)sender {
    [MailController sendWakeableEmail];
}

- (void) setConnectionButton {
    if([BluetoothManager isConnected]){
        
        [self.ReconnectButton setHidden:YES];
        [self.StatusButton setTitle:@"you're good to go" forState:UIControlStateDisabled];
        [self.StatusImage setImage:self.btImage];
    }
    else{
        [self.StatusImage setImage:self.exclamationImage];
        [self.StatusButton setTitle:@"houston, we have a problem" forState:UIControlStateDisabled];
        [self.ReconnectButton setHidden:NO];
        
    }
}

- (void) setAlarmButton:(bool)status{
    self.alarmSet = status;
    NSString *buttonText = (status) ? @"ON" : @"OFF";
    [self.AlarmSetButton setTitle:buttonText forState:UIControlStateNormal];
}

// EVENT HANDLER FUNCTIONS START HERE

- (void) handlePhysicalButtonPress {
    if (self.dateSet != nil) {
        NSDate * currentDate = [NSDate dateWithTimeIntervalSinceNow:0];
        NSDate * result = [currentDate laterDate:self.dateSet];
        if (result == currentDate ) {
            NSLog(@"Got a one. cancelling all notifications");
            [self turnOffAlarm];
        }
        else{
            NSLog(@"Got a one, but it's before the scheduled alarm. Don't cancel anything just yet.");
        }
    }
    else{
        // Turn off notifications in case of a kill/reconnect situation..
        [NotificationController turnOffWakeableNotifications];
        NSLog(@"Got a one, but there's no date set. Likely just connecting");
    }
}

- (void) handleConnectionChange {
    [self setConnectionButton];
    if ([BluetoothManager isConnected]){
        self.foundDevice = YES;
        NSLog(@"Connected to a peripheral. Current date set: %@", self.dateSet);
        [NotificationController resetPreviousNotifications:self.dateSet];
    }
    else{
        [NotificationController turnOffWakeableNotifications];
        if (self.dateSet != nil) {
            NSLog(@"We had a date set, cancelling all notifications.");
            [NotificationController scheduleLocalNotification:self.dateSet];
        }
    }

}

- (void) checkForFailsafe {
    
    if (self.dateSet != nil && ![BluetoothManager isConnected]) {
        NSDateComponents *secondComponent = [[NSDateComponents alloc] init];
        secondComponent.second = [NotificationController getFailsafeNumber] * [NotificationController getNotificationInterval];
        
        NSCalendar *theCalendar = [NSCalendar currentCalendar];
        NSDate *failsafeDate = [theCalendar dateByAddingComponents:secondComponent toDate:self.dateSet options:0];
        NSString *dtString = [self getDateString:failsafeDate];
        
        NSLog(@"Looking for this date as failsafe: %@", dtString);
        
        NSDate * currentDate = [NSDate dateWithTimeIntervalSinceNow:0];
        NSDate * result = [currentDate laterDate:failsafeDate];
        if (result == currentDate ) {
            NSLog(@"Failsafe should have gone off. Turning button off.");
            [self turnOffAlarm];
        }
        
    }
    
}

- (void) foregroundNotification {
    [self dismissViewControllerAnimated:NO completion:^{}];
    [NSThread sleepForTimeInterval:1.0f];
    [RMUniversalAlert showAlertInViewController:self withTitle:@"Time to wake up" message:[NotificationController getNotificationText] cancelButtonTitle:@"OK" destructiveButtonTitle:nil otherButtonTitles:nil tapBlock:nil];
    
    if (!soundId) {
        NSURL *soundURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"alarm_beep" ofType:@"wav"]];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundURL, &soundId);
        
    }
    
    if(SYSTEM_VERSION_GREATERTHAN_OR_EQUALTO(@"10.0")){
        if(!self.soundPlaying && soundId){
            self.soundPlaying = YES;
            AudioServicesPlaySystemSoundWithCompletion(soundId, ^{
                AudioServicesDisposeSystemSoundID(soundId);
                soundId=0;
                self.soundPlaying=NO;
            });
        }
    }
    else{
        AudioServicesPlaySystemSound(soundId);
    }

}


@end
