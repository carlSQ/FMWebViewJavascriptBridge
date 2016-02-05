# FMWebViewJavascriptBridge


# About

FMWebViewJavascriptBridge inspired by [WebViewJavascripBridge](http://git.elenet.me/arch.iOS/ELMWebViewJavascriptBridge/blob/developer/WebViewJavascripBridge.md) and [react native](https://github.com/facebook/react-native)

you can call native method like android( object.method() ), native communicate with js by json(if native return custom object ,you must
imp FMJSONModelDelegate ) ,for more information ,you can see demo;

### For Native

``` objective-c

[FMJavascriptBridge enableLogging];
_manager = [FMWebViewManager
webViewManagerWithWebView:self.webView
webViewDelegate:self
bridge:[[FMJavascriptBridge alloc]
initWithResourceBundle:nil]];

[_manager addJavascriptInterface:[[JavascripInterface alloc]
initWithController:self]
withName:@"JavascripInterface"];

// if you need evaluateJavaScript ,you can this
[_manager fm_evaluateJavaScript:@"testJS()"
              completionHandler:^(id result, NSError *error) {
  NSLog(@"js  ==== %@", result);
}];

```

#### if you need return custom object to js ,you need imp FMJSONModelDelegate, here use [Mantle](https://github.com/Mantle/Mantle) 

``` objective-c

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

### export native object to js, if you want export method of object to js, you must imp like this FM_REMAP_METHOD(push, void, push : (NSUInteger)one)

``` objective-c
@interface JavascripInterface : NSObject

- (instancetype)initWithController:(UIViewController *)viewController;

@end


@implementation JavascripInterface

- (instancetype)initWithController:(ViewController *)viewController {
  if (self = [super init]) {
    self.viewController = viewController;
  }
  return self;
}

FM_REMAP_METHOD(push, void, push : (NSUInteger)one) {
  [self.viewController.navigationController pushViewController:[ViewController new] animated:YES];
  NSLog(@"test push%ld", one);
}

FM_REMAP_METHOD(pop, void, pop : (NSString  *)testArray) {
  [self.viewController.navigationController popViewControllerAnimated:YES];
  NSLog(@"pop array %@", testArray);
}

FM_REMAP_METHOD(present, void, present) {
  [self.viewController presentViewController:[ViewController new] animated:YES completion:NULL];
}

FM_REMAP_METHOD(dismiss, void, dismiss) { [self.viewController dismissViewControllerAnimated:YES completion:NULL]; }

FM_REMAP_METHOD(testBOOL, BOOL, testBOOL : (BOOL)testBOOL) {
  if (testBOOL) {
    NSLog(@"xxxxxxxxx");
  } else {
    NSLog(@"yyyyyyyy");
  }
  return YES;
}

FM_REMAP_METHOD(testInt, int, testInt : (int)testInt) {
  NSLog(@"%d", testInt);
  return 168;
}

FM_REMAP_METHOD(testString, NSString *, testString : (NSString *)testString) {
  NSLog(@"==%@", testString);
  return @"168";
}

FM_REMAP_METHOD(testArray, NSArray *, testArray : (NSArray *)testArray) {
  NSLog(@"==%@", testArray);
  return @[ @"1", @"2" ];
}

FM_REMAP_METHOD(testDictionary, NSDictionary *, testDictionary
: (NSDictionary *)testDictionary) {
  NSLog(@"== %@", testDictionary);
  return @{ @"name" : @"carl" };
}

FM_REMAP_METHOD(testCustomObject, User *, testCustomObject : (User *)user) {
  NSLog(@"name = %@,  age = %@", user.name, user.age);
  return user;
}


@end

```

### For js




``` javascrip
<html>
<head>
<meta name="viewport" content="user-scalable=no, width=device-width, initial-scale=1.0, maximum-scale=1.0" />
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

  var push = document.getElementById('push')
  push.onclick = function() {
    JavascripInterface.push()
    return false
  }

  var pop = document.getElementById('pop')
  pop.onclick = function() {
      JavascripInterface.pop("one")
      return false
  }

  var setNavTitle = document.getElementById('setNavTitle')
  setNavTitle.onclick = function() {
    JavascripInterface.setNavTitle({"name" : "carl", age:"18"},function(responseData) {
      alert(responseData.name + responseData.age);
    })
    return false
  }

  var present = document.getElementById('present')
  present.onclick = function() {
    JavascripInterface.present()
    return false
  }

  var dismiss = document.getElementById('dismiss')
  dismiss.onclick = function() {
    JavascripInterface.dismiss()
    return false
  }

  var testBOOL = document.getElementById('testBOOL')

  testBOOL.onclick = function() {
    JavascripInterface.testBOOL(true,function(responseData) {
    alert(responseData);
    })
    return false
  }
  var testInt = document.getElementById('testInt')
  testInt.onclick = function() {
    JavascripInterface.testInt(1,function(responseData) {
      alert(responseData);
    })
    return false
  }
  var testString = document.getElementById('testString')
    testString.onclick = function() {
      JavascripInterface.testString('1',function(responseData) {
      alert(responseData);
    })
    return false
  }
  var testArray = document.getElementById('testArray')
  testArray.onclick = function() {
    JavascripInterface.testArray(['1','2'],function(responseData) {
      alert(responseData[0]+' '+responseData[1]);
    })
    return false
  }
  var testDictionary = document.getElementById('testDictionary')
  testDictionary.onclick = function() {
    JavascripInterface.testDictionary({'name':'carl'},function(responseData) {
      alert('name  ' + responseData.name);
    })
    return false
  }
  var testCustomObject = document.getElementById('testCustomObject')
  testCustomObject.onclick = function() {
    JavascripInterface.testCustomObject({"name" : "carl", 'age':"18"},function(responseData) {
      alert(responseData.name +'  '+responseData.age);
    })
    return false
  }
})

</script>
</head>
<body>
<center>
<h2>FMWebViewJavascriptBridge Demo</h2>
</center>
<br />
<center>
<p>clientInfo</p>
</center>
<center>
<p id="clientinfo"></p>
<center>
<br />
<center>
<p>JsCallNativeExample</p>
</center>
<center>
<p><a href="#" id="push">push</a></p>
<p><a href="#" id="pop">pop</a></p>
<p><a href="#" id="present">present</a></p>
<p><a href="#" id="dismiss">dismiss</a></p>
<p><a href="#" id="setNavTitle">setNavTitle</a></p>
<p><a href="http://www.baidu.com" id="setBack">baidu</a></p>
<p><a href="#" id="testInterfaceReturnData">testInterfaceReturnData</a></p>
<p><a href="#" id="testBOOL">testBOOL</a></p>
<p><a href="#" id="testInt">testInt</a></p>
<p><a href="#" id="testString">testString</a></p>
<p><a href="#" id="testArray">testArray</a></p>
<p><a href="#" id="testDictionary">testDictionary</a></p>
<p><a href="#" id="testCustomObject">testCustomObject</a></p>
<center> 
<br /> 
</center> 
</center> 
</center> 
</center>  
</body>
</html>
```

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

FMWebViewJavascriptBridge is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "FMWebViewJavascriptBridge"
```

## Author

carl, yuzhoulangzik@126.com

## License

FMWebViewJavascriptBridge is available under the MIT license. See the LICENSE file for more info.
