//
//  ViewController.m
//  RecordScreen
//
//  Created by JustinYang on 2021/3/20.
//

#import "ViewController.h"
#import "BNRRecordScreen.h"
#import "SceneDelegate.h"
@interface ViewController ()
@property (nonatomic,strong) BNRRecordScreen *recordHandle;
@property (weak, nonatomic) IBOutlet UIButton *recordBtn;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    float y = UIScreen.mainScreen.bounds.size.height - 160;
    UIView * animatorView = [[UIView alloc] initWithFrame:CGRectMake(0, y, 60, 60)];
    
    [self.view addSubview:animatorView];
    animatorView.backgroundColor = UIColor.purpleColor;
   
    CABasicAnimation *positionA = [CABasicAnimation animationWithKeyPath:@"position"];
    
    positionA.fromValue = [NSValue valueWithCGPoint:CGPointMake(0, y)];
    positionA.toValue =  [NSValue valueWithCGPoint:CGPointMake(UIScreen.mainScreen.bounds.size.width, y)];
    positionA.duration = 3;
    positionA.repeatCount = MAXFLOAT;
    positionA.autoreverses = YES;
    [animatorView.layer addAnimation:positionA forKey:nil];
    
    self.recordHandle = [BNRRecordScreen new];
        

}
- (IBAction)startRecord:(id)sender {
    if (self.recordHandle.isRecording == NO) {
        SceneDelegate *delegate = (SceneDelegate *)([[[UIApplication sharedApplication] connectedScenes] allObjects].firstObject.delegate);
        [self.recordHandle startRecordWithFileName:@"test.mp4" recordView:delegate.window];
        [self.recordBtn setTitle:@"正在录制" forState:UIControlStateNormal];
    }
}
- (IBAction)saveAlbum:(id)sender {
    [self.recordHandle saveVideoToAlbum];
}
- (IBAction)saveRecord:(id)sender {
    if (self.recordHandle.isRecording == YES) {
        [self.recordHandle stopRecord];
        [self.recordBtn setTitle:@"开始录制" forState:UIControlStateNormal];
    }
}

@end
