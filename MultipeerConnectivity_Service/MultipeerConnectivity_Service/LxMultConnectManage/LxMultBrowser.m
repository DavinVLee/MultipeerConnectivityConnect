//
//  LxMultBrowser.m
//  MultipeerConnectivity_Service
//
//  Created by 李翔 on 2017/3/30.
//  Copyright © 2017年 李翔. All rights reserved.
//

#import "LxMultBrowser.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface LxMultBrowser ()<MCNearbyServiceBrowserDelegate>

/**
 *负责发现设备
 **/
@property (strong, nonatomic) MCNearbyServiceBrowser *nearByBrowser;
/**
 *所有当前搜寻到的设备容器
 **/
@property (strong, nonatomic) NSMutableSet *avaiblePeeridsArray;

@end

@implementation LxMultBrowser

#pragma mark - CallFunction
- (void)startSearchDevicesWithPeerId:(MCPeerID *)peerId serviceType:(NSString *)serviceType
{
    if (self.nearByBrowser) {
        [self.nearByBrowser stopBrowsingForPeers];
        self.nearByBrowser.delegate = nil;
        self.nearByBrowser = nil;
    }
    MCNearbyServiceBrowser *browser = [[MCNearbyServiceBrowser alloc] initWithPeer:peerId serviceType:serviceType];
    browser.delegate = self;
    [browser startBrowsingForPeers];
    self.nearByBrowser = browser;
    
}

- (void)resetBrowser
{
    self.nearByBrowser.delegate = nil;
    self.searchBlock = nil;
    [self.nearByBrowser stopBrowsingForPeers];
    self.nearByBrowser = nil;
}

#pragma mark - McNearbyBrowserDelegate
// Found a nearby advertising peer.
- (void)browser:(MCNearbyServiceBrowser *)browser
      foundPeer:(MCPeerID *)peerID
      withDiscoveryInfo:(nullable NSDictionary<NSString *, NSString *> *)info
{
    [self.avaiblePeeridsArray addObject:peerID];
    if (self.searchBlock) {
        
       MCSession *session = self.searchBlock(peerID,NO);
        if (session) {
            [self.nearByBrowser invitePeer:peerID
                                 toSession:session
                               withContext:nil
                                   timeout:10];
        }
    }
    NSLog(@"搜到设备:%@",peerID.displayName);
}

// A nearby peer has stopped advertising.
- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    [self.avaiblePeeridsArray removeObject:peerID];
    if (self.searchBlock) {
        self.searchBlock(peerID,YES);
    }
    NSLog(@"失去设备设备:%@",peerID.displayName);
}

// Browsing did not start due to an error.
- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
    
}

#pragma mark - GetMethod
- (NSMutableSet *)avaiblePeeridsArray;
{
    if (!_avaiblePeeridsArray) {
        _avaiblePeeridsArray = [[NSMutableSet alloc] init];
    }
    return _avaiblePeeridsArray;
}

@end
