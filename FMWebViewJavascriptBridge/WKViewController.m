//
//  WKViewController.m
//  ELMWebViewJavascripBridge
//
//  Created by sq on 16/1/21.
//  Copyright © 2016年 sq. All rights reserved.
//



#import "WKViewController.h"
#import "FMWKWebViewBridge.h"
#import "JavascripInterface.h"
#import "TestJavaScripInterface.h"

@interface WKViewController ()

@property(nonatomic, strong)FMWKWebViewBridge *webViewBridge;

@end

@implementation WKViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"refresh" style:UIBarButtonItemStylePlain target:self action:@selector(loadExamplePage)];
  self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
  [self.view addSubview:self.webView];
  _webViewBridge = [FMWKWebViewBridge wkwebViewBridge:self.webView];
  JavascripInterface *interface = [[JavascripInterface alloc]initWithController:self];
  [_webViewBridge addJavascriptInterface:[JavascripInterface new] withName:@"JavascripInterface"];
  [_webViewBridge addJavascriptInterface:[TestJavaScripInterface new] withName:@"TestInterface"];
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
