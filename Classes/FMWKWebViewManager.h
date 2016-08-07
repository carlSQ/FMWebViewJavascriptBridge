//
//  FMWKWebViewManager.h
//  Pods
//
//  Created by carl on 16/2/3.
//
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "FMJavascriptBridge.h"
#import "FMJavascriptInterface.h"
@interface FMWKWebViewManager : NSObject

+ (instancetype)webViewManagerWithWebView:(WKWebView *)webView
                                   bridge:(FMJavascriptBridge *)bridge;

+ (instancetype)webViewManagerWithWebView:(WKWebView *)webView
                          webViewDelegate:
                              (id<WKNavigationDelegate>)webViewDelegate
                                   bridge:(FMJavascriptBridge *)bridge;
/**
 *  evaluateJavaScript after webview finish loading
 *
 *  @param javaScriptString
 *  @param completionHandler
 */
- (void)fm_evaluateJavaScript:(NSString *)javaScriptString
            completionHandler:
                (void (^)(id result, NSError *error))completionHandler;

/**
 *  inject native object to js
 *
 *  @param interface native object
 *  @param name      name that js use
 */
- (void)addJavascriptInterface:(NSObject *)interface withName:(NSString *)name;
  
- (void)callFunctionOnObject:(NSString *)object
                      method:(NSString *)methodName
                        args:(NSArray *)args;
  
- (void)callFunctionOnObject:(NSString *)object
                      method:(NSString *)methodName
                        args:(NSArray *)args
                    response:(FMJSFunctonResponse) response;
@end
