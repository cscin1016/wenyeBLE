//
//  BLEConnectVC.m
//  ADMBL
//
//  Created by 陈双超 on 14/12/7.
//  Copyright (c) 2014年 com.aidian. All rights reserved.
//

#import "BLEConnectVC.h"


#define IS_IOS_8 ([[[UIDevice currentDevice] systemVersion] doubleValue]>=8.0)?YES:NO
const double pi = 3.14159265358979324;
// 定义经纬度结构体
typedef struct {
    double lng;
    double lat;
} Location;

inline Location
LocationMake(double lng, double lat) {
    Location loc; loc.lng = lng, loc.lat = lat; return loc;
}

@interface BLEConnectVC (){
    NSMutableArray *dataArray;
    UIBarButtonItem *AllButton;
    BOOL canSendMes;//判断是否找到了发送信息的特性
    
    CLLocationManager *myLM;
   
    NSMutableString* subTitleLocation;
}

@end

@implementation BLEConnectVC
@synthesize peripheralOpration;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"连接蓝牙";
    subTitleLocation=[[NSMutableString alloc]init];
    
    
    dataArray=[[NSMutableArray alloc] init];
    
    AllButton=[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"search"] style:UIBarButtonItemStylePlain target:self action:@selector(seachAction)];
    AllButton.tintColor=[UIColor blueColor];
    self.navigationItem.rightBarButtonItem = AllButton;
    
    
    self.cbCentralMgr = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    self.cbCentralMgr.delegate=self;
    
    myLM = [[CLLocationManager alloc] init];
    myLM.delegate = self;
   
    
    //判断用户定位服务是否开启
    if ([CLLocationManager locationServicesEnabled]) {
        [myLM startUpdatingLocation];//开始定位用户的位置
        myLM.distanceFilter=kCLDistanceFilterNone;//每隔多少米定位一次（这里的设置为任何的移动）
        //设置定位的精准度，一般精准度越高，越耗电（这里设置为精准度最高的，适用于导航应用）
        myLM.desiredAccuracy=kCLLocationAccuracyBestForNavigation;
        NSLog(@"启动定位");
        if(IS_IOS_8){
            [myLM requestAlwaysAuthorization];
        }
        
    }else{
        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:nil message:@"没有开启定位服务" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
    }
    
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(sendBLEData:) name:@"BLEDataNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(sendFindMeBLEData:) name:@"FindMeNotification" object:nil];
}



-(void)seachAction{
    NSLog(@"搜索");
    for (int i=0; i<[dataArray count]; i++) {
        NSLog(@"i:%d",i);
        CBPeripheral * peripheral=[dataArray objectAtIndex:i];
        if (peripheral.state!=0) {
            [self.cbCentralMgr cancelPeripheralConnection:peripheral];
        }
    }
    NSLog(@"释放完毕");
    self.cbCentralMgr.delegate=self;
    [self.cbCentralMgr stopScan];
    
    [dataArray removeAllObjects];
    [_bleTableView reloadData];
    NSDictionary * dic = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],CBCentralManagerScanOptionAllowDuplicatesKey, nil];
    [self.cbCentralMgr scanForPeripheralsWithServices:nil options:dic];
}

-(void)sendBLEData:(NSNotification*) notification{
    NSLog(@"发送数据");
    
    if (peripheralOpration.state==2)
    {
        NSLog(@"收到通知：%@",[[notification userInfo] objectForKey:@"tempData"]);
        //保留找到的特性6,实现跟定时器相关
        [self sendDatawithperipheral:self.peripheralOpration characteristic:TRANSFER_CHARACTERISTIC_UUID_FFE3 data:[[notification userInfo] objectForKey:@"tempData"] showAlert:YES];
    }
}
//根据蓝牙对象和特性发送数据
-(BOOL)sendDatawithperipheral:(CBPeripheral *)peripheral characteristic:(NSString*)characteristicStr data:(NSData*)data showAlert:(BOOL)isShow{
    NSLog(@"sendDatawithperipheral：%@",peripheral.services);
    for(int i=0;i<peripheral.services.count;i++){
        for (CBCharacteristic *characteristic in [[peripheral.services objectAtIndex:i] characteristics])
        {
            NSLog(@"%@",[characteristic.UUID UUIDString]);
            //保留找到的特性6
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:characteristicStr]])
            {
                NSLog(@"FFE3找到");
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
            }
        }
    }
    return canSendMes;
}

-(void)sendFindMeBLEData:(NSNotification*) notification{
    if (peripheralOpration.state==2)
    {
        NSLog(@"收到FindMe通知：%@",self.peripheralOpration.services);
        for(int i=0;i<self.peripheralOpration.services.count;i++){
            for (CBCharacteristic *characteristic in [[self.peripheralOpration.services objectAtIndex:i] characteristics])
            {
                NSLog(@"%d:%@",i,[characteristic.UUID UUIDString]);
                //保留找到的特性6
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID_2A06]])
                {
                    NSLog(@"FFA5找到");
                    [self.peripheralOpration setNotifyValue:YES forCharacteristic:characteristic];
                    [self.peripheralOpration writeValue:[[notification userInfo] objectForKey:@"tempData"] forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
                }
            }
        }
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return dataArray.count;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (((CBPeripheral*)[dataArray objectAtIndex:indexPath.row]).state==2) {
       
    }else{
        int countConnected=0;
        for (int i=0; i<[dataArray count]; i++)
        {
            CBPeripheral * peripheral = [dataArray objectAtIndex:i];
            if (peripheral.state!=0)
            {
                countConnected++;
            }
        }
        peripheralOpration=(CBPeripheral*)[dataArray objectAtIndex:indexPath.row];
        [self.cbCentralMgr connectPeripheral:((CBPeripheral*)[dataArray objectAtIndex:indexPath.row]) options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
    }
    [self.bleTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * cellIdentifier = @"cell";
    UITableViewCell * cell=[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    NSString *State=nil;
    if (((CBPeripheral*)[dataArray objectAtIndex:indexPath.row]).state==0) {
        State=@"disconnected";
        cell.textLabel.textColor=[UIColor blackColor];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }else if (((CBPeripheral*)[dataArray objectAtIndex:indexPath.row]).state==1){
        State=@"Connecting";
        cell.textLabel.textColor=[UIColor blackColor];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }else{
        State=@"Connected";
        cell.textLabel.textColor=[UIColor blueColor];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@  %@", ((CBPeripheral*)[dataArray objectAtIndex:indexPath.row]).name ,State];
    cell.detailTextLabel.text = [((CBPeripheral*)[dataArray objectAtIndex:indexPath.row]).identifier UUIDString];
    return cell;
}
#pragma mark - Navigation
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    [self addLog:@"------------centralManagerDidUpdateState---------------"];
    switch (central.state) {
        case CBCentralManagerStateUnknown:
        breakcenterMgrStateCentralManagerStateResetting:
            [self addLog:@"State Resetting"];
            break;
        case CBCentralManagerStateUnsupported:
            [self addLog:@"State Unsupported"];
            break;
        case CBCentralManagerStateUnauthorized:
            [self addLog:@"State Unauthorized"];
            break;
        case CBCentralManagerStatePoweredOff:
            [self addLog:@"State PoweredOff"];
            break;
        case CBCentralManagerStatePoweredOn:
            [self addLog:@"State PoweredOn"];
            [self seachAction];
            break;
        default:
            [self addLog:@"State  未知"];
            break;
    }
}

-(void)addLog:(NSString*)log{
    NSLog(@"%@",log);
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    [self addLog:@"------------didDiscoverPeripheral---------------"];
    if([dataArray containsObject:peripheral]){
        return;
    }
    NSLog(@"能发现设备:%@",RSSI);
    [self addLog:peripheral.name];
    
    [dataArray addObject:peripheral];
    [_bleTableView reloadData];
}
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [self addLog:@"-------------didConnectPeripheral-----------------"];
    [_bleTableView reloadData];
    
    peripheral.delegate = self;
    [peripheral discoverServices:nil];
    
    [peripheral readRSSI];
    
    [myLM startUpdatingLocation];//开始定位用户的位置
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    [myLM stopUpdatingLocation];
    
    NSUserDefaults *MyUserDefault;
    MyUserDefault=[NSUserDefaults standardUserDefaults];
    [MyUserDefault setObject:subTitleLocation forKey:@"subTitleLocation"];
    NSDictionary *dic=[[NSDictionary alloc]initWithObjectsAndKeys:[NSString stringWithFormat:@"最后位置:%@",subTitleLocation],@"subTitleLocation",nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LocationNotification" object:nil userInfo:dic];
    
    [self addLog:@"-------------didDisconnectPeripheral-----------------"];
    UIAlertView *alert=[[UIAlertView alloc]initWithTitle:nil message:@"蓝牙连接断开，请重连！" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alert show];
   
    
    
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(NSError *)error
{
    [self addLog:@"-------------didDiscoverIncludedServicesForService-----------------"];
    [self addLog:peripheral.name];
    
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    [self addLog:@"-------------didDiscoverCharacteristicsForService-----------------"];
    
    for (CBCharacteristic * characteristic in service.characteristics) {
        [peripheral setNotifyValue:YES forCharacteristic:characteristic];
    }
}
//peripheral:didUpdateValueForCharacteristic:error
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    NSString *str=[[NSString alloc]initWithData:characteristic.value encoding:NSASCIIStringEncoding];
    NSLog(@"特性的值：%@，UUID：%@",str,[characteristic.UUID UUIDString]);
    if ([[characteristic.UUID UUIDString] isEqualToString:@"2A19"]) {
        NSString *str1=[NSString stringWithFormat:@"%@",characteristic.value];
        NSString *tempStr=[str1 substringWithRange:NSMakeRange(1, str1.length-2)];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangeBatteryNotification" object:[NSNumber numberWithInt:[self TotexHex1:tempStr]]];
    }else if ([[characteristic.UUID UUIDString] isEqualToString:@"FFE1"]){
        NSString *str1=[NSString stringWithFormat:@"%@",characteristic.value];
        NSString *tempStr=[str1 substringWithRange:NSMakeRange(1, str1.length-2)];
        int hexResult=[self TotexHex1:tempStr];
        if (hexResult) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"TakePhotoNotification" object:[NSNumber numberWithInt:[self TotexHex1:tempStr]]];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    [self addLog:@"-------------didWriteValueForCharacteristic-----------------"];
    [self addLog:peripheral.name];
    if ([[[UIDevice currentDevice] systemVersion] floatValue]>=7.0)
    {
        [self addLog:[NSString stringWithFormat:@"%@ ",characteristic]];//ios7时，这里的value并不是写进去的值
    }else{
        [self addLog:[NSString stringWithFormat:@"%@ value:%@",characteristic,characteristic.value]];
    }
    NSLog(@"写数据委托完毕");
}
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    [self addLog:@"-------------didUpdateNotificationStateForCharacteristic-----------------"];
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"aaaaa");
    for (CBService* service in peripheral.services){
        [peripheral discoverCharacteristics:nil forService:service];
        [peripheral discoverIncludedServices:nil forService:service];
    }
}
- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"%@",peripheral.RSSI);
}
- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error{
    NSLog(@"RSSI:%@",RSSI);
    NSDictionary *dic=[[NSDictionary alloc]initWithObjectsAndKeys:RSSI,@"RSSI",nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateRSSINotification" object:nil userInfo:dic];
}
//十六进制数转十进制数
-(int)TotexHex1:(NSString*)tmpid
{
    int int_ch;  ///两位16进制数转化后的10进制数
    unichar hex_char1 = [tmpid characterAtIndex:0]; ////两位16进制数中的第一位(高位*16)
    int int_ch1;
    if(hex_char1 >= '0' && hex_char1 <='9')
        int_ch1 = (hex_char1-48)*16;   //// 0 的Ascll - 48
    else if(hex_char1 >= 'A' && hex_char1 <='F')
        int_ch1 = (hex_char1-55)*16; //// A 的Ascll - 65
    else
        int_ch1 = (hex_char1-87)*16; //// a 的Ascll - 97
    unichar hex_char2 = [tmpid characterAtIndex:1]; ///两位16进制数中的第二位(低位)
    int int_ch2;
    if(hex_char2 >= '0' && hex_char2 <='9')
        int_ch2 = (hex_char2-48); //// 0 的Ascll - 48
    else if(hex_char2 >= 'A' && hex_char2 <='F')
        int_ch2 = (hex_char2-55); //// A 的Ascll - 65
    else
        int_ch2 = (hex_char2-87); //// a 的Ascll - 97
    int_ch = int_ch1+int_ch2;
    
    return int_ch;
}


#pragma mark - 定位功能


- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    CLLocation *loc = [locations firstObject];
    CLLocationCoordinate2D curCoords = loc.coordinate;
    NSLog(@"%f,%f",curCoords.longitude,curCoords.latitude);
    Location WGS_84={curCoords.longitude,curCoords.latitude};
    Location GCJ_02=transformFromWGSToGCJ(WGS_84);
//    Location BD_09=bd_decrypt(GCJ_02);

    CLLocation *newLocation = [[CLLocation alloc]initWithLatitude:GCJ_02.lat longitude:GCJ_02.lng];
    
    //根据经纬度解析成位置
    CLGeocoder *geocoder=[[CLGeocoder alloc]init];
    [geocoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray *placemark,NSError *error)
     {
         CLPlacemark *mark=[placemark objectAtIndex:0];
         NSString* subTitle=[NSString stringWithFormat:@"%@",mark.name];//获取subtitle的信息
         NSLog(@"subTitle:%@",subTitle);
         subTitleLocation=[NSMutableString stringWithString:subTitle];
         NSDictionary *dic=[[NSDictionary alloc]initWithObjectsAndKeys:[NSString stringWithFormat:@"当前位置:%@",subTitle],@"subTitleLocation",nil];
         [[NSNotificationCenter defaultCenter] postNotificationName:@"LocationNotification" object:nil userInfo:dic];
     } ];
}


//iPhone的GPS定位(CLLocationManager)获得的经纬坐标是基于WGS-84坐标系（世界标准），Google地图使用的是GCJ-02坐标系（中国特色的火星坐标系），这就是为什么获得的经纬坐标在google地图上会发生偏移。我项目需求是使用百度Place API，百度的经纬坐标在GCJ-02的基础上再做了次加密，就是DB-09坐标系。
//  WGS-84 到 GCJ-02 的转换
const double a = 6378245.0;
const double ee = 0.00669342162296594323;
///
///  WGS-84 到 GCJ-02 的转换
///
Location transformFromWGSToGCJ(Location wgLoc)
{
    Location mgLoc;
    if (outOfChina(wgLoc.lat, wgLoc.lng))
    {
        mgLoc = wgLoc;
        return mgLoc;
    }
    double dLat = transformLat(wgLoc.lng - 105.0, wgLoc.lat - 35.0);
    double dLon = transformLon(wgLoc.lng - 105.0, wgLoc.lat - 35.0);
    double radLat = wgLoc.lat / 180.0 * pi;
    double magic = sin(radLat);
    magic = 1 - ee * magic * magic;
    double sqrtMagic = sqrt(magic);
    dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * pi);
    dLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * pi);
    mgLoc.lat = wgLoc.lat + dLat;
    mgLoc.lng = wgLoc.lng + dLon;
    
    return mgLoc;
}

bool outOfChina(double lat, double lon)
{
    if (lon < 72.004 || lon > 137.8347)
        return true;
    if (lat < 0.8293 || lat > 55.8271)
        return true;
    return false;
}

double transformLat(double x, double y)
{
    double ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(fabs(x));
    ret += (20.0 * sin(6.0 * x * pi) + 20.0 *sin(2.0 * x * pi)) * 2.0 / 3.0;
    ret += (20.0 * sin(y * pi) + 40.0 * sin(y / 3.0 * pi)) * 2.0 / 3.0;
    ret += (160.0 * sin(y / 12.0 * pi) + 320 * sin(y * pi / 30.0)) * 2.0 / 3.0;
    return ret;
}

double transformLon(double x, double y)
{
    double ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(fabs(x));
    ret += (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0;
    ret += (20.0 * sin(x * pi) + 40.0 * sin(x / 3.0 * pi)) * 2.0 / 3.0;
    ret += (150.0 * sin(x / 12.0 * pi) + 300.0 * sin(x / 30.0 * pi)) * 2.0 / 3.0;
    return ret;
}


///
///  GCJ-02 坐标转换成 BD-09 坐标
///

const double x_pi = 3.14159265358979324 * 3000.0 / 180.0;
Location bd_encrypt(Location gcLoc)
{
    double x = gcLoc.lng, y = gcLoc.lat;
    double z = sqrt(x * x + y * y) + 0.00002 * sin(y * x_pi);
    double theta = atan2(y, x) + 0.000003 * cos(x * x_pi);
    return LocationMake(z * cos(theta) + 0.0065, z * sin(theta) + 0.006);
}

///
///   BD-09 坐标转换成 GCJ-02坐标
///
///
Location bd_decrypt(Location bdLoc)
{
    double x = bdLoc.lng - 0.0065, y = bdLoc.lat - 0.006;
    double z = sqrt(x * x + y * y) - 0.00002 * sin(y * x_pi);
    double theta = atan2(y, x) - 0.000003 * cos(x * x_pi);
    return LocationMake(z * cos(theta), z * sin(theta));
}
@end
