//
//  ItemCellView.h
//  sunfl0wer
//
//  Created by Vitaly Parovishnik on 12/29/11.
//  Copyright 2011 IGR Software. All rights reserved.
//

@interface ItemCellView : NSTableCellView {
	NSTextField *_detailTextField;
	
	NSButton	*_detailUninstallButton;
}

@property (nonatomic, strong) IBOutlet NSTextField *detailTextField;
@property (nonatomic, strong) IBOutlet NSButton	*detailUninstallButton;

@end
