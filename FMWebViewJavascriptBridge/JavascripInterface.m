//
//  JavascripInterface.m
//  ELMWebViewJavascripBridge
//
//  Created by sq on 15/9/1.
//  Copyright (c) 2015年 sq. All rights reserved.
//

#import "JavascripInterface.h"
#import "NSObject+FMAnnotation.h"


@interface JavascripInterface ()
@property(nonatomic, weak) WKViewController *viewController;
@end

@implementation JavascripInterface

- (instancetype)initWithController:(WKViewController *)viewController {
  if (self = [super init]) {
    self.viewController = viewController;
  }
  return self;
}

FM_EXPORT_METHOD(@selector(push:))
- (void)push:(NSUInteger)one {
  [self.viewController.navigationController
      pushViewController:[WKViewController new]
                animated:YES];
  NSLog(@"test push%ld", (unsigned long)one);
}

FM_EXPORT_METHOD(@selector(pop:))
- (void)pop:(NSString *)testArray {
  [self.viewController.navigationController popViewControllerAnimated:YES];
  NSLog(@"pop array %@", testArray);
}

FM_EXPORT_METHOD(@selector(present))
- (void)present {
  [self.viewController presentViewController:[WKViewController new]
                                    animated:YES
                                  completion:NULL];
}

FM_EXPORT_METHOD(@selector(dismiss))
- (void)dismiss {
  [self.viewController dismissViewControllerAnimated:YES completion:NULL];
}

FM_EXPORT_METHOD(@selector(setNavTitle:response:))
- (void)setNavTitle:(NSDictionary *)userInfo response:(FMCallBack)callBack {
  self.viewController.title = userInfo[@"name"];
}

FM_EXPORT_METHOD(@selector(setBack))
- (void)setBack {
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

- (void)back {
  if ([self.viewController.webView canGoBack]) {
    [self.viewController.webView goBack];
  } else {
    [self loadExamplePage:self.viewController.webView];
    self.viewController.navigationItem.leftBarButtonItem = nil;
  }
}

- (void)loadExamplePage:(WKWebView *)webView {
  NSString *htmlPath =
      [[NSBundle mainBundle] pathForResource:@"Test" ofType:@"html"];
  NSString *appHtml = [NSString stringWithContentsOfFile:htmlPath
                                                encoding:NSUTF8StringEncoding
                                                   error:nil];
  NSURL *baseURL = [NSURL fileURLWithPath:htmlPath];
  [webView loadHTMLString:appHtml baseURL:baseURL];
}
@end
