//
//  LRCManager.m
//  MyTunesControllerPlus
//
//  Created by zhili hu on 2/9/11.
//  Copyright 2011 scut. All rights reserved.
//

#import "LRCManagerController.h"


@implementation LRCManagerController


- (id)initWithStorage:(LrcStorage*)lrcstore
{
	if (self = [super initWithWindowNibName:@"LRCManagerWindow" owner:self]) {
		store = [lrcstore retain];
		keyList = [[[store allItemKey] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] mutableCopy];
	}
    return self;
}

- (void)showWindow:(id)sender
{
	[super showWindow:sender];
	[self.window makeFirstResponder:nil];
}

- (IBAction)deleteIt:(id)sender
{	
	if ([tableView selectedRow] < 0 || [tableView selectedRow] >= [keyList count])
		return;
	NSString *thisKey = [keyList objectAtIndex:[tableView selectedRow]];
	[store deleteLRCFile:thisKey];
	[keyList removeObjectAtIndex:[tableView selectedRow]];
	[tableView reloadData];
}

- (int)numberOfRowsInTableView:(NSTableView *)tv
{
	return [keyList count];
}

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tc row:(int)row
{
	if (keyList != nil) {
		return [keyList objectAtIndex:row];
	}
    return nil;
}

- (void)dealloc
{
	[store release];
	store = nil;
	[keyList release];
	[super dealloc];
}
@end
