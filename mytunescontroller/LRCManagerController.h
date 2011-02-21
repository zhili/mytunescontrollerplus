//
//  LRCManager.h
//  MyTunesControllerPlus
//
//  Created by zhili hu on 2/9/11.
//  Copyright 2011 scut. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LrcStorage.h"
#import "NSTableView+deleteRow.h"

enum queryFormIndices {
    QFIArtist=0,
    QFITitle,
};

@class LrcSearch;

@interface LRCManagerController : NSWindowController {
	IBOutlet NSTableView_deleteRow *_tableView;
	NSMutableArray *keyList;
	IBOutlet NSForm *queryForm;
	IBOutlet NSWindow *resultSheet;
	LrcStorage *store;
	NSMutableArray *lrcOfSongs;
	LrcSearch *_search;
	IBOutlet NSProgressIndicator *searchProgressIndicator;
	IBOutlet NSArrayController *arrayController;
}

@property (nonatomic, readwrite, copy) NSMutableArray *lrcOfSongs;

- (id)initWithStorage:(LrcStorage*)lrcstore;
- (IBAction)SearchIt:(id)sender;
- (IBAction)closeResultSheet:(id)sender;
- (IBAction)DownloadSelected:(id)sender;

@end
