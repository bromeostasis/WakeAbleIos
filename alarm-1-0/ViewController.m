//
//  ViewController.m
//  alarm-1-0
//
//  Created by Evan Snyder on 4/3/16.
//  Copyright (c) 2016 Evan Snyder. All rights reserved.
//

#import "ViewController.h"
#import "BluetoothManager.h"

@interface ViewController ()


@end

@implementation ViewController

#define SYSTEM_VERSION_GREATERTHAN_OR_EQUALTO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

- (id) initWithNibName:(NSString *)aNibName bundle:(NSBundle *)aBundle {
    self = [super initWithNibName:aNibName bundle:aBundle]; // The UIViewController's version of init
    if (self) {
//        _bluetoothCapable = NO;
        _notificationCount = 0;
//        _hm10Peripheral = nil;
        _soundPlaying = NO;
//        _connected = NO;
    }
    return self;
}

- (void)viewDidLayoutSubviews {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *address = [defaults objectForKey:@"address"];
    if (address == nil) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        SetupViewController *setupController = [sb instantiateViewControllerWithIdentifier:@"SetupViewController"];
        setupController.delegate = self;
        [self presentViewController:setupController animated:NO completion:NULL];
    }
    else{
        if ([BluetoothManager isBluetoothCapable] && [BluetoothManager hasPeripheral]) {
            NSLog(@"We have an address, bluetooth is on, and we're not currently connected. Let's scan for devices.");
            
            [BluetoothManager connect];
            //            NSArray *services = @[ [CBUUID UUIDWithString:@"FFE0"] ];
            //            [self.centralManager scanForPeripheralsWithServices:services options:nil];
        }
        
    }

}

- (void) viewDidAppear:(BOOL)animated {
    CBCentralManager* testBluetooth = [[CBCentralManager alloc] initWithDelegate:nil queue: nil];
    [testBluetooth state];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.notificationInterval = 5;
    self.standardNotificationNumber = 60;
    self.failsafeNotificationNumber = 12;
    self.failsafeMessage = @"You're disconnected from your Wakeable device. We'll shut off the alarm for you after one minute!";
    self.failsafeTitle = @"Disconnected!";
    self.standardTitle = @"Time to get up!";
    self.standardMessage = @"Press the physical Wakeable button to turn off your alarm.";
    self.btImage = [UIImage imageNamed:@"bluetooth.png"];
    self.exclamationImage = [UIImage imageNamed:@"exclamation.png"];
    
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
     selector:@selector(setConnectionButton)
     name:@"ConnectionChanged"
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(handlePhysicalButtonPress)
     name:@"ReceivedOne"
     object:nil];
    
    [self.StatusButton setEnabled:NO];
    [self.StatusButton.layer setBorderWidth:2.0];
    [self.StatusButton.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    [self.StatusButton.layer setCornerRadius:3.0];
    [self.StatusButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0)];
    self.StatusButton.titleLabel.numberOfLines = 1;
    self.StatusButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    
    [self.AlarmSetButton.layer setBorderWidth:2.0];
    [self.AlarmSetButton.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    [self.AlarmSetButton.layer setCornerRadius:3.0];
    [self.AlarmSetButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0)];
    [self.AlarmSetButton.titleLabel setBaselineAdjustment:UIBaselineAdjustmentAlignCenters];
    self.AlarmSetButton.titleLabel.numberOfLines = 1;
    self.AlarmSetButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.AlarmSetButton.titleLabel.lineBreakMode = NSLineBreakByClipping;
    
    [self.LogButton.layer setBorderWidth:2.0];
    [self.LogButton.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    [self.LogButton.layer setCornerRadius:3.0];
    [self.LogButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0)];
    self.LogButton.titleLabel.numberOfLines = 1;
    self.LogButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    
    [self.ReconnectButton setHidden:YES];
    [self.ReconnectButton.layer setBorderWidth:2.0];
    [self.ReconnectButton.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    [self.ReconnectButton.layer setCornerRadius:3.0];
    [self.ReconnectButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0)];
    self.ReconnectButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.ReconnectButton.titleLabel.lineBreakMode = NSLineBreakByClipping;
    
    self.muteChecker = [[MuteChecker alloc] initWithCompletionBlk:^(NSTimeInterval lapse, BOOL muted) {
        
        if(muted){
            UIAlertController* alert = [UIAlertController
                                        alertControllerWithTitle:@"Your phone is silenced!"
                                        message: @"Please turn off the silence switch to hear notifications in the morning."
                                        preferredStyle:UIAlertControllerStyleAlert];
            
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Thanks!" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            [alert addAction:defaultAction];
            
            [self presentViewController:alert animated:NO completion:^{}];
        }
    }];
    // Get the first one out of the way.
    [_muteChecker check];
    

    
    NSURL *soundURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"alarm_beep" ofType:@"wav"]];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundURL, &soundId);
    dateTimePicker.datePickerMode = UIDatePickerModeTime;
    
//    BLUETOOTH SETUP
//    CBCentralManager *centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
//    self.centralManager = centralManager;
    [BluetoothManager connect];

    [self setConnectionButton];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (IBAction)Reconnect:(id)sender {
    // Checks if bluetooth is turned on?
    CBCentralManager* testBluetooth = [[CBCentralManager alloc] initWithDelegate:nil queue: nil];
    [testBluetooth state];
    
    if ([BluetoothManager isBluetoothCapable]) {
        [BluetoothManager connect];
//        NSArray *services = @[ [CBUUID UUIDWithString:@"FFE0"] ];
//        [self.centralManager scanForPeripheralsWithServices:services options:nil];
    }
    
    self.foundDevice = NO;
    [self performSelector:@selector(alertNoDevices) withObject:nil afterDelay:5.0];
}

- (IBAction)SetAlarm:(id)sender {
    
    if(!self.alarmSet){
        [_muteChecker check];
        // Get the minute/hour components
        self.dateSet = dateTimePicker.date;
        
        NSCalendar *theCalendar = [NSCalendar currentCalendar];
        NSDate * currentDate = [NSDate dateWithTimeIntervalSinceNow:0];
        
        
        // Base things off the current date just to be sure..
        NSDateComponents *currentComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:currentDate];
        NSDateComponents *timeComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitMinute | NSCalendarUnitHour fromDate:self.dateSet];
        
        [currentComponents setHour:[timeComponents hour]];
        [currentComponents setMinute:[timeComponents minute]];
        [currentComponents setSecond:0];
        
        self.dateSet = [theCalendar dateFromComponents:currentComponents];
        
        NSDate * result = [currentDate laterDate:self.dateSet];
        if (result == currentDate ) {
            NSLog(@"Current date is later than selected. Set for tomorrow");
            NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
            dayComponent.day = 1;
            
            self.dateSet = [theCalendar dateByAddingComponents:dayComponent toDate:self.dateSet options:0];
        }
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.timeZone = [NSTimeZone defaultTimeZone];
        dateFormatter.timeStyle = NSDateFormatterMediumStyle;
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        
        NSString *dtString = [dateFormatter stringFromDate:self.dateSet];
        if ([BluetoothManager isConnected]) {
        
            NSLog(@"The switch is on:  %@", dtString);
            [self scheduleLocalNotification:self.dateSet];
            
            [self setAlarmButton:YES];
        }
        else{
            UIAlertController* alert = [UIAlertController
                                        alertControllerWithTitle:@"Head's up!"
                                        message: @"You're not connected to Wakeable, but you just turned on your alarm."
                                        preferredStyle:UIAlertControllerStyleAlert];
            
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Got it, I will try to reconnect first" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                      [self setAlarmButton:NO];
                                                                      self.dateSet = nil;
                                                                      
                                                                  }];
            [alert addAction:defaultAction];
            
            UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Set my alarm anyway, I'll connect later." style:UIAlertActionStyleCancel
                                                                 handler:^(UIAlertAction * action) {
                                                                     [self scheduleLocalNotification:self.dateSet];
                                                                     NSLog(@"The switch is on:  %@", dtString);
                                                                     [_muteChecker check];
                                                                     [self setAlarmButton:YES];
                                                                 }];
            [alert addAction:cancelAction];
            
            [self presentViewController:alert animated:NO completion:^{}];
        }
    
    }
    else{
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
        self.dateSet = nil;
        NSLog(@"The switch is off");
        [self setAlarmButton:NO];
    }
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

- (IBAction)PlaySound:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"address"];
    [defaults synchronize];
    if(SYSTEM_VERSION_GREATERTHAN_OR_EQUALTO(@"10.0")){
        AudioServicesPlaySystemSoundWithCompletion(soundId, ^{
            AudioServicesDisposeSystemSoundID(soundId);
        });
    }
    else{
        AudioServicesPlaySystemSound(soundId);
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

// BLUETOOTH METHODS BEGIN HERE:

#pragma mark - CBCentralManagerDelegate

// method called whenever you have successfully connected to the BLE peripheral
//- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
//{
//    [peripheral setDelegate:self];
//    [peripheral discoverServices:nil];
//    
//    self.connected = peripheral.state == CBPeripheralStateConnected;
//    [self setConnectionButton];
//
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
- (void) cancelCurrentNotifications {
    if (self.dateSet != nil) {
        NSLog(@"We had a date set, cancelling all notifications.");
        [self scheduleLocalNotification:self.dateSet];
    }
}
//}
//
//// CBCentralManagerDelegate - This is called with the CBPeripheral class as its main input parameter. This contains most of the information there is to know about a BLE peripheral.
//- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
//{
//    
//    if ([peripheral.identifier.UUIDString isEqualToString:self.address]) {
//        [self.centralManager stopScan];
//        self.hm10Peripheral = peripheral;
//        peripheral.delegate = self;
//        [self.centralManager connectPeripheral:peripheral options:nil];
//    }
//    else{
//        NSLog(@"Found a device with non-wakeable name");
//    }
//}
//
//- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(nonnull CBPeripheral *)peripheral error:(nullable NSError *)error{
//    if ([peripheral.identifier.UUIDString isEqualToString:self.address]) {
//        
//        self.connected = peripheral.state == CBPeripheralStateConnected;
//        [self setConnectionButton];
//        NSLog(@"Disconnected from our wakeable.");
//        
//        [self turnOffWakeableNotifications];
//        
//        if (self.dateSet != nil) {
//            NSLog(@"We had a date set, cancelling all notifications.");
//            [self scheduleLocalNotification:self.dateSet];
//        }
//        [self.centralManager connectPeripheral:peripheral options:nil];
//    }
//    
//}
//
//// method called whenever the device state changes.
//- (void)centralManagerDidUpdateState:(CBCentralManager *)central
//{
//    // Determine the state of the peripheral
//    if ([central state] == CBCentralManagerStatePoweredOff) {
//        NSLog(@"CoreBluetooth BLE hardware is powered off");
//        self.bluetoothCapable = NO;
//        self.connected = NO;
//        [self setConnectionButton];
//    }
//    else if ([central state] == CBCentralManagerStatePoweredOn) {
//        NSLog(@"CoreBluetooth BLE hardware is powered on and ready");
//        self.bluetoothCapable = YES;
//        if (self.address != nil && self.hm10Peripheral == nil) {
//            NSLog(@"We have an address stored, but we're not connected. Let's scan for our device.");
//            NSArray *services = @[ [CBUUID UUIDWithString:@"FFE0"] ];
//            [self.centralManager scanForPeripheralsWithServices:services options:nil];
//        }
//    }
//    else if ([central state] == CBCentralManagerStateUnauthorized) {
//        NSLog(@"CoreBluetooth BLE state is unauthorized");
//    }
//    else if ([central state] == CBCentralManagerStateUnknown) {
//        NSLog(@"CoreBluetooth BLE state is unknown");
//    }
//    else if ([central state] == CBCentralManagerStateUnsupported) {
//        NSLog(@"CoreBluetooth BLE hardware is unsupported on this platform");
//    }
//}
//
//#pragma mark - CBPeripheralDelegate
//
//// CBPeripheralDelegate - Invoked when you discover the peripheral's available services.
//- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
//{
//    for (CBService *service in peripheral.services) {
//        [peripheral discoverCharacteristics:nil forService:service];
//    }
//}
//
//// Invoked when you discover the characteristics of a specified service.
//- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
//{
//    
//    // Retrieve Device Information Services for the Manufacturer Name
//    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"FFE0"]])  {
//        for (CBCharacteristic *aChar in service.characteristics)
//        {
//            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:@"FFE1"]]) {
//                [self.hm10Peripheral readValueForCharacteristic:aChar];
//                [self.hm10Peripheral setNotifyValue:YES forCharacteristic:aChar];
//            }
//        }
//    }
//}
//
//// Invoked when you retrieve a specified characteristic's value, or when the peripheral device notifies your app that the characteristic's value has changed.
//- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
//{
//    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"FFE1"]]) {
//        [self getStringPackage:characteristic];
//    }
//}
//
//// Instance method to get the string from the device
//- (void) getStringPackage:(CBCharacteristic *)characteristic
//{
//    NSString *packageContents = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
//    NSLog(@"%@", [NSString stringWithFormat:@"Data from arduino: %@", packageContents]);
//    
//    if ([packageContents containsString:@"1"]) {
//        if (self.dateSet != nil) {
//            NSDate * currentDate = [NSDate dateWithTimeIntervalSinceNow:0];
//            NSDate * result = [currentDate laterDate:self.dateSet];
//            if (result == currentDate ) {
//                NSLog(@"Got a one. cancelling all notifications");
//                [self turnOffWakeableNotifications];
//                self.dateSet = nil;
//                [self setAlarmButton:NO];
//            }
//            else{
//                NSLog(@"Got a one, but it's before the scheduled alarm. Don't cancel anything just yet.");
//            }
//        }
//        else{
//            // Turn off notifications in case of a kill/reconnect situation..
//            [self turnOffWakeableNotifications];
//            NSLog(@"Got a one, but there's no date set. Likely just connecting");
//        }
//    }
//    else{
//        NSLog(@"Package did not contain a one: %@", packageContents);
//    }
//    return;
//}

// Non-BT helper functions

- (void)addPeripheralViewController:(SetupViewController *)controller foundPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"This was returned from Setup %@", peripheral.name);
    [BluetoothManager setConnected:(peripheral.state == CBPeripheralStateConnected)];
    [self setConnectionButton];
    [BluetoothManager connect];
//    NSArray *services = @[ [CBUUID UUIDWithString:@"FFE0"] ];
//    [self.centralManager scanForPeripheralsWithServices:services options:nil];
}

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
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Time to wake up!"
                                                                   message:self.notificationText
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    [alert addAction:defaultAction];
    
    [self presentViewController:alert animated:YES completion:nil];
    
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

- (void) alertNoDevices {
    [BluetoothManager stopScan];
    if (!self.foundDevice) {
        UIAlertController* alert = [UIAlertController
                                    alertControllerWithTitle:@"Oh dear"
                                    message: [NSString stringWithFormat:@"It looks like Wakeable had a problem connecting. Try moving closer to the device and confirm that the bluetooth on your phone is on."]
                                    preferredStyle:UIAlertControllerStyleAlert];
        
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:NO completion:^{}];
        
        
    }
    
    self.foundDevice = NO;
}

@end
