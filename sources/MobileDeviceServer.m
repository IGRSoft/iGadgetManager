//
//  MobileDeviceServer.m
//  iGadgetManager
//
//  Created by Vitalii Parovishnyk on 12/17/12.
//
//

#import "MobileDeviceServer.h"

#include <libimobiledevice/libimobiledevice.h>
#include <libimobiledevice/installation_proxy.h>
#include <libimobiledevice/lockdown.h>
#include <libimobiledevice/afc.h>
#include <libimobiledevice/sbservices.h>
#include <libimobiledevice/screenshotr.h>
#include <libimobiledevice/diagnostics_relay.h>

#include <plist/plist.h>

typedef enum {
	
	deviceInfoTypeName = 0,
	deviceInfoTypeProductType,
	deviceInfoTypeCapacity,
	deviceInfoTypeProductVersion,
	deviceInfoTypeSerialNumber,
	deviceInfoTypePhoneNumber,
	deviceInfoTypeDeviceClass,
	deviceInfoTypeDeviceColor,
	deviceInfoTypeBasebandVersion,
	deviceInfoTypeFirmwareVersion,
	deviceInfoTypeHardwareModel,
	deviceInfoTypeUniqueDeviceID,
	deviceInfoTypeCPUArchitecture,
	deviceInfoTypeHardwarePlatform,
	deviceInfoTypeBluetoothAddress,
	deviceInfoTypeWiFiAddress,
	deviceInfoTypeModelNumber,
	deviceInfoTypeActivation,
	
	deviceInfoTypeAll,
	
	deviceInfoTypeCount

} deviceInfoType;

typedef enum {
	
	deviceAFSTotalBytes = 0,
	deviceAFSFreeBytes,
	
	deviceAFSInfoTypeCount
	
} deviceAFCInfoType;

static MobileDeviceServer* tmpSelf = nil;

@interface MobileDeviceServer ()
{
	idevice_t device;
	lockdownd_client_t lockdownd;
	afc_client_t afc;
	screenshotr_client_t shotr;
}

void device_event_cb(const idevice_event_t* event, void* userdata);
- (NSString *) deviceInfoFor:(deviceInfoType)deviceInfoType;
- (NSString *) deviceAFCInfoFor:(deviceAFCInfoType)deviceAFCInfoType;
- (void) checkNewDeviceEvent:(const idevice_event_t*)event withUserData:(void*)userdata;
- (lockdownd_client_t) getInfoForDevice:(idevice_t)_device;
NSString* load_icon (sbservices_client_t sbs, const char *_id);
void status_cb(const char *operation, plist_t status, void *unused);

@end

@implementation MobileDeviceServer

- (id) init {
	if (!(self = [super init]))
	{
		return nil;
	}
	
	shotr = nil;
	lockdownd = nil;
	afc = nil;
	device = nil;
	
	int64_t delayInSeconds = 1.0;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		idevice_event_subscribe(&device_event_cb, nil);
	});
	
	tmpSelf = self;
	
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	MobileDeviceServer *mds = [[MobileDeviceServer alloc] init];
	mds->device = self->device;
	mds->lockdownd = self->lockdownd;
	mds->afc = self->afc;
	mds->shotr = self->shotr;
	
	return mds;
}

- (void) dealloc
{	
	if (afc)		afc_client_free(afc), afc = nil;
	if (shotr)		screenshotr_client_free(shotr) , shotr = nil;
	if (lockdownd)	lockdownd_client_free(lockdownd), lockdownd = nil;
	if (device)		idevice_free(device), device = nil;
}

- (void) scanForDevice
{
	@synchronized(self)
    {
		device = [self findDevices];
		
		if (!device) {
			return;
		}
		
		afc = [self getAFCInfoForDevice:device];
		lockdownd = [self getInfoForDevice:device];
		
		if (device && [self.delegate respondsToSelector:@selector(newDeviceDetected:)]) {
			[self.delegate newDeviceDetected:[self deviceProductType]];
		}
	}
}

- (idevice_t) findDevices
{
	idevice_t _device = nil;
	
    char uuid[41];
    int count = 0;
    char **list = nil;
    idevice_error_t device_status = 0;
	
	DBNSLog(@"INFO: Retrieving device list");

    if (idevice_get_device_list(&list, &count) < 0 || count == 0) {
		DBNSLog(@"ERROR: Cannot retrieve device list");
		return nil;
    }
	
    memset(uuid, '\0', 41);
    memcpy(uuid, list[0], 40);
    idevice_device_list_free(list);
    
	DBNSLog(@"INFO: Opening device");
    device_status = idevice_new(&_device, uuid);
    if (device_status != IDEVICE_E_SUCCESS) {
        if (device_status == IDEVICE_E_NO_DEVICE) {
			DBNSLog(@"ERROR: No device found");
        } else {
			DBNSLog(@"ERROR: Unable to open device, %d", device_status);
        }
		return nil;
    }
	
	return _device;
}

- (lockdownd_client_t) getInfoForDevice:(idevice_t)_device
{
	lockdownd_client_t _lockdownd = nil;
	
 	lockdownd_error_t lockdownd_error = 0;
	DBNSLog(@"INFO: Creating lockdownd client");
	lockdownd_error = lockdownd_client_new_with_handshake(_device, &_lockdownd, "iGadgetManager");
	if(lockdownd_error != LOCKDOWN_E_SUCCESS) {
		DBNSLog(@"ERROR: Cannot create lockdownd client");
		return nil;
	}
	
	return _lockdownd;
}

- (afc_client_t) getAFCInfoForDevice:(idevice_t)_device
{
	lockdownd_client_t client = [self getInfoForDevice:device];
	
	afc_client_t _afc = nil;
	lockdownd_service_descriptor_t descriptor = 0;
	
	if (!client) {
		lockdownd_client_free(client);
		return _afc;
	}
	
	if ((lockdownd_start_service(client, "com.apple.afc", &descriptor) != LOCKDOWN_E_SUCCESS) || !descriptor)
	{
		lockdownd_client_free(client);
		return _afc;
	}
	
	lockdownd_client_free(client);
	afc_client_new(_device, descriptor, &_afc);
	
	return _afc;
}

- (bool) isConnected
{
	return device != nil;
}

- (NSString *) deviceName
{	
	return [self deviceInfoFor:deviceInfoTypeName];
}

- (NSString *) deviceProductType
{
	return [self deviceInfoFor:deviceInfoTypeProductType];
}

- (NSString *) deviceProductVersion
{
	return [self deviceInfoFor:deviceInfoTypeProductVersion];
}

- (NSString *) deviceCapacity
{
	return [self deviceInfoFor:deviceInfoTypeCapacity];
}

- (NSString *) deviceSerialNumber
{
	return [self deviceInfoFor:deviceInfoTypeSerialNumber];
}

- (NSString *) devicePhoneNumber
{
	return [self deviceInfoFor:deviceInfoTypePhoneNumber];
}

- (NSString *) deviceClass
{
	return [self deviceInfoFor:deviceInfoTypeDeviceClass];
}

- (NSString *) deviceColor
{
	return [self deviceInfoFor:deviceInfoTypeDeviceColor];
}

- (NSString *) deviceBaseband
{
	return [self deviceInfoFor:deviceInfoTypeBasebandVersion];
}

- (NSString *) deviceBootloader
{
	return [self deviceInfoFor:deviceInfoTypeFirmwareVersion];
}

- (NSString *) deviceHardwareModel
{
	return [self deviceInfoFor:deviceInfoTypeHardwareModel];
}

- (NSString *) deviceUniqueDeviceID
{
	return [self deviceInfoFor:deviceInfoTypeUniqueDeviceID];
}

- (NSString *) deviceCPUArchitecture
{
	return [self deviceInfoFor:deviceInfoTypeCPUArchitecture];
}

- (NSString *) deviceHardwarePlatform
{
	return [self deviceInfoFor:deviceInfoTypeHardwarePlatform];
}

- (NSString *) deviceBluetoothAddress
{
	return [self deviceInfoFor:deviceInfoTypeBluetoothAddress];
}

- (NSString *) deviceWiFiAddress
{
	return [self deviceInfoFor:deviceInfoTypeWiFiAddress];
}

- (NSString *) deviceModelNumber
{
	return [self deviceInfoFor:deviceInfoTypeModelNumber];
}

- (NSString *) deviceActivation
{
	return [self deviceInfoFor:deviceInfoTypeActivation];
}

- (NSString *) deviceAllInfo
{
	return [self deviceInfoFor:deviceInfoTypeAll];
}

- (NSString *) deviceAFSTotalBytes
{
	return [self deviceAFCInfoFor:deviceAFSTotalBytes];
}

- (NSString *) deviceAFSFreeBytes
{
	return [self deviceAFCInfoFor:deviceAFSFreeBytes];
}

- (NSString *) deviceInfoFor:(deviceInfoType)deviceInfoType
{
	const char *key = nil;
	
	switch (deviceInfoType) {
		case deviceInfoTypeName:
			key = "DeviceName";
			break;
		case deviceInfoTypeProductType:
			key = "ProductType";
			break;
		case deviceInfoTypeCapacity:
			key = "ProductType";
			break;
		case deviceInfoTypeProductVersion:
			key = "ProductVersion";
			break;
		case deviceInfoTypeSerialNumber:
			key = "SerialNumber";
			break;
		case deviceInfoTypePhoneNumber:
			key = "PhoneNumber";
			break;
		case deviceInfoTypeDeviceClass:
			key = "DeviceClass";
			break;
		case deviceInfoTypeDeviceColor:
			key = "DeviceColor";
			break;
		case deviceInfoTypeBasebandVersion:
			key = "BasebandVersion";
			break;
		case deviceInfoTypeFirmwareVersion:
			key = "FirmwareVersion";
			break;
		case deviceInfoTypeHardwareModel:
			key = "HardwareModel";
			break;
		case deviceInfoTypeUniqueDeviceID:
			key = "UniqueDeviceID";
			break;
		case deviceInfoTypeCPUArchitecture:
			key = "CPUArchitecture";
			break;
		case deviceInfoTypeHardwarePlatform:
			key = "HardwarePlatform";
			break;
		case deviceInfoTypeBluetoothAddress:
			key = "BluetoothAddress";
			break;
		case deviceInfoTypeWiFiAddress:
			key = "WiFiAddress";
			break;
		case deviceInfoTypeModelNumber:
			key = "ModelNumber";
			break;
		case deviceInfoTypeActivation:
			key = "ActivationState";
			break;
		case deviceInfoTypeAll:
			key = nil;
			break;
		
		default:
			break;
	}
	plist_t value_node = nil;

	//lockdownd_client_t lockdownd = [self getInfoForDevice:device];
	lockdownd_get_value(lockdownd, nil, key, &value_node);
	
	char *val = nil;
	if (value_node) {
		if (key) {
			plist_get_string_val(value_node, &val);
		}
		else
		{
			uint32_t xml_length;
			plist_to_xml(value_node, &val, &xml_length);
		}
	}
	//lockdownd_client_free(lockdownd);
	
	if (val && strlen(val) > 0) {
		return [NSString stringWithUTF8String:val];
	}
	
	return @"none";
}

- (NSString *) deviceAFCInfoFor:(deviceAFCInfoType)deviceAFCInfoType
{
	const char *key = nil;
	
	switch (deviceAFCInfoType) {
		case deviceAFSTotalBytes:
			key = "FSTotalBytes";
			break;
		case deviceAFSFreeBytes:
			key = "FSFreeBytes";
			break;
		
		default:
			key = "Model";
			break;
	}
	
	char* val = nil;
	afc_get_device_info_key (afc, key, &val );
	
	if (val && strlen(val) > 0) {
		return [NSString stringWithUTF8String:val];
	}
	
	return @"0";
}

void device_event_cb(const idevice_event_t* event, void* userdata)
{
	if (tmpSelf) {
		[tmpSelf checkNewDeviceEvent:event withUserData:userdata];
	}
}

- (void) checkNewDeviceEvent:(const idevice_event_t*)event withUserData:(void*)userdata
{
	if (event->event == IDEVICE_DEVICE_ADD) {
		[self scanForDevice];
		deviceConnected = true;
	} else if (event->event == IDEVICE_DEVICE_REMOVE) {
		afc = nil;
		shotr = nil;
		lockdownd = nil;
		device = nil;
		deviceConnected = false;
		if ([self.delegate respondsToSelector:@selector(deviceRemoved)]) {
			[self.delegate deviceRemoved];
		}
	}
}

- (NSArray*) appsList
{
	lockdownd_service_descriptor_t descriptor = 0;
	instproxy_client_t ipc = nil;
	lockdownd_client_t client = [self getInfoForDevice:device];
	sbservices_client_t sbs = nil;
	if ((lockdownd_start_service
		 (client, "com.apple.mobile.installation_proxy",
		  &descriptor) != LOCKDOWN_E_SUCCESS) || !descriptor) {
			 DBNSLog(@"ERROR: Could not start com.apple.mobile.installation_proxy!");
			 return nil;
		 }
	
	if (instproxy_client_new(device, descriptor, &ipc) != INSTPROXY_E_SUCCESS) {
		DBNSLog(@"ERROR: Could not connect to installation_proxy");
		return nil;
	}
	
	if ((lockdownd_start_service (client, "com.apple.springboardservices", &descriptor) != LOCKDOWN_E_SUCCESS) || !descriptor)
	{
		DBNSLog(@"INFO: Could not start com.apple.springboardservices!");
	}
	else
	{
		if (sbservices_client_new(device, descriptor, &sbs) != INSTPROXY_E_SUCCESS) {
			DBNSLog(@"INFO: Could not connect to springboard");
		}
	}
	
	int xml_mode = 0;
	plist_t client_opts = instproxy_client_options_new();
	instproxy_client_options_add(client_opts, "ApplicationType", "User", nil);
	instproxy_error_t err;
	plist_t apps = nil;
	
	if (!deviceConnected) {
		return nil;
	}
	err = instproxy_browse(ipc, client_opts, &apps);
	instproxy_client_options_free(client_opts);
	if (err != INSTPROXY_E_SUCCESS) {
		DBNSLog(@"ERROR: instproxy_browse returned %d", err);
		if (err != INSTPROXY_E_CONN_FAILED) {
			lockdownd_client_free(client);
		}
		instproxy_client_free(ipc);
		
		if (sbs) sbservices_client_free(sbs);
		return nil;
	}
	if (!apps || (plist_get_node_type(apps) != PLIST_ARRAY)) {
		DBNSLog(@"ERROR: instproxy_browse returnd an invalid plist!");
		instproxy_client_free(ipc);
		lockdownd_client_free(client);
		if (sbs) sbservices_client_free(sbs);
		return nil;
	}
	if (xml_mode) {
		char *xml = nil;
		uint32_t len = 0;
		
		plist_to_xml(apps, &xml, &len);
		if (xml) {
			puts(xml);
			free(xml);
		}
		plist_free(apps);
		instproxy_client_free(ipc);
		lockdownd_client_free(client);
		if (sbs) sbservices_client_free(sbs);
		return nil;
	}

	NSMutableArray *arr = [NSMutableArray array];
	uint32_t i = 0;
	for (i = 0; i < plist_array_get_size(apps); i++) {
		plist_t app = plist_array_get_item(apps, i);
		plist_t p_appid = plist_dict_get_item(app, "CFBundleIdentifier");
		char *s_appid = nil;
		char *s_dispName = nil;
		char *s_version = nil;

		plist_t dispName = plist_dict_get_item(app, "CFBundleDisplayName");
		plist_t version = plist_dict_get_item(app, "CFBundleVersion");
		
		if (p_appid) {
			plist_get_string_val(p_appid, &s_appid);
			plist_free(p_appid);
		}
		if (!s_appid) {
			DBNSLog(@"ERROR: Failed to get APPID!");
			continue;
		}
		
		if (dispName) {
			plist_get_string_val(dispName, &s_dispName);
		}
		if (version) {
			plist_get_string_val(version, &s_version);
		}
		
		if (!s_dispName) {
			s_dispName = strdup(s_appid);
		}

		NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSString stringWithUTF8String:s_dispName], @"app_name",
									[NSString stringWithUTF8String:s_appid], @"app_id",
									@"", @"app_version",
									@"", @"app_icon",
									nil];
		if (s_version) {
			dic[@"app_version"] = [NSString stringWithUTF8String:s_version];
			free(s_version);
		}
		
		if (sbs)
		{
			NSString *s_icon = nil;
			s_icon = load_icon(sbs, s_appid);
			if (s_icon) {
				dic[@"app_icon"] = s_icon;
			}
		}
		
		[arr addObject:dic];
		free(s_dispName);
		free(s_appid);
	}
	plist_free(apps);
	instproxy_client_free(ipc);
	lockdownd_client_free(client);
	if (sbs) sbservices_client_free(sbs);
	
	return arr;
}

NSString* load_icon (sbservices_client_t sbs, const char *_id)
{
	NSString *path;
	NSString *filename;
	char *data;
	uint64_t len;
	
	NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDir = NO;
	NSError *error = nil;
	
	NSString *cache = [cachesPath stringByAppendingPathComponent:@"iGadgetManager"];
	if ([fm fileExistsAtPath:cache isDirectory:&isDir] && isDir) {
	}
	else{
		[fm createDirectoryAtPath:cache
	  withIntermediateDirectories:YES
					   attributes:nil
							error:&error];
		if (error) {
			DBNSLog(@"ERROR: Can't write a folder: %@!", cache);
			return nil;
		}
		
	}
	cache = [cache stringByAppendingPathComponent:@"icons"];
	if ([fm fileExistsAtPath:cache isDirectory:&isDir] && isDir) {
		
	}
	else{
		[fm createDirectoryAtPath:cache
	  withIntermediateDirectories:YES
					   attributes:nil
							error:&error];
		if (error) {
			DBNSLog(@"ERROR: Can't write a folder: %@!", cache);
			return nil;
		}
		
	}
	filename = [NSString stringWithFormat:@"%s.png", _id];
	path = [NSString stringWithFormat:@"%@/%@", cache, filename];
	
	if ([fm fileExistsAtPath:path])
		return path;
	
	data = nil;
	len = 0;
	if (sbservices_get_icon_pngdata (sbs, _id, &data, &len) != SBSERVICES_E_SUCCESS ||
		data == nil || len == 0)
    {
		if (data) free(data);
		
		return nil;
    }
	
	if (![fm createFileAtPath:path
					contents:[NSData dataWithBytes:data length:len]
				  attributes:nil]){
		DBNSLog(@"ERROR: Can't write a file: %@!", filename);
		free (data);
		return nil;
	}

	free (data);
	
	return path;
}

- (void) deviceAFSUninstallAppID:(NSString*) appID
{
	lockdownd_service_descriptor_t descriptor = 0;
	instproxy_client_t ipc = nil;
	lockdownd_client_t client = [self getInfoForDevice:device];
	sbservices_client_t sbs = nil;
	if ((lockdownd_start_service
		 (client, "com.apple.mobile.installation_proxy",
		  &descriptor) != LOCKDOWN_E_SUCCESS) || !descriptor) {
			 DBNSLog(@"ERROR: Could not start com.apple.mobile.installation_proxy!");
			 return;
		 }
	
	if (instproxy_client_new(device, descriptor, &ipc) != INSTPROXY_E_SUCCESS) {
		DBNSLog(@"ERROR: Could not connect to installation_proxy");
		return;
	}
	
	if ((lockdownd_start_service (client, "com.apple.springboardservices", &descriptor) != LOCKDOWN_E_SUCCESS) || !descriptor)
	{
		DBNSLog(@"INFO: Could not start com.apple.springboardservices!");
	}
	else
	{
		if (sbservices_client_new(device, descriptor, &sbs) != INSTPROXY_E_SUCCESS) {
			DBNSLog(@"INFO: Could not connect to springboard");
		}
	}
	
	plist_t client_opts = instproxy_client_options_new();
	instproxy_error_t err;
	plist_t apps = nil;
	
	err = instproxy_browse(ipc, client_opts, &apps);
	instproxy_client_options_free(client_opts);
	if (err != INSTPROXY_E_SUCCESS) {
		DBNSLog(@"ERROR: instproxy_browse returned %d", err);
		instproxy_client_free(ipc);
		lockdownd_client_free(client);
		if (sbs) sbservices_client_free(sbs);
		return;
	}
	
	instproxy_uninstall(ipc, [appID UTF8String], NULL, status_cb, NULL);
	
	instproxy_client_free(ipc);
}

void status_cb(const char *operation, plist_t status, void *unused)
{
	if (status && operation) {
		plist_t npercent = plist_dict_get_item(status, "PercentComplete");
		plist_t nstatus = plist_dict_get_item(status, "Status");
		uint64_t percent = 0;
		char *status_msg = NULL;
		if (npercent) {
			uint64_t val = 0;
			plist_get_uint_val(npercent, &val);
			percent = val;
			DBNSLog(@"INFO: percent compleate: %lld%%", percent);
		}
		if (nstatus) {
			plist_get_string_val(nstatus, &status_msg);
			if (status_msg) {
				if (!strcmp(status_msg, "Complete")) {
					if ([tmpSelf.delegate respondsToSelector:@selector(updateAppList)]) {
						[tmpSelf.delegate updateAppList];
					}
				}
				free(status_msg);
			}
			
		}
	} else {
		printf("%s: called with invalid data!\n", __func__);
	}
}

- (NSImage*) takeScreenshot
{
	NSImage* img = nil;
	
	if (!shotr) {
		[self createScrenshotService];
	}
	
	if (!shotr) {
		printf("Could not connect to screenshotr!\n");
	} else {
		char *imgdata = NULL;
		uint64_t imgsize = 0;
		
		if (screenshotr_take_screenshot(shotr, &imgdata, &imgsize) == SCREENSHOTR_E_SUCCESS) {
			NSData *imgData = [NSData dataWithBytes:imgdata length:imgsize];
			img = [[NSImage alloc] initWithData:imgData];
			free(imgdata);
			imgsize = 0;
		} else {
			printf("Could not get screenshot!\n");
		}
	}
	
	return img;
}

- (bool) createScrenshotService
{
	bool ret = false;
	if (!deviceConnected) {
		return false;
	}
	if (shotr) {
		screenshotr_client_free(shotr);
		shotr = nil;
	}
	lockdownd_client_t lckd = [self getInfoForDevice:device];
	lockdownd_service_descriptor_t shotrDescriptor = NULL;
	lockdownd_start_service(lckd, "com.apple.mobile.screenshotr", &shotrDescriptor);
	lockdownd_client_free(lckd);
	if (shotrDescriptor) {
		if (shotrDescriptor->port && shotrDescriptor->port > 0) {
			if (screenshotr_client_new(device, shotrDescriptor, &shotr) != SCREENSHOTR_E_SUCCESS) {
				printf("Could not connect to screenshotr!\n");
			} else {
				ret = true;
			}
		}
		else
		{
			printf("Could not start screenshotr service! Remember that you have to mount the Developer disk image on your device if you want to use the screenshotr service.\n");
		}
		
		lockdownd_service_descriptor_free(shotrDescriptor);
	} else {
		printf("Could not start screenshotr service! Remember that you have to mount the Developer disk image on your device if you want to use the screenshotr service.\n");
	}
	
	return ret;
}

- (bool) deviceEnterRecovery
{
	lockdownd_client_t _lockdownd = [self getInfoForDevice:device];
	lockdownd_error_t isSuccessful = lockdownd_enter_recovery(_lockdownd);
	
	if (isSuccessful == LOCKDOWN_E_SUCCESS) {
		if ([self.delegate respondsToSelector:@selector(deviceRemoved)]) {
			[self.delegate deviceRemoved];
		}
	}
	
	lockdownd_goodbye(_lockdownd);
	lockdownd_client_free(_lockdownd);
	
	return isSuccessful == LOCKDOWN_E_SUCCESS;
}

- (bool) deviceReboot
{
	lockdownd_client_t _lockdownd = [self getInfoForDevice:device];
	diagnostics_relay_client_t diagnostics_client = NULL;
	lockdownd_service_descriptor_t descriptor = 0;
	lockdownd_error_t ret = LOCKDOWN_E_UNKNOWN_ERROR;
	diagnostics_relay_error_t result = DIAGNOSTICS_RELAY_E_UNKNOWN_ERROR;
	
	/*  attempt to use newer diagnostics service available on iOS 5 and later */
	ret = lockdownd_start_service(_lockdownd, "com.apple.mobile.diagnostics_relay", &descriptor);
	if (ret != LOCKDOWN_E_SUCCESS) {
		/*  attempt to use older diagnostics service */
		ret = lockdownd_start_service(_lockdownd, "com.apple.iosdiagnostics.relay", &descriptor);
	}
	
	if ((ret == LOCKDOWN_E_SUCCESS) && (descriptor && descriptor->port > 0)) {
		if (diagnostics_relay_client_new(device, descriptor, &diagnostics_client) != DIAGNOSTICS_RELAY_E_SUCCESS) {
			printf("Could not connect to diagnostics_relay!\n");
		} else {
			result = diagnostics_relay_restart(diagnostics_client, 0);
			if (result == DIAGNOSTICS_RELAY_E_SUCCESS) {
				printf("Restarting device.\n");
				if ([self.delegate respondsToSelector:@selector(deviceRemoved)]) {
					[self.delegate deviceRemoved];
				}
			} else {
				printf("Failed to restart device.\n");
			}
		}
	} else {
		printf("Could not start diagnostics service!\n");
	}
	
	diagnostics_relay_goodbye(diagnostics_client);
	diagnostics_relay_client_free(diagnostics_client);
	
	return result == DIAGNOSTICS_RELAY_E_SUCCESS;
}

- (bool) deviceShutdown
{
	lockdownd_client_t _lockdownd = [self getInfoForDevice:device];
	diagnostics_relay_client_t diagnostics_client = NULL;
	lockdownd_service_descriptor_t descriptor = 0;
	lockdownd_error_t ret = LOCKDOWN_E_UNKNOWN_ERROR;
	diagnostics_relay_error_t result = DIAGNOSTICS_RELAY_E_UNKNOWN_ERROR;
	
	/*  attempt to use newer diagnostics service available on iOS 5 and later */
	ret = lockdownd_start_service(_lockdownd, "com.apple.mobile.diagnostics_relay", &descriptor);
	if (ret != LOCKDOWN_E_SUCCESS) {
		/*  attempt to use older diagnostics service */
		ret = lockdownd_start_service(_lockdownd, "com.apple.iosdiagnostics.relay", &descriptor);
	}
	
	if ((ret == LOCKDOWN_E_SUCCESS) && (descriptor && descriptor->port > 0)) {
		if (diagnostics_relay_client_new(device, descriptor, &diagnostics_client) != DIAGNOSTICS_RELAY_E_SUCCESS) {
			printf("Could not connect to diagnostics_relay!\n");
		} else {
			result = diagnostics_relay_shutdown(diagnostics_client, 0);
			if (result == DIAGNOSTICS_RELAY_E_SUCCESS) {
				printf("Restarting device.\n");
				if ([self.delegate respondsToSelector:@selector(deviceRemoved)]) {
					[self.delegate deviceRemoved];
				}
			} else {
				printf("Failed to restart device.\n");
			}
		}
	} else {
		printf("Could not start diagnostics service!\n");
	}
	
	diagnostics_relay_goodbye(diagnostics_client);
	diagnostics_relay_client_free(diagnostics_client);
	
	return result == DIAGNOSTICS_RELAY_E_SUCCESS;
}

@end
