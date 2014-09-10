//
//  KMessage.h
//  Pods
//
//  Created by klaus on 14-3-15.
//
//

#import <Foundation/Foundation.h>
#import "KDefine.h"
#import "AFNetworking.h"

@class KMessage;

typedef KMessage *   (^KMessageBlockNormalIO)(id key, id value);

typedef KMessage *   (^KMessageBlockFileIO)(id key, id value, NSString *fileName, NSString *contentType);

@protocol KMessageStatusChangeDelegate <NSObject>

@optional
- (void) messageStatusChange:(KMessage *)message;

@end

@interface KMessage : NSObject

+ (instancetype) messageWithURLString:(NSString *)urlString;

+ (instancetype) messageWithURLString:(NSString *)urlString timeOutSeconds:(NSTimeInterval)timeOutSeconds;

@property (nonatomic, K_Strong, readonly) NSString                      *                  urlString;
@property (nonatomic, K_Strong, readonly) NSDictionary                  *              parameters;

@property (nonatomic, assign, readonly  ) BOOL                          sending;
@property (nonatomic, assign            ) BOOL                          succeed;
@property (nonatomic, assign            ) BOOL                          failed;
@property (nonatomic, assign, readonly  ) BOOL                          finished;
@property (nonatomic, assign, readonly  ) BOOL                          cancelled;
@property (nonatomic, assign            ) id<KMessageStatusChangeDelegate > messageStatusChangeDelegate;

@property (nonatomic, assign, readonly  ) NSTimeInterval                sendTimeStamp;
@property (nonatomic, assign, readonly  ) NSTimeInterval                recvTimeStamp;
@property (nonatomic, assign            ) AFHTTPClientParameterEncoding parameterEncoding;

- (NSTimeInterval) timeConsuming;

- (KMessageBlockNormalIO) input;
- (KMessageBlockFileIO) inputFile;
- (KMessageBlockNormalIO) output;
- (KMessageBlockNormalIO) header;

- (id) getInput:(NSString *)key;

- (id) getOutput:(NSString *)key;

- (NSString *) requestHeaderForKey:(NSString *)key;

- (instancetype) send;

- (instancetype) send:(BOOL)async;

@property (nonatomic, assign, readonly) NSString *                  responseString;
@property (nonatomic, retain, readonly) NSError *                   error;

@end
