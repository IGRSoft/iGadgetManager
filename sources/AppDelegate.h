//
//  AppDelegate.h
//  iGadgetManager
//
//  Created by Vitalii Parovishnyk on 12/30/12.
//  Copyright (c) 2012 IGR Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MobileDeviceServer.h"

@class DeviceInfo;
@class QTMovie;

@interface AppDelegate : NSObject <NSApplicationDelegate, MobileDeviceServerDelegate, NSTabViewDelegate> {
	
	NSMutableDictionary*			m_DevicesDict;
	NSTimer*						m_ImageCaptureTimer;
	NSOperationQueue*				m_OperationQueue;

	QTMovie*						movie;
	int								pos;
}

@property (assign) IBOutlet NSWindow *window;

@property (nonatomic, strong) MobileDeviceServer	*mobileDeviceServer;
@property (nonatomic, strong) IBOutlet DeviceInfo	*deviceInfo;
@property (nonatomic, strong) IBOutlet NSTabView	*tabView;
@property (nonatomic, strong) IBOutlet NSImageView	*imageCapture;
@property (nonatomic, strong) IBOutlet NSButton		*btnSaveVideo;
@property (nonatomic) bool useRecordVideo;

- (IBAction)onTouchSaveVideo:(NSButton*)sender;

@end
