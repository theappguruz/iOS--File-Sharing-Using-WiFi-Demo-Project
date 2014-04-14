//
//  ViewController.m
//  FileShareDemo
//
//  Created by Krupa-iMac on 03/04/14.
//  Copyright (c) 2014 TheAppGuruz. All rights reserved.
//

#import "ViewController.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    marrFileData = [[NSMutableArray alloc] init];
    marrReceiveData = [[NSMutableArray alloc] init];
}

#pragma mark - Action Methods

- (IBAction)btnShareClicked:(id)sender
{
    if (!self.mySession) {
        [self setUpMultipeer];
    }
    [self showBrowserVC];
}

- (IBAction)btnSendClicked:(id)sender
{
    [self sendData];
}

#pragma mark - Wifi Sharing Methods

-(void)setUpMultipeer
{
    //  Setup peer ID
    self.myPeerID = [[MCPeerID alloc] initWithDisplayName:[UIDevice currentDevice].name];
    
    //  Setup session
    self.mySession = [[MCSession alloc] initWithPeer:self.myPeerID];
    self.mySession.delegate = self;
    
    //  Setup BrowserViewController
    self.browserVC = [[MCBrowserViewController alloc] initWithServiceType:@"chat" session:self.mySession];
    self.browserVC.delegate = self;
    
    //  Setup Advertiser
    self.advertiser = [[MCAdvertiserAssistant alloc] initWithServiceType:@"chat" discoveryInfo:nil session:self.mySession];
    [self.advertiser start];
}

-(void)showBrowserVC
{
    [self presentViewController:self.browserVC animated:YES completion:nil];
}

-(void)dismissBrowserVC
{
    [self.browserVC dismissViewControllerAnimated:YES completion:^(void){
        [self invokeAlertMethod:@"Connected Sucessfully" Body:@"Both device connected successfully." Delegate:nil];
    }];
}

-(void)stopWifiSharing:(BOOL)isClear
{
    if(isClear && self.mySession != nil){
        [self.mySession disconnect];
        
        [self.mySession setDelegate:nil];
        
        self.mySession = nil;
        
        self.browserVC = nil;
    }
}

#pragma marks MCBrowserViewControllerDelegate
// Notifies the delegate, when the user taps the done button
-(void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController
{
    [self dismissBrowserVC];
    [marrReceiveData removeAllObjects];
}

// Notifies delegate that the user taps the cancel button.
-(void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController
{
    [self dismissBrowserVC];
}

#pragma marks MCSessionDelegate
// Received data from remote peer
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NSLog(@"data receiveddddd : %lu",(unsigned long)data.length);
    
    if (data.length > 0) {
        if (data.length < 2) {
            noOfDataSend++;
            NSLog(@"noofdatasend : %d",noOfDataSend);
            NSLog(@"array count : %d",marrFileData.count);
            if (noOfDataSend < ([marrFileData count])) {
                [self.mySession sendData:[marrFileData objectAtIndex:noOfDataSend] toPeers:[self.mySession connectedPeers] withMode:MCSessionSendDataReliable error:nil];
            }else {
                [self.mySession sendData:[@"File Transfer Done" dataUsingEncoding:NSUTF8StringEncoding] toPeers:[self.mySession connectedPeers] withMode:MCSessionSendDataReliable error:nil];
            }
        } else {
            if ([[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] isEqualToString:@"File Transfer Done"]) {
                [self appendFileData];
            }else {
                [self.mySession sendData:[@"1" dataUsingEncoding:NSUTF8StringEncoding] toPeers:[self.mySession connectedPeers] withMode:MCSessionSendDataReliable error:nil];
                [marrReceiveData addObject:data];
            }
        }
    }
}

// Received a byte stream from remote peer
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    NSLog(@"did receive stream");
}

// Start receiving a resource from remote peer
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    NSLog(@"start receiving");
}

// Finished receiving a resource from remote peer and saved the content in a temporary location - the app is responsible for moving the file to a permanent location within its sandbox
- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    NSLog(@"finish receiving resource");
}

-(void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    NSLog(@"change state : %d",state);
}

#pragma mark - Other Methods

-(void)sendData
{
    [marrFileData removeAllObjects];
    
    NSData *sendData = UIImagePNGRepresentation([UIImage imageNamed:@"test2.PNG"]);
    NSUInteger length = [sendData length];
    NSUInteger chunkSize = 100 * 1024;
    NSUInteger offset = 0;
    do {
        NSUInteger thisChunkSize = length - offset > chunkSize ? chunkSize : length - offset;
        NSData* chunk = [NSData dataWithBytesNoCopy:(char *)[sendData bytes] + offset
                                             length:thisChunkSize
                                       freeWhenDone:NO];
        NSLog(@"chunk length : %lu",(unsigned long)chunk.length);
        
        [marrFileData addObject:[NSData dataWithData:chunk]];
        offset += thisChunkSize;
    } while (offset < length);
    
    noOfdata = [marrFileData count];
    noOfDataSend = 0;
    
    if ([marrFileData count] > 0) {
        [self.mySession sendData:[marrFileData objectAtIndex:noOfDataSend] toPeers:[self.mySession connectedPeers] withMode:MCSessionSendDataReliable error:nil];
    }
}

-(void)appendFileData
{
    NSMutableData *fileData = [NSMutableData data];
    
    for (int i = 0; i < [marrReceiveData count]; i++) {
        [fileData appendData:[marrReceiveData objectAtIndex:i]];
    }
    
    [fileData writeToFile:[NSString stringWithFormat:@"%@/Image.png", [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]] atomically:YES];
    
    UIImageWriteToSavedPhotosAlbum([UIImage imageWithData:fileData], self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (!error) {
        [self invokeAlertMethod:@"Successfully Sent" Body:@"Image shared successfully and saved in Cameraroll." Delegate:nil];
    }
}

- (void)invokeAlertMethod:(NSString *)strTitle Body:(NSString *)strBody Delegate:(id)delegate
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strTitle
                                                    message:strBody
                                                   delegate:delegate
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    alert = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
