//
//  NSObject+FMJavascriptInterfaceCache.h
//  Pods
//
//  Created by carl on 16/2/3.
//
//

#import <Foundation/Foundation.h>

@interface NSObject (FMJavascriptInterfaceCache)

/**
 *  native interface of export to js cache
 */
@property(nonatomic, copy) NSDictionary *ocMethodsMapJsInterfaces;

@end
