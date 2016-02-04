//
//  NSObject+FMJavascriptInterfaceCache.m
//  Pods
//
//  Created by carl on 16/2/3.
//
//

#import <objc/runtime.h>
#import "NSObject+FMJavascriptInterfaceCache.h"

@implementation NSObject (FMJavascriptInterfaceCache)
- (void)setOcMethodsMapJsInterfaces:(NSArray *)ocMethodsMapJsInterfaces {
  objc_setAssociatedObject(
      [self class], @"__fm_export__ocMethodsMapJsInterfaces",
      ocMethodsMapJsInterfaces, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSArray *)ocMethodsMapJsInterfaces {
  return objc_getAssociatedObject([self class],
                                  @"__fm_export__ocMethodsMapJsInterfaces");
}
@end
