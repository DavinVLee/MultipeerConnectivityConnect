//
//  LxMultSession.h
//  MultipeerConnectivity_Service
//
//  Created by 李翔 on 2017/3/30.
//  Copyright © 2017年 李翔. All rights reserved.
//

#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface LxMultSession : MCSession
/**
 *失去连接后重连次数,在连接成功后重置
 **/
@property (assign, nonatomic) NSInteger reconnectCount;
/**
 *是否需要重连,考虑到在释放disconnect时重复调用重连，赋值则不进行重连
 **/
@property (assign, nonatomic) BOOL notReconnect;
/**
 *会话的连接状态
 **/
@property (assign, nonatomic) MCSessionState state;
/**
 *连接客户端的唯一标识id
 **/
@property (copy, nonatomic) NSString *peerId;
@end
