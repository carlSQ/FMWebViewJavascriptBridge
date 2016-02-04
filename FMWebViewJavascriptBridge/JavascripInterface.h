//
//  JavascripInterface.h
//  ELMWebViewJavascripBridge
//
//  Created by sq on 15/9/1.
//  Copyright (c) 2015年 sq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FMJavascriptInterface.h"
#import "User.h"
@interface JavascripInterface : NSObject

- (instancetype)initWithController:(UIViewController *)viewController;

- (void)push:(NSUInteger)one;

- (void)pop:(NSString *)testArray;

- (void)present;

- (void)dismiss;

- (void)setNavTitle:(User *)user response:(FMAsyResponse)response;

- (void)setBack;

- (NSString *)testInterfaceReturnData:(NSDictionary *)dictionary;

@end
