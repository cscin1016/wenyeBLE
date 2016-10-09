//
//  ViewController.m
//  wenyeBLE
//
//  Created by 陈双超 on 15/1/4.
//  Copyright (c) 2015年 陈双超. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

#define IS_IOS_7 ([[[UIDevice currentDevice] systemVersion] doubleValue]>=7.0)?YES:NO
#define IS_IOS_8 ([[[UIDevice currentDevice] systemVersion] doubleValue]>=8.0)?YES:NO

#import "ViewController.h"
#import "BLEConnectVC.h"

@interface ViewController (){
    BLEConnectVC *bleConnectViewContrller;
    AVAudioPlayer *MyAudioPlayer;
    AVAudioSession *MusicSession;
    
    __block int timeout;
    dispatch_queue_t queue;
    dispatch_source_t _timer;
    
    NSInteger FlashNumber;//闪烁的类型
    BOOL ShowMusic;//是否音乐提醒,默认YES
    BOOL ShowShake;//是否震动提醒,默认YES
    NSInteger RSSIAlertLevel;//0代表近，1代表一般，2代表远
    
    NSUserDefaults *MyUserDefault;
    int barnaryNumber;
    
    CGRect originJDImageRect;
    CGRect originJDFlagRect;
    
    BOOL isTouchIn;
}

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    bleConnectViewContrller=[[UIStoryboard storyboardWithName:@"Main" bundle:nil]  instantiateViewControllerWithIdentifier:@"bleConnectVC"];
    
    //后台播放音频设置
    MusicSession = [AVAudioSession sharedInstance];
    [MusicSession setActive:YES error:nil];
    [MusicSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    queue= dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    timeout=3600; //倒计时时间
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(updateRSSINumber:) name:@"updateRSSINotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(updateBatteryAction:) name:@"ChangeBatteryNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(TakePhotoAction:) name:@"TakePhotoNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(LocationAction:) name:@"LocationNotification" object:nil];
    
    MyUserDefault=[NSUserDefaults standardUserDefaults];
    
    _LocationLabel.numberOfLines=0;
    NSString *tempLOcationStr=[MyUserDefault objectForKey:@"subTitleLocation"];
    if (tempLOcationStr.length==0) {
        _LocationLabel.text=[NSString stringWithFormat:@"最后位置:未能获取到位置!"];
    }else{
        _LocationLabel.text=[NSString stringWithFormat:@"最后位置:%@",tempLOcationStr];
    }
    
    
    FlashNumber=[MyUserDefault integerForKey:@"FlashNumber"];
    [self sendFlashAction];
    
    ShowMusic=YES;
    ShowShake=YES;
    
    isTouchIn=NO;
    RSSIAlertLevel=1;
    
    [_SiglaStrengthImageView setImage:[UIImage imageNamed:@"sign02"]];
    
    _bateryLabel=[[UIView alloc]init];
    self.bateryLabel.backgroundColor=[UIColor colorWithRed:6/255.0 green:65/255.0 blue:170/255.0 alpha:1];
    [self.view addSubview:_bateryLabel];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangeBatteryNotification" object:[NSNumber numberWithInt:0]];
    
    
    
}
-(void)viewDidAppear:(BOOL)animated{
    originJDImageRect=_JingDuImage.frame;
    
    if (!_JDFlagImage) {
        _JDFlagImage=[[UIImageView alloc]initWithFrame:CGRectMake(originJDImageRect.origin.x+55, originJDImageRect.origin.y-29, 26, 49)];
        [_JDFlagImage setImage:[UIImage imageNamed:@"general.png"]];
        [self.view addSubview:_JDFlagImage];
        originJDFlagRect=_JDFlagImage.frame;
    }
    
}

-(void)viewWillAppear:(BOOL)animated{
//    self.navigationController.navigationBar.hidden=YES;
     if (bleConnectViewContrller.peripheralOpration.state==2) {
         NSLog(@"开启");
         [self ShowRSSI];
     }
}

//显示相册库进行选择图片
- (IBAction)AddFlashAction:(UIButton *)sender {
    FlashNumber++;
    if (FlashNumber>4) {
        FlashNumber=4;
    }
    [self sendFlashAction];
}

- (IBAction)ReduceFlashAction:(id)sender {
    FlashNumber--;
    if (FlashNumber<0) {
        FlashNumber=0;
    }
    [self sendFlashAction];
}
-(void)sendFlashAction{
    
    char strcommand[1]={'0'};
    if (FlashNumber==0) {
        strcommand[0] =0x00;
    }else if(FlashNumber==1){
        strcommand[0] =0x31;
    }else if (FlashNumber==2){
        strcommand[0] =0x21;
    }else if (FlashNumber==3){
        strcommand[0] =0x11;
    }else {
        strcommand[0] =0x01;
    }
    NSData *cmdData = [NSData dataWithBytes:strcommand length:1];
    NSDictionary *dic=[[NSDictionary alloc]initWithObjectsAndKeys:cmdData,@"tempData",nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BLEDataNotification" object:nil userInfo:dic];
    [MyUserDefault setInteger:FlashNumber forKey:@"FlashNumber"];
    
    
    if (FlashNumber>3) {
        [_ImageFour setImage:[UIImage imageNamed:@"normayellow.png"]];
    }else{
        [_ImageFour setImage:[UIImage imageNamed:@"normal.png"]];
    }
    if (FlashNumber>2) {
        [_ImageThree setImage:[UIImage imageNamed:@"normayellow.png"]];
    }else{
        [_ImageThree setImage:[UIImage imageNamed:@"normal.png"]];
    }
    if (FlashNumber>1) {
        [_ImageTwo setImage:[UIImage imageNamed:@"normayellow.png"]];
    }else{
        [_ImageTwo setImage:[UIImage imageNamed:@"normal.png"]];
    }
    if (FlashNumber>0) {
        [_ImageOne setImage:[UIImage imageNamed:@"normayellow.png"]];
    }else{
        [_ImageOne setImage:[UIImage imageNamed:@"normal.png"]];
    }
    
    
    
}


-(void)showImagePicker
{
    _imagePicker = [[UIImagePickerController alloc] init];
    _imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    NSArray *temp_MediaTypes = [UIImagePickerController availableMediaTypesForSourceType:_imagePicker.sourceType];
    _imagePicker.mediaTypes = temp_MediaTypes;
    _imagePicker.delegate = self;
    [self presentViewController:_imagePicker animated:YES completion:nil];
    //调用系统照片库
}

- (IBAction)TakePhotoStartAction:(id)sender {
    [self showImagePicker];
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    CGPoint touched=[[[touches allObjects] objectAtIndex:0] locationInView:self.view];
    [self tochAction:touched event:0];
}
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    CGPoint touched=[[[touches allObjects] objectAtIndex:0] locationInView:self.view];
    [self tochAction:touched event:1];
    
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    CGPoint touched=[[[touches allObjects] objectAtIndex:0] locationInView:self.view];
    [self tochAction:touched event:2];
}
-(void)tochAction:(CGPoint)touched event:(int)status{
    CGRect mCenterRect=CGRectMake(originJDImageRect.origin.x-10, originJDImageRect.origin.y-originJDFlagRect.size.height+7, originJDImageRect.origin.x+20, originJDFlagRect.size.height+20);
    
    if (CGRectContainsPoint (mCenterRect, touched)) {
        if (status==0) {
            isTouchIn=YES;
        }
    }
    if (status==1&&isTouchIn) {
        _JDFlagImage.frame=CGRectMake(touched.x, originJDFlagRect.origin.y,originJDFlagRect.size.width, originJDFlagRect.size.height);
    }
    
    if (status==2&&isTouchIn){
        if (touched.x<34+originJDImageRect.origin.x) {
            NSLog(@"完结一");
            _JDFlagImage.frame=CGRectMake(originJDImageRect.origin.x-5, originJDFlagRect.origin.y, originJDFlagRect.size.width, originJDFlagRect.size.height);
            [_JDFlagImage setImage:[UIImage imageNamed:@"near.png"]];
            RSSIAlertLevel=0;
        }else if (touched.x<103+originJDImageRect.origin.x){
            NSLog(@"完结二");
            _JDFlagImage.frame=CGRectMake(originJDImageRect.origin.x+55, originJDFlagRect.origin.y, originJDFlagRect.size.width, originJDFlagRect.size.height);
            [_JDFlagImage setImage:[UIImage imageNamed:@"general.png"]];
            RSSIAlertLevel=1;
        }else{
            NSLog(@"完结三");
            _JDFlagImage.frame=CGRectMake(originJDImageRect.origin.x+116, originJDFlagRect.origin.y,originJDFlagRect.size.width, originJDFlagRect.size.height);
            [_JDFlagImage setImage:[UIImage imageNamed:@"far.png"]];
            RSSIAlertLevel=2;
        }
        isTouchIn=NO;
    }
}

- (IBAction)MusicAlertAction:(id)sender {
    ShowMusic=!ShowMusic;
    if (ShowMusic) {
        [_MusicAlertButton setBackgroundImage:[UIImage imageNamed:@"music_hover"] forState:UIControlStateNormal];
    }else{
        [_MusicAlertButton setBackgroundImage:[UIImage imageNamed:@"music"] forState:UIControlStateNormal];
    }
}

- (IBAction)shakeAlertAction:(id)sender {
    ShowShake=!ShowShake;
    if (ShowShake) {
        [_ShakeAlertButton setBackgroundImage:[UIImage imageNamed:@"phone_hover"] forState:UIControlStateNormal];
    }else{
        [_ShakeAlertButton setBackgroundImage:[UIImage imageNamed:@"phone"] forState:UIControlStateNormal];
    }
}

- (IBAction)ShowConnectionAction:(UIBarButtonItem *)sender {
    [self.navigationController pushViewController:bleConnectViewContrller animated:YES];
}

- (IBAction)FindMeKeyAction:(id)sender {
    char strcommand[1]={'0'};
    strcommand[0] =0x02;
    NSData *cmdData = [NSData dataWithBytes:strcommand length:1];
    NSDictionary *dic=[[NSDictionary alloc]initWithObjectsAndKeys:cmdData,@"tempData",nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FindMeNotification" object:nil userInfo:dic];
}

-(void)playMusicAction{
    NSString *string = [[NSBundle mainBundle] pathForResource:@"voice_01" ofType:@"wav"];
    //把音频文件转换成url格式
    NSURL *url = [NSURL fileURLWithPath:string];
    //初始化音频类 并且添加播放文件
    MyAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    //MyAudioPlayer.volume = 1;//设置初始音量大小
    //MyAudioPlayer.numberOfLoops = -1;//设置音乐播放次数  -1为一直循环
    [MyAudioPlayer prepareToPlay];//预播放
    [MyAudioPlayer play];
}
-(void)ShakeAction{
    AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
}


#pragma - mark delegate methods
//选择完成之后
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo{
    NSLog(@"editingInfo:%@",editingInfo);
    //改背景图为选择的图片
    [self dismissModalViewControllerAnimated:YES];
}


#pragma - mark delegate methods
-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    //取消选择图片，取消拍照
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void) imagePickerController: (UIImagePickerController *) picker didFinishPickingMediaWithInfo: (NSDictionary *) info
{
    NSLog(@"拍照完毕");
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
     if ([mediaType isEqualToString:@"public.image"]){
         NSLog(@"保存图片") ;
         UIImage *originalImage = (UIImage *) [info objectForKey: UIImagePickerControllerOriginalImage];//得到照片
         UIImageWriteToSavedPhotosAlbum(originalImage, nil, nil, nil);//图片存入相册
     }else if([mediaType isEqualToString:@"public.movie"]){
         NSLog(@"保存视频");
         NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
         ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
         [library writeVideoAtPathToSavedPhotosAlbum:videoURL
                                     completionBlock:^(NSURL *assetURL, NSError *error) {
                                         if (error) {
                                             NSLog(@"Save video fail:%@",error);
                                         } else {
                                             NSLog(@"Save video succeed.");
                                         }
                                     }];
     }
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)ShowRSSI{
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,queue);
    dispatch_source_set_timer(_timer,dispatch_walltime(NULL, 0),1.0*NSEC_PER_SEC, 0); //每秒执行
    dispatch_source_set_event_handler(_timer, ^{
        if(timeout<=0){ //倒计时结束，关闭
            dispatch_source_cancel(_timer);
            dispatch_async(dispatch_get_main_queue(), ^{
                //设置界面的按钮显示 根据自己需求设置
//                NSLog(@"--");
            });
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (bleConnectViewContrller.peripheralOpration.state==2) {
                    if (IS_IOS_8) {
                        [bleConnectViewContrller.peripheralOpration readRSSI];
                    }else{
//                        NSLog(@"%@",[NSString stringWithFormat:@"%@",[bleConnectViewContrller.peripheralOpration RSSI]]);
                    }
                }else{
//                    NSLog(@"--");
                }
            });
            timeout--;
        }
    });
    dispatch_resume(_timer);
}

-(void)updateRSSINumber:(NSNotification*) notification{
    
    
    
    if( [[[notification userInfo] objectForKey:@"RSSI"] intValue]>-55){
        [_SiglaStrengthImageView setImage:[UIImage imageNamed:@"sign.png"]];
    }else if ([[[notification userInfo] objectForKey:@"RSSI"] intValue]>-65){
        [_SiglaStrengthImageView setImage:[UIImage imageNamed:@"sign06"]];
    }else if ([[[notification userInfo] objectForKey:@"RSSI"] intValue]>-75){
        [_SiglaStrengthImageView setImage:[UIImage imageNamed:@"sign05"]];
    }else if ([[[notification userInfo] objectForKey:@"RSSI"] intValue]>-80){
        [_SiglaStrengthImageView setImage:[UIImage imageNamed:@"sign04"]];
    }else if ([[[notification userInfo] objectForKey:@"RSSI"] intValue]>-90){
        [_SiglaStrengthImageView setImage:[UIImage imageNamed:@"sign03"]];
    }else{
        [_SiglaStrengthImageView setImage:[UIImage imageNamed:@"sign02.png"]];
    }
    
    
    if (RSSIAlertLevel==0) {
        if( [[[notification userInfo] objectForKey:@"RSSI"] intValue]<-55){
            [self MyalertAction];
        }
    }else if(RSSIAlertLevel==1){
        if( [[[notification userInfo] objectForKey:@"RSSI"] intValue]<-70){
            [self MyalertAction];
        }
    }else if(RSSIAlertLevel==2){
        if( [[[notification userInfo] objectForKey:@"RSSI"] intValue]<-100){
            [self MyalertAction];
        }
    }
}


-(void)MyalertAction{
    if(ShowMusic){
        [self playMusicAction];
    }
    if (ShowShake) {
        [self ShakeAction];
    }
}

-(void)updateBatteryAction:(NSNotification*) notification{
    self.batteryLabel.text=[NSString stringWithFormat:@"%@%%",[notification object] ];
    barnaryNumber=[[notification object] intValue];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.bateryLabel.frame=CGRectMake(_BatteryImage.frame.origin.x+3, _BatteryImage.frame.origin.y+3, 0.31*barnaryNumber, 10);
    });
    
}

-(void)TakePhotoAction:(NSNotification*) notification{
    
    if ([[notification object] intValue]==2) {
        NSLog(@"照相");
        [_imagePicker takePicture];
    }else{
        NSLog(@"_imagePicker.startVideoCapture:%d",_imagePicker.startVideoCapture);
        [_imagePicker startVideoCapture];
    }
}

-(void)LocationAction:(NSNotification*) notification{
    _LocationLabel.numberOfLines=0;
    _LocationLabel.text=[[notification userInfo] objectForKey:@"subTitleLocation"];
}

@end
