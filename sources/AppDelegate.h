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
#if !__has_feature(objc_arc)
@class QTMovie;
#endif

@interface AppDelegate : NSObject <NSApplicationDelegate, MobileDeviceServerDelegate, NSTabViewDelegate> {
	
	NSMutableDictionary*			m_DevicesDict;
	NSTimer*						m_ImageCaptureTimer;
	NSOperationQueue*				m_OperationQueue;
#if !__has_feature(objc_arc)
	QTMovie*						movie;
	int								pos;
#endif
}

@property (assign) IBOutlet NSWindow *window;

@property (nonatomic, strong) MobileDeviceServer	*mobileDeviceServer;
@property (nonatomic, strong) IBOutlet DeviceInfo	*deviceInfo;
@property (nonatomic, strong) IBOutlet NSTabView	*tabView;
@property (nonatomic, strong) IBOutlet NSImageView	*imageCapture;

@end
