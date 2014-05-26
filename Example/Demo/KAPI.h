//
//  KAPI.h
//  Demo
//
//  Created by klaus on 14-3-16.
//  Copyright (c) 2014年 corp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KFramework.h"

@interface USER : NSObject
@property (nonatomic, assign) int               collection_num;
@property (nonatomic, strong) NSString *		name;
@property (nonatomic, strong) NSString *		email;
@property (nonatomic, strong) NSDictionary *	order_num;
@property (nonatomic, strong) NSString *		rank_name;
@property (nonatomic, strong) NSString *		mobile_phone;
@property (nonatomic, assign) int               integral;
@property (nonatomic, assign) int               redpocket;
@property (nonatomic, strong) NSString *        balance;
@property (nonatomic, assign) int               rank_level;
@property (nonatomic, assign) int               u_id;
@end

@class TEST_ABC;

@interface TEST_USER : NSObject
@property (nonatomic, assign) int               u_id;
@property (nonatomic, strong) NSString *        name;
@property (nonatomic, assign) int               age;
@property (nonatomic, strong) NSArray *         oldNames;
@property (nonatomic, strong) NSDictionary *    order_num;
@property (nonatomic, strong) TEST_ABC *        abc;
@end

@interface TEST_ABC : NSObject
@property (nonatomic, assign) int               a;
@property (nonatomic, strong) NSString *        b;
@property (nonatomic, strong) NSString *        c;
@end

@interface KAPI : NSObject

AS_API(user_signin)

AS_API(upload)

@end
