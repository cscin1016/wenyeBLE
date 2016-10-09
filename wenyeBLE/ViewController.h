//
//  ViewController.h
//  wenyeBLE
//
//  Created by 陈双超 on 15/1/4.
//  Copyright (c) 2015年 陈双超. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController<UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *LocationLabel;
@property (weak, nonatomic) IBOutlet UIImageView *SiglaStrengthImageView;
@property (weak, nonatomic) IBOutlet UIImageView *ImageOne;
@property (weak, nonatomic) IBOutlet UIImageView *ImageTwo;
@property (weak, nonatomic) IBOutlet UIImageView *ImageThree;
@property (weak, nonatomic) IBOutlet UIImageView *ImageFour;
@property (weak, nonatomic) IBOutlet UIImageView *BatteryImage;
@property (weak, nonatomic) IBOutlet UIButton *MusicAlertButton;
@property (weak, nonatomic) IBOutlet UIButton *ShakeAlertButton;
@property (weak, nonatomic) IBOutlet UIImageView *JingDuImage;
@property (weak, nonatomic) IBOutlet UILabel *batteryLabel;

@property (strong, nonatomic)  UIImagePickerController *imagePicker;
@property (strong, nonatomic)  UIView *bateryLabel;
@property (strong, nonatomic)  UIImageView *JDFlagImage;


- (void)showImagePicker;
- (IBAction)TakePhotoStartAction:(id)sender;
- (IBAction)AddFlashAction:(UIButton *)sender;
- (IBAction)ReduceFlashAction:(id)sender;
- (IBAction)MusicAlertAction:(id)sender;
- (IBAction)shakeAlertAction:(id)sender;
- (IBAction)ShowConnectionAction:(UIBarButtonItem *)sender;
- (IBAction)FindMeKeyAction:(id)sender;
@end

