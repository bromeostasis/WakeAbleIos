//
//  ViewController.m
//  alarm-1-0
//
//  Created by Evan Snyder on 4/3/16.
//  Copyright (c) 2016 Evan Snyder. All rights reserved.
//

#import "ViewController.h"
#import "BluetoothManager.h"
#import "RMUniversalAlert/RMUniversalAlert.h"

@interface ViewController ()


@end

@implementation ViewController

#define SYSTEM_VERSION_GREATERTHAN_OR_EQUALTO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

- (id) initWithNibName:(NSString *)aNibName bundle:(NSBundle *)aBundle {
    self = [super initWithNibName:aNibName bundle:aBundle]; // The UIViewController's version of init
    if (self) {
        _notificationCount = 0;
        _soundPlaying = NO;
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (void) viewDidAppear:(BOOL)animated {
    [self checkIfBluetoothIsOn];
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
    self.notificationInterval = 5;
    self.standardNotificationNumber = 60;
    self.failsafeNotificationNumber = 12;
    self.failsafeMessage = @"You're disconnected from your Wakeable device. We'll shut off the alarm for you after one minute!";
    self.failsafeTitle = @"Disconnected!";
    self.standardTitle = @"Time to get up!";
    self.standardMessage = @"Press the physical Wakeable button to turn off your alarm.";
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
        // Get the minute/hour components
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

- (NSString *)getDateString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.timeZone = [NSTimeZone defaultTimeZone];
    dateFormatter.timeStyle = NSDateFormatterMediumStyle;
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    
    return [dateFormatter stringFromDate:self.dateSet];
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
    NSString *dtString = [self getDateString];
    
    [_muteChecker check];
    [self scheduleLocalNotification:self.dateSet];
    NSLog(@"The switch is on:  %@", dtString);
    [self setAlarmButton:YES];
}

- (void) turnOffAlarm {
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    self.dateSet = nil;
    NSLog(@"The switch is off");
    [self setAlarmButton:NO];
}

- (IBAction)SendLogs:(id)sender {
    
    if (![MFMailComposeViewController canSendMail]) {
        NSLog(@"Mail services are not available.");
        return;
    }
    
    MFMailComposeViewController* mailComposer = [[MFMailComposeViewController alloc] init];

    mailComposer.mailComposeDelegate = self;
    [mailComposer setSubject:@"This thing didn't work!"];
    NSArray *toRecipients = [NSArray arrayWithObject:@"wakeable.team@gmail.com"];
    [mailComposer setToRecipients:toRecipients];
    NSString *emailBody = @"We love feedback! Please include below: a short description of the problem your facing along with the approximate time of failure if possible. We'll look into the problem and get back to you as soon as possible.";
    [mailComposer setMessageBody:emailBody isHTML:NO];
    
    // Attach the Crash Log..
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *logPath = [documentsDirectory stringByAppendingPathComponent:@"wakeable-log.txt"];
    NSData *myData = [NSData dataWithContentsOfFile:logPath];
    [mailComposer addAttachmentData:myData mimeType:@"Text/XML" fileName:@"wakeable-log.txt"];
    [self presentViewController:mailComposer animated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) scheduleLocalNotification: (NSDate *) fireDate{
    int numberOfNotifications = 0;
    if ([BluetoothManager isConnected]) {
        self.notificationText = self.standardMessage;
        self.notificationTitle = self.standardTitle;
        numberOfNotifications = self.standardNotificationNumber;
    }
    else{
        self.notificationText = self.failsafeMessage;
        self.notificationTitle = self.failsafeTitle;
        numberOfNotifications = self.failsafeNotificationNumber;
        
    }
    
    if (SYSTEM_VERSION_GREATERTHAN_OR_EQUALTO(@"10.0")) {
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        content.title = [NSString localizedUserNotificationStringForKey:self.notificationTitle arguments:nil];
        content.body = [NSString localizedUserNotificationStringForKey:self.notificationText
                                                             arguments:nil];
        content.sound = [UNNotificationSound soundNamed:@"alarm_beep.wav"];
        
        for (int i=0; i<numberOfNotifications; i++){
            self.notificationCount = self.notificationCount + 1;
            
            NSDate *modDate = [fireDate dateByAddingTimeInterval:self.notificationInterval*i];
            NSCalendar *gregorian = [[NSCalendar alloc]
                                     initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            NSDateComponents *dateComponents = [gregorian components:(NSCalendarUnitSecond | NSCalendarUnitMinute |
                                                                      NSCalendarUnitHour| NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:modDate];
            UNCalendarNotificationTrigger *trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:dateComponents repeats:NO];
            UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:[NSString stringWithFormat:@"notification%d", self.notificationCount]
                                                                                  content:content trigger:trigger];
            UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
            [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {}];

        }
        
    }
    else {
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.alertBody = self.notificationText;
        notification.alertTitle = self.notificationTitle;
        notification.soundName = @"alarm_beep.wav";
        
        for (int i=0; i<numberOfNotifications; i++){
            NSDate *modDate = [fireDate dateByAddingTimeInterval:self.notificationInterval*(i+1)];
            notification.fireDate = modDate;
            [[UIApplication sharedApplication] scheduleLocalNotification:notification];
            
        }
    }
    
    
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

- (void) turnOffWakeableNotifications {
    if(SYSTEM_VERSION_GREATERTHAN_OR_EQUALTO(@"10.0")){
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center removeAllDeliveredNotifications];
        [center removeAllPendingNotificationRequests];
    }
    else{
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
        AudioServicesDisposeSystemSoundID(soundId);
    }
    [self dismissViewControllerAnimated:NO completion:^{}];
}

- (void) handlePhysicalButtonPress {
    if (self.dateSet != nil) {
        NSDate * currentDate = [NSDate dateWithTimeIntervalSinceNow:0];
        NSDate * result = [currentDate laterDate:self.dateSet];
        if (result == currentDate ) {
            NSLog(@"Got a one. cancelling all notifications");
            [self turnOffWakeableNotifications];
            self.dateSet = nil;
            [self setAlarmButton:NO];
        }
        else{
            NSLog(@"Got a one, but it's before the scheduled alarm. Don't cancel anything just yet.");
        }
    }
    else{
        // Turn off notifications in case of a kill/reconnect situation..
        [self turnOffWakeableNotifications];
        NSLog(@"Got a one, but there's no date set. Likely just connecting");
    }
}

- (void) handleConnectionChange {
    [self setConnectionButton];
    if ([BluetoothManager isConnected]){
        [self resetPreviousNotifications];
    }
    else{
        [self turnOffWakeableNotifications];
        [self resetCurrentNotifications];
    }

}

- (void) resetPreviousNotifications {
    if ([BluetoothManager isConnected]) {
        self.foundDevice = YES;
        NSLog(@"Connected to a peripheral. Current date set: %@", self.dateSet);
        if (self.dateSet != nil) {
            NSDate * currentDate = [NSDate dateWithTimeIntervalSinceNow:0];
            
            NSDate * earlierDate = [currentDate earlierDate:self.dateSet];
            if (earlierDate == currentDate ) {
                NSLog(@"We had an alarm set that hasn't gone off yet. Reschedule notifications now that we're connected.");
                [self turnOffWakeableNotifications];
                [self scheduleLocalNotification:self.dateSet];
            }
            else{
                NSLog(@"Failsafe notifications already went off. Let's just reset");
                self.dateSet = nil;
                [self setAlarmButton:NO];
            }
        }
    }
}
- (void) resetCurrentNotifications {
    if (self.dateSet != nil) {
        NSLog(@"We had a date set, cancelling all notifications.");
        [self scheduleLocalNotification:self.dateSet];
    }
}

// Helper functions

- (void) checkForFailsafe {
    
    if (self.dateSet != nil && ![BluetoothManager isConnected]) {
        NSDateComponents *secondComponent = [[NSDateComponents alloc] init];
        secondComponent.second = self.notificationInterval * self.failsafeNotificationNumber;
        
        NSCalendar *theCalendar = [NSCalendar currentCalendar];
        NSDate *failsafeDate = [theCalendar dateByAddingComponents:secondComponent toDate:self.dateSet options:0];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.timeZone = [NSTimeZone defaultTimeZone];
        dateFormatter.timeStyle = NSDateFormatterMediumStyle;
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        
        NSString *dtString = [dateFormatter stringFromDate:failsafeDate];
        
        NSLog(@"Looking for this date as failsafe: %@", dtString);
        
        NSDate * currentDate = [NSDate dateWithTimeIntervalSinceNow:0];
        NSDate * result = [currentDate laterDate:failsafeDate];
        if (result == currentDate ) {
            NSLog(@"Failsafe should have gone off. Turning button off.");
            self.dateSet = nil;
            [self setAlarmButton:NO];
            [self turnOffWakeableNotifications];
        }
        
    }
    
}

- (void) foregroundNotification {
    [self dismissViewControllerAnimated:NO completion:^{}];
    [RMUniversalAlert showAlertInViewController:self withTitle:@"Time to wake up" message:self.notificationText cancelButtonTitle:@"OK" destructiveButtonTitle:nil otherButtonTitles:nil tapBlock:nil];
    
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
