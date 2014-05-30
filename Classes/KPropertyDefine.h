//
//  KPropertyDefine.h
//  Pods
//
//  Created by klaus on 14-3-16.
//
//

#ifndef Pods_KPropertyDefine_h
#define Pods_KPropertyDefine_h

#ifndef K_Retain
#include "KDefine.h"
#endif

#undef AS_API
#define AS_API(__name) \
    + (NSString *) __name;

#undef DEF_API
#define DEF_API(__name, __action_url) \
    + (NSString *) __name \
    { \
        static NSString * _action_url_ = nil; \
        if (_action_url_ == nil) { \
            _action_url_ = K_Copy(__action_url); \
        } \
        return _action_url_;\
    }

#endif
