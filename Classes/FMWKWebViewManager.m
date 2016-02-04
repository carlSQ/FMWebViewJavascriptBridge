//
//  FMWKWebViewManager.m
//  Pods
//
//  Created by carl on 16/2/3.
//
//

#import "FMJavascriptBridge+private.h"
#import "FMWKWebViewManager.h"

@interface FMWKWebViewManager ()<FMWebViewJavascriptDelegate,
                                 WKNavigationDelegate> {
  __weak WKWebView *_webView;
  __weak id _webViewDelegate;
  FMJavascriptBridge *_bridge;
}

@end

@implementation FMWKWebViewManager

+ (instancetype)webViewManagerWithWebView:(WKWebView *)webView
                                   bridge:(FMJavascriptBridge *)bridge {
  return [self webViewManagerWithWebView:webView
                         webViewDelegate:nil
                                  bridge:bridge];
}

+ (instancetype)webViewManagerWithWebView:(WKWebView *)webView
                          webViewDelegate:
                              (id<WKNavigationDelegate>)webViewDelegate
                                   bridge:(FMJavascriptBridge *)bridge {
  FMWKWebViewManager *manager = [FMWKWebViewManager new];
  [manager setup:webView webViewDelgate:webViewDelegate bridge:bridge];
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

- (void)setup:(WKWebView *)webView
    webViewDelgate:(id<WKNavigationDelegate>)webViewDelagate
            bridge:(FMJavascriptBridge *)bridge {
  _webView = webView;
  _webViewDelegate = webViewDelagate;
  _webView.navigationDelegate = self;
  _bridge = bridge;
  _bridge.delegate = self;
}

- (void)WKFlushMessageQueue {
  [_webView evaluateJavaScript:[_bridge webViewJavascriptFetchQueyCommand]
             completionHandler:^(NSString *result, NSError *error) {
               if (!error) {
                 [_bridge flushMessageQueue:result];
               }
             }];
}

- (void)dealloc {
  _bridge = nil;
  _webView.navigationDelegate = nil;
  _webView = nil;
  _webViewDelegate = nil;
}

#pragma mark - FMWebViewJavascriptDelegate
- (void)evaluateJavaScript:(NSString *)javaScriptString
         completionHandler:
             (void (^)(id result, NSError *error))completionHandler {
  [_webView evaluateJavaScript:javaScriptString
             completionHandler:completionHandler];
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView
    didFinishNavigation:(WKNavigation *)navigation {
  if (webView != _webView) {
    return;
  }
  _bridge.numRequestsLoading--;
  if (_bridge.numRequestsLoading == 0) {
    [webView evaluateJavaScript:[_bridge webViewJavascriptCheckCommand]
              completionHandler:^(NSString *result, NSError *error) {
                if (!result.boolValue) {
                  NSString *js = [_bridge injectJavascript];
                  [webView evaluateJavaScript:js
                            completionHandler:^(id _Nullable result,
                                                NSError *_Nullable error) {
                              if (!error) {
                                [_bridge dispatchStartUpMessageQueue];
                              }
                            }];
                }
              }];
  }
  __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;
  if (strongDelegate &&
      [strongDelegate
          respondsToSelector:@selector(webView:didFinishNavigation:)]) {
    [strongDelegate webView:webView didFinishNavigation:navigation];
  }
}

- (void)webView:(WKWebView *)webView
    decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
                    decisionHandler:
                        (void (^)(WKNavigationActionPolicy))decisionHandler {
  if (webView != _webView) {
    return;
  }
  NSURL *url = navigationAction.request.URL;
  __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;
  if ([_bridge isCorrectProcotocolScheme:url]) {
    if ([_bridge isCorrectHost:url]) {
      [self WKFlushMessageQueue];
    } else {
      [_bridge logUnkownMessage:url];
    }
    [webView stopLoading];
  }
  if (strongDelegate &&
      [strongDelegate
          respondsToSelector:@selector(webView:
                                 decidePolicyForNavigationAction:
                                                 decisionHandler:)]) {
    [_webViewDelegate webView:webView
        decidePolicyForNavigationAction:navigationAction
                        decisionHandler:decisionHandler];
  } else {
    if (decisionHandler) {
      decisionHandler(WKNavigationActionPolicyAllow);
    }
  }
}

- (void)webView:(WKWebView *)webView
    didStartProvisionalNavigation:(WKNavigation *)navigation {
  if (webView != _webView) {
    return;
  }
  [_bridge reset];
  _bridge.numRequestsLoading++;
  __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;
  if (strongDelegate &&
      [strongDelegate respondsToSelector:@selector(webView:
                                             didStartProvisionalNavigation:)]) {
    [strongDelegate webView:webView didStartProvisionalNavigation:navigation];
  }
}

- (void)webView:(WKWebView *)webView
    didFailNavigation:(WKNavigation *)navigation
            withError:(NSError *)error {
  if (webView != _webView) {
    return;
  }
  _bridge.numRequestsLoading--;
  __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;
  if (strongDelegate &&
      [strongDelegate
          respondsToSelector:@selector(webView:didFailNavigation:withError:)]) {
    [strongDelegate webView:webView
          didFailNavigation:navigation
                  withError:error];
  }
}

- (void)webView:(WKWebView *)webView
    decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse
                      decisionHandler:(void (^)(WKNavigationResponsePolicy))
                                          decisionHandler {
  __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;
  if (strongDelegate &&
      [strongDelegate
          respondsToSelector:@selector(webView:
                                 decidePolicyForNavigationResponse:
                                                   decisionHandler:)]) {
    [strongDelegate webView:webView
        decidePolicyForNavigationResponse:navigationResponse
                          decisionHandler:decisionHandler];
  } else {
    if (decisionHandler) {
      decisionHandler(WKNavigationResponsePolicyAllow);
    }
  }
}

- (void)webView:(WKWebView *)webView
    didReceiveServerRedirectForProvisionalNavigation:
        (null_unspecified WKNavigation *)navigation {
  __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;
  if (strongDelegate &&
      [strongDelegate
          respondsToSelector:
              @selector(webView:
                  didReceiveServerRedirectForProvisionalNavigation:)]) {
    [strongDelegate webView:webView
        didReceiveServerRedirectForProvisionalNavigation:navigation];
  }
}

- (void)webView:(WKWebView *)webView
    didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation
                       withError:(NSError *)error {
  __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;
  if (strongDelegate &&
      [strongDelegate respondsToSelector:@selector(webView:
                                             didFailProvisionalNavigation:
                                                                withError:)]) {
    [strongDelegate webView:webView
        didFailProvisionalNavigation:navigation
                           withError:error];
  }
}

- (void)webView:(WKWebView *)webView
    didCommitNavigation:(null_unspecified WKNavigation *)navigation {
  __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;
  if (strongDelegate &&
      [strongDelegate
          respondsToSelector:@selector(webView:didCommitNavigation:)]) {
    [strongDelegate webView:webView didCommitNavigation:navigation];
  }
}

- (void)
                          webView:(WKWebView *)webView
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
                completionHandler:
                    (void (^)(NSURLSessionAuthChallengeDisposition disposition,
                              NSURLCredential *__nullable credential))
                        completionHandler {
  __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;
  if (strongDelegate &&
      [strongDelegate
          respondsToSelector:@selector(webView:
                                 didReceiveAuthenticationChallenge:
                                                 completionHandler:)]) {
    [strongDelegate webView:webView
        didReceiveAuthenticationChallenge:challenge
                        completionHandler:completionHandler];
  } else {
    if (completionHandler) {
      completionHandler(NSURLSessionAuthChallengeRejectProtectionSpace,
                        challenge.proposedCredential);
    }
  }
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
  __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;
  if (strongDelegate &&
      [strongDelegate
          respondsToSelector:@selector(
                                 webViewWebContentProcessDidTerminate:)]) {
    [strongDelegate webViewWebContentProcessDidTerminate:webView];
  }
}

@end
