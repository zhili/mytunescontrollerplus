//
//  LRCManager.m
//  MyTunesControllerPlus
//
//  Created by zhili hu on 2/9/11.
//  Copyright 2011 scut. All rights reserved.
//

#import "LRCManagerController.h"
#import "LrcSearch.h"

@interface LRCManagerController () <LrcSearchDelegate>
@end

@implementation LRCManagerController


- (NSMutableArray *)lrcOfSongs
{
	return lrcOfSongs;
}

- (void)setLrcOfSongs:(NSMutableArray *)newLrcOfSong
{
    if (lrcOfSongs != newLrcOfSong)
	{
        [lrcOfSongs autorelease];
        lrcOfSongs = [newLrcOfSong mutableCopy];
    }
}

- (id)initWithStorage:(LrcStorage*)lrcstore
{
	if (self = [super initWithWindowNibName:@"LRCManagerWindow" owner:self]) {
		lrcOfSongs = [NSMutableArray array];
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


- (int)numberOfRowsInTableView:(NSTableView_deleteRow *)tv
{
	NSLog(@"in row number");
	return [keyList count];
}

- (id)tableView:(NSTableView_deleteRow *)tv objectValueForTableColumn:(NSTableColumn *)tc row:(int)row
{

	if (keyList != nil) {
		return [keyList objectAtIndex:row];
	}
    return nil;
}

- (void)tableView:(NSTableView_deleteRow *)tv deleteRows:(NSIndexSet *)selectedRowIndexes
{
	NSLog(@"deleting");
	
	NSUInteger index = [selectedRowIndexes firstIndex];
	
	while(index != NSNotFound) {
		NSString *thisKey = [keyList objectAtIndex:index];
		[store deleteLRCFile:thisKey];
		//[keyList removeObjectAtIndex:index];
		index=[selectedRowIndexes indexGreaterThanIndex:index];
	}
	[keyList removeObjectsAtIndexes:selectedRowIndexes];
	[_tableView reloadData];
}

- (IBAction)SearchIt:(id)sender
{
//	[self willChangeValueForKey:@"lrcOfSongs"];
// 
//	LrcOfSong *asong = [[LrcOfSong alloc] initWithArtist:@"abc" Title:@"adv" DownloadURL:[NSURL URLWithString:@"http://abc.com"]];
//	[lrcOfSongs addObject:asong];
//	[self didChangeValueForKey:@"lrcOfSongs"];
	NSString *ar = [[queryForm cellAtIndex:QFIArtist] stringValue];
	NSString *ti = [[queryForm cellAtIndex:QFITitle] stringValue];
	
	search = [[LrcSearch alloc] initWithArtist:ar Title:ti];
	search.delegate = self;
	[search start];
	[searchProgressIndicator startAnimation:sender];
	[NSApp beginSheet:resultSheet
       modalForWindow:self.window
        modalDelegate:nil
       didEndSelector:NULL
          contextInfo:NULL];
//    [queryForm cellAtIndex:QFITitle];
}

-(void)searchDone:(NSArray *)lrcList
{
	[self willChangeValueForKey:@"lrcOfSongs"];
 
	[lrcOfSongs addObjectsFromArray:lrcList];
	[self didChangeValueForKey:@"lrcOfSongs"];
	[searchProgressIndicator stopAnimation:nil];
}

- (IBAction)closeResultSheet:(id)sender
{
	// Return to normal event handling
	[NSApp endSheet:resultSheet];
	
	// Hide the sheet
	[resultSheet orderOut:sender];
}
- (void)dealloc
{
	[store release];
	store = nil;
	[keyList release];
	[super dealloc];
}
@end
