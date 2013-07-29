//
//  DeviceInfo.m
//  iGadgetManager
//
//  Created by Vitalii Parovishnyk on 12/27/12.
//
//

#import "DeviceInfo.h"
#import "MobileDeviceServer.h"
#import "ItemCellView.h"
#import "LBProgressBar.h"

#define BYTE_IN_GB 1073741824

@interface DeviceInfo ()

@end

@implementation DeviceInfo

- (void)setupWithMobileDeviceServer:(MobileDeviceServer*)_mobileDeviceServer withPlist:(NSMutableDictionary*)plist
{
	mobileDeviceServer = _mobileDeviceServer;
	m_DevicesDict = [plist copy];
}

- (void)updateViews
{	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(queue, ^{
		
		NSString *originalDeviceName = [mobileDeviceServer deviceClass];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_originalDeviceName setStringValue:originalDeviceName];
		});
		
		NSString *productType = [mobileDeviceServer deviceProductType];
		NSDictionary *info = m_DevicesDict[productType];
		NSString *color = [mobileDeviceServer deviceColor];
		
		NSImage *img = nil;
		if (info) {
			NSString *imgKey = @"img";
			if (![color isEqualToString:@"black"]) {
				imgKey = [imgKey stringByAppendingFormat:@"_%@", color];
				if (!info[imgKey]) {
					imgKey = @"img";
				}
			}
			NSString *val = [[NSBundle mainBundle] pathForResource:info[imgKey]
															ofType:@"png"
													   inDirectory:@"devices"];
			img = [[NSImage alloc] initWithContentsOfFile:val];
		}
		
		if (img) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[_devicePic setImage:img];
			});
		}
		
		NSString *deviceName = [mobileDeviceServer deviceName];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_deviceName setStringValue:deviceName];
		});
		
		NSString *deviceProductVersion = [mobileDeviceServer deviceProductVersion];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_deviceOSVersion setStringValue:deviceProductVersion];
		});
		
		NSString *deviceSerialNumber = [mobileDeviceServer deviceSerialNumber];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_deviceSerialNumber setStringValue:deviceSerialNumber];
		});
		
		NSString *devicePhoneNumber = [mobileDeviceServer devicePhoneNumber];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_devicePhoneNumber setStringValue:devicePhoneNumber];
		});
		
		NSString *deviceBaseband = [mobileDeviceServer deviceBaseband];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_deviceBaseband setStringValue:deviceBaseband];
		});
		
		NSString *deviceBootloader = [mobileDeviceServer deviceBootloader];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_deviceBootloader setStringValue:deviceBootloader];
		});
		
		NSString *deviceHardwareModel = [mobileDeviceServer deviceHardwareModel];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_deviceHardwareModel setStringValue:deviceHardwareModel];
		});
		
		NSString *deviceModelNumber = [mobileDeviceServer deviceModelNumber];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_deviceModelNumber setStringValue:deviceModelNumber];
		});
		
		NSString *deviceUniqueDeviceID = [mobileDeviceServer deviceUniqueDeviceID];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_deviceUDID setStringValue:deviceUniqueDeviceID];
		});
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[_deviceProdictType setStringValue:productType];
			[_deviceColor setStringValue:color];
		});
		
		NSString *deviceCPUArchitecture = [mobileDeviceServer deviceCPUArchitecture];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_deviceCPU setStringValue:deviceCPUArchitecture];
		});
		
		NSString *deviceHardwarePlatform = [mobileDeviceServer deviceHardwarePlatform];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_deviceHardwarePlatform setStringValue:deviceHardwarePlatform];
		});
		
		NSString *deviceActivation = [mobileDeviceServer deviceActivation];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_deviceActivated setStringValue:deviceActivation];
		});
		
		NSString *deviceBluetoothAddress = [mobileDeviceServer deviceBluetoothAddress];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_deviceBluetoothAddress setStringValue:deviceBluetoothAddress];
		});
		
		NSString *deviceWiFiAddress = [mobileDeviceServer deviceWiFiAddress];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_deviceWiFiAddress setStringValue:deviceWiFiAddress];
		});
		
		NSString *totalBytes = [mobileDeviceServer deviceAFSTotalBytes];
		NSString *freeBytes = [mobileDeviceServer deviceAFSFreeBytes];
		float total = [totalBytes floatValue] > 0 ? [totalBytes floatValue] / BYTE_IN_GB : 0;
		float free = [freeBytes floatValue] > 0 ? [freeBytes floatValue] / BYTE_IN_GB : 0;
		float filled = total - free;
		dispatch_async(dispatch_get_main_queue(), ^{
			[_deviceCapacity setStringValue:[NSString stringWithFormat:@"%.3f GB", total]];
			[_deviceFilledCapacity setStringValue:[NSString stringWithFormat:@"%.3f GB", filled]];
			[_deviceFreeCapacity setStringValue:[NSString stringWithFormat:@"%.3f GB", free]];
			
			[_progressIndicator setMinValue:0];
			[_progressIndicator setMaxValue:total];
			[_progressIndicator setDoubleValue:filled];
		});
		
		[self updateAppList];
		
		[mobileDeviceServer getFileSystem];
	});
}

- (void)updateAppList
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[_spiner startAnimation:self];
		[_appsList setEnabled:NO];
	});
	NSArray *_AppsList = [[NSArray alloc] initWithArray:[mobileDeviceServer appsList]];
	dispatch_async(dispatch_get_main_queue(), ^{
		m_AppsList = [_AppsList copy];
		[_spiner stopAnimation:self];
		if ([m_AppsList count] > 0) {
			[_appsList setEnabled:YES];
			[_appsList reloadData];
		}
	});
}

- (IBAction)unistallApp:(id)sender
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[_spiner startAnimation:self];
	});
	
	NSButton *btn = (NSButton*)sender;
	NSDictionary *dic = m_AppsList[btn.tag];
	NSString *appID = dic[@"app_id"];
	
	[mobileDeviceServer deviceAFSUninstallAppID:appID];

}

#pragma mark - NSTableViewDelegate
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [m_AppsList count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	ItemCellView *result = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
	
	NSDictionary *dic = m_AppsList[row];
	result.textField.stringValue = dic[@"app_name"];
	result.detailTextField.stringValue = dic[@"app_version"];
	result.detailUninstallButton.tag = row;
	NSString *iconPath = dic[@"app_icon"];
	if ([iconPath length] > 0) {
		NSImage *img = [[NSImage alloc] initWithContentsOfFile:iconPath];
		result.imageView.image = img;
	}
	
	return result;
}

- (IBAction)rebootDevice:(id)sender
{
	[mobileDeviceServer deviceReboot];
}

- (IBAction)shutdownDevice:(id)sender
{
	[mobileDeviceServer deviceShutdown];
}

- (IBAction)recoveryModeDevice:(id)sender
{
	[mobileDeviceServer deviceEnterRecovery];
}

@end
