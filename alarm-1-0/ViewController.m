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

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSURL *soundURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"alarm_beep" ofType:@"wav"]];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundURL, &soundId);
    
//    BLUETOOTH SETUP
    
    
    self.hm10Peripheral = nil;
    // Scan for all available CoreBluetooth LE devices
//    NSLog( [CBUUID UUIDWithString:@"FFE0"]);
//    NSArray *services = @[[CBUUID UUIDWithString:HM10_SERVICE_UUID]];
    CBCentralManager *centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    self.centralManager = centralManager;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)SwitchToggled:(id)sender {
    if(self.SwitchOutlet.on){
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.timeZone = [NSTimeZone defaultTimeZone];
        dateFormatter.timeStyle = NSDateFormatterShortStyle;
        dateFormatter.dateStyle = NSDateFormatterShortStyle;
        
        self.dateSet = dateTimePicker.date;
        
        
        for (int i=0; i<20; i++){
            NSDate *modDate = [dateTimePicker.date dateByAddingTimeInterval:3*(i+1)];
            
            NSString *dtString = [dateFormatter stringFromDate:dateTimePicker.date];
            
            [self scheduleLocalNotification:modDate];
            if(i == 0){
                NSLog(@"The switch is on:  %@", dtString);
            }
        }
        
    }
    else{
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
        NSLog(@"The switch is off");
    }
}

- (void) scheduleLocalNotification: (NSDate *) fireDate{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.fireDate = fireDate;
//    
    notification.alertBody = @"Wake up, nerdasauras";
    notification.soundName = @"alarm_beep.wav";
//    notification.alertAction = @"Turn it off";
    
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    
    
}

- (IBAction)PlaySound:(id)sender {
    
    AudioServicesPlaySystemSound(soundId);
//    [[UIApplication sharedApplication] cancelAllLocalNotifications];
//    self.SwitchOutlet.on = FALSE;
    
    
}


- (void) turnOffWakeableNotifications {
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    self.dateSet = nil;
    AudioServicesDisposeSystemSoundID(soundId);
    self.SwitchOutlet.on = FALSE;
}

// BLUETOOTH METHODS BEGIN HERE:

#pragma mark - CBCentralManagerDelegate

// method called whenever you have successfully connected to the BLE peripheral
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
//    TODO: verify this is actually HM-10
    if ([peripheral.name.lowercaseString isEqualToString:@"wakeable"]) {
        
        [peripheral setDelegate:self];
        [peripheral discoverServices:nil];
        self.connected = [NSString stringWithFormat:@"Connected: %@", peripheral.state == CBPeripheralStateConnected ? @"YES" : @"NO"];
        NSLog(@"%@", self.connected);
        
        if (self.connected) {
            if (self.dateSet != nil) {
                for (int i=0; i<20; i++){
                    NSDate *modDate = [self.dateSet dateByAddingTimeInterval:3*(i+1)];
                    
                    [self scheduleLocalNotification:modDate];
                    if(i == 0){
                        NSLog(@"Reconnected and reset the notifications");
                    }
                }
                self.SwitchOutlet.on = YES;
            }
        }
    }
}

// CBCentralManagerDelegate - This is called with the CBPeripheral class as its main input parameter. This contains most of the information there is to know about a BLE peripheral.
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSString *localName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
    if ([localName length] > 0) {
        NSLog(@"Found the HM 10!: %@", localName);
        [self.centralManager stopScan];
        self.hm10Peripheral = peripheral;
        peripheral.delegate = self;
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
    else{
        NSLog(@"Found device with name of length less than 0");
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(nonnull CBPeripheral *)peripheral error:(nullable NSError *)error{
    NSLog(@"Disconnected from peripheral: %@",  peripheral.name);
    NSLog(@"Looking for peripheral: %@", self.hm10Peripheral.name);
    if ([peripheral.name isEqualToString:self.hm10Peripheral.name]) {
        
        self.connected = [NSString stringWithFormat:@"Connected: %@", peripheral.state == CBPeripheralStateConnected ? @"YES" : @"NO"];
        NSLog(@"Disconnected. Cancelling all notifications. For now.. %@", self.connected);
        
//        UIUserNotificationSettings *notifySettings=[[UIApplication sharedApplication] currentUserNotificationSettings];
//        if ((notifySettings.types & UIUserNotificationTypeAlert)!=0) {
//            UILocalNotification *notification=[UILocalNotification new];
//            notification.alertBody=@"Disconnected from wakeable device. Reconnecting.";
//            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
//        }
        
        [self turnOffWakeableNotifications];
        
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
        NSArray *services = @[ [CBUUID UUIDWithString:@"FFE0"] ];
        [self.centralManager scanForPeripheralsWithServices:services options:nil];
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
        NSDate * currentDate = [NSDate dateWithTimeIntervalSinceNow:0];
        
        NSDate * result = [currentDate laterDate:self.dateSet];
        if (result == currentDate ) {
            NSLog(@"Got a one. cancelling all notifications");
            [self turnOffWakeableNotifications];
        }
        else{
            NSLog(@"Got a one, but it's before the scheduled alarm. Don't cancel anything just yet.");
        }
    }
    else{
        NSLog(manufacturerName);
    }
    return;
}


@end
