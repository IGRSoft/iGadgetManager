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
#import "FileSystemItem.h"

#import <QTKit/QTKit.h>

@interface AppDelegate (Private)

@end

#define FPS 24
#define MOVIE_FILE_NAME @"/Users/Shared/iGadget_Manager_Movie.mov"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	m_OperationQueue = [[NSOperationQueue alloc] init];
	
	self.mobileDeviceServer = [[MobileDeviceServer alloc] init];
	[self.mobileDeviceServer setDelegate:self];
	
	m_ImageCaptureTimer = nil;
	self.isDeviceConnected = false;
	self.useRecordVideo = false;
	
	if (![Helper isVideoRecordSupported])
    {
		[self.btnSaveVideo setEnabled:NO];
	}
}

- (void)newDeviceDetected:(NSString*)connectedDevice
{
	DBNSLog(@"Device: %@ is connected", connectedDevice);
	
	self.isDeviceConnected = (connectedDevice != nil);
	
	[self.deviceInfo setupWithMobileDeviceServer:self.mobileDeviceServer];
    
    __weak AppDelegate *weakSelf = self;
	[self.deviceInfo updateViewsWithCompletionBlock:^(FileSystemItem *fileSystem)
    {
        _rootNode = fileSystem;
        [weakSelf.fileManager setColumnResizingType:NSBrowserAutoColumnResizing];
        [weakSelf.fileManager reloadColumn:0];
    }];
}

- (void)deviceRemoved
{
	DBNSLog(@"Device is disconnected");
	
	self.isDeviceConnected = false;
	
	[m_OperationQueue cancelAllOperations];
}

- (void)updateAppList
{
	if (!self.isDeviceConnected)
    {
		return;
	}
	
	[m_OperationQueue addOperationWithBlock:^{
		[self.deviceInfo updateAppList];
	}];
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	if (!self.isDeviceConnected)
    {
		return;
	}
	
	int tabSelection = [[tabViewItem identifier] intValue];
	if (tabSelection == 3)
	{
		m_iMoviePos = 0;

		[self.mobileDeviceServer createScrenshotService];
		m_ImageCaptureTimer = [NSTimer scheduledTimerWithTimeInterval:0.001
															target:self
														  selector:@selector(handleImageCaptureTimerTimer:)
														  userInfo:nil
														   repeats:YES];
	}
	else
	{
		if (m_QTMovie)
        {
			[m_QTMovie stop];
			m_QTMovie = nil;
			m_iMoviePos = 0;
		}
		
		[m_ImageCaptureTimer invalidate];
		m_ImageCaptureTimer = nil;
	}
}

- (void)handleImageCaptureTimerTimer:(NSTimer *)theTimer
{
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(queue, ^
    {
		dispatch_async(dispatch_get_main_queue(), ^
        {
			NSImage *img = [self.mobileDeviceServer takeScreenshot];
			if (img)
			{
				[_imageCapture setImage:img];

				if (_useRecordVideo)
                {
					NSError *error = nil;
					if (!m_QTMovie)
                    {
						NSFileManager *fm = [NSFileManager defaultManager];
						if ([fm fileExistsAtPath:MOVIE_FILE_NAME isDirectory:nil])
                        {
							[fm removeItemAtPath:MOVIE_FILE_NAME error:&error];
						}
						
						m_QTMovie = [[QTMovie alloc] initToWritableFile:MOVIE_FILE_NAME error:&error];
						if (error)
                        {
							NSLog(@"Could not create QTMovie: %@", [error localizedDescription]);
							return;
						}
						[m_QTMovie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
					}
					
					[m_QTMovie addImage:img
						forDuration:QTMakeTime(m_iMoviePos++, FPS)
					 withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:@"jpeg", QTAddImageCodecType,
									 [NSNumber numberWithInt:codecHighQuality], QTAddImageCodecQuality, nil]];
					
					[m_QTMovie updateMovieFile];
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

- (IBAction) goToURL:(id)sender
{
	NSURL *url = [self getHiperLinkForTool:[sender title]];
	
	[[NSWorkspace sharedWorkspace] openURL:url];
}

- (NSURL*) getHiperLinkForTool:(NSString*)tool
{
	tool = [tool lowercaseString];
	
	if ([tool isEqualToString:@"donate"])
    {
		return [NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=ENPVXEYJUQU9G"];
	}
	else if ([tool isEqualToString:@"igr software"])
    {
		return [NSURL URLWithString:@"http://www.igrsoft.com"];
	}
	
	return [NSURL URLWithString:@"http://www.igrsoft.com"];
}

#pragma mark - File Manager

// This method is optional, but makes the code much easier to understand
- (id)rootItemForBrowser:(NSBrowser *)browser {
	
    return _rootNode;
}

- (NSInteger)browser:(NSBrowser *)browser numberOfChildrenOfItem:(id)item
{
    FileSystemItem *node = (FileSystemItem *)item;
    return node.children.count;
}

- (id)browser:(NSBrowser *)browser child:(NSInteger)index ofItem:(id)item
{
    FileSystemItem *node = (FileSystemItem *)item;
    return [node.children objectAtIndex:index];
}

- (BOOL)browser:(NSBrowser *)browser isLeafItem:(id)item
{
    FileSystemItem *node = (FileSystemItem *)item;
    return !node.isDir;
}

- (id)browser:(NSBrowser *)browser objectValueForItem:(id)item
{
    FileSystemItem *node = (FileSystemItem *)item;
    return node.name;
}

@end
