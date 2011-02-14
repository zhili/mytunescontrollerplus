//
//  PreferencesController.m
//  MyTunesController
//
//  Created by Toomas Vahter on 25.12.09.
//  Copyright (c) 2010 Toomas Vahter
//
//  This content is released under the MIT License (http://www.opensource.org/licenses/mit-license.php).
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


#import "PreferencesController.h"
#import <CoreServices/CoreServices.h>

@interface PreferencesController()
- (BOOL)isAppStartingOnLogin;
- (void)insertAppToLoginItems;
- (void)removeAppFromLoginItems;
@end


@implementation PreferencesController

- (id)init 
{
	return [super initWithWindowNibName:@"Preferences"];
}

- (void)showWindow:(id)sender 
{
	[self.window center];
	[super showWindow:sender];
	NSInteger state = 0;
	([self isAppStartingOnLogin]) ? (state = NSOnState) : (state = NSOffState);
	[loginCheckBox setState:state];
	[self.window makeKeyAndOrderFront:self];
}

- (IBAction)toggleStartOnLogin:(id)sender 
{
	if ([(NSButton*)sender state] == NSOnState) {
		[self insertAppToLoginItems];
	} 
	else {
		[self removeAppFromLoginItems];
	}
}

#pragma mark -

- (BOOL)isAppStartingOnLogin 
{
	LSSharedFileListRef loginListRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	BOOL startOnLogin = NO;
	if (loginListRef) {
		NSArray *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(loginListRef, NULL);
		NSURL *itemURL;
		for (id itemRef in loginItemsArray) {		
			if (LSSharedFileListItemResolve((LSSharedFileListItemRef)itemRef, 0, (CFURLRef *) &itemURL, NULL) == noErr) {
				if ([[itemURL path] hasPrefix:[[NSBundle mainBundle] bundlePath]])
					startOnLogin = YES;
			}
		}
		[loginItemsArray release];
		CFRelease(loginListRef);
	}
	return startOnLogin;
}

- (void)insertAppToLoginItems 
{
	LSSharedFileListRef loginListRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	if (loginListRef) {
		NSURL *bundleURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath] isDirectory:YES];
		LSSharedFileListItemRef loginItemRef = LSSharedFileListInsertItemURL(loginListRef, kLSSharedFileListItemLast, 
																			 NULL, NULL, (CFURLRef)bundleURL, NULL, NULL);             
		if (loginItemRef) {
			CFRelease(loginItemRef);
		}
		CFRelease(loginListRef);
	}
}

- (void)removeAppFromLoginItems 
{
	LSSharedFileListRef loginListRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	if (loginListRef) {
		NSArray *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(loginListRef, NULL);
		NSURL *itemURL;
		for (id itemRef in loginItemsArray) {		
			if (LSSharedFileListItemResolve((LSSharedFileListItemRef)itemRef, 0, (CFURLRef *) &itemURL, NULL) == noErr) {
				if ([[itemURL path] hasPrefix:[[NSBundle mainBundle] bundlePath]])
					LSSharedFileListItemRemove(loginListRef, (LSSharedFileListItemRef)itemRef);
			}
		}
		[loginItemsArray release];
		CFRelease(loginListRef);
	}
}

@end
