//
//  KUserModel.h
//  Demo
//
//  Created by klaus on 14-3-15.
//  Copyright (c) 2014年 corp. All rights reserved.
//

#import "KModel.h"

@interface KUserModel : KModel

AS_SINGLETEN(KUserModel)

- (void) signin:(NSString *)username
               :(NSString *)password;

- (void) upload:(NSString *)filePath;

@end
