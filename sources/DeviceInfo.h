//
//  DeviceInfo.h
//  iGadgetManager
//
//  Created by Vitalii Parovishnyk on 12/27/12.
//
//

#import <Cocoa/Cocoa.h>

@class MobileDeviceServer;
@class NSColoredView;
@class LBProgressBar;

@interface DeviceInfo : NSObject <NSTableViewDelegate> {
	
	NSArray*				m_DevicesDict;
	MobileDeviceServer*		mobileDeviceServer;
	NSArray*				m_AppsList;
}

- (void)setupWithMobileDeviceServer:(MobileDeviceServer*) mobileDeviceServer;
- (void)updateViews;

///////////////////////////////Summary///////////////////////////////
//Basic
@property (nonatomic, strong) IBOutlet NSImageView *devicePic;
@property (nonatomic, assign) IBOutlet NSTextField *originalDeviceName;
@property (nonatomic, assign) IBOutlet NSTextField *deviceName;
@property (nonatomic, assign) IBOutlet NSTextField *deviceOSVersion;
@property (nonatomic, assign) IBOutlet NSTextField *deviceSerialNumber;
@property (nonatomic, assign) IBOutlet NSTextField *devicePhoneNumber;

//Advanced
@property (nonatomic, assign) IBOutlet NSTextField *deviceBaseband;
@property (nonatomic, assign) IBOutlet NSTextField *deviceBootloader;
@property (nonatomic, assign) IBOutlet NSTextField *deviceHardwareModel;
@property (nonatomic, assign) IBOutlet NSTextField *deviceModelNumber;
@property (nonatomic, assign) IBOutlet NSTextField *deviceUDID;
@property (nonatomic, assign) IBOutlet NSTextField *deviceColor;
@property (nonatomic, assign) IBOutlet NSTextField *deviceProdictType;
@property (nonatomic, assign) IBOutlet NSTextField *deviceCPU;
@property (nonatomic, assign) IBOutlet NSTextField *deviceHardwarePlatform;
@property (nonatomic, assign) IBOutlet NSTextField *deviceBluetoothAddress;
@property (nonatomic, assign) IBOutlet NSTextField *deviceWiFiAddress;
@property (nonatomic, assign) IBOutlet NSTextField *deviceActivated;

//Capacity
@property (nonatomic, assign) IBOutlet NSColoredView *coloredView;
@property (nonatomic, assign) IBOutlet NSTextField *deviceCapacity;
@property (nonatomic, assign) IBOutlet NSTextField *deviceFilledCapacity;
@property (nonatomic, assign) IBOutlet NSTextField *deviceFreeCapacity;
@property (nonatomic, assign) IBOutlet LBProgressBar *progressIndicator;

///////////////////////////////Apps///////////////////////////////
@property (nonatomic, strong) IBOutlet NSTableView *appsList;
@property (nonatomic, assign) IBOutlet NSProgressIndicator *spiner;
- (IBAction)unistallApp:(id)sender;
- (void)updateAppList;

///////////////////////////////Tools///////////////////////////////
- (IBAction)rebootDevice:(id)sender;
- (IBAction)shutdownDevice:(id)sender;
- (IBAction)recoveryModeDevice:(id)sender;
@end
