//
//  NSObject+Extension.m
//  TUIVideoSeat
//
//  Created by WesleyLei on 2022/9/23.
//  Copyright © 2022 Tencent. All rights reserved.
//

#import "NSObject+Extension.h"
@implementation NSObject (Extension)

+ (void)load {
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([self respondsToSelector:@selector(swiftLoad)]) {
        [self performSelector:@selector(swiftLoad)];
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
#pragma clang diagnostic ignored "-Wundeclared-selector"
+ (void)initialize {
    if ([self respondsToSelector:@selector(swiftInitialize)]) {
        [self performSelector:@selector(swiftInitialize)];
    }
}
#pragma clang diagnostic pop

@end
