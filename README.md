
# About

FMWebViewJavascriptBridge inspired by [WebViewJavascripBridge](http://git.elenet.me/arch.iOS/ELMWebViewJavascriptBridge/blob/developer/WebViewJavascripBridge.md) and [react native](https://github.com/facebook/react-native)

you can call native method like android( object.method() ), native communicate with js by json(if native return custom object ,you must
imp FMJSONModelDelegate ) ,for more information ,you can see demo;

![image](http://7xs4ye.com1.z0.glb.clouddn.com/jsbridge.png)

#Usage

```ruby
pod "FMWebViewJavascriptBridge"
```

## Native JavascripInterface

Native JavascripInterface can export method by FM_REMAP_METHOD or FM_EXPORT_METHOD to js, those method can recevice less than two parameters， the one parameter is valid JSONObject( NSString, NSNumber, NSArray, NSDictionary, or NSNull), basic data type(int, float ....) or custom object that must implement FMJSONModelDelegate protocol, th another parameter is FMAsyResponse  (typedef void (^FMAsyResponse)(id responseData))  type that asynchronous return values to js, the parameter responseData is same as to the first parameter.those method also synchronize return values to js.


####Custom object

 must implement FMJSONModelDelegate protocol, here use [Mantle](https://github.com/Mantle/Mantle) 

``` objective-c

@interface User : MTLModel<MTLJSONSerializing, FMJSONModelDelegate>
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *age;
@end


@implementation User

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{ @"name" : @"name", @"age" : @"age" };
}
+ (id)fm_modelWithDictionary:(NSDictionary *)dictionary {
  return [MTLJSONAdapter modelOfClass:self.class
                   fromJSONDictionary:dictionary
                                error:nil];
}

- (NSDictionary *)fm_jsonDicWithModel:(id)model {
  return [MTLJSONAdapter JSONDictionaryFromModel:model error:nil];
}

@end

```


####Export method

``` objective-c

@implementation JavascripInterface
 
/* only receive the one parameter , JSONObject is valid JSONObject( NSString, NSNumber, NSArray, 

*NSDictionary, or NSNull), basic data type(int, float ....) or custom object that must implement
 
*FMJSONModelDelegate protocol 

*e.g. User  */

FM_REMAP_METHOD(testJSONObject, void , testJSONObject : (type )JSONObject) {
 // do something
}

// only receive th another parameter asynchronous return to js
FM_REMAP_METHOD(asynchronousResponse, void , asynchronousResponse:(FMAsyResponse)response) {
  // do something
  // asynchronous return to js
  response(JSONObject);
}

// recevice two
FM_REMAP_METHOD(testTwoParms, void, testJSONObject:(type )JSONObject asynchronousResponse: (FMAsyResponse)response) {

  // do something
  // asynchronous return to js
  response(JSONObject);
  
}

// synchronize return to js
FM_REMAP_METHOD(synchronizeResponse, type , synchronizeResponse:(type)JSONObject) {
  // do something
  // asynchronous return to js
  return ()type) object
}

@end

```

#### Init jsBridge and inject JavascripInterface object to js

``` objective-c

[FMJavascriptBridge enableLogging];
_manager = [FMWebViewManager
webViewManagerWithWebView:self.webView
webViewDelegate:self
bridge:[[FMJavascriptBridge alloc]
initWithResourceBundle:nil]];

[_manager addJavascriptInterface:[JavascripInterface new] withName:@"NativeObjectInJSInterface"];

// if you need evaluateJavaScript ,you can this
[_manager fm_evaluateJavaScript:@"testJS()"
              completionHandler:^(id result, NSError *error) {
  NSLog(@"js  ==== %@", result);
}];

```

### JS use native JavascripInterface object


``` javascrip
<script>

  function testJS() {
    var clientInfo = document.getElementById('clientinfo')
    clientInfo.innerHTML = 'show by native'
    return 'response'
  }
  
  function connectWebViewJavascriptBridge(callback) {
    if (window.WebViewJavascriptBridge) {
      callback(WebViewJavascriptBridge)
    } else {
        document.addEventListener('WebViewJavascriptBridgeInjectFinishedReady', function() {
          callback(WebViewJavascriptBridge)
      }, false)
    }
  }

connectWebViewJavascriptBridge(function(bridge) {

	NativeObjectInJSInterface.testJSONObject(value);
	
	NativeObjectInJSInterface.asynchronousResponse(function(responseData) {
                                                                  //do something
                                                                  });
    NativeObjectInJSInterface.testTwoParms(value,function(responseData) {
                                                                  //do something
                                                                  } );
                                                                  
   NativeObjectInJSInterface.synchronizeResponse(function(responseData) {
                                                                  //do something
                                                                  });
})
</script>
```



## Author

carl Shen

## License

FMWebViewJavascriptBridge is available under the MIT license. See the LICENSE file for more info.
