//
//  MobileDeviceServer.h
//  sunfl0wer
//
//  Created by Vitalii Parovishnyk on 12/17/12.
//
//

#import <Foundation/Foundation.h>

@protocol MobileDeviceServerDelegate <NSObject>
@optional
- (void)newDeviceDetected:(NSString*)connectedDevice;
- (void)deviceRemoved;
- (void)updateAppList;
@end

@interface MobileDeviceServer : NSObject
{
	NSMutableDictionary*			m_PlistDict;
	id <MobileDeviceServerDelegate>	_delegate;
	bool deviceConnected;
}

@property (nonatomic, strong) id <MobileDeviceServerDelegate> delegate;

- (void) scanForDevice;
- (bool) isConnected;
- (NSString *) deviceName;
- (NSString *) deviceProductType;
- (NSString *) deviceProductVersion;
- (NSString *) deviceCapacity;
- (NSString *) deviceSerialNumber;
- (NSString *) devicePhoneNumber;
- (NSString *) deviceClass;
- (NSString *) deviceColor;
- (NSString *) deviceBaseband;
- (NSString *) deviceBootloader;
- (NSString *) deviceHardwareModel;
- (NSString *) deviceUniqueDeviceID;
- (NSString *) deviceCPUArchitecture;
- (NSString *) deviceHardwarePlatform;
- (NSString *) deviceBluetoothAddress;
- (NSString *) deviceWiFiAddress;
- (NSString *) deviceModelNumber;
- (NSString *) deviceActivation;
- (NSString *) deviceAllInfo;
- (NSString *) deviceAFSTotalBytes;
- (NSString *) deviceAFSFreeBytes;
- (void) deviceAFSUninstallAppID:(NSString*) appID;
- (NSArray*) appsList;
- (bool) createScrenshotService;
- (NSImage*) takeScreenshot;
- (bool) deviceEnterRecovery;
- (bool) deviceReboot;
- (bool) deviceShutdown;
@end
