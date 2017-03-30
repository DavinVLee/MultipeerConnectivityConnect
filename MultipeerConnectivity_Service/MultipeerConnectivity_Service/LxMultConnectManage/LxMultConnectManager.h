//
//  LxMultConnectManager.h
//  MultipeerConnectivity_Service
//
//  Created by 李翔 on 2017/3/29.
//  Copyright © 2017年 李翔. All rights reserved.
//

#import <Foundation/Foundation.h>
#define kAdvertiseType_Service @"service"
#define kAdvertiseType_Client @"client"
typedef NS_ENUM(NSInteger,MC_PlatformType)
{
    MC_PlatformClient,
    MC_PlatformService,
};
typedef void(^ConnectManagerBlock)(NSString *receiveMessage,NSString *peerId);
@interface LxMultConnectManager : NSObject
/**
 *连接类型
 **/
@property (assign, nonatomic)  MC_PlatformType platformType;
/**
 *获取实例方法
 * @param type   类型，分为服务端和客户端
 * @param peerIDs 唯一标识集合，其中第一个为自身标识，主要用于海伦课堂控制，所以直接定义死每个设备的标识
 **/

- (void)setupPlatformType:(MC_PlatformType)type andPeerIDs:(NSArray *)peerIDs block:(ConnectManagerBlock)aBlock;

/**
 *发送消息，暂时只有服务端和客户端的对发，，服务端默认发送所有已连接的客户端
 **/
- (void)sendMessage:(NSString *)str;

@end
