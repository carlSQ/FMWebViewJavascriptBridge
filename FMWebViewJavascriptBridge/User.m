//
//  User.m
//  ELMWebViewJavascripBridge
//
//  Created by sq on 15/10/29.
//  Copyright © 2015年 sq. All rights reserved.
//

#import "User.h"

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
