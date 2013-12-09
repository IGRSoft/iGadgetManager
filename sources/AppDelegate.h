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
@class FileSystemNode;

@interface AppDelegate : NSObject <NSApplicationDelegate, MobileDeviceServerDelegate, NSTabViewDelegate, NSBrowserDelegate> {
	
	NSTimer*						m_ImageCaptureTimer;
	NSOperationQueue*				m_OperationQueue;

@private
	QTMovie*						m_QTMovie;
	int								m_iMoviePos;

	FileSystemNode					*_rootNode;
}

@property (assign) IBOutlet NSWindow *window;

@property (nonatomic, strong) MobileDeviceServer	*mobileDeviceServer;
@property (nonatomic, strong) IBOutlet DeviceInfo	*deviceInfo;
@property (nonatomic, strong) IBOutlet NSTabView	*tabView;
@property (nonatomic, strong) IBOutlet NSImageView	*imageCapture;
@property (nonatomic, strong) IBOutlet NSButton		*btnSaveVideo;
@property (nonatomic, strong) IBOutlet NSBrowser	*fileManager;
@property (nonatomic) bool							useRecordVideo;
@property (nonatomic) bool							isDeviceConnected;

- (IBAction)onTouchSaveVideo:(NSButton*)sender;

@end
