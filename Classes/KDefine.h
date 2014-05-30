//
//  KDefine.h
//  KFramework
//
//  Created by corptest on 14-1-29.
//  Copyright (c) 2014年 corp. All rights reserved.
//

#ifndef KFramework_KDefine_h
#define KFramework_KDefine_h

#if defined (DEBUG) && DEBUG==1
#define KLog(...) NSLog(__VA_ARGS__)
#else
#define KLog(...)
#endif

#pragma mark - memmory

#ifndef K_Strong
    #if __has_feature(objc_arc)
        #define K_Strong    strong
    #else
        #define K_Strong    retain
    #endif
#endif

#ifndef K_Week
    #if __has_feature(objc_arc_week)
        #define K_Week  week
    #elif __has_feature(objc_arc)
        #define K_Week  unsafe_unretained
    #else
        #define K_Week  assign
    #endif
#endif

#ifndef K__Week
    #if __has_feature(objc_arc_weak)
        #define K__Week __weak
    #else
        #define K__Week __unsafe_unretained
    #endif
#endif

#ifndef K_Release
    #if __has_feature(objc_arc)
        #define K_Release(__x)
    #else
        #define K_Release(__x) [__x release]; __x = nil
    #endif
#endif

#ifndef K_Auto_Release
    #if __has_feature(objc_arc)
        #define K_Auto_Release(__x) __x
    #else
        #define K_Auto_Release(__x) [__x autorelease]
    #endif
#endif

#ifndef K_Copy
    #if __has_feature(objc_arc)
        #define K_Copy(__x) __x
    #else
        #define K_Copy(__x) [__x copy]
    #endif
#endif

#ifndef K_Retain
    #if __has_feature(objc_arc)
        #define K_Retain(__x) __x
    #else
        #define K_Retain(__x) [__x retain]
    #endif
#endif

#ifndef K_Dispatch_Queue_Release
    #if __has_feature(objc_arc)
        // If OS_OBJECT_USE_OBJC=1, then the dispatch objects will be treated like ObjC objects
        // and will participate in ARC.
        // See the section on "Dispatch Queues and Automatic Reference Counting" in "Grand Central Dispatch (GCD) Reference" for details.
        #if OS_OBJECT_USE_OBJC
            #define K_Dispatch_Queue_Release(__x)
        #else
            #define K_Dispatch_Queue_Release(__x) (dispatch_release(__x));
        #endif
    #else
        #define K_Dispatch_Queue_Release(__x) (dispatch_release(__x));
    #endif
#endif

#pragma mark - math



#pragma mark - color

#define RGBCOLOR(r,g,b) \
[UIColor colorWithRed:r/256.f green:g/256.f blue:b/256.f alpha:1.f]

#define RGBACOLOR(r,g,b,a) \
[UIColor colorWithRed:r/256.f green:g/256.f blue:b/256.f alpha:a]

#define UIColorFromRGB(rgbValue) \
    [UIColor \
        colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
               green:((float)((rgbValue & 0x00FF00) >> 8))/255.0 \
                blue:((float)(rgbValue & 0x0000FF))/255.0 \
               alpha:1.0]

#define UIColorFromRGBA(rgbValue, alphaValue) \
    [UIColor \
        colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
               green:((float)((rgbValue & 0x00FF00) >> 8))/255.0 \
                blue:((float)(rgbValue & 0x0000FF))/255.0 \
               alpha:alphaValue]

#pragma mark - thread

#define KBackground(block) dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block)

#define KMainThread(block) dispatch_async(dispatch_get_main_queue(),block)


#endif
