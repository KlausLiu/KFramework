//
//  KWebViewJavascriptBridge.h
//  KFrameworkDemo
//
//  Created by corptest on 14-3-6.
//  Copyright (c) 2014年 corp. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^KWVJBResponseCallback)(id responseData);
typedef void(^KWVJBHandler)(id data, KWVJBResponseCallback callback);

@interface KWebViewJavascriptBridge : NSObject

+ (void)enableLogging;

+ (instancetype) bridgeWithWebView:(UIWebView *)webView
                   webViewDelegate:(id <UIWebViewDelegate>)webViewDelegate
                           handler:(KWVJBHandler)handler;

- (void) registerHandler:(NSString*)handlerName
                 handler:(KWVJBHandler)handler;

- (void) callHandler:(NSString*)handlerName;
- (void) callHandler:(NSString*)handlerName
                data:(id)data;

- (void) callHandler:(NSString*)handlerName
                data:(id)data
    responseCallback:(KWVJBResponseCallback)responseCallback;

- (void) reset;

@end
