//
//  BLEConnectVC.h
//  ADMBL
//
//  Created by 陈双超 on 14/12/7.
//  Copyright (c) 2014年 com.aidian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreBluetooth/CoreBluetooth.h"

#import "CoreLocation/CLLocationManagerDelegate.h"
#import <CoreLocation/CoreLocation.h>

#define TRANSFER_CHARACTERISTIC_UUID_FFE3    @"FFE3"
#define TRANSFER_CHARACTERISTIC_UUID_2A06    @"2A06"

@interface BLEConnectVC : UIViewController<CBCentralManagerDelegate,CBPeripheralDelegate,CLLocationManagerDelegate>

@property (strong,nonatomic) CBCentralManager * cbCentralMgr;
@property (strong,nonatomic) CBPeripheral *peripheralOpration;//一个灯时操作的蓝牙对象

@property (weak, nonatomic) IBOutlet UITableView *bleTableView;

@end
