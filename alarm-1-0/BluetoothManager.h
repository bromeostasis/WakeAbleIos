//
//  BluetoothManager.h
//  Wakeable
//
//  Created by Evan Snyder on 7/31/17.
//  Copyright © 2017 Evan Snyder. All rights reserved.
//

@import CoreBluetooth;
@import QuartzCore;

#ifndef BluetoothManager_h
#define BluetoothManager_h

@interface BluetoothManager : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate>

+ (void) connect;
+ (BOOL) isConnected;
+ (void) setConnected:(BOOL) connectedValue;
+ (BOOL) isBluetoothCapable;
+ (BOOL) hasPeripheral;
+ (void) stopScan;
+ (void) connectToPeripheral:(CBPeripheral *) peripheral;
+ (CBPeripheral *) getPeripheral;

@end

#endif /* BluetoothManager_h */
