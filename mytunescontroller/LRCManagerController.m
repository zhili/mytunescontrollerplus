//
//  LRCManager.m
//  MyTunesControllerPlus
//
//  Created by zhili hu on 2/9/11.
//  Copyright 2011 scut. All rights reserved.
//

#import "LRCManagerController.h"
#import "LrcSearch.h"
#import "LrcOfSong.h"

@interface LRCManagerController () <LrcSearchDelegate>

- (LrcOfSong *)songFromString:(NSString*)songString;

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

- (LrcOfSong *)songFromString:(NSString*)songString
{
	NSScanner *scanner = [NSScanner scannerWithString:songString];
	NSString *at;
	NSString *ti;
	LrcOfSong *asong;
	
	if ([scanner scanUpToString:@"-" intoString:&at]) {
		ti = [songString substringFromIndex:[scanner scanLocation]+1];
		asong = [[LrcOfSong alloc] initWithArtist:at title:ti];
	} else {
		asong = [[LrcOfSong alloc] initWithArtist:songString title:@""];
	}
	return [asong autorelease];
}

- (id)initWithStorage:(LrcStorage*)lrcstore
{
	if (self = [super initWithWindowNibName:@"LRCManagerWindow" owner:self]) {
		lrcOfSongs = [NSMutableArray array];

		store = [lrcstore retain];

		NSArray *lrcFiles = [[store allItemKey] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
		keyList = [[NSMutableArray alloc] initWithCapacity:[lrcFiles count]];
		NSEnumerator *etor = [lrcFiles objectEnumerator];
		id anObject;
		while (anObject = [etor nextObject]) {
			
			[keyList addObject:[self songFromString:anObject]];

		}
		
		_search = [[LrcSearch alloc] initWithDelegate:self];
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
	return [keyList count];
}

- (id)tableView:(NSTableView_deleteRow *)tv objectValueForTableColumn:(NSTableColumn *)tc row:(int)row
{
	if (row != -1) {
		LrcOfSong *asong = [keyList objectAtIndex:row];
		return [asong valueForKey:[tc identifier]];
	}
    return nil;
}


- (void)tableView:(NSTableView_deleteRow *)tv deleteRows:(NSIndexSet *)selectedRowIndexes
{
	
	NSUInteger index = [selectedRowIndexes firstIndex];
	
	while(index != NSNotFound) {
		LrcOfSong *asong = [keyList objectAtIndex:index];
		if ([asong.title length] != 0) {
			[store deleteLRCFile:[NSString stringWithFormat:@"%@-%@", asong.artist, asong.title]];
		} else {
			[store deleteLRCFile:asong.artist];
		}

		index=[selectedRowIndexes indexGreaterThanIndex:index];
	}
	[keyList removeObjectsAtIndexes:selectedRowIndexes];
	[_tableView reloadData];
}

- (IBAction)SearchIt:(id)sender
{

	NSString *ar = [[queryForm cellAtIndex:QFIArtist] stringValue];
	NSString *ti = [[queryForm cellAtIndex:QFITitle] stringValue];
	_search.title = ti;
	_search.artist = ar;

	[_search startSearch];
	[searchProgressIndicator startAnimation:sender];
	[NSApp beginSheet:resultSheet
       modalForWindow:self.window
        modalDelegate:nil
       didEndSelector:NULL
          contextInfo:NULL];
}

-(void)searchDone:(NSArray *)lrcList
{
	if (lrcList != nil) {
		[self willChangeValueForKey:@"lrcOfSongs"];
		
		[lrcOfSongs addObjectsFromArray:lrcList];
		[self didChangeValueForKey:@"lrcOfSongs"];
	}

	[searchProgressIndicator stopAnimation:nil];
}

- (IBAction)closeResultSheet:(id)sender
{
	// Return to normal event handling
	[NSApp endSheet:resultSheet];
	
	// Hide the sheet
	[resultSheet orderOut:sender];
	[_tableView reloadData];
}

- (IBAction)DownloadSelected:(id)sender
{
	NSArray *selectedObjects = [arrayController selectedObjects];
	
	
	for (LrcOfSong *lrcSong in selectedObjects) {
		[_search startDownloadLrc:lrcSong];
	}
	[searchProgressIndicator startAnimation:sender];
}

-(void)downloadDone:(NSString *)lrcName
{
	if (lrcName != nil) {
		[store addLRCFile:lrcName];
		[keyList addObject:[self songFromString:lrcName]];
	}
	[searchProgressIndicator stopAnimation:nil];
}

- (void)dealloc
{
	[_search stopAll];
	[_search release];
	[store release];
	store = nil;
	[keyList release];
	[super dealloc];
}
@end
