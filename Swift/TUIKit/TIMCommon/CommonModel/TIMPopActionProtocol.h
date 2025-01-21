//
//  TIMPopActionProtocol.h
//  TIMCommon
//
//  Created by wyl on 2023/4/3.
//  Copyright © 2023 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TIMPopActionProtocol <NSObject>

- (void)onDelete:(nullable id)sender;

- (void)onCopyMsg:(nullable id)sender;

- (void)onRevoke:(nullable id)sender;

- (void)onReSend:(nullable id)sender;

- (void)onMulitSelect:(nullable id)sender;

- (void)onForward:(nullable id)sender;

- (void)onReply:(nullable id)sender;

- (void)onReference:(nullable id)sender;

@end

NS_ASSUME_NONNULL_END
