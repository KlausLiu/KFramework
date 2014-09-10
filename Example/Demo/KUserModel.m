//
//  KUserModel.m
//  Demo
//
//  Created by klaus on 14-3-15.
//  Copyright (c) 2014年 corp. All rights reserved.
//

#import "KUserModel.h"
#import "KAPI.h"
#import "JSONKit.h"

@interface KUserModel()

@property (nonatomic, strong) USER *user;

@end

@implementation KUserModel

DEF_SINGLETEN(KUserModel)

- (void) signin:(NSString *)username
               :(NSString *)password
{
    [super message:KAPI.user_signin]
    .header(@"Content-Type", @"application/json")
    .input(@"PhoneNumber", @"15921755334");
}

- (void) upload:(NSString *)filePath
{
    [super message:KAPI.upload]
    .inputFile(@"uploadify", filePath, nil, nil)
    .input(@"productId", @"1")
    .input(@"type", @"1");
}

- (void) handleMessage:(KMessage *)message
{
    if ([message is:KAPI.user_signin]) {
        if (message.sending) {
            NSLog(@"KUserModel user_signin sending");
//        } else {
//            NSLog(@"KUserModel user_signin send over");
        }
        if (message.succeed) {
            NSDictionary *dic = [message.responseString objectFromJSONString];
            NSLog(@"user_signin:%@", dic);
            if ([[dic objectForPath:@"status.succeed"] intValue] == 1) {
                self.user = [USER objectFromDictionary:[dic objectForPath:@"data.user"]];
                NSLog(@"KUserModel user_signin success");
            } else {
                NSLog(@"KUserModel user_signin mark failed!!!");
                message.failed = YES;
                return;
            }
        }
        if (message.failed) {
            NSLog(@"KUserModel user_signin failed");
        }
    } else if ([message is:KAPI.upload]) {
        if (message.succeed) {
            NSLog(@"upload success!!, response:%@", message.responseString);
        } else if (message.failed) {
            NSLog(@"upload faild, error:%@", message.error);
        }
    }
}

@end
