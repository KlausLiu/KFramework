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

#undef KWeek
#if __has_feature(objc_arc_weak)
#define KWeek __weak
#else
#define KWeek __unsafe_unretained
#endif

#undef KRelease
#if __has_feature(objc_arc)
    #define KRelease(__x)
#else
    #define KRelease(__x) [__x release]; __x = nil
#endif

#undef KAutoRelease
#if __has_feature(objc_arc)
    #define KAutoRelease(__x) __x
#else
    #define KAutoRelease(__x) [__x autorelease]
#endif

#undef KCopy
#if __has_feature(objc_arc)
    #define KCopy(__x) __x
#else
    #define KCopy(__x) [__x copy]
#endif

#undef KRetain
#if __has_feature(objc_arc)
    #define KRetain(__x) __x
#else
    #define KRetain(__x) [__x retain]
#endif

#undef KDispatchQueueRelease
#if __has_feature(objc_arc)
// If OS_OBJECT_USE_OBJC=1, then the dispatch objects will be treated like ObjC objects
// and will participate in ARC.
// See the section on "Dispatch Queues and Automatic Reference Counting" in "Grand Central Dispatch (GCD) Reference" for details.
#if OS_OBJECT_USE_OBJC
#define KDispatchQueueRelease(__x)
#else
#define KDispatchQueueRelease(__x) (dispatch_release(__x));
#endif
#else
#define KDispatchQueueRelease(__x) (dispatch_release(__x));
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
