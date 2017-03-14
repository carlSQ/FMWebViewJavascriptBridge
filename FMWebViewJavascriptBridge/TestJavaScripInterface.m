//
//  TestJavaScripInterface.m
//  FMWebViewJavascriptBridge
//
//  Created by 沈强 on 2017/3/14.
//  Copyright © 2017年 沈强. All rights reserved.
//

#import "TestJavaScripInterface.h"
#import "NSObject+FMAnnotation.h"

@implementation TestJavaScripInterface

FM_EXPORT_METHOD(@selector(testData:))
- (void)testData:(id)data {
  NSLog(@"data class: %@, body is %@",[data class], [data debugDescription]);
}

@end
