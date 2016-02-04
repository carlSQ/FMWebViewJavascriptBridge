//
//  FMJSONModelDelegate.h
//  Pods
//
//  Created by carl on 16/2/3.
//
//

#import <Foundation/Foundation.h>

@protocol FMJSONModelDelegate<NSObject>
@required
/**
 *
 *  dic to model, you must imp, native communicate with js by json
 *
 *  @param dictionary
 *
 *  @return model
 */
+ (id)fm_modelWithDictionary:(NSDictionary *)dictionary;

/**
 *  dic to json
 *
 *  @param model
 *
 *  @return dic
 */
- (NSDictionary *)fm_jsonDicWithModel:(id)model;
@end
