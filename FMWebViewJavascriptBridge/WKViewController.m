//
//  WKViewController.m
//  ELMWebViewJavascripBridge
//
//  Created by sq on 16/1/21.
//  Copyright © 2016年 sq. All rights reserved.
//

#import "FMJavascriptBridge.h"
#import "FMWKWebViewManager.h"
#import "JavascripInterface.h"
#import "WKViewController.h"

@interface WKViewController ()<WKNavigationDelegate>
@property(nonatomic, strong) FMWKWebViewManager *manager;
@end

@implementation WKViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"refresh" style:UIBarButtonItemStylePlain target:self action:@selector(loadExamplePage)];
  self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
  [self.view addSubview:self.webView];
  [FMJavascriptBridge enableLogging];

  _manager = [FMWKWebViewManager
      webViewManagerWithWebView:self.webView
                webViewDelegate:self
                         bridge:[[FMJavascriptBridge alloc]
                                    initWithResourceBundle:[NSBundle
                                                               mainBundle]]];

  [_manager addJavascriptInterface:[[JavascripInterface alloc]
                                       initWithController:self]
                          withName:@"JavascripInterface"];

  [_manager fm_evaluateJavaScript:@"testJS()"
                completionHandler:^(id result, NSError *error) {
                  NSLog(@"js  ==== %@", result);
                }];
  [_manager callFunctionOnObject:@"testObj" method:@"testMethod" args:@[@"carlShen", @{@"name":@"carlShen"}] response:^(id responseData) {
    NSLog(@"call js return %@",responseData);
  }];
  [self loadExamplePage];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)loadExamplePage{
  NSString *htmlPath =
      [[NSBundle mainBundle] pathForResource:@"Test" ofType:@"html"];
  NSString *appHtml = [NSString stringWithContentsOfFile:htmlPath
                                                encoding:NSUTF8StringEncoding
                                                   error:nil];
  NSURL *baseURL = [NSURL fileURLWithPath:htmlPath];
  [self.webView loadHTMLString:appHtml baseURL:baseURL];
}

@end
