//
//  FMJavascriptInterface.h
//  Pods
//
//  Created by carl on 16/2/3.
//
//

typedef void (^FMAsyResponse)(id responseData);
typedef void (^FMJSFunctonResponse)(id responseData);


#define FM_EXPORT_METHOD(returnType, method) \
  FM_REMAP_METHOD(, returnType, method)

#define FM_REMAP_METHOD(js_name, returnType, method) \
  FM_EXTERN_REMAP_METHOD(js_name, method)            \
  -(returnType)method

#define FM_EXTERN_REMAP_METHOD(js_name, method)                              \
  +(NSArray *)FM_CONCAT(                                                     \
      __fm_export__, FM_CONCAT(js_name, FM_CONCAT(__LINE__, __COUNTER__))) { \
    return @[ @ #js_name, @ #method ];                                       \
  }

#define FM_CONCAT2(A, B) A##B

#define FM_CONCAT(A, B) FM_CONCAT2(A, B)
