//
//  ViewController.m
//  MultipeerConnectivity_Service
//
//  Created by 李翔 on 2017/3/29.
//  Copyright © 2017年 李翔. All rights reserved.
//

#import "ViewController.h"
#import "LxMultConnectManager.h"


@interface ViewController ()
/**
 *存放可连接的设备自定义id
 **/
@property (weak, nonatomic) IBOutlet UITextField *avaibleIDfiled;
/**
 *存放即将发送的文本信息
 **/
@property (weak, nonatomic) IBOutlet UITextField *textOutputFiele;
/**
 *显示获取信息
 **/
@property (weak, nonatomic) IBOutlet UITextView *textInputTextView;

/**
 *连接管理
 **/
@property (strong, nonatomic) LxMultConnectManager *connectManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.avaibleIDfiled.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"text"];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - clickAction
- (IBAction)clickStart:(id)sender {
    NSArray *peerIdsArray = [self.avaibleIDfiled.text componentsSeparatedByString:@","];
    __weak typeof(self) weakSelf = self;
    [self.connectManager setupPlatformType:(peerIdsArray.count > 1 ? MC_PlatformService : MC_PlatformClient) andPeerIDs:peerIdsArray block:^(NSString *receiveMessage, NSString *peerId) {
        NSString *str = [NSString stringWithFormat:@"%@%@:%@\n",weakSelf.textInputTextView.text,peerId,receiveMessage];
        dispatch_async(dispatch_get_main_queue(), ^{
           weakSelf.textInputTextView.text = str;
            [weakSelf.textInputTextView scrollRectToVisible:CGRectMake(0, weakSelf.textInputTextView.contentSize.height - weakSelf.textInputTextView.frame.size.height, weakSelf.textInputTextView.frame.size.width, weakSelf.textInputTextView.frame.size.height) animated:YES];
        });
        
    }];
}
- (IBAction)clickSend:(id)sender {
    [self.connectManager sendMessage:self.textOutputFiele.text];
}

#pragma mark - GetMethod
- (LxMultConnectManager *)connectManager
{
    [[NSUserDefaults standardUserDefaults] setObject:self.avaibleIDfiled.text forKey:@"text"];
    if (!_connectManager) {
        _connectManager = [[LxMultConnectManager alloc] init];
    }
    return _connectManager;
}

@end
