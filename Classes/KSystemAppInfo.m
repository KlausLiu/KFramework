//
//  KSystemAppInfo.m
//  Pods
//
//  Created by corptest on 14-3-21.
//
//

#import "KSystemAppInfo.h"

@implementation KSystemAppInfo

#pragma mark - system

+ (NSString *) OSVersion
{
    return [UIDevice currentDevice].systemVersion;
}
+ (NSString *) deviceModel;
{
    return [UIDevice currentDevice].model;
}

+ (CGSize) screenSize;
{
    (floor(NSFoundationVersionNumber) >= NSFoundationVersionNumber_iOS_6_0);
    return [UIScreen mainScreen].currentMode.size;
}

#pragma mark - app

+ (NSString *) appVersion;
{
    NSString *ret = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersion"];
    return ret?ret:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}
+ (NSString *) appBuildVersion;
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}
+ (NSString *) appIdentifier;
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
}

+ (NSString *) documentsDirectory
{
    return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
}
+ (NSString *) somethingInDocumentsDirectoryWithSomeThing:(NSString *)something
{
    return [NSString stringWithFormat:@"%@%@", [self documentsDirectory], something];
}

@end
