//
//  JavascripInterface.m
//  ELMWebViewJavascripBridge
//
//  Created by sq on 15/9/1.
//  Copyright (c) 2015年 sq. All rights reserved.
//

#import "JavascripInterface.h"
#import "ViewController.h"
@interface JavascripInterface ()
@property(nonatomic, weak) ViewController *viewController;
@end

@implementation JavascripInterface

- (instancetype)initWithController:(ViewController *)viewController {
  if (self = [super init]) {
    self.viewController = viewController;
  }
  return self;
}
FM_REMAP_METHOD(push, void, push : (NSUInteger)one) {
  [self.viewController.navigationController
      pushViewController:[ViewController new]
                animated:YES];
  NSLog(@"test push%ld", (unsigned long)one);
}

FM_REMAP_METHOD(pop, void, pop : (NSString *)testArray) {
  [self.viewController.navigationController popViewControllerAnimated:YES];
  NSLog(@"pop array %@", testArray);
}

FM_REMAP_METHOD(present, void, present) {
  [self.viewController presentViewController:[ViewController new]
                                    animated:YES
                                  completion:NULL];
}

FM_REMAP_METHOD(dismiss, void, dismiss) {
  [self.viewController dismissViewControllerAnimated:YES completion:NULL];
}

FM_REMAP_METHOD(setNavTitle, void, setNavTitle
                : (User *)user response
                : (FMAsyResponse)response) {
  self.viewController.title = user.name;
  response(user);
}

FM_REMAP_METHOD(setBack, void, setBack) {
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  [button setTitle:@"back" forState:UIControlStateNormal];
  [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  button.frame = CGRectMake(0, 0, 60, 44);
  [button addTarget:self
                action:@selector(back)
      forControlEvents:UIControlEventTouchUpInside];
  self.viewController.navigationItem.leftBarButtonItem =
      [[UIBarButtonItem alloc] initWithCustomView:button];
}
FM_REMAP_METHOD(testInterfaceReturnData, NSString *, testInterfaceReturnData
                : (NSDictionary *)dictionary) {
  NSLog(@"test interface return data %@", dictionary);
  //  return @[ @"returnData", @"test interface return data" ];
  User *user = [User new];
  user.name = @"ELE";
  user.age = @"8";
  return @"8";
}

FM_REMAP_METHOD(testBOOL, BOOL, testBOOL : (BOOL)testBOOL) {
  if (testBOOL) {
    NSLog(@"TEST IS YES");
  } else {
    NSLog(@"TEST IS NO");
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

- (void)back {
  if ([self.viewController.webView canGoBack]) {
    [self.viewController.webView goBack];
  } else {
    [self loadExamplePage:self.viewController.webView];
    self.viewController.navigationItem.leftBarButtonItem = nil;
  }
}

- (void)loadExamplePage:(UIWebView *)webView {
  NSString *htmlPath =
      [[NSBundle mainBundle] pathForResource:@"Test" ofType:@"html"];
  NSString *appHtml = [NSString stringWithContentsOfFile:htmlPath
                                                encoding:NSUTF8StringEncoding
                                                   error:nil];
  NSURL *baseURL = [NSURL fileURLWithPath:htmlPath];
  [webView loadHTMLString:appHtml baseURL:baseURL];
}
@end
