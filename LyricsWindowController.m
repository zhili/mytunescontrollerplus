//
//  LyricsWindowController.m
//  MyTunesController
//
//  Created by Toomas Vahter on 18.09.10.
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

#import "LyricsWindowController.h"


@implementation LyricsWindowController

@synthesize track;
@synthesize lyricsText;

- (id)init
{
	if ((self = [super initWithWindowNibName:@"LyricsWindow" owner:self])) {
		lyricsText = @"No Lyrics";
	}
	
	return self;
}

- (void)showWindow:(id)sender
{
	[super showWindow:sender];
	[self.window makeFirstResponder:nil];
}

- (void)dealloc
{
	[lyricsText release];
	[track release];
	[super dealloc];
}


- (NSFont *)lyricsFont
{
	return [NSFont fontWithName:@"Lucida Grande" size:10.f];
}

- (NSColor *)lyricsTextColor
{
	return [NSColor colorWithCalibratedWhite:1.f alpha:0.8];
}

@end
