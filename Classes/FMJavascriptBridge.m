//
//  FMJavascriptBridge.m
//  Pods
//
//  Created by carl on 16/2/3.
//
//

#import <objc/runtime.h>
#import "FMJSONModelDelegate.h"
#import "FMJavascriptBridge.h"
#import "FMJavascriptInterface.h"
#import "NSObject+FMJavascriptInterfaceCache.h"
#import "FMJavascriptBridge+private.h"

#define FMCustomProtocolScheme @"fmscheme"
#define FMQueueHasMessage @"__FM_QUEUE_MESSAGE__"

#define FMNativeFunctionArgsData @"nativeFunctionArgsData"
#define FMCallBackId @"callbackId"
#define FMJSFunctionArgsData @"jsFunctionArgsData"
#define FMMethod @"method"
#define FMObj @"obj"

static void FMParseObjCMethodName(NSString **objCMethodName,
                                  NSArray **arguments) {
  static NSRegularExpression *typeNameRegex;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSString *unusedPattern = @"(?:__unused|__attribute__\\(\\(unused\\)\\))";
    NSString *constPattern = @"(?:const)";
    NSString *nullablePattern =
    @"(?:__nullable|nullable|__attribute__\\(\\(nullable\\)\\))";
    NSString *nonnullPattern =
    @"(?:__nonnull|nonnull|__attribute__\\(\\(nonnull\\)\\))";
    NSString *annotationPattern = [NSString
                                   stringWithFormat:@"(?:(?:(%@)|%@|(%@)|(%@))\\s*)", unusedPattern,
                                   constPattern, nullablePattern, nonnullPattern];
    NSString *pattern = [NSString
                         stringWithFormat:
                         @"(?<=:)(\\s*\\(%1$@?(\\w+?)(?:\\s*(\\*)*)?%1$@?\\))?\\s*\\w+",
                         annotationPattern];
    typeNameRegex = [[NSRegularExpression alloc] initWithPattern:pattern
                                                         options:0
                                                           error:NULL];
  });
  
  NSString *methodName = *objCMethodName;
  NSRange methodRange = {0, methodName.length};
  NSMutableArray *args = [NSMutableArray array];
  [typeNameRegex
   enumerateMatchesInString:methodName
   options:0
   range:methodRange
   usingBlock:^(NSTextCheckingResult *result,
                __unused NSMatchingFlags flags,
                __unused BOOL *stop) {
     NSRange typeRange = [result rangeAtIndex:5];
     NSString *type =
     typeRange.length
     ? [methodName substringWithRange:typeRange]
     : @"id";
     [args addObject:type];
   }];
  *arguments = [args copy];
  
  methodName = [typeNameRegex stringByReplacingMatchesInString:methodName
                                                       options:0
                                                         range:methodRange
                                                  withTemplate:@""];
  
  methodName =
  [methodName stringByReplacingOccurrencesOfString:@"\n" withString:@""];
  methodName =
  [methodName stringByReplacingOccurrencesOfString:@" " withString:@""];
  
  if ([methodName hasSuffix:@";"]) {
    methodName = [methodName substringToIndex:methodName.length - 1];
  }
  
  *objCMethodName = methodName;
}

@interface FMJavascriptBridge () {
  NSMutableDictionary *_startupMessageQueue;
  NSBundle *_resourceBundle;
  NSMutableDictionary *_javascriptInterfaceMethods;
  NSMutableDictionary *_jsBridgeResponses;
  NSMutableArray *_callJSFunctionMessage;
  NSUInteger _uniqueId;
}
@property(nonatomic, strong) NSMutableDictionary *javascriptInterfaces;
@property(assign) id<FMWebViewJavascriptDelegate> delegate;
@property(assign) NSUInteger numRequestsLoading;
  
@end

@implementation FMJavascriptBridge
  
  static BOOL logging = NO;
  static NSUInteger logMaxLength = 500;
  
+ (void)enableLogging {
  logging = YES;
}
  
+ (void)setLogMaxLength:(NSUInteger)length {
  logMaxLength = length;
}
  
- (instancetype)initWithResourceBundle:(NSBundle *)bundle {
  if (self = [super init]) {
    _resourceBundle = bundle;
    _startupMessageQueue = [NSMutableDictionary dictionary];
    _jsBridgeResponses = [NSMutableDictionary dictionary];
    _callJSFunctionMessage = [NSMutableArray array];
    _uniqueId = 0;
  }
  return self;
}
  
- (void)fm_evaluateJavaScript:(NSString *)javaScriptString
            completionHandler:
(void (^)(id result, NSError *error))completionHandler {
  if (_startupMessageQueue) {
    [_startupMessageQueue setValue:[completionHandler copy]
                            forKey:javaScriptString];
  } else {
    [_delegate evaluateJavaScript:javaScriptString
                completionHandler:completionHandler];
  }
}
  
  
- (void)callFunctionOnObject:(NSString *)object
                      method:(NSString *)methodName
                        args:(NSArray *)args
                    response:(FMJSFunctonResponse) response {
  NSMutableDictionary *message = [@{FMObj: object, FMMethod:methodName, FMJSFunctionArgsData:args} mutableCopy];
  
  if (response) {
    NSString *callbackId = [NSString stringWithFormat:@"objc_cb_%@", @(++_uniqueId)];
    [_jsBridgeResponses setObject:response forKey:callbackId];
    [message setObject:callbackId forKey:FMCallBackId];
  }
  if (_callJSFunctionMessage) {
    [_callJSFunctionMessage addObject:message];
  } else {
    [self queueMessage:message];
  }
  
}
  
  
- (void)reset {
  _startupMessageQueue = _startupMessageQueue
  ? _startupMessageQueue
  : [NSMutableDictionary dictionary];
  _callJSFunctionMessage = _callJSFunctionMessage ? _callJSFunctionMessage : [NSMutableArray array];
}
  
- (void)addJavascriptInterface:(NSObject *)interface withName:(NSString *)name {
  if (!self.javascriptInterfaces) {
    self.javascriptInterfaces = [[NSMutableDictionary alloc] init];
  }
  [self.javascriptInterfaces setValue:interface forKey:name];
}
  
- (void)flushMessageQueue:(NSString *)messageQueueString {
  id messages = [self deserializeMessageJSON:messageQueueString];
  if (![messages isKindOfClass:[NSArray class]]) {
#if DEBUG
    NSLog(@"WebViewJavascriptBridge: WARNING: Invalid %@ received: %@",
          [messages class], messages);
#endif
    return;
  }
  for (NSDictionary *message in messages) {
    if (![message isKindOfClass:[NSDictionary class]]) {
#if DEBUG
      NSLog(@"WebViewJavascriptBridge: WARNING: Invalid %@ received: %@",
            [message class], message);
#endif
      continue;
    }
    [self log:@"FM" json:message];
    
    if (message[FMObj]) {
      [self callJavascriptInterface:message];
      continue;
    } else if (message[FMCallBackId]) {
      FMJSFunctonResponse jsResponse =  [_jsBridgeResponses objectForKey:message[FMCallBackId]];
      [_jsBridgeResponses removeObjectForKey:message[FMCallBackId]];
      jsResponse(message[FMNativeFunctionArgsData]);
    }
  }
}
  
- (NSString *)injectJavascript {
  NSBundle *bundle = _resourceBundle ? _resourceBundle : [NSBundle mainBundle];
  NSString *filePath =
  [bundle pathForResource:@"FMWebViewJavascriptBridge.js" ofType:@"txt"];
  NSString *content = [NSString stringWithContentsOfFile:filePath
                                                encoding:NSUTF8StringEncoding
                                                   error:nil];
  NSMutableArray *objs = [NSMutableArray array];
  NSMutableArray *methods = [NSMutableArray array];
  [self injectJavascriptInterfaces:objs methods:methods];
  NSString *jsObjs = [self serializeMessage:objs pretty:NO];
  NSString *jsMethods = [self serializeMessage:methods pretty:NO];
  NSString *js =
  [NSString stringWithFormat:@"%@(%@,%@);", content, jsObjs, jsMethods];
  return js;
}
  
- (BOOL)isCorrectProcotocolScheme:(NSURL *)url {
  if ([[url scheme] isEqualToString:FMCustomProtocolScheme]) {
    return YES;
  } else {
    return NO;
  }
}
  
- (BOOL)isCorrectHost:(NSURL *)url {
  if ([[url host] isEqualToString:FMQueueHasMessage]) {
    return YES;
  } else {
    return NO;
  }
}
  
- (void)logUnkownMessage:(NSURL *)url {
#if DEBUG
  NSLog(@"WebViewJavascriptBridge: WARNING: Received unknown "
        @"WebViewJavascriptBridge command %@://%@",
        FMCustomProtocolScheme, [url path]);
#endif
}
  
- (void)dispatchStartUpMessageQueue {
  if (_startupMessageQueue) {
    for (NSString *queuedMessage in _startupMessageQueue.allKeys) {
      [_delegate evaluateJavaScript:queuedMessage
                  completionHandler:_startupMessageQueue[queuedMessage]];
    }
    _startupMessageQueue = nil;
  }
  if (_callJSFunctionMessage) {
    for (NSDictionary *message in _callJSFunctionMessage) {
      [self queueMessage:message];
    }
    _callJSFunctionMessage = nil;
  }
}
  
- (NSString *)webViewJavascriptCheckCommand {
  return @"typeof WebViewJavascriptBridge == \'object\';";
}
  
- (NSString *)webViewJavascriptFetchQueyCommand {
  return @"WebViewJavascriptBridge.fetchQueue();";
}
  
#pragma mark - private
  
- (void)injectJavascriptInterfaces:(NSMutableArray *)objs
                           methods:(NSMutableArray *)objsMethods {
  for (id key in self.javascriptInterfaces) {
    NSObject *interface = [self.javascriptInterfaces objectForKey:key];
    [objs addObject:key];
    NSArray *methods = [self methods:interface key:key];
    [objsMethods addObject:methods];
  }
}
  
- (NSArray *)methods:(NSObject *)javascriptObject key:(NSString *)key {
  if (!javascriptObject.ocMethodsMapJsInterfaces) {
    NSMutableDictionary *methodsMap = [NSMutableDictionary dictionary];
    Class moduleClass = javascriptObject.class;
    unsigned int methodCount;
    Method *methods =
    class_copyMethodList(object_getClass(moduleClass), &methodCount);
    for (unsigned int i = 0; i < methodCount; i++) {
      Method method = methods[i];
      SEL selector = method_getName(method);
      if ([NSStringFromSelector(selector) hasPrefix:@"__fm_export__"]) {
        IMP imp = method_getImplementation(method);
        NSArray *entries = ((NSArray * (*)(id, SEL))imp)(moduleClass, selector);
        NSString *objcMethodName = entries[1];
        NSString *jsMethodName =
        ((NSString *)entries[0]).length > 0 ? entries[0] : objcMethodName;
        [methodsMap setValue:objcMethodName forKey:jsMethodName];
      }
    }
    javascriptObject.ocMethodsMapJsInterfaces = methodsMap;
    free(methods);
  }
  if (javascriptObject.ocMethodsMapJsInterfaces.count > 0) {
    if (!_javascriptInterfaceMethods) {
      _javascriptInterfaceMethods = [NSMutableDictionary dictionary];
    }
    [_javascriptInterfaceMethods
     setValue:javascriptObject.ocMethodsMapJsInterfaces
     forKey:key];
  }
  return javascriptObject.ocMethodsMapJsInterfaces.allKeys;
}
  
- (void)callJavascriptInterface:(NSDictionary *)message {
  id interface;
  if (message[FMObj]) {
    interface = self.javascriptInterfaces[message[FMObj]];
  }
  if (!interface) {
    [self raiseException:@"FMNoHandlerException"
                 message:[NSString stringWithFormat:
                          @"No handler for message from JS: %@",
                          message]];
    return;
  }
  NSString *jsMethod = message[FMMethod];
  NSString *objcMethod = _javascriptInterfaceMethods[message[FMObj]][jsMethod];
  if (!objcMethod) {
    [self raiseException:@"FMNoHandlerException"
                 message:[NSString stringWithFormat:
                          @"No handler for message from JS: %@",
                          message]];
    return;
  }
  NSArray *argMethodTypes = nil;
  FMParseObjCMethodName(&objcMethod, &argMethodTypes);
  SEL selector = NSSelectorFromString(objcMethod);
  NSMethodSignature *sig =
  [[interface class] instanceMethodSignatureForSelector:selector];
  NSInvocation *invoker = [NSInvocation invocationWithMethodSignature:sig];
  [invoker retainArguments];
  invoker.selector = selector;
  invoker.target = interface;
  id arg = message[FMNativeFunctionArgsData];
  if (sig.numberOfArguments > 4) {
    [self raiseException:@"FMNoHandlerException"
                 message:@"javascrip interface arguments error"];
    return;
  }
  
#define FM_CASE(_typeChar, _type, _typeSelector, i)                   \
case _typeChar: {                                                   \
if (arg && ![arg isKindOfClass:[NSNumber class]]) {               \
[self raiseException:@"args type" message:@"args type  error"]; \
return;                                                         \
}                                                                 \
_type argValue = [(NSNumber *)arg _typeSelector];                 \
[invoker setArgument:&argValue atIndex:i];                        \
break;                                                            \
}
  
  for (int i = 2; i < sig.numberOfArguments; i++) {
    const char *argType = [sig getArgumentTypeAtIndex:i];
    switch (argType[0]) {
      FM_CASE('c', char, charValue, i)
      FM_CASE('C', unsigned char, unsignedCharValue, i)
      FM_CASE('s', short, shortValue, i)
      FM_CASE('S', unsigned short, unsignedShortValue, i)
      FM_CASE('i', int, intValue, i)
      FM_CASE('I', unsigned int, unsignedIntValue, i)
      FM_CASE('l', long, longValue, i)
      FM_CASE('L', unsigned long, unsignedLongValue, i)
      FM_CASE('q', long long, longLongValue, i)
      FM_CASE('Q', unsigned long long, unsignedLongLongValue, i)
      FM_CASE('f', float, floatValue, i)
      FM_CASE('d', double, doubleValue, i)
      FM_CASE('B', BOOL, boolValue, i)
      case '@': {
#define FM_ARG_CASE(_type)                                                     \
([argMethodTypes[i - 2] isEqualToString:NSStringFromClass([_type class])] && \
(!arg || [arg isKindOfClass:[_type class]]))
        
        if (FM_ARG_CASE(NSArray) || FM_ARG_CASE(NSDictionary) ||
            FM_ARG_CASE(NSString) || FM_ARG_CASE(NSNumber)) {
          [invoker setArgument:&arg atIndex:i];
          continue;
        }
        if ([argMethodTypes[i - 2] isEqualToString:@"FMAsyResponse"]) {
          FMAsyResponse responseCallback = message[FMCallBackId] ?
          ^(id responseData) {
            if (responseData == nil) {
              responseData = [NSNull null];
            } else if ([responseData respondsToSelector:@selector(fm_jsonDicWithModel:)]) {
              responseData = [((id<FMJSONModelDelegate>)responseData) fm_jsonDicWithModel:responseData];
            }
            NSDictionary *msg = @{FMCallBackId: message[FMCallBackId], FMJSFunctionArgsData: responseData};
            [self queueMessage:msg];
          } : ^(id responseData) {
          };
          
          [invoker setArgument:&responseCallback atIndex:i];
          continue;
        }
        if (arg && ![arg isKindOfClass:[NSDictionary class]]) {
          [self raiseException:@"args type" message:@"args type  error"];
          return;
        }
        Class modelClass = NSClassFromString(argMethodTypes[i - 2]);
        id model = nil;
        if ([modelClass
             respondsToSelector:@selector(fm_modelWithDictionary:)]) {
          model = [(Class<FMJSONModelDelegate>)modelClass
                   fm_modelWithDictionary:arg];
        }
        if (model) {
          [invoker setArgument:&model atIndex:i];
        } else {
          [self log:[NSString stringWithFormat:@"%@ init error",
                     argMethodTypes[i - 2]]
               json:arg];
        }
        
      } break;
      default:
      [self raiseException:@"args type" message:@"args type  error"];
      return;
    }
  }
  [invoker invoke];
  if (message[FMCallBackId] && sig.methodReturnLength > 0) {
    id responseData = nil;
#define FM_RETUNR_CASE(_typeChar, _type) \
case _typeChar: {                      \
_type response;                      \
[invoker getReturnValue:&response];  \
responseData = @(response);          \
break;                               \
}
    
    const char *retType = [sig methodReturnType];
    switch (retType[0]) {
      FM_RETUNR_CASE('c', char)
      FM_RETUNR_CASE('C', unsigned char)
      FM_RETUNR_CASE('s', short)
      FM_RETUNR_CASE('S', unsigned short)
      FM_RETUNR_CASE('i', int)
      FM_RETUNR_CASE('I', unsigned int)
      FM_RETUNR_CASE('l', long)
      FM_RETUNR_CASE('L', unsigned long)
      FM_RETUNR_CASE('q', long long)
      FM_RETUNR_CASE('Q', unsigned long long)
      FM_RETUNR_CASE('f', float)
      FM_RETUNR_CASE('d', double)
      FM_RETUNR_CASE('B', BOOL)
      case '@': {
        void *response;
        [invoker getReturnValue:&response];
        responseData = (__bridge id)response;
        if ([responseData isKindOfClass:[NSArray class]] ||
            [responseData isKindOfClass:[NSDictionary class]] ||
            [responseData isKindOfClass:[NSString class]] ||
            [responseData isKindOfClass:[NSNumber class]]) {
        } else if ([responseData
                    respondsToSelector:@selector(fm_jsonDicWithModel:)]) {
          responseData = [(id<FMJSONModelDelegate>)responseData
                          fm_jsonDicWithModel:responseData];
        } else {
          responseData = [NSNull null];
          ;
        }
      }
    }
    NSDictionary *msg =
    @{FMCallBackId : message[FMCallBackId], FMJSFunctionArgsData : responseData};
    [self queueMessage:msg];
  }
}
  
- (void)queueMessage:(NSDictionary *)message {
  [self dispatchMessage:message];
}
  
- (void)dispatchMessage:(NSDictionary *)message {
  NSString *messageJSON = [self serializeMessage:message pretty:NO];
  [self log:@"SEND" json:messageJSON];
  messageJSON = [self filterJsonString:messageJSON];
  NSString *javascriptCommand = [NSString
                                 stringWithFormat:@"WebViewJavascriptBridge.handleMessageFromNative('%@');",
                                 messageJSON];
  [self log:@"SEND" json:javascriptCommand];
  if ([[NSThread currentThread] isMainThread]) {
    [self evaluateJavascript:javascriptCommand];
  } else {
    dispatch_sync(dispatch_get_main_queue(), ^{
      [self evaluateJavascript:javascriptCommand];
    });
  }
}
  
- (void)evaluateJavascript:(NSString *)javascriptCommand {
  [self.delegate evaluateJavaScript:javascriptCommand completionHandler:NULL];
}
  
- (NSString *)filterJsonString:(NSString *)messageJSON {
  messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\\"
                                                       withString:@"\\\\"];
  messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\""
                                                       withString:@"\\\""];
  messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\'"
                                                       withString:@"\\\'"];
  messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\n"
                                                       withString:@"\\n"];
  messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\r"
                                                       withString:@"\\r"];
  messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\f"
                                                       withString:@"\\f"];
  messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2028"
                                                       withString:@"\\u2028"];
  messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2029"
                                                       withString:@"\\u2029"];
  return messageJSON;
}
  
- (void)log:(NSString *)action json:(id)json {
#if DEBUG
  if (!logging) {
    return;
  }
  if (![json isKindOfClass:[NSString class]]) {
    json = [self serializeMessage:json pretty:YES];
  }
  if ([json length] > logMaxLength) {
    NSLog(@"FM %@: %@ [...]", action, [json substringToIndex:logMaxLength]);
  } else {
    NSLog(@"FM %@: %@", action, json);
  }
#endif
}
  
- (void)raiseException:(NSString *)name message:(NSString *)reason {
#if DEBUG
  NSException *exception =
  [[NSException alloc] initWithName:name reason:reason userInfo:nil];
  [exception raise];
#endif
}
  
- (NSString *)serializeMessage:(id)message pretty:(BOOL)pretty {
  return [[NSString alloc]
          initWithData:[NSJSONSerialization
                        dataWithJSONObject:message
                        options:(NSJSONWritingOptions)(
                                                       pretty
                                                       ? NSJSONWritingPrettyPrinted
                                                       : 0)
                        error:nil]
          encoding:NSUTF8StringEncoding];
}
  
- (NSArray *)deserializeMessageJSON:(NSString *)messageJSON {
  return [NSJSONSerialization
          JSONObjectWithData:[messageJSON dataUsingEncoding:NSUTF8StringEncoding]
          options:NSJSONReadingAllowFragments
          error:nil];
}
  
  @end
