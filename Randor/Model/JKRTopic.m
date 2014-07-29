//
//  JKRTopic.m
//  Randor
//
//  Created by Jack on 29/7/14.
//  Copyright (c) 2014 Xu Xinyuan. All rights reserved.
//

#import "JKRTopic.h"

@implementation JKRTopic
- (id)initWithName:(NSString *)name
{
    if (self) {
        self.topicName = name;
        self.items = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder;
{
    [coder encodeObject:self.items forKey:@"items"];
    [coder encodeObject:self.topicName forKey:@"topicName"];
}

- (id)initWithCoder:(NSCoder *)coder;
{
    self = [[JKRTopic alloc] init];
    if (self != nil)
    {
        self.topicName = [coder decodeObjectForKey:@"topicName"];
        self.items = [coder decodeObjectForKey:@"items"];
    }
    return self;
}
@end
