//
//  NSTableView+deleteRow.h
//  MyTunesControllerPlus
//
//  Created by zhili hu on 2/20/11.
//  Copyright 2011 zhili hu. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// http://www.omnigroup.com/mailman/archive/macosx-dev/2001-March/023299.html

@interface NSTableView_deleteRow : NSTableView {
	BOOL _dataSourceDeleteRow;
}

@end


@protocol NSTableView_deleteRowDataSouce <NSObject>
- (void)tableView:(NSTableView *)tableView deleteRows:(NSIndexSet *)selectedRowIndexes;
@end