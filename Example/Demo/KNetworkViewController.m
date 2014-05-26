//
//  KNetworkViewController.m
//  Demo
//
//  Created by corptest on 14-3-19.
//  Copyright (c) 2014年 corp. All rights reserved.
//

#import "KNetworkViewController.h"
#import "KUserModel.h"
#import "KAPI.h"

@interface KNetworkViewController () <KModelObserver>

@property (nonatomic, strong) KUserModel *userModel;

@end

@implementation KNetworkViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [self.userModel removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBar.translucent = NO;
    
//    NSString *json = @"{\"name\":\"张三\",\"age\":23}";
//    NSDictionary *dic = [json objectFromJSONString];
//    TEST_USER *u = [TEST_USER objectFromDictionary:dic];
    
    self.userModel = [KUserModel sharedInstance];
    [self.userModel addObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)startConnection:(id)sender
{
    [self.userModel signin:@"dzchang" :@"111111"];
}

- (IBAction)doUpload:(id)sender
{
    NSString *filePath = [[NSBundle mainBundle].resourcePath stringByAppendingFormat:@"/res/html5.jpg"];
    [self.userModel upload:filePath];
}

- (void) handleMessage:(KMessage *)message
{
    if ([message is:KAPI.user_signin]) {
        if (message.sending) {
            NSLog(@"KMainViewController sending");
//        } else {
//            NSLog(@"KMainViewController send over");
        }
        if (message.succeed) {
            NSLog(@"KMainViewController success");
        }
        if (message.failed) {
            NSLog(@"KMainViewController failed");
        }
    }
}


@end
