//
//  KClassUtils.h
//  Pods
//
//  Created by klaus on 14-5-2.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKitDefines.h>

typedef NS_ENUM(NSInteger, KClassType) {
KClassType_Unknow            = 0,    // 未知类型
KClassType_Int_NSInteger,            // int
KClassType_Long,                     // long
KClassType_Long_Long,                // long long
KClassType_Float_CGFloat,            // float
KClassType_Double,                   // double
KClassType_NSNumber,                 // NSNumber
KClassType_NSString,                 // NSString
KClassType_NSDate,                   // NSDate
KClassType_NSArray,                  // NSArray
KClassType_NSDictionary,             // NSDictionary
KClassType_Object                    // Object
};

UIKIT_EXTERN NSString *const KClassPropertyNameKey;
UIKIT_EXTERN NSString *const KClassPropertyTypeKey;
UIKIT_EXTERN NSString *const KClassPropertyColumnNameKey;

@interface KClassUtils : NSObject

+ (NSArray *) propertiesInClass:(Class)class;

+ (KClassType) typeWithPropertyName:(NSString *)propertyName
                            inClass:(Class)class;

+ (KClassType) typeWithObject:(id)obj;

/**
 *  获取指定class中的指定成员名的class类型
 *
 *  @param propertyName 成员名称
 *  @param inClass
 *
 *  @return 成员名对应的class类型
 */
+ (Class) classWithPropertyName:(NSString *)propertyName
                        inClass:(Class)inClass;

@end
