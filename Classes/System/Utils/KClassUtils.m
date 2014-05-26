//
//  KClassUtils.m
//  Pods
//
//  Created by klaus on 14-5-2.
//
//

#import "KClassUtils.h"
#import <objc/runtime.h>
#import "NSString+KExtension.h"
#import "KNumberUtils.h"

NSString *const KClassPropertyNameKey = @"KClassPropertyNameKey";
NSString *const KClassPropertyTypeKey = @"KClassPropertyTypeKey";
NSString *const KClassPropertyColumnNameKey = @"KClassPropertyColumnNameKey";

@implementation KClassUtils

+ (NSArray *) propertiesInClass:(Class)class
{
    unsigned int propertyCount = 0;
    objc_property_t * properties = class_copyPropertyList(class, &propertyCount);
    NSMutableArray *propertyArray = [NSMutableArray arrayWithCapacity:propertyCount];
    for (int i = 0; i < propertyCount; i ++) {
        const char * name = property_getName(properties[i]);
        NSString *propertyName = [NSString stringWithUTF8String:name];
        const char * attr = property_getAttributes(properties[i]);
        KClassType type = [self typeOf:attr];
        [propertyArray addObject:@{
                                   KClassPropertyNameKey : propertyName,
                                   KClassPropertyTypeKey : @(type)
                                   }];
    }
    if (properties) {
        free(properties);
    }
    return propertyArray;
}

+ (KClassType) typeWithPropertyName:(NSString *)_propertyName
                            inClass:(Class)class
{
    unsigned int propertyCount = 0;
    objc_property_t * properties = class_copyPropertyList(class, &propertyCount);
    for (int i = 0; i < propertyCount; i ++) {
        const char * name = property_getName(properties[i]);
        NSString *propertyName = [NSString stringWithUTF8String:name];
        if ([propertyName isEqualToStringIgnoreCase:_propertyName]) {
            const char * attr = property_getAttributes(properties[i]);
            return [self typeOf:attr];
        }
    }
    return KClassType_Unknow;
}

+ (KClassType) typeWithObject:(id)obj
{
    if ([obj isKindOfClass:[NSString class]]) {
        return KClassType_NSString;
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        if ([KNumberUtils isInteger:obj]) {
            return KClassType_Int_NSInteger;
        }
        if ([KNumberUtils isLongLong:obj]) {
            return KClassType_Long_Long;
        }
        if ([KNumberUtils isFloat:obj]) {
            return KClassType_Float_CGFloat;
        }
        if ([KNumberUtils isDouble:obj]) {
            return KClassType_Double;
        }
        return KClassType_NSNumber;
    }
    if ([obj isKindOfClass:[NSArray class]]) {
        return KClassType_NSArray;
    }
    if ([obj isKindOfClass:[NSDictionary class]]) {
        return KClassType_NSDictionary;
    }
    if ([obj isKindOfClass:[NSObject class]]) {
        return KClassType_Object;
    }
    return KClassType_Unknow;
}

+ (Class) classWithPropertyName:(NSString *)propertyName
                        inClass:(Class)inClass
{
    Class clazz = nil;
    unsigned int        propertyCount = 0;
    objc_property_t *   properties = class_copyPropertyList(inClass, &propertyCount);
    for (int i = 0; i < propertyCount; i ++) {
        const char *    name = property_getName(properties[i]);
        NSString *      pn = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
        if ([propertyName isEqualToString:pn]) {
            const char *    attr = property_getAttributes(properties[i]);
            clazz = [self classWithPropertAttributes:attr];
            break;
        }
    }
    
    if (properties) {
        free(properties);
    }
    return clazz;
}

#pragma mark - private

+ (Class) classWithPropertAttributes:(const char *)attr
{
	if ( attr[0] != 'T' )
		return nil;
	
	const char * type = &attr[1];
	if ( type[0] == '@' )
	{
		if ( type[1] != '"' )
			return nil;
		
		char typeClazz[128] = { 0 };
		
		const char * clazz = &type[2];
		const char * clazzEnd = strchr( clazz, '"' );
		
		if ( clazzEnd && clazz != clazzEnd )
		{
			unsigned int size = (unsigned int)(clazzEnd - clazz);
			strncpy( &typeClazz[0], clazz, size );
		}
		
		return NSClassFromString([NSString stringWithUTF8String:typeClazz]);
	}
	
	return nil;
}

+ (KClassType) typeOf:(const char *)attr
{
    if (attr[0] != 'T') {
		return KClassType_Unknow;
    }
	
	const char * type = &attr[1];
	if (type[0] == '@') {
        if ( type[1] != '"' )
			return KClassType_Unknow;
		
		char typeClazz[128] = { 0 };
		
		const char * clazz = &type[2];
		const char * clazzEnd = strchr( clazz, '"' );
		
		if ( clazzEnd && clazz != clazzEnd )
		{
			unsigned int size = (unsigned int)(clazzEnd - clazz);
			strncpy( &typeClazz[0], clazz, size );
		}
		
		if ( 0 == strcmp((const char *)typeClazz, "NSNumber") )
		{
			return KClassType_NSNumber;
		}
		else if ( 0 == strcmp((const char *)typeClazz, "NSString") )
		{
			return KClassType_NSString;
		}
		else if ( 0 == strcmp((const char *)typeClazz, "NSDate") )
		{
			return KClassType_NSDate;
		}
		else if ( 0 == strcmp((const char *)typeClazz, "NSArray") )
		{
			return KClassType_NSArray;
		}
		else if ( 0 == strcmp((const char *)typeClazz, "NSDictionary") )
		{
			return KClassType_NSDictionary;
		}
		else
		{
			return KClassType_Object;
		}
    } else if ((type[0] == 'i' || type[0] == 'I') && type[1] == ',') {
        return KClassType_Int_NSInteger;
    } else if ((type[0] == 'l' || type[0] == 'L') && type[1] == ',') {
        return KClassType_Long;
    } else if ((type[0] == 'q' || type[0] == 'Q') && type[1] == ',') {
        return KClassType_Long_Long;
    } else if ((type[0] == 'f' || type[0] == 'F') && type[1] == ',') {
        return KClassType_Float_CGFloat;
    } else if ((type[0] == 'd' || type[0] == 'D') && type[1] == ',') {
        return KClassType_Double;
    }
    return KClassType_Unknow;
}

@end
