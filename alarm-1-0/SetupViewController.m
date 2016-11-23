//
//  SetupViewController.m
//  alarm-1-0
//
//  Created by Evan Snyder on 11/8/16.
//  Copyright © 2016 Evan Snyder. All rights reserved.
//

#import "SetupViewController.h"

@interface SetupViewController ()

@end

@implementation SetupViewController

@synthesize delegate;

- (id) initWithNibName:(NSString *)aNibName bundle:(NSBundle *)aBundle {
    self = [super initWithNibName:aNibName bundle:aBundle]; // The UIViewController's version of init
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.OneLabel.layer setBorderWidth:5.0];
    [self.OneLabel.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    [self.OneLabel.layer setCornerRadius:3.0];
    
    [self.TwoLabel.layer setBorderWidth:5.0];
    [self.TwoLabel.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    [self.TwoLabel.layer setCornerRadius:3.0];
    
    [self.ConnectButton.layer setBorderWidth:2.0];
    [self.ConnectButton.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    [self.ConnectButton.layer setCornerRadius:3.0];
    [self.ConnectButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0)];
    self.ConnectButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.ConnectButton.titleLabel.lineBreakMode = NSLineBreakByClipping;
    
    //    BLUETOOTH SETUP
    
    
    CBCentralManager *centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    self.centralManager = centralManager;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)DismissView:(id)sender {
    self.foundDevice = NO;
    NSArray *services = @[ [CBUUID UUIDWithString:@"FFE0"] ];
    [self.centralManager scanForPeripheralsWithServices:services options:nil];
    
    NSLog(@"In dismissview: %hhd", self.foundDevice);
    [self performSelector:@selector(alertNoDevices) withObject:nil afterDelay:5.0];
    
}

- (void) alertNoDevices {
    NSLog(@"In alert devices: %hhd", self.foundDevice);
    if (!self.foundDevice) {
        [self.centralManager stopScan];
        UIAlertController* alert = [UIAlertController
                                    alertControllerWithTitle:@"Oh dear"
                                    message: [NSString stringWithFormat:@"It looks like wakeable had a problem connecting. try moving closer to the device and confirm that the bluetooth on your phone is on."]
                                    preferredStyle:UIAlertControllerStyleAlert];
        
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        [alert addAction:defaultAction];
        
        //            UIViewController *vc = [[[UIApplication sharedApplication] keyWindow] rootViewController];
        //
        [self presentViewController:alert animated:NO completion:^{}];
        
        
    }
    
    self.foundDevice = NO;
}

- (void) handleWakeableConnection:(CBPeripheral *) peripheral{
    self.hm10Peripheral = peripheral;
    [self.centralManager connectPeripheral:peripheral options:nil];
}

// BLUETOOTH METHODS BEGIN

#pragma mark - CBCentralManagerDelegate

// method called whenever you have successfully connected to the BLE peripheral
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
//    [peripheral setDelegate:self];
//    [peripheral discoverServices:nil];
    
    bool connected = peripheral.state == CBPeripheralStateConnected;
    NSLog(@"Connected: %hhd", connected);
    
    if (connected) {
        NSLog(@"Connected to the HM10. Maybe redirect here or pass some data letting ViewController know we're all set");
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:peripheral.identifier.UUIDString forKey:@"address"];
        [defaults synchronize];

        [self.delegate addPeripheralViewController:self foundPeripheral:self.hm10Peripheral];
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

// CBCentralManagerDelegate - This is called with the CBPeripheral class as its main input parameter. This contains most of the information there is to know about a BLE peripheral.
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSString *localName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
    if ([localName length] > 0) {
        NSLog(@"Found the HM 10!: %@", localName);
        if ([[localName lowercaseString] isEqualToString:@"wakeable"]) {
            [self.centralManager stopScan];
            self.foundDevice = YES;
            
            UIAlertController* alert = [UIAlertController
                                        alertControllerWithTitle:@"Wakeable Found"
                                        message: [NSString stringWithFormat:@"Found a Wakeable with identifier %@, want to connect?", [peripheral.identifier UUIDString]]
                                        preferredStyle:UIAlertControllerStyleAlert];
            
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                      [self handleWakeableConnection:peripheral];
                                                                  }];
            [alert addAction:defaultAction];
            
            UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"No thanks" style:UIAlertActionStyleCancel
                                                                 handler:^(UIAlertAction * action) {}];
            [alert addAction:cancelAction];
            
//            UIViewController *vc = [[[UIApplication sharedApplication] keyWindow] rootViewController];
//            
            [self presentViewController:alert animated:NO completion:^{}];
        }
        else{
            NSLog(@"Found a device with non-wakeable name");
        }
    }
    else{
        NSLog(@"Found device with name of length less than 0");
    }
}

// method called whenever the device state changes.
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    // TODO: Take action if anything but POWERED ON happens
    // Determine the state of the peripheral
    if ([central state] == CBCentralManagerStatePoweredOff) {
        NSLog(@"CoreBluetooth BLE hardware is powered off");
    }
    else if ([central state] == CBCentralManagerStatePoweredOn) {
        NSLog(@"CoreBluetooth BLE hardware is powered on and ready");
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

@end