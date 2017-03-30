//
//  LxMultBrowser.h
//  MultipeerConnectivity_Service
//
//  Created by 李翔 on 2017/3/30.
//  Copyright © 2017年 李翔. All rights reserved.
//

#import <Foundation/Foundation.h>
@class MCPeerID;
@class MCSession;

typedef MCSession *(^BrowserBlock)(MCPeerID *peerId,BOOL isLost);
@interface LxMultBrowser : NSObject
/**
 *实时回调搜索信息
 **/
@property (copy, nonatomic) BrowserBlock searchBlock;
/**
 *开始搜索附近设备,会在每次发起是清空上一次的搜寻管理
 * @param peerId 发起搜寻的自身设备id
 * @param serviceType 发起搜寻的类型，必须同类型的搜寻才能互相发现
 **/
- (void)startSearchDevicesWithPeerId:(MCPeerID *)peerId serviceType:(NSString *)serviceType;

@end
