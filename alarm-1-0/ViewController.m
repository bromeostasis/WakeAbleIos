//
//  ViewController.m
//  alarm-1-0
//
//  Created by Evan Snyder on 4/3/16.
//  Copyright (c) 2016 Evan Snyder. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

#define SYSTEM_VERSION_GREATERTHAN_OR_EQUALTO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

- (id) initWithNibName:(NSString *)aNibName bundle:(NSBundle *)aBundle {
    self = [super initWithNibName:aNibName bundle:aBundle]; // The UIViewController's version of init
    if (self) {
        _bluetoothCapable = NO;
        _notificationCount = 0;
        _hm10Peripheral = nil;
    }
    return self;
}

- (void)viewDidLayoutSubviews {
    if (self.hm10Peripheral == nil ) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        SetupViewController *setupController = [sb instantiateViewControllerWithIdentifier:@"SetupViewController"];
        setupController.delegate = self;
        [self presentViewController:setupController animated:YES completion:NULL];
    }
    
}

- (void)viewDidLoad {
    
    
    [self.ConnectButton.layer setBorderWidth:2.0];
    [self.ConnectButton.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    [self.ConnectButton.layer setCornerRadius:3.0];
    [self.ConnectButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0)];
    
    [self.AlarmSetButton.layer setBorderWidth:2.0];
    [self.AlarmSetButton.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    [self.AlarmSetButton.layer setCornerRadius:3.0];
    [self.AlarmSetButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0)];
    self.AlarmSetButton.titleLabel.numberOfLines = 1;
    self.AlarmSetButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.AlarmSetButton.titleLabel.lineBreakMode = NSLineBreakByClipping;
    
    
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSURL *soundURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"alarm_beep" ofType:@"wav"]];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundURL, &soundId);
    self.connected = NO;
    dateTimePicker.datePickerMode = UIDatePickerModeTime;
    
//    BLUETOOTH SETUP
    
    
    CBCentralManager *centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    self.centralManager = centralManager;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)Connect:(id)sender {
    NSLog(@"Connection string hititttt");
    
    if (self.bluetoothCapable) {
        NSArray *services = @[ [CBUUID UUIDWithString:@"FFE0"] ];
        [self.centralManager scanForPeripheralsWithServices:services options:nil];
    }
    
}

- (IBAction)SetAlarm:(id)sender {
    if(!self.alarmSet){
        if (self.connected) {
        
            self.dateSet = dateTimePicker.date;
            
            NSCalendar *theCalendar = [NSCalendar currentCalendar];
            self.dateSet = [theCalendar dateBySettingUnit:NSCalendarUnitSecond value:0 ofDate:self.dateSet options:0];
            NSDateComponents *minuteComponent = [[NSDateComponents alloc] init];
            minuteComponent.minute = -1;
            self.dateSet = [theCalendar dateByAddingComponents:minuteComponent toDate:self.dateSet options:0];
            NSDate * currentDate = [NSDate dateWithTimeIntervalSinceNow:0];
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
            NSLog(@"The switch is on:  %@", dtString);
            
                
            [self scheduleLocalNotification:self.dateSet forMessage:@"Wake up time!" howMany:20];
            
            [self setAlarmButton:YES];
        }
        else{
            NSLog(@"not connected. No alarm for you! Maybe..??!");
            [self setAlarmButton:NO];
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
    [mailComposer setSubject:@"Crash Log"];
    // Set up recipients
    NSArray *toRecipients = [NSArray arrayWithObject:@"evan.snyder92@gmail.com"];
    [mailComposer setToRecipients:toRecipients];
    // Fill out the email body text
    NSString *emailBody = @"Crash Log";
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

- (void) scheduleLocalNotification: (NSDate *) fireDate forMessage:(NSString*)message howMany:(int)numberOfNotifications{
    
    if (SYSTEM_VERSION_GREATERTHAN_OR_EQUALTO(@"10.0")) {
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
//        content.title = [NSString localizedUserNotificationStringForKey:@"Elon said:" arguments:nil];
        content.body = [NSString localizedUserNotificationStringForKey:message
                                                             arguments:nil];
        content.sound = [UNNotificationSound soundNamed:@"alarm_beep.wav"];
        
        for (int i=0; i<numberOfNotifications; i++){
            self.notificationCount = self.notificationCount + 1;
            
            NSDate *modDate = [fireDate dateByAddingTimeInterval:5*i];
            NSCalendar *gregorian = [[NSCalendar alloc]
                                     initWithCalendarIdentifier:NSGregorianCalendar];
            NSDateComponents *dateComponents = [gregorian components:(NSSecondCalendarUnit | NSMinuteCalendarUnit |
                                                                      NSHourCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit) fromDate:modDate];
            UNCalendarNotificationTrigger *trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:dateComponents repeats:NO];
            UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:[NSString stringWithFormat:@"notification%d", self.notificationCount]
                                                                                  content:content trigger:trigger];
            UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
            [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                if (!error) {
                    NSLog(@"Added notification number %d!", i);
                }
            }];

        }
        
    }
    else {
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.alertBody = message;
        //    notification.repeatInterval = NSSecondCalendarUnit;
        notification.soundName = @"alarm_beep.wav";
        //    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
        
        for (int i=0; i<numberOfNotifications; i++){
            
            NSDate *modDate = [fireDate dateByAddingTimeInterval:3*(i+1)];
            notification.fireDate = modDate;
            [[UIApplication sharedApplication] scheduleLocalNotification:notification];
            
        }
    }
    
    
}

- (IBAction)PlaySound:(id)sender {
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
    if(self.connected){
        [self.ConnectButton setEnabled:NO];
        [self.ConnectButton setTitle:@"WakeAble is connected" forState:UIControlStateDisabled];
    }
    else{
        [self.ConnectButton setEnabled:YES];
        [self.ConnectButton setTitle:@"Connect to WakeAble" forState:UIControlStateNormal];
        
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

// BLUETOOTH METHODS BEGIN HERE:

#pragma mark - CBCentralManagerDelegate

// method called whenever you have successfully connected to the BLE peripheral
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [peripheral setDelegate:self];
    [peripheral discoverServices:nil];
    
    self.connected = peripheral.state == CBPeripheralStateConnected;
    NSLog(@"Connected: %hhd", self.connected);
    [self setConnectionButton];
    
    if (self.connected) {
        NSLog(@"Date set: %@", self.dateSet);
        if (self.dateSet != nil) {
            NSDate * currentDate = [NSDate dateWithTimeIntervalSinceNow:0];
            
            NSDate * result = [currentDate earlierDate:self.dateSet];
            if (result == currentDate ) {
                NSLog(@"Reconnected and reset the notifications");
                [self turnOffWakeableNotifications];
                [self scheduleLocalNotification:self.dateSet forMessage:@"Time to wake up!" howMany:20];
            }
            else{
                NSLog(@"Failsafe notifications already went off. Let's just reset");
                self.dateSet = nil;
                [self setAlarmButton:NO];
            }
        }
    }
}

- (void) handleWakeableConnection:(CBPeripheral *) peripheral{
    self.hm10Peripheral = peripheral;
    peripheral.delegate = self;
    [self.centralManager connectPeripheral:peripheral options:nil];
}

// CBCentralManagerDelegate - This is called with the CBPeripheral class as its main input parameter. This contains most of the information there is to know about a BLE peripheral.
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSString *localName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
    if ([localName length] > 0) {
        NSLog(@"Found the HM 10!: %@", localName);
        if ([[localName lowercaseString] isEqualToString:@"wakeable"]) {
            [self.centralManager stopScan];
            
            UIAlertController* alert = [UIAlertController
                                        alertControllerWithTitle:@"My Alert"
                                        message: [NSString stringWithFormat:@"Found a WakeAble with identifier %@, want to connect?", [peripheral.identifier UUIDString]]
                                        preferredStyle:UIAlertControllerStyleAlert];
            
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                      [self handleWakeableConnection:peripheral];
                                                                  }];
            [alert addAction:defaultAction];
            
            UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"No thanks" style:UIAlertActionStyleCancel
                                                                  handler:^(UIAlertAction * action) {}];
            [alert addAction:cancelAction];
            
            UIViewController *vc = [[[UIApplication sharedApplication] keyWindow] rootViewController];
            
            [vc presentViewController:alert animated:NO completion:^{}];
        }
        else{
            NSLog(@"Found a device with non-wakeable name");
        }
    }
    else{
        NSLog(@"Found device with name of length less than 0");
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(nonnull CBPeripheral *)peripheral error:(nullable NSError *)error{
    NSLog(@"Disconnected from peripheral: %@",  peripheral.name);
    if ([peripheral.name isEqualToString:self.hm10Peripheral.name]) {
        
        self.connected = peripheral.state == CBPeripheralStateConnected;
        [self setConnectionButton];
        NSLog(@"Disconnected. Cancelling all notifications. For now.. %hhd", self.connected);
        
        [self turnOffWakeableNotifications];
        
        if (self.dateSet != nil) {
            [self scheduleLocalNotification:self.dateSet forMessage:@"You're disconnected from your WakeAble device. We'll shut off the alarm for you after three minutes!" howMany:5];
        }
        
        NSLog(@"Looking for peripheral: %@", self.hm10Peripheral.name);
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
    
}

// method called whenever the device state changes.
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    // Determine the state of the peripheral
    if ([central state] == CBCentralManagerStatePoweredOff) {
        NSLog(@"CoreBluetooth BLE hardware is powered off");
    }
    else if ([central state] == CBCentralManagerStatePoweredOn) {
        NSLog(@"CoreBluetooth BLE hardware is powered on and ready");
        self.bluetoothCapable = YES;
    }
    else if ([central state] == CBCentralManagerStateUnauthorized) {
        NSLog(@"CoreBluetooth BLE state is unauthorized");
    }
    else if ([central state] == CBCentralManagerStateUnknown) {
        NSLog(@"CoreBluetooth BLE state is unknown");
    }
    else if ([central state] == CBCentralManagerStateUnsupported) {
        NSLog(@"CoreBluetooth BLE hardware is unsupported on this platform");
    }
}

#pragma mark - CBPeripheralDelegate

// CBPeripheralDelegate - Invoked when you discover the peripheral's available services.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    for (CBService *service in peripheral.services) {
        NSLog(@"Discovered service: %@", service.UUID);
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

// Invoked when you discover the characteristics of a specified service.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    
    // Retrieve Device Information Services for the Manufacturer Name
    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"FFE0"]])  { // 4
        for (CBCharacteristic *aChar in service.characteristics)
        {
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:@"FFE1"]]) {
                [self.hm10Peripheral readValueForCharacteristic:aChar];
                NSLog(@"Found the serial characteristic");
                [self.hm10Peripheral setNotifyValue:YES forCharacteristic:aChar];
            }
        }
    }
}

// Invoked when you retrieve a specified characteristic's value, or when the peripheral device notifies your app that the characteristic's value has changed.
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"FFE1"]]) {
        [self getStringPackage:characteristic];
    }
}

// Instance method to get the string from the device
- (void) getStringPackage:(CBCharacteristic *)characteristic
{
    NSString *manufacturerName = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];  // 1
    NSLog([NSString stringWithFormat:@"Manufacturer: %@", manufacturerName]);    // 2
    
    if ([manufacturerName containsString:@"1"]) {
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
            NSLog(@"Got a one, but there's no date set. Likely just connecting");
        }
    }
    else{
        NSLog(manufacturerName);
    }
    return;
}

- (void)addPeripheralViewController:(SetupViewController *)controller foundPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"This was returned from Setup %@", peripheral.name);
    self.hm10Peripheral = peripheral;
}

@end
