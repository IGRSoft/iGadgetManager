//
//  FileSystemItem.m
//  iGadgetManager
//
//  Created by Korich on 12/18/13.
//  Copyright (c) 2013 IGR Software. All rights reserved.
//

#import "FileSystemItem.h"

@implementation FileSystemItem

- (id)init
{
    if (self = [super init])
    {
        _name = @"";
        _dir = NO;
        _size = @0;
        _children = [NSMutableArray array];
        _parent = nil;
    }
    
    return self;
}

- (id)initRoot
{
    if (self = [self init])
    {
        _name = @"/";
        _dir = YES;
    }
    
    return self;
}

- (id)initWithParent:(FileSystemItem*)item;
{
    if (self = [self init])
    {
        _parent = item;
    }
    
    return self;
}

- (id)initWithDictionary:(NSDictionary*)item
{
    if (self = [self init])
    {
        [self updateFromDictionary:item];
    }
    
    return self;
}

- (void)updateFromDictionary:(NSDictionary*)item
{
    _name = item[NSURLNameKey];
    _dir = [item[NSURLIsDirectoryKey] boolValue];
    _size = item[NSURLFileSizeKey];
}

- (void) addChildrenFromDictionary:(NSDictionary*)item
{
    FileSystemItem *newItem = [FileSystemItem new];
    
    newItem.name = item[NSURLNameKey];
    newItem.dir = [item[NSURLIsDirectoryKey] boolValue];
    newItem.size = item[NSURLFileSizeKey];
    newItem.children = nil;
    newItem.parent = self;
    
    [self.children addObject:newItem];
}

- (void) addChildren:(FileSystemItem*)item
{
    if (item)
    {
        item.parent = self;
        
        [self.children addObject:item];
    }
}

- (const char*) UTFName
{
    return [self.name cStringUsingEncoding:NSUTF8StringEncoding];
}

- (const char*) UTFPath
{
    NSMutableArray *items = [[NSMutableArray alloc] initWithObjects:self.name, nil];
    
    FileSystemItem *parent = self;
    while ((parent = parent.parent))
    {
        [items addObject:parent.name];
    }
    
    NSString *path = @"";
    
    for (NSInteger i = ([items count] - 1); i >= 0; --i)
    {
        path = [path stringByAppendingPathComponent:items[i]];
    }
    
    if ([path length] > 1)
    {
        path = [path stringByAppendingString:@"/"];
    }
    
    return [path cStringUsingEncoding:NSUTF8StringEncoding];
}

- (BOOL) isValid
{
    return (self.name.length > 0);
}

@end
