//
//  LRCManager.h
//  MyTunesControllerPlus
//
//  Created by zhili hu on 2/9/11.
//  Copyright 2011 scut. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LrcStorage.h"

@interface LRCManagerController : NSWindowController {
	IBOutlet NSTableView *tableView;
	NSMutableArray *keyList;
	IBOutlet NSButton *deleteButton;
	LrcStorage *store;
}

- (id)initWithStorage:(LrcStorage*)lrcstore;
- (IBAction)deleteIt:(id)sender;

@end
