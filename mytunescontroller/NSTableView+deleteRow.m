//
//  NSTableView+deleteRow.m
//  MyTunesControllerPlus
//
//  Created by zhili hu on 2/20/11.
//  Copyright 2011 scut. All rights reserved.
//

#import "NSTableView+deleteRow.h"


@implementation NSTableView_deleteRow

- (void)setDataSource:(id)anObject
{
	[super setDataSource:anObject];
	// whether conform delete delegate.
	_dataSourceDeleteRow = [anObject respondsToSelector:@selector(tableView:deleteRows:)];
}

- (void)keyDown:(NSEvent *)theEvent
{
	NSString *keyString;
	unichar   keyChar;
	
	keyString = [theEvent charactersIgnoringModifiers];
	keyChar = [keyString characterAtIndex:0];
	
	switch(keyChar){
			
		case 0177: /* Delete key */
		case NSDeleteFunctionKey:
		case NSDeleteCharFunctionKey:
			if (_dataSourceDeleteRow && ([self selectedRow] != -1) ){
				id<NSTableView_deleteRowDataSouce> deleteHandler = (id<NSTableView_deleteRowDataSouce>)[self dataSource];
				[deleteHandler tableView:self deleteRows:[self selectedRowIndexes]];
			}
			break;
		default:
			;
			
	}
	[super keyDown:theEvent];
}

@end
