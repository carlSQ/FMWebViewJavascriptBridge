//
//  FMWebViewManager.h
//  Pods
//
//  Created by carl on 16/2/3.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIWebView.h>
#import "FMJavascriptBridge.h"

@interface FMWebViewManager : NSObject

+ (instancetype)webViewManagerWithWebView:(UIWebView *)webView
                                   bridge:(FMJavascriptBridge *)bridge;

+ (instancetype)webViewManagerWithWebView:(UIWebView *)webView
                          webViewDelegate:
                              (NSObject<UIWebViewDelegate> *)webViewDelegate
                                   bridge:(FMJavascriptBridge *)bridge;

- (void)fm_evaluateJavaScript:(NSString *)javaScriptString
            completionHandler:
                (void (^)(id result, NSError *error))completionHandler;

- (void)addJavascriptInterface:(NSObject *)interface withName:(NSString *)name;
@end
