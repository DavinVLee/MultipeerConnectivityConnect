//
//  LxMultConnectManager.m
//  MultipeerConnectivity_Service
//
//  Created by 李翔 on 2017/3/29.
//  Copyright © 2017年 李翔. All rights reserved.
//

#import "LxMultConnectManager.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "LxMultBrowser.h"
#import "LxMultSession.h"
@interface LxMultConnectManager()<MCSessionDelegate,
                                  MCNearbyServiceAdvertiserDelegate
                                  >

/*****************************MultConnect相关******************************/
@property (strong, nonatomic) MCPeerID *myPeerID;//唯一标识
/**
 *会话管理（聊天室)
 **/
@property (strong, nonatomic) MCSession *mySession;
 /**
 *负责附近设备的邀请管理
 **/
@property (strong, nonatomic) MCNearbyServiceAdvertiser *nearByAdvertiser;
/**
 *负责附近设备的设备发现管理
 **/
@property (strong, nonatomic) LxMultBrowser *nearByBrowser;
/**
 *回调获取内容
 **/
@property (copy, nonatomic) ConnectManagerBlock receiveBlock;

/****************************容器等相关**********************/
/**
 *服务端包含所有可连接控制的peerid
 **/
@property (strong, nonatomic) NSMutableArray <NSString *>*peerIdsArray;

@property (strong, nonatomic) dispatch_queue_t sessionQueue;
@end

@implementation LxMultConnectManager
#pragma mark - GetMethod
- (instancetype)init
{
    if (self == [super init]) {
        _sessionQueue = dispatch_queue_create("sessionQueue", NULL);
    }
    return self;
}

- (NSMutableArray *)peerIdsArray
{
    if (!_peerIdsArray) {
        _peerIdsArray = [[NSMutableArray alloc] init];
    }
    return _peerIdsArray;
}

#pragma mark - CallFunction
- (void)setupPlatformType:(MC_PlatformType)type andPeerIDs:(NSArray *)peerIDs block:(ConnectManagerBlock)aBlock;
{
    self.receiveBlock = nil;
    self.receiveBlock = [aBlock copy];
    self.platformType = type;
    [self.peerIdsArray removeAllObjects];
    [self.peerIdsArray addObjectsFromArray:peerIDs];
    [self setupDefault];
}

- (void)sendMessage:(NSString *)str
{
    NSData *sendData = [str dataUsingEncoding:NSUTF8StringEncoding];
    
    [self.mySession sendData:sendData
                     toPeers:[self.mySession
                              connectedPeers]
                    withMode:MCSessionSendDataReliable
                       error:nil];
}

- (void)resetConnect
{
    self.myPeerID = nil;
    self.mySession.delegate = nil;
    [self.mySession disconnect];
    self.mySession =  nil;
    self.receiveBlock = nil;
    [self.nearByBrowser resetBrowser];
    self.nearByBrowser = nil;
    
    
}

#pragma mark - init
- (void)setupDefault
{
    self.myPeerID = [[MCPeerID alloc] initWithDisplayName:[self.peerIdsArray firstObject]];
    self.mySession = [[MCSession alloc] initWithPeer:self.myPeerID securityIdentity:nil encryptionPreference:MCEncryptionNone];
    self.mySession.delegate = self;

    //开始搜寻设备
    if (self.platformType == MC_PlatformService) {
        self.nearByBrowser = [[LxMultBrowser alloc] init];
        [self.nearByBrowser startSearchDevicesWithPeerId:self.myPeerID serviceType:@"chat"];
        __weak __typeof(self) weakSelf = self;
        self.nearByBrowser.searchBlock = ^MCSession *(MCPeerID *peerId, BOOL isLost){
            if (isLost) {
                
            }else
            {
                if ([weakSelf.peerIdsArray containsObject:peerId.displayName] && ![peerId.displayName isEqualToString:weakSelf.myPeerID.displayName]) {
                    return weakSelf.mySession;
                }
            }
            return nil;
        };
    }
    //开始附近广播
    self.nearByAdvertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.myPeerID
                                                              discoveryInfo:nil
                                                                serviceType:@"chat"];
    self.nearByAdvertiser.delegate = self;
    [self.nearByAdvertiser startAdvertisingPeer];
}
#pragma mark - NearbyAdvertiserDelegate
// Incoming invitation request.  Call the invitationHandler block with YES
// and a valid session to connect the inviting peer to the session.
- (void)            advertiser:(MCNearbyServiceAdvertiser *)advertiser
  didReceiveInvitationFromPeer:(MCPeerID *)peerID
                   withContext:(nullable NSData *)context
             invitationHandler:(void (^)(BOOL accept, MCSession * __nullable session))invitationHandler
{
    if (self.platformType == MC_PlatformClient) {//收到连接会话邀请，
        invitationHandler(YES,self.mySession);
    }
}


// Advertising did not start due to an error.
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error
{

}

#pragma mark - SessionDelegate
// Remote peer changed state.
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    NSLog(@"连接状态%ld,连接的绘画id%@",state,peerID.displayName);

    switch (state) {
        case MCSessionStateConnected:
        {
            /*for (int i = 0; i < NSNotFound; i ++) {
                [self sendMessage:@"fwefew"];
            }*/
        }
            break;
            case MCSessionStateConnecting:
        {
            
        }
            break;
            case MCSessionStateNotConnected:
        {
            
        }
            break;
        default:
            break;
    }
}

// Received data from remote peer.
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
     NSLog(@"data receiveddddd : %lu",(unsigned long)data.length);
    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (message.length > 0 && self.receiveBlock) {
        self.receiveBlock(message,peerID.displayName);
    }
}

// Received a byte stream from remote peer.
- (void)    session:(MCSession *)session
   didReceiveStream:(NSInputStream *)stream
           withName:(NSString *)streamName
           fromPeer:(MCPeerID *)peerID
{
      NSLog(@"did receive stream");
}

// Start receiving a resource from remote peer.
- (void)                    session:(MCSession *)session
  didStartReceivingResourceWithName:(NSString *)resourceName
                           fromPeer:(MCPeerID *)peerID
                       withProgress:(NSProgress *)progress
{
     NSLog(@"start receiving");
}

// Finished receiving a resource from remote peer and saved the content
// in a temporary location - the app is responsible for moving the file
// to a permanent location within its sandbox.
- (void)                    session:(MCSession *)session
 didFinishReceivingResourceWithName:(NSString *)resourceName
                           fromPeer:(MCPeerID *)peerID
                              atURL:(NSURL *)localURL
                          withError:(nullable NSError *)error
{
     NSLog(@"finish receiving resource");
}

@end
