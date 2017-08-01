//
//  BluetoothManager.m
//  Wakeable
//
//  Created by Evan Snyder on 7/31/17.
//  Copyright © 2017 Evan Snyder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BluetoothManager.h"

static CBCentralManager *centralManager;
static CBPeripheral *hm10Peripheral;
static BOOL connected;
static BOOL bluetoothCapable;
static NSString *address;
static NSString   *bodyData;
static NSString   *manufacturer;
static NSString   *hm10Device;

@implementation BluetoothManager

+ (void) connect
{
    [self createManagerIfNecessary];
    NSArray *services = @[ [CBUUID UUIDWithString:@"FFE0"] ];
    [centralManager scanForPeripheralsWithServices:services options:nil];
}

+ (void) createManagerIfNecessary
{
    if (centralManager == nil) {
        CBCentralManager *centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        centralManager = centralManager;
    }
}

+ (BOOL) isConnected
{
    return connected;
}
+ (void) setConnected:(BOOL) connectedValue
{
    connected = connectedValue;
}

+ (BOOL) isBluetoothCapable
{
    return bluetoothCapable || NO;
}

+ (BOOL) hasPeripheral
{
    return hm10Peripheral == nil;
}

+ (void) stopScan
{
    [centralManager stopScan];
}

// Peripheral methods

// method called whenever you have successfully connected to the BLE peripheral
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [peripheral setDelegate:self];
    [peripheral discoverServices:nil];
    
    connected = peripheral.state == CBPeripheralStateConnected;
    // VIEW CONTROLLER THAT STATUS HAS CHANGED
//    [self setConnectionButton];
//    
//    if (connected) {
//        foundDevice = YES;
//        NSLog(@"Connected to a peripheral. Current date set: %@", dateSet);
//        if (dateSet != nil) {
//            NSDate * currentDate = [NSDate dateWithTimeIntervalSinceNow:0];
//            
//            NSDate * result = [currentDate earlierDate:dateSet];
//            if (result == currentDate ) {
//                NSLog(@"We had an alarm set that hasn't gone off yet. Reschedule notifications now that we're connected.");
//                [self turnOffWakeableNotifications];
//                [self scheduleLocalNotification:dateSet];
//            }
//            else{
//                NSLog(@"Failsafe notifications already went off. Let's just reset");
//                dateSet = nil;
//                [self setAlarmButton:NO];
//            }
//        }
//    }
}

// CBCentralManagerDelegate - This is called with the CBPeripheral class as its main input parameter. This contains most of the information there is to know about a BLE peripheral.
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    
    if ([peripheral.identifier.UUIDString isEqualToString:address]) {
        [centralManager stopScan];
        hm10Peripheral = peripheral;
        peripheral.delegate = self;
        [centralManager connectPeripheral:peripheral options:nil];
    }
    else{
        NSLog(@"Found a device with non-wakeable name");
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(nonnull CBPeripheral *)peripheral error:(nullable NSError *)error{
    if ([peripheral.identifier.UUIDString isEqualToString:address]) {
        
        connected = peripheral.state == CBPeripheralStateConnected;
        
        // VIEW CONTROLLER CALL
//        [self setConnectionButton];
//        NSLog(@"Disconnected from our wakeable.");
//        
//        [self turnOffWakeableNotifications];
//        
//        if (dateSet != nil) {
//            NSLog(@"We had a date set, cancelling all notifications.");
//            [self scheduleLocalNotification:dateSet];
//        }
//        [centralManager connectPeripheral:peripheral options:nil];
    }
    
}

// method called whenever the device state changes.
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    // Determine the state of the peripheral
    if ([central state] == CBCentralManagerStatePoweredOff) {
        NSLog(@"CoreBluetooth BLE hardware is powered off");
        bluetoothCapable = NO;
        connected = NO;
        // SET BUTTON ON VIEW CONTROLLER
//        [self setConnectionButton];
    }
    else if ([central state] == CBCentralManagerStatePoweredOn) {
        NSLog(@"CoreBluetooth BLE hardware is powered on and ready");
        bluetoothCapable = YES;
        if (address != nil && hm10Peripheral == nil) {
            NSLog(@"We have an address stored, but we're not connected. Let's scan for our device.");
            NSArray *services = @[ [CBUUID UUIDWithString:@"FFE0"] ];
            [centralManager scanForPeripheralsWithServices:services options:nil];
        }
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
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

// Invoked when you discover the characteristics of a specified service.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    
    // Retrieve Device Information Services for the Manufacturer Name
    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"FFE0"]])  {
        for (CBCharacteristic *aChar in service.characteristics)
        {
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:@"FFE1"]]) {
                [hm10Peripheral readValueForCharacteristic:aChar];
                [hm10Peripheral setNotifyValue:YES forCharacteristic:aChar];
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
    NSString *packageContents = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    NSLog(@"%@", [NSString stringWithFormat:@"Data from arduino: %@", packageContents]);

    // VIEW CONTROLLER SHOULD KNOW ABOUT PACKAGE UPDATE
//    if ([packageContents containsString:@"1"]) {
//        if (dateSet != nil) {
//            NSDate * currentDate = [NSDate dateWithTimeIntervalSinceNow:0];
//            NSDate * result = [currentDate laterDate:dateSet];
//            if (result == currentDate ) {
//                NSLog(@"Got a one. cancelling all notifications");
//                [self turnOffWakeableNotifications];
//                dateSet = nil;
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
}
@end
