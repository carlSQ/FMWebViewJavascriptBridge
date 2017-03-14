//
//  JavascripInterface.h
//  ELMWebViewJavascripBridge
//
//  Created by sq on 15/9/1.
//  Copyright (c) 2015年 sq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NSObject+FMAnnotation.h"
#import "WKViewController.h"

@interface JavascripInterface : NSObject

- (instancetype)initWithController:(WKViewController *)viewController;

- (void)push:(NSUInteger)one;

- (void)pop:(NSString *)testArray;

- (void)present;

- (void)dismiss;

- (void)setNavTitle:(NSDictionary *)userInfo response:(FMCallBack)callBack;

- (void)setBack;

@end
