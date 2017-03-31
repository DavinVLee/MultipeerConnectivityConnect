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
 *会话管理（聊天室)客户端使用，
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
/**
 *服务端peerID,当客户端失去与服务端的连接时，打开广告，断开当前连接
 **/
@property (strong, nonatomic) MCPeerID *serverId;

/****************************容器等相关**********************/
/**
 *服务端包含所有可连接控制的peerid
 **/
@property (strong, nonatomic) NSMutableArray <NSString *>*peerIdsArray;

@property (strong, nonatomic) dispatch_queue_t sessionQueue;
@property (strong, nonatomic) NSMutableArray  <LxMultSession *>*sessionArray;
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

- (NSMutableArray<LxMultSession *>*)sessionArray
{
    if (!_sessionArray) {
        _sessionArray = [[NSMutableArray alloc] init];
    }
    return _sessionArray;
}

- (LxMultSession *)getNewSession
{
    LxMultSession *session = [[LxMultSession alloc] initWithPeer:self.myPeerID
                                                securityIdentity:nil
                                            encryptionPreference:MCEncryptionNone];
    session.delegate = self;
    [self.sessionArray addObject:session];
    return session;
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
    if (self.platformType == MC_PlatformService) {//服务端向所有客户端发送消息
       /* [self.mySession sendData:sendData
                         toPeers:[self.mySession
                                  connectedPeers]
                        withMode:MCSessionSendDataReliable
                           error:nil];*/
        for (LxMultSession *session in self.sessionArray) {
            [session sendData:sendData
                      toPeers:[session connectedPeers]
                     withMode:MCSessionSendDataReliable
                        error:nil];
        }
    }else if(self.serverId)
    {
        [self.mySession sendData:sendData//客户端只向服务端发送消息
                         toPeers:@[self.serverId]
                        withMode:MCSessionSendDataReliable
                           error:nil];
    }
    
    
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
    for (LxMultSession *session in self.sessionArray) {
        session.delegate = nil;
        [session disconnect];
    }
    [self.sessionArray removeAllObjects];
    
    
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
                    return [weakSelf getNewSession];
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
        NSLog(@"收到会话邀请");
        [self.mySession disconnect];
        self.mySession.delegate = nil;
        self.mySession = nil;
        self.mySession = [[MCSession alloc] initWithPeer:self.myPeerID
                                        securityIdentity:nil
                                    encryptionPreference:MCEncryptionNone];
        self.mySession.delegate = self;
        [self.nearByAdvertiser stopAdvertisingPeer];
        self.serverId = peerID;
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

        }
            break;
            case MCSessionStateConnecting:
        {
            
        }
            break;
        case MCSessionStateNotConnected:
        {
            if (self.platformType == MC_PlatformClient && [peerID.displayName isEqualToString:self.serverId.displayName]) {//当学生失去与老师连接时，不论任何情况，停止连接并重新由老师发起邀请
                self.mySession.delegate = nil;
                [self.mySession disconnect];
                [self.nearByAdvertiser startAdvertisingPeer];
            }else if (self.platformType == MC_PlatformService)
            {
                LxMultSession *tempSession = (LxMultSession *)session;
                tempSession.delegate = nil;
                [tempSession disconnect];
                [self.sessionArray removeObject:tempSession];
            }
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
