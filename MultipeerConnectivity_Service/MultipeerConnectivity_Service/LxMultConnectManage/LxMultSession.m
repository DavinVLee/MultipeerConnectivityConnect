//
//  LxMultSession.m
//  MultipeerConnectivity_Service
//
//  Created by 李翔 on 2017/3/30.
//  Copyright © 2017年 李翔. All rights reserved.
//

#import "LxMultSession.h"

@implementation LxMultSession


- (NSString *)description
{
    return [NSString stringWithFormat:@"displayname:%@\n state = %ld",self.myPeerID.displayName,self.state];
}

@end
