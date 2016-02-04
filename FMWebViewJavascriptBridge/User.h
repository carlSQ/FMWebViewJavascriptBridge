//
//  User.h
//  ELMWebViewJavascripBridge
//
//  Created by sq on 15/10/29.
//  Copyright © 2015年 sq. All rights reserved.
//

#import "FMJSONModelDelegate.h"
#import "Mantle.h"
@interface User : MTLModel<MTLJSONSerializing, FMJSONModelDelegate>
@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) NSString *age;
@end
