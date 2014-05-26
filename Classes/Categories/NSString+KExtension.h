//
//  NSString+KExtension.h
//  K
//
//  Created by corptest on 14-1-3.
//  Copyright (c) 2014年 corp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (KExtension)

+ (BOOL) isBlank:(NSString *)str;

+ (BOOL) isNotBlank:(NSString *)str;

// 根据url获取请求参数
- (NSDictionary *) queryStringToarameterDictionary;

- (BOOL) isEmail;

- (BOOL) isUrl;

- (BOOL) isIPAddress;

- (BOOL) isEqualToStringIgnoreCase:(NSString *)aString;

/**
 *  去除json中的空格，回车，注释
 *
 *  @return 格式化后的json字符串
 */
- (NSString *) formatToJsonString;

- (BOOL) isInteger;

- (BOOL) isLongLong;

- (BOOL) isFloat;

- (BOOL) isDouble;

@end
