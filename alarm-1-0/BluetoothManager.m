//
//  BluetoothManager.m
//  Wakeable
//
//  Created by Evan Snyder on 7/31/17.
//  Copyright © 2017 Evan Snyder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BluetoothManager.h"
#import "ViewController.h"

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
        CBCentralManager *newCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        centralManager = newCentralManager;
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
    return hm10Peripheral != nil;
}

+ (void) stopScan
{
    [centralManager stopScan];
}
+ (CBPeripheral *) getPeripheral
{
    return hm10Peripheral;
}
+ (void) connectToPeripheral:(CBPeripheral *) peripheral
{
    hm10Peripheral = peripheral;
    peripheral.delegate = self;
    [centralManager connectPeripheral:hm10Peripheral options:nil];
}

// Peripheral methods

// method called whenever you have successfully connected to the BLE peripheral
+ (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    connected = peripheral.state == CBPeripheralStateConnected;
//    [peripheral setDelegate:self];
    [peripheral discoverServices:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ConnectionChanged" object:nil];
    
    if (address == nil) {
        NSLog(@"Connected to the HM10. Redirect to main view.");
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:peripheral.identifier.UUIDString forKey:@"address"];
        [defaults synchronize];
        
        address = peripheral.identifier.UUIDString;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ConnectedWakeable" object:nil];
        
    }
}

// CBCentralManagerDelegate - This is called with the CBPeripheral class as its main input parameter. This contains most of the information there is to know about a BLE peripheral.
+ (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *storedAddress = [defaults objectForKey:@"address"];
    if (storedAddress == nil) {
        NSString *deviceName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
        if ([deviceName length] > 0) {
            NSLog(@"Found the HM 10!: %@", deviceName);
            if ([[deviceName lowercaseString] isEqualToString:@"wakeable"]) {
                [centralManager stopScan];
                hm10Peripheral = peripheral;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"FoundWakeable" object:nil];
            }
            else{
                NSLog(@"Found a device with non-wakeable name: %@", deviceName);
                return;
            }
        }
    }
    else{
        if ([peripheral.identifier.UUIDString isEqualToString:storedAddress]) {
            [centralManager stopScan];
            
            [self connectToPeripheral:peripheral];
            hm10Peripheral = peripheral;
            peripheral.delegate = self;
            [centralManager connectPeripheral:peripheral options:nil];
        }
        else{
            NSLog(@"Found a device with non-wakeable name");
            return;
        }
    }
    
}

+ (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(nonnull CBPeripheral *)peripheral error:(nullable NSError *)error{
    if ([peripheral.identifier.UUIDString isEqualToString:address]) {
        
        connected = peripheral.state == CBPeripheralStateConnected;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ConnectionChanged" object:nil];
        NSLog(@"Disconnected from our wakeable.");
        [centralManager connectPeripheral:peripheral options:nil];
    }
    
}

// method called whenever the device state changes.
+ (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    // Determine the state of the peripheral
    if ([central state] == CBCentralManagerStatePoweredOff) {
        NSLog(@"CoreBluetooth BLE hardware is powered off");
        bluetoothCapable = NO;
        connected = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ConnectionChanged" object:nil];

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
+ (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

// Invoked when you discover the characteristics of a specified service.
+ (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
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
+ (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"FFE1"]]) {
        [self getStringPackage:characteristic];
    }
}

// Instance method to get the string from the device
+ (void) getStringPackage:(CBCharacteristic *)characteristic
{
    NSString *packageContents = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    NSLog(@"%@", [NSString stringWithFormat:@"Data from arduino: %@", packageContents]);

    if ([packageContents containsString:@"1"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ReceivedOne" object:nil];
    }
    else{
        NSLog(@"Package did not contain a one: %@", packageContents);
    }
}

+ (ViewController *) getViewControllerInstance:(NSString *) viewName{
    // Is this really the way to do this?
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ViewController *viewController = [sb instantiateViewControllerWithIdentifier:viewName];
    return viewController;
}
@end
