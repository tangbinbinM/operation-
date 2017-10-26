//
//  TBBAppModel.h
//  多图片下载
//
//  Created by YiGuo on 2017/10/26.
//  Copyright © 2017年 tbb. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TBBAppModel : NSObject
/** 图标 */
@property (nonatomic, strong) NSString *icon;
/** 下载量 */
@property (nonatomic, strong) NSString *download;
/** 名字 */
@property (nonatomic, strong) NSString *name;

+ (instancetype)appWithDict:(NSDictionary *)dict;
@end
