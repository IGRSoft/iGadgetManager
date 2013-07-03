//
//  Helper.m
//  iGadgetManager
//
//  Created by Vitalii Parovishnyk on 7/3/13.
//  Copyright (c) 2013 IGR Software. All rights reserved.
//

#import "Helper.h"

@implementation Helper

+ (bool) isVideoRecordSupported
{
	NSArray *bundleArch = [[NSBundle bundleWithPath:@"/System/Library/Frameworks/QTKit.framework"] executableArchitectures];
	
	for (NSNumber *arch in bundleArch) {
		if ([arch intValue] == NSBundleExecutableArchitectureX86_64) {
			return true;
		}
	}
	
	return false;
}

@end
