//
//  KWebViewJavascriptBridge.m
//  KFrameworkDemo
//
//  Created by corptest on 14-3-6.
//  Copyright (c) 2014年 corp. All rights reserved.
//

#import "KWebViewJavascriptBridge.h"
#import "KDefine.h"
#import "JSONKit.h"

#define kCustomProtocolScheme @"ccwvjbscheme"
#define kQueueHasMessage      @"__CCWVJB_QUEUE_MESSAGE__"

typedef NSDictionary KWVJBMessage;

#if __has_feature(objc_arc_weak)
#define WVJB_WEAK __weak
#else
#define WVJB_WEAK __unsafe_unretained
#endif

@interface KWebViewJavascriptBridge () <UIWebViewDelegate> {
    WVJB_WEAK UIWebView* _webView;
    WVJB_WEAK id _webViewDelegate;
    long _uniqueId;
    KWVJBHandler _messageHandler;
    
    NSUInteger _numRequestsLoading;
}

@property (nonatomic, strong) NSMutableArray *          startupMessageQueue;
@property (nonatomic, strong) NSMutableDictionary *     responseCallbacks;
@property (nonatomic, strong) NSMutableDictionary *     messageHandlers;

@end

@implementation KWebViewJavascriptBridge

- (void) dealloc
{
    _webView.delegate = nil;
    
    [self.startupMessageQueue removeAllObjects];
    self.startupMessageQueue = nil;
    [self.responseCallbacks removeAllObjects];
    self.responseCallbacks = nil;
    [self.messageHandlers removeAllObjects];
    self.messageHandlers = nil;
    
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}

static bool logging = false;
+ (void) enableLogging { logging = true; }

+ (instancetype) bridgeWithWebView:(UIWebView *)webView
                   webViewDelegate:(id <UIWebViewDelegate>)webViewDelegate
                           handler:(KWVJBHandler)handler
{
    KWebViewJavascriptBridge *bridge = [[KWebViewJavascriptBridge alloc] init];
    [bridge _platformSpecificSetup:webView webViewDelegate:webViewDelegate handler:handler];
    [bridge reset];
    return KAutoRelease(bridge);
}

- (void) registerHandler:(NSString*)handlerName
                 handler:(KWVJBHandler)handler
{
    _messageHandlers[handlerName] = [handler copy];
}

- (void) callHandler:(NSString*)handlerName
{
    [self callHandler:handlerName data:nil responseCallback:nil];
}

- (void) callHandler:(NSString*)handlerName
                data:(id)data
{
    [self callHandler:handlerName data:data responseCallback:nil];
}

- (void) callHandler:(NSString*)handlerName
                data:(id)data
    responseCallback:(KWVJBResponseCallback)responseCallback
{
    [self _sendData:data responseCallback:responseCallback handlerName:handlerName];
}

- (void) reset
{
    self.startupMessageQueue = [NSMutableArray array];
    self.responseCallbacks = [NSMutableDictionary dictionary];
    _uniqueId = 0;
}

#pragma mark -

- (void) _platformSpecificSetup:(UIWebView*)webView
                webViewDelegate:(id<UIWebViewDelegate>)webViewDelegate
                        handler:(KWVJBHandler)messageHandler
{
    _messageHandler = messageHandler;
    _webView = webView;
    _webViewDelegate = webViewDelegate;
    self.messageHandlers = [NSMutableDictionary dictionary];
    _webView.delegate = self;
}

- (void) _sendData:(id)data
  responseCallback:(KWVJBResponseCallback)responseCallback
       handlerName:(NSString*)handlerName
{
    NSMutableDictionary* message = [NSMutableDictionary dictionary];
    
    if (data) {
        message[@"data"] = data;
    }
    
    if (responseCallback) {
        NSString* callbackId = [NSString stringWithFormat:@"objc_cb_%ld", ++_uniqueId];
        _responseCallbacks[callbackId] = [responseCallback copy];
        message[@"callbackId"] = callbackId;
    }
    
    if (handlerName) {
        message[@"handlerName"] = handlerName;
    }
    [self _queueMessage:message];
}

- (void) _queueMessage:(KWVJBMessage*)message
{
    if (_startupMessageQueue) {
        [_startupMessageQueue addObject:message];
    } else {
        [self _dispatchMessage:message];
    }
}

- (void) _dispatchMessage:(KWVJBMessage*)message
{
    NSString *messageJSON = [self _serializeMessage:message];
    [self _log:@"SEND" json:messageJSON];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\f" withString:@"\\f"];
    
    NSString* javascriptCommand = [NSString stringWithFormat:@"wvjb._handleMessageFromObjC('%@');", messageJSON];
    if ([[NSThread currentThread] isMainThread]) {
        [_webView stringByEvaluatingJavaScriptFromString:javascriptCommand];
    } else {
        __strong typeof(_webView) strongWebView = _webView;
        dispatch_sync(dispatch_get_main_queue(), ^{
            [strongWebView stringByEvaluatingJavaScriptFromString:javascriptCommand];
        });
    }
}

- (void)_log:(NSString *)action json:(id)json {
    if (!logging) { return; }
    if (![json isKindOfClass:[NSString class]]) {
        json = [self _serializeMessage:json];
    }
    if ([json length] > 500) {
        NSLog(@"CCWVJB %@: %@ [...]", action, [json substringToIndex:500]);
    } else {
        NSLog(@"CCWVJB %@: %@", action, json);
    }
}

- (void) _flushMessageQueue
{
    NSString *messageQueueString = [_webView stringByEvaluatingJavaScriptFromString:@"wvjb._fetchQueue();"];
    
    id messages = [self _deserializeMessageJSON:messageQueueString];
    if (![messages isKindOfClass:[NSArray class]]) {
        NSLog(@"CCWVJB: WARNING: Invalid %@ received: %@", [messages class], messages);
        return;
    }
    for (KWVJBMessage* message in messages) {
        if (![message isKindOfClass:[KWVJBMessage class]]) {
            NSLog(@"CCWVJB: WARNING: Invalid %@ received: %@", [message class], message);
            continue;
        }
        [self _log:@"RCVD" json:message];
        
        NSString* responseId = message[@"responseId"];
        if (responseId) {
            KWVJBResponseCallback responseCallback = _responseCallbacks[responseId];
            responseCallback(message[@"responseData"]);
            [_responseCallbacks removeObjectForKey:responseId];
        } else {
            KWVJBResponseCallback responseCallback = NULL;
            NSString* callbackId = message[@"callbackId"];
            if (callbackId) {
                responseCallback = ^(id responseData) {
                    KWVJBMessage* msg = @{ @"responseId":callbackId, @"responseData":responseData };
                    [self _queueMessage:msg];
                };
            } else {
                responseCallback = ^(id ignoreResponseData) {
                    // Do nothing
                };
            }
            
            KWVJBHandler handler;
            if (message[@"handlerName"]) {
                handler = _messageHandlers[message[@"handlerName"]];
                if (!handler) {
                    NSLog(@"CCWVJB Warning: No handler for %@", message[@"handlerName"]);
                    // not Found HandlerName return {status:{code:404}}
                    return responseCallback(@{@"status" : @{@"code" : @(404)}});
                }
            } else {
                handler = _messageHandler;
            }
            
            @try {
                id data = message[@"data"];
                handler(data, responseCallback);
            }
            @catch (NSException *exception) {
                NSLog(@"CCWVJB: WARNING: objc handler threw. %@ %@", message, exception);
            }
        }
    }
}

- (NSString *) _serializeMessage:(KWVJBMessage *)message
{
    if (NSClassFromString(@"NSJSONSerialization")) {
        return KAutoRelease([[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:message
                                                                                              options:0
                                                                                                error:nil]
                                                     encoding:NSUTF8StringEncoding]);
    }
    
    return [message JSONString];
}

- (NSArray*) _deserializeMessageJSON:(NSString *)messageJSON
{
    if (NSClassFromString(@"NSJSONSerialization")) {
        return [NSJSONSerialization JSONObjectWithData:[messageJSON dataUsingEncoding:NSUTF8StringEncoding]
                                               options:NSJSONReadingAllowFragments
                                                 error:nil];
    }
    return [messageJSON objectFromJSONString];
}

#pragma mark - UIWebViewDelegate

- (void) webViewDidFinishLoad:(UIWebView *)webView
{
    if (webView != _webView) { return; }
    
    _numRequestsLoading--;
    
    if (_numRequestsLoading == 0 && ![[webView stringByEvaluatingJavaScriptFromString:@"typeof wvjb == 'object'"]
                                      isEqualToString:@"true"]) {
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *filePath = [bundle pathForResource:@"KWebViewJavascriptBridge.js"
                                              ofType:@"txt"];
        NSString *js = [NSString stringWithContentsOfFile:filePath
                                                 encoding:NSUTF8StringEncoding
                                                    error:nil];
        [webView stringByEvaluatingJavaScriptFromString:js];
    }
    
    if (_startupMessageQueue) {
        for (id queuedMessage in _startupMessageQueue) {
            [self _dispatchMessage:queuedMessage];
        }
        _startupMessageQueue = nil;
    }
    
    __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [strongDelegate webViewDidFinishLoad:webView];
    }
}

- (void) webView:(UIWebView *)webView
didFailLoadWithError:(NSError *)error
{
    if (webView != _webView) { return; }
    
    _numRequestsLoading--;
    
    __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [strongDelegate webView:webView
           didFailLoadWithError:error];
    }
}

- (BOOL) webView:(UIWebView *)webView
shouldStartLoadWithRequest:(NSURLRequest *)request
  navigationType:(UIWebViewNavigationType)navigationType
{
    if (webView != _webView) { return YES; }
    NSURL *url = [request URL];
    __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;
    if ([[url scheme] isEqualToString:kCustomProtocolScheme]) {
        if ([[url host] isEqualToString:kQueueHasMessage]) {
            [self _flushMessageQueue];
        } else {
            NSLog(@"CCWVJB: WARNING: Received unknown wvjb command %@://%@", kCustomProtocolScheme, [url path]);
        }
        return NO;
    } else if (strongDelegate && [strongDelegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
        return [strongDelegate webView:webView
            shouldStartLoadWithRequest:request
                        navigationType:navigationType];
    } else {
        return YES;
    }
}

- (void) webViewDidStartLoad:(UIWebView *)webView
{
    if (webView != _webView) { return; }
    
    _numRequestsLoading++;
    
    __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [strongDelegate webViewDidStartLoad:webView];
    }
}

@end
