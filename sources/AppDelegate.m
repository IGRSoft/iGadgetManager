//
//  AppDelegate.m
//  iGadgetManager
//
//  Created by Vitalii Parovishnyk on 12/30/12.
//  Copyright (c) 2012 IGR Software. All rights reserved.
//

#import "AppDelegate.h"
#import "DeviceInfo.h"
#import "Helper.h"

#import <QTKit/QTKit.h>

@interface AppDelegate (Private)

@end

#define FPS 24
#define MOVIE_FILE_NAME @"/Users/Shared/iGadget_Manager_Movie.mov"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	m_OperationQueue = [[NSOperationQueue alloc] init];
	
	m_DevicesDict = [[NSMutableDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Devices" ofType:@"plist"]];
	
	self.mobileDeviceServer = [[MobileDeviceServer alloc] init];
	[self.mobileDeviceServer setDelegate:self];
	
	m_ImageCaptureTimer = nil;
	
	self.useRecordVideo = false;
	
	if (![Helper isVideoRecordSupported]) {
		[self.btnSaveVideo setEnabled:NO];
	}
}

- (void)newDeviceDetected:(NSString*)connectedDevice
{
	DBNSLog(@"Device: %@ is connected", connectedDevice);
	
	if (m_DevicesDict && [m_DevicesDict count] > 0)
	{		
		[self.deviceInfo setupWithMobileDeviceServer:self.mobileDeviceServer
										   withPlist:m_DevicesDict];
		
		[self.deviceInfo updateViews];
	}
}

- (void)deviceRemoved
{
	DBNSLog(@"Device is disconnected");
	[m_OperationQueue cancelAllOperations];
}

- (void)updateAppList
{
	[m_OperationQueue addOperationWithBlock:^{
		[self.deviceInfo updateAppList];
	}];
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	int tabSelection = [[tabViewItem identifier] intValue];
	if (tabSelection == 3)
	{
		pos = 0;

		[self.mobileDeviceServer createScrenshotService];
		m_ImageCaptureTimer = [NSTimer scheduledTimerWithTimeInterval:0.001
															target:self
														  selector:@selector(handleImageCaptureTimerTimer:)
														  userInfo:nil
														   repeats:YES];
	}
	else
	{
		if (movie) {
			[movie stop];
			movie = nil;
			pos = 0;
		}
		
		[m_ImageCaptureTimer invalidate];
		m_ImageCaptureTimer = nil;
	}
}

- (void)handleImageCaptureTimerTimer:(NSTimer *)theTimer
{
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(queue, ^{
		dispatch_async(dispatch_get_main_queue(), ^{
			NSImage *img = [self.mobileDeviceServer takeScreenshot];
			if (img)
			{
				[_imageCapture setImage:img];

				if (_useRecordVideo) {
					NSError *error = nil;
					if (!movie) {
						NSFileManager *fm = [NSFileManager defaultManager];
						if ([fm fileExistsAtPath:MOVIE_FILE_NAME isDirectory:nil]) {
							[fm removeItemAtPath:MOVIE_FILE_NAME error:&error];
						}
						
						movie = [[QTMovie alloc] initToWritableFile:MOVIE_FILE_NAME error:&error];
						if (error) {
							NSLog(@"Could not create QTMovie: %@", [error localizedDescription]);
							return;
						}
						[movie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
					}
					
					[movie addImage:img
						forDuration:QTMakeTime(pos++, FPS)
					 withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:@"jpeg", QTAddImageCodecType,
									 [NSNumber numberWithInt:codecHighQuality], QTAddImageCodecQuality, nil]];
					
					[movie updateMovieFile];
				}
			}
		});
	});
		
}

#pragma mark - window delegates

// ask to save changes if dirty
- (BOOL)windowShouldClose:(id)sender
{
#pragma unused(sender)
	
    return YES;
}

#pragma mark - application delegates

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	[m_OperationQueue cancelAllOperations];
#pragma unused(sender)
	
    return NSTerminateNow;
}

// split when window is closed
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
#pragma unused(sender)
	
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)notification { }

- (IBAction)onTouchSaveVideo:(NSButton*)sender
{
	self.useRecordVideo = sender.state;
}
@end
