//
//  ViewController.h
//  FileShareDemo
//
//  Created by Krupa-iMac on 03/04/14.
//  Copyright (c) 2014 TheAppGuruz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface ViewController : UIViewController <MCBrowserViewControllerDelegate, MCSessionDelegate>
{
    __block BOOL _isSendData;
    NSMutableArray *marrFileData, *marrReceiveData;
    int noOfdata, noOfDataSend;
}

@property (nonatomic, strong) MCBrowserViewController *browserVC;
@property (nonatomic, strong) MCAdvertiserAssistant *advertiser;
@property (nonatomic, strong) MCSession *mySession;
@property (nonatomic, strong) MCPeerID *myPeerID;

@end
