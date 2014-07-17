//
//  KMessage.m
//  Pods
//
//  Created by klaus on 14-3-15.
//
//

#import "KMessage.h"
#import "ASIFormDataRequest.h"
#import "KCategories.h"

#define CORP_MESSAGE_TIME_OUT_SECONDS_DEFAULT    (30)

typedef NS_ENUM(NSInteger, KMessageStatus) {
    KMessageStatusSending,               // 消息已经被发送
    KMessageStatusSuccessed,             // 成功
    KMessageStatusFailed,                // 失败
    KMessageStatusCanceled,              // 取消
};

@interface FileParam : NSObject
@property (nonatomic, K_Strong) NSString *            filePath;
@property (nonatomic, K_Strong) NSData *              fileData;
@property (nonatomic, K_Strong) NSString *            fileName;
@property (nonatomic, K_Strong) NSString *            contentType;
@end
@implementation FileParam
@end

@interface KMessage ()

@property (nonatomic, K_Strong) NSURL *               url;
@property (nonatomic, assign) NSTimeInterval        timeOutSeconds;
@property (nonatomic, assign) KMessageStatus     status;

@property (nonatomic, K_Strong) NSMutableDictionary * inputData;
@property (nonatomic, K_Strong) NSMutableDictionary * inputFiles;
@property (nonatomic, K_Strong) NSMutableDictionary * outputData;
@property (nonatomic, K_Strong) NSMutableDictionary * requestHeaders;

@end

@implementation KMessage

#pragma mark - init/dealoac

+ (instancetype) messageWithURLString:(NSString *)urlString
{
    return [[self class] messageWithURLString:urlString timeOutSeconds:CORP_MESSAGE_TIME_OUT_SECONDS_DEFAULT];
}

+ (instancetype) messageWithURLString:(NSString *)urlString timeOutSeconds:(NSTimeInterval)timeOutSeconds
{
    KMessage *message = [[KMessage alloc] init];
    message.url = [NSURL URLWithString:urlString];
    message.timeOutSeconds = timeOutSeconds;
    return K_Auto_Release(message);
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        self.inputData = [NSMutableDictionary dictionary];
        self.inputFiles = [NSMutableDictionary dictionary];
        self.outputData = [NSMutableDictionary dictionary];
        self.requestHeaders = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void) dealloc
{
    self.url = nil;
    
    [self.inputData removeAllObjects];
    K_Release(self.inputData);
    [self.inputFiles removeAllObjects];
    K_Release(self.inputFiles);
    [self.outputData removeAllObjects];
    K_Release(self.outputData);
    [self.requestHeaders removeAllObjects];
    K_Release(self.requestHeaders);
    
    K_Release(_responseString);
    K_Release(_error);
    
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}

#pragma mark -

- (NSString *) urlString
{
    return [self.url absoluteString];
}

- (NSDictionary *) parameters
{
    return self.inputData;
}

- (NSTimeInterval) timeConsuming
{
    if (_sendTimeStamp != 0 && _recvTimeStamp != 0) {
        return _recvTimeStamp - _sendTimeStamp;
    }
    return 0;
}

- (KMessageBlockNormalIO) input
{
    KMessageBlockNormalIO block = ^ KMessage * (id key, id value)
    {
        if (key && value) {
            id lastValue = [self.inputData objectForKey:key];
            if (lastValue) {
                if ([lastValue isKindOfClass:[NSMutableArray class]]) {
                    [((NSMutableArray *)lastValue) addObject:value];
                } else {
                    NSMutableArray *ma = [NSMutableArray array];
                    [ma addObject:lastValue];
                    [ma addObject:value];
                    [self.inputData setObject:ma forKey:key];
                }
            } else {
                [self.inputData setObject:value forKey:key];
            }
        }
        return self;
    };
    
    return K_Auto_Release([block copy]);
}

- (KMessageBlockFileIO) inputFile
{
    KMessageBlockFileIO block = ^ KMessage * (id key, id value, NSString *fileName, NSString *contentType)
    {
        if (key && value && ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSData class]])) {
            FileParam *fp = [[FileParam alloc] init];
            if ([value isKindOfClass:[NSString class]]) {
                BOOL isDirectory = NO;
                BOOL fileExists = [[[[NSFileManager alloc] init] autorelease] fileExistsAtPath:(NSString *)value isDirectory:&isDirectory];
                if (fileExists && !isDirectory) {
                    fp.filePath = (NSString *)value;
                } else {
                    fp.fileData = [((NSString *)value) dataUsingEncoding:NSUTF8StringEncoding];
                }
                fp.fileName = fileName;
                fp.contentType = contentType;
            } else if ([value isKindOfClass:[NSData class]]) {
                fp.fileData = (NSData *)value;
                fp.fileName = fileName;
                fp.contentType = contentType;
            }
            [self.inputFiles setObject:fp forKey:key];
            K_Release(fp);
        }
        return self;
    };
    
    return K_Auto_Release([block copy]);
}

- (KMessageBlockNormalIO) output
{
    KMessageBlockNormalIO block = ^ KMessage * (id key, id value)
    {
        if (key && value) {
            [self.outputData setObject:value forKey:key];
        }
        return self;
    };
    
    return K_Auto_Release([block copy]);
}

- (KMessageBlockNormalIO) header
{
    KMessageBlockNormalIO block = ^ KMessage * (id key, id value)
    {
        if (key && value) {
            [self.requestHeaders setObject:value
                                    forKey:key];
        }
        return self;
    };
    return K_Auto_Release([block copy]);
}

- (id) getInput:(NSString *)key
{
    return [self.inputData objectForKey:key];
}

- (id) getOutput:(NSString *)key
{
    return [self.outputData objectForKey:key];
}

- (NSString *) requestHeaderForKey:(NSString *)key
{
    return [self.requestHeaders objectForKey:key];
}

- (BOOL) sending
{
    return self.status == KMessageStatusSending;
}

- (BOOL) succeed
{
    return self.status == KMessageStatusSuccessed;
}

- (void) setSucceed:(BOOL)succeed
{
    self.status = KMessageStatusSuccessed;
}

- (BOOL) failed
{
    return self.status == KMessageStatusFailed;
}

- (void) setFailed:(BOOL)failed
{
    self.status = KMessageStatusFailed;
}

- (BOOL) finished
{
    return self.status == KMessageStatusFailed || self.status == KMessageStatusSuccessed;
}

- (BOOL) cancelled
{
    return self.status == KMessageStatusCanceled;
}

- (instancetype) send
{
    return [self send:YES];
}

- (instancetype) send:(BOOL)async
{
    dispatch_queue_t queue;
    if ([[NSThread currentThread] isMainThread]) {
        queue = dispatch_get_main_queue();
    } else {
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
    __block KMessage *messageRef = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), queue, ^{
        if (async) {
            [messageRef asyncSend];
        } else {
            [messageRef syncSend];
        }
    });
    return self;
}

- (BOOL) is:(id)obj
{
    if ([obj isKindOfClass:[NSString class]]) {
        return [self.url.absoluteString isEqualToString:(NSString *)obj];
    }
    return [super is:obj];
}

#pragma mark -

- (void) setStatus:(KMessageStatus)status
{
    _status = status;
    if (self.messageStatusChangeDelegate &&
        [self.messageStatusChangeDelegate respondsToSelector:@selector(messageStatusChange:)]) {
        [self.messageStatusChangeDelegate performSelectorOnMainThread:@selector(messageStatusChange:)
                                                           withObject:self
                                                        waitUntilDone:[NSThread isMainThread]];
    }
}

- (void) asyncSend
{
    KLog(@"http request url:%@", self.url);
    if (self.inputData) {
        KLog(@"http request parameters:%@", self.inputData);
    }
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:self.url];
    for (id key in self.inputData.allKeys) {
        id value = [self.inputData objectForKey:key];
        if ([value isKindOfClass:[NSMutableArray class]]) {
            for (id v in ((NSArray *)value)) {
                [request addPostValue:v
                               forKey:key];
            }
        } else {
            [request setPostValue:[self.inputData objectForKey:key]
                           forKey:key];
        }
    }
    for (id key in self.inputFiles.allKeys) {
        FileParam *fp = [self.inputFiles objectForKey:key];
        if (fp.fileData) {
            [request addData:fp.fileData
                withFileName:fp.fileName
              andContentType:fp.contentType
                      forKey:key];
        } else if (fp.filePath) {
            [request addFile:fp.filePath
                withFileName:fp.fileName
              andContentType:fp.contentType
                      forKey:key];
        }
    }
    for (NSString *key in self.requestHeaders.allKeys) {
        [request addRequestHeader:key
                            value:[self.requestHeaders objectForKey:key]];
    }
    request.timeOutSeconds = self.timeOutSeconds;
    [request setRequestMethod:@"POST"];
    [request setResponseEncoding:NSUTF8StringEncoding];
    [request setDefaultResponseEncoding:NSUTF8StringEncoding];
    [request setShouldAttemptPersistentConnection:NO];
    ASIFormDataRequest *requestRef = request;
    [request setCompletionBlock:^{
        _recvTimeStamp = [[NSDate date] timeIntervalSince1970];
        _responseString = K_Copy(requestRef.responseString);
        KLog(@"url:%@", requestRef.url);
        KLog(@"success! response:%@", _responseString);
        self.status = KMessageStatusSuccessed;
    }];
    [request setFailedBlock:^{
        _recvTimeStamp = [[NSDate date] timeIntervalSince1970];
        NSMutableDictionary *userInfo = K_Retain([NSMutableDictionary dictionaryWithDictionary:requestRef.error.userInfo]);
        [userInfo setValue:requestRef.url forKey:@"Host"];
        _error = K_Retain([NSError errorWithDomain:requestRef.error.domain
                                                code:requestRef.error.code
                                            userInfo:userInfo]);
        KLog(@"url:%@", requestRef.url);
        KLog(@"failed! error:%@", _error);
        K_Release(userInfo);
        self.status = KMessageStatusFailed;
    }];
    [request startAsynchronous];
    _sendTimeStamp = [[NSDate date] timeIntervalSince1970];
    self.status = KMessageStatusSending;
}

- (void) syncSend
{
    
}

@end
