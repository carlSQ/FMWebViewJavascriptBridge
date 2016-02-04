//
//  FMWebViewManager.m
//  Pods
//
//  Created by carl on 16/2/3.
//
//

#import "FMJavascriptBridge+private.h"
#import "FMWebViewManager.h"

@interface FMWebViewManager ()<FMWebViewJavascriptDelegate, UIWebViewDelegate>
@end

@implementation FMWebViewManager {
  __weak UIWebView *_webView;
  __weak id _webViewDelegate;
  FMJavascriptBridge *_bridge;
}

+ (instancetype)webViewManagerWithWebView:(UIWebView *)webView
                                   bridge:(FMJavascriptBridge *)bridge {
  return [self webViewManagerWithWebView:webView
                         webViewDelegate:nil
                                  bridge:bridge];
}

+ (instancetype)webViewManagerWithWebView:(UIWebView *)webView
                          webViewDelegate:(id<UIWebViewDelegate>)webViewDelegate
                                   bridge:(FMJavascriptBridge *)bridge {
  FMWebViewManager *manager = [FMWebViewManager new];
  [manager setup:webView webViewDelegate:webViewDelegate bridge:bridge];
  return manager;
}

- (void)fm_evaluateJavaScript:(NSString *)javaScriptString
            completionHandler:
                (void (^)(id result, NSError *error))completionHandler {
  [_bridge fm_evaluateJavaScript:javaScriptString
               completionHandler:completionHandler];
}

- (void)addJavascriptInterface:(NSObject *)interface withName:(NSString *)name {
  [_bridge addJavascriptInterface:interface withName:name];
}

- (void)setup:(UIWebView *)webView
    webViewDelegate:(id<UIWebViewDelegate>)webViewDelegate
             bridge:(FMJavascriptBridge *)bridge {
  _webView = webView;
  _webViewDelegate = webViewDelegate;
  _webView.delegate = self;
  _bridge = bridge;
  _bridge.delegate = self;
}

- (void)dealloc {
  _webView.delegate = nil;
  ;
  _webView = nil;
  _webViewDelegate = nil;
}

#pragma mark - FMWebViewJavascriptDelegate

- (void)evaluateJavaScript:(NSString *)javaScriptString
         completionHandler:
             (void (^)(id result, NSError *error))completionHandler {
  NSString *result =
      [_webView stringByEvaluatingJavaScriptFromString:javaScriptString];
  if (completionHandler) {
    completionHandler(result, nil);
  }
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
  if (webView != _webView) {
    return;
  }
  _bridge.numRequestsLoading--;
  if (_bridge.numRequestsLoading == 0 &&
      ![[webView stringByEvaluatingJavaScriptFromString:
                     [_bridge webViewJavascriptCheckCommand]]
          isEqualToString:@"true"]) {
    [webView stringByEvaluatingJavaScriptFromString:[_bridge injectJavascript]];
  }
  [_bridge dispatchStartUpMessageQueue];
  __strong NSObject<UIWebViewDelegate> *strongDelegate = _webViewDelegate;
  if (strongDelegate &&
      [strongDelegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
    [strongDelegate webViewDidFinishLoad:webView];
  }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
  if (webView != _webView) {
    return;
  }
  _bridge.numRequestsLoading--;
  __strong NSObject<UIWebViewDelegate> *strongDelegate = _webViewDelegate;
  if (strongDelegate &&
      [strongDelegate
          respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
    [strongDelegate webView:webView didFailLoadWithError:error];
  }
}

- (BOOL)webView:(UIWebView *)webView
    shouldStartLoadWithRequest:(NSURLRequest *)request
                navigationType:(UIWebViewNavigationType)navigationType {
  if (webView != _webView) {
    return YES;
  }
  NSURL *url = [request URL];
  __strong NSObject<UIWebViewDelegate> *strongDelegate = _webViewDelegate;
  if ([_bridge isCorrectProcotocolScheme:url]) {
    if ([_bridge isCorrectHost:url]) {
      NSString *messageQueueString =
          [webView stringByEvaluatingJavaScriptFromString:
                       [_bridge webViewJavascriptFetchQueyCommand]];
      [_bridge flushMessageQueue:messageQueueString];
    } else {
      [_bridge logUnkownMessage:url];
    }
    return NO;
  }
  if (strongDelegate &&
      [strongDelegate respondsToSelector:@selector(webView:
                                             shouldStartLoadWithRequest:
                                                         navigationType:)]) {
    return [strongDelegate webView:webView
        shouldStartLoadWithRequest:request
                    navigationType:navigationType];
  }
  return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
  if (webView != _webView) {
    return;
  }
  [_bridge reset];
  _bridge.numRequestsLoading++;
  __strong NSObject<UIWebViewDelegate> *strongDelegate = _webViewDelegate;
  if (strongDelegate &&
      [strongDelegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
    [strongDelegate webViewDidStartLoad:webView];
  }
}

@end
