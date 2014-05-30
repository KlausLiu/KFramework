//
//  KBaseModel.m
//  KFramework
//
//  Created by corptest on 14-1-7.
//  Copyright (c) 2014年 corp. All rights reserved.
//

#import "KModel.h"
#import "KDefine.h"

@interface KModel()<KMessageStatusChangeDelegate>

@property (nonatomic, K_Strong) NSMutableArray *messageArray;

@property (nonatomic, assign) NSUInteger status_code;

@end

@implementation KModel {
    NSMutableArray *_observers;
}

- (void) dealloc
{
    [_observers removeAllObjects];
    K_Release(_observers);
    [self.messageArray removeAllObjects];
    K_Release(self.messageArray);
    
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}

- (id) init
{
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype) addObserver:(id)observer
{
    [_observers addObject:observer];
    return self;
}

- (instancetype) removeObserver:(id)observer
{
    if (!_observers) {
        [_observers removeObject:observer];
    }
    return self;
}

#pragma mark - message

- (KMessage *) message:(NSString *)url
{
    KMessage *message = [KMessage messageWithURLString:url];
    message.messageStatusChangeDelegate = self;
    [self.messageArray addObject:message];
    return [message send];
}

#pragma mark - private

- (void) initialize
{
    _observers = [[NSMutableArray alloc] init];
    [self addObserver:self];
    
    self.messageArray = [NSMutableArray array];
}

#pragma mark - delegate

- (void) messageStatusChange:(KMessage *)message
{
    if (!_observers) {
        return;
    }
    self.status_code ++;
    int _last_status_code = self.status_code;
    for (id<KModelObserver> observer in _observers) {
        if (observer &&
            [observer respondsToSelector:@selector(handleMessage:)] &&
            self.status_code == _last_status_code) {
            [observer handleMessage:K_Auto_Release(K_Retain(message))];
        }
    }
    
    if (message.finished) {
        [self.messageArray removeObject:message];
    }
}

- (void) handleMessage:(KMessage *)message
{
}

@end
