//
//  KViewController.m
//  KFrameworkDemo
//
//  Created by corptest on 14-3-6.
//  Copyright (c) 2014年 corp. All rights reserved.
//

#import "KWVJBViewController.h"
#import "KWebViewJavascriptBridge.h"
#import "KCategories.h"
#import "Base64.h"
#import <Reachability/Reachability.h>

@interface KWVJBViewController () <UIWebViewDelegate>

@property (strong, nonatomic) IBOutlet UIWebView *webView;

@property (strong, nonatomic) KWebViewJavascriptBridge *bridge;

@property (strong, nonatomic) Reachability *reach;

@end

@implementation KWVJBViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle].resourcePath stringByAppendingFormat:@"/res/index.html"]]]];
    
    [KWebViewJavascriptBridge enableLogging];
    [[NSNotificationCenter defaultCenter] addObserverForName:kReachabilityChangedNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      if (note.object == nil || ![note.object isKindOfClass:[Reachability class]]) {
                                                          return ;
                                                      }
                                                      NSLog(@"%d", ((Reachability *)note.object).currentReachabilityStatus);
                                                  }];
    self.reach = [Reachability reachabilityForInternetConnection];
    [self.reach startNotifier];
    
    self.bridge = [KWebViewJavascriptBridge bridgeWithWebView:self.webView webViewDelegate:self handler:^(id data, KWVJBResponseCallback callback) {
        
    }];
    
    [self.bridge registerHandler:@"getImage" handler:^(id data, KWVJBResponseCallback callback) {
        NSLog(@"ocCallback called with data:%@", data);
        NSData *imgData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle].resourcePath stringByAppendingFormat:@"/res/html5.jpg"]];
        callback(@{@"data" : [NSString stringWithFormat:@"data:image/jpeg;base64,%@", [imgData base64EncodedString]]});
    }];
    
    // 网络状态
    [self.bridge registerHandler:@"app.network_status" handler:^(id data, KWVJBResponseCallback callback) {
        callback(@{@"status":@([[Reachability
                                 reachabilityForInternetConnection]
                                currentReachabilityStatus])});
    }];
}

- (void) reachabilityChanged:(NSNotification *)note
{
    if (note.object == nil || ![note.object isKindOfClass:[Reachability class]]) {
        return ;
    }
    NSLog(@"%d", ((Reachability *)note.object).currentReachabilityStatus);
}

- (IBAction) getUserId:(id)sender
{
    [self.bridge callHandler:@"getUserId111" data:@{@"session_id" : @"1231312323"} responseCallback:^(id responseData) {
        NSLog(@"getUserId response data : %@", responseData);
    }];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"webView:shouldStartLoadWithRequest:navigationType:");
    return YES;
}
- (void)webViewDidStartLoad:(UIWebView *)webView
{
    NSLog(@"webViewDidStartLoad");
}
- (void)webViewDidFinishLoad:(UIWebView *)webView;
{
    NSLog(@"webViewDidFinishLoad");
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error;
{
    NSLog(@"didFailLoadWithError");
}

@end
