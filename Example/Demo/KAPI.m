//
//  KAPI.m
//  Demo
//
//  Created by klaus on 14-3-16.
//  Copyright (c) 2014年 corp. All rights reserved.
//

#import "KAPI.h"
#import "KDatabase.h"

@implementation USER

@end

@implementation TEST_USER
KDB_Table_Name(t_user)
KDB_Primary_Key(u_id, user_id)
@end

@implementation TEST_ABC
KDB_Table_Name(t_abc)

@end

@implementation KAPI

DEF_API(user_signin, @"http://27.115.8.166:83/api/sms/newCode")

DEF_API(upload, @"http://192.168.1.138:8080/clmj-app-server/admin/upload!doUpload.action")

@end
