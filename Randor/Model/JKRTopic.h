//
//  JKRTopic.h
//  Randor
//
//  Created by Jack on 29/7/14.
//  Copyright (c) 2014 Xu Xinyuan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JKRTopic : NSObject<NSCoding>
@property(nonatomic, retain) NSString *topicName;
@property(nonatomic, retain) NSMutableArray *items;
- (id)initWithName:(NSString *)name;
@end
