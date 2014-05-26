//
//  KSystemAppInfo.h
//  Pods
//
//  Created by corptest on 14-3-21.
//
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

#ifndef K_System_App_Info
#define K_System_App_Info


#define DEVICE_SYSTEM_VERSION_GT( __version )     ( [[[UIDevice currentDevice] systemVersion] compare:__version] != NSOrderedAscending )

#define IOS7_OR_LATER		( DEVICE_SYSTEM_VERSION_GT( @"7.0" ) )
#define IOS6_OR_LATER		( DEVICE_SYSTEM_VERSION_GT( @"6.0" ) )
#define IOS5_OR_LATER		( DEVICE_SYSTEM_VERSION_GT( @"5.0" ) )
#define IOS4_OR_LATER		( DEVICE_SYSTEM_VERSION_GT( @"4.0" ) )

#define IOS7_OR_EARLIER		( !IOS8_OR_LATER )
#define IOS6_OR_EARLIER		( !IOS7_OR_LATER )
#define IOS5_OR_EARLIER		( !IOS6_OR_LATER )
#define IOS4_OR_EARLIER		( !IOS5_OR_LATER )

// 是否为指定大小屏幕
#define K_Device_Is_Screen_Size(__width, __height) ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(__width, __height), [[UIScreen mainScreen] currentMode].size) : NO)

#define K_Is_iPhone_4inch        K_Device_Is_Screen_Size(640, 1136)
#define K_Is_iPhone_Non_Retina   K_Device_Is_Screen_Size(320, 640)
#define K_Is_iPhone_Retina       K_Device_Is_Screen_Size(640, 960)
#define K_Is_iPad_Non_Retina     K_Device_Is_Screen_Size(768, 1024)
#define K_Is_iPad_Retina         K_Device_Is_Screen_Size(1536, 2048)


#endif

@interface KSystemAppInfo : NSObject

#pragma mark - system

+ (NSString *) OSVersion;
+ (NSString *) deviceModel;

+ (CGSize) screenSize;

#pragma mark - app

+ (NSString *) appVersion;
+ (NSString *) appBuildVersion;
+ (NSString *) appIdentifier;

+ (NSString *) documentsDirectory;
+ (NSString *) somethingInDocumentsDirectoryWithSomeThing:(NSString *)something;

@end
