//
//  FileSystemItem.h
//  iGadgetManager
//
//  Created by Korich on 12/18/13.
//  Copyright (c) 2013 IGR Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileSystemItem : NSObject

@property(nonatomic, strong)            NSString        *name;
@property(nonatomic, getter = isDir)    BOOL            *dir;
@property(nonatomic, strong)            NSNumber        *size;
@property(nonatomic, strong)            NSMutableArray  *children;
@property(nonatomic, strong)            FileSystemItem  *parent;

- (id)initRoot;
- (id)initWithDictionary:(NSDictionary*)item;
- (id)initWithParent:(FileSystemItem*)item;

- (void) addChildren:(FileSystemItem*)item;
- (void) addChildrenFromDictionary:(NSDictionary*)item;

- (void)updateFromDictionary:(NSDictionary*)item;

- (const char*) UTFName;
- (const char*) UTFPath;

- (BOOL) isValid;

@end
