//
//  FMJavascriptBridge+private.h
//  Pods
//
//  Created by carl on 16/2/3.
//
//

#import "FMJavascriptBridge.h"

@interface FMJavascriptBridge (private)

- (void)addJavascriptInterface:(NSObject *)interface withName:(NSString *)name;

- (void)flushMessageQueue:(NSString *)messageQueueString;

- (NSString *)injectJavascript;

- (BOOL)isCorrectProcotocolScheme:(NSURL *)url;

- (BOOL)isCorrectHost:(NSURL *)urll;

- (void)logUnkownMessage:(NSURL *)url;

- (void)dispatchStartUpMessageQueue;

- (NSString *)webViewJavascriptCheckCommand;

- (NSString *)webViewJavascriptFetchQueyCommand;

- (void)fm_evaluateJavaScript:(NSString *)javaScriptString
            completionHandler:
                (void (^)(id result, NSError *error))completionHandler;

- (void)reset;

@end
