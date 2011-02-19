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
#import "basictypes.h"

@implementation LyricsWindowController

@synthesize track;
@synthesize statusText;
@synthesize lyricsPool;
@synthesize lyricsID;

- (id)init
{
	if ((self = [super initWithWindowNibName:@"LyricsWindow" owner:self])) {
		statusText = [[NSString alloc] initWithString:@""];
	}
	
	return self;
}
- (void)windowDidLoad
{
	NSRect windowsFrame = [[self.window contentView] frame];

	DeLog(@"x:%f y:%f, width:%f, height:%f", windowsFrame.origin.x, windowsFrame.origin.y, windowsFrame.size.width, windowsFrame.size.height);
	NSRect scrollFrame = NSMakeRect(windowsFrame.origin.x+20, windowsFrame.origin.y+20, windowsFrame.size.width-40,  windowsFrame.size.height-150);
	
	scrollview = [[NSScrollView alloc] initWithFrame:scrollFrame];
	
	NSSize contentSize = [scrollview contentSize];
	[scrollview setBorderType:NSNoBorder];
	[scrollview setHasVerticalScroller:NO];
	[scrollview setHasHorizontalScroller:NO];
	[scrollview setAutoresizingMask: NSViewWidthSizable |
	 NSViewHeightSizable];
	
	lyricsTextView = [[NSTextView alloc] initWithFrame:scrollFrame];
	[lyricsTextView setMinSize:NSMakeSize(0.0, contentSize.height)];
	[lyricsTextView setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
	[lyricsTextView setVerticallyResizable:YES];
	[lyricsTextView setHorizontallyResizable:NO];
	[lyricsTextView setEditable:NO];
	[lyricsTextView setAutoresizingMask:NSViewWidthSizable];
	[[lyricsTextView textContainer]
	 setContainerSize:NSMakeSize(contentSize.width, FLT_MAX)];
	[[lyricsTextView textContainer] setWidthTracksTextView:YES];
	
	// scrollview transparence
	[scrollview setDrawsBackground:NO];
	[[scrollview enclosingScrollView] setDrawsBackground:NO];
	[[[scrollview enclosingScrollView] superview] setNeedsDisplay:YES];
	
	// textview transparence
	[lyricsTextView setDrawsBackground:NO];
	[[lyricsTextView enclosingScrollView] setDrawsBackground:NO];
	[[[lyricsTextView enclosingScrollView] superview] setNeedsDisplay:YES];
	
	// set delegate.
	//[[lyricsTextView textStorage] setDelegate:self];
	
	[scrollview setDocumentView:lyricsTextView];
	
	
	[[self.window contentView] addSubview:scrollview];
	[scrollview release];
	[self.window makeKeyAndOrderFront:nil];
	[self.window makeFirstResponder:lyricsTextView];
}
- (void)awakeFromNib
{

	
}

- (void)setLyricsID:(NSUInteger)lyid
{

	NSColor *blue = [NSColor whiteColor];
	NSColor *darkGray = [NSColor darkGrayColor];
	NSTextStorage *textStorage = [lyricsTextView textStorage];
	NSRange area;
	NSRange highLightArea;
	if (lyricsPool != nil) {
		// remove the old colors
		NSString *string = [textStorage string];
		unsigned int length = [string length];
		area.location = 0;
		area.length = length;
		[textStorage removeAttribute:NSForegroundColorAttributeName range:area];
		
		NSUInteger i = 0;
		area.length = 0;
		// styles for lyrics before current playing.
		while (i < lyid) {
			// we added a new line symbol, so length become larger.
			area.length += [[lyricsPool objectAtIndex:i] length] + 1; 
			i += 1;
		}

		[textStorage addAttribute:NSForegroundColorAttributeName
							value:darkGray
							range:area];
		
		// styles for playing lyrics.
		highLightArea.location = area.length;
		highLightArea.length = [[lyricsPool objectAtIndex:lyid] length];
		
		[textStorage addAttribute:NSForegroundColorAttributeName
							value:blue
							range:highLightArea];

		
		// styles for lyrics after current playing.
		area.location = highLightArea.location + highLightArea.length;
		area.length = [string length] - area.location;
		
		[textStorage addAttribute:NSForegroundColorAttributeName
							value:darkGray
							range:area];
		// set scroll value.
		NSSize contentSize = [scrollview contentSize];
		CGFloat locY = lyid * lineHeight - (ceil(contentSize.height / 2)-1) ; // lyid > 10 ? (lyid - 8 )*lineHeight : 0;
		//DeLog(@"%f, %f", contentSize.width, contentSize.height);
		// scroll to proper position.
		[[scrollview documentView] scrollPoint:NSMakePoint(0, locY)];
		// this keep playing sentence visiable.
		[[scrollview documentView] scrollRangeToVisible:highLightArea];
	}

}


- (void)setLyricsPool:(NSArray*)newPool {
	
	// clear-up the old string.
	NSTextStorage *textStorage = [lyricsTextView textStorage];
	NSUInteger length = [[textStorage string] length];
	
	[textStorage deleteCharactersInRange:NSMakeRange(0, length)];
	
	if (newPool == nil) {
		[lyricsPool release];
		lyricsPool = nil;
		return;
	}
	if (lyricsPool != newPool) {
		
		// clear-up the old lyrics and assign new one.
		[lyricsPool release];
		lyricsPool = [newPool retain];
		
		// setting up the initial attribute.
		NSMutableParagraphStyle *mutParaStyle = [[NSMutableParagraphStyle alloc] init];
		[mutParaStyle setAlignment:NSCenterTextAlignment];
		
		NSFont *lyFont = [NSFont fontWithName:@"Lucida Grande" size:12.f];
		NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSColor darkGrayColor], NSForegroundColorAttributeName,
									mutParaStyle, NSParagraphStyleAttributeName, 
									lyFont, NSFontAttributeName, nil];
		[mutParaStyle release];

		//NSMutableString* theString = [NSMutableString string];
		for (NSString *str in lyricsPool) {
			//[theString appendString:[NSString stringWithFormat:@"%@\n",str]];
			NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n",str] attributes:attributes];
			[textStorage appendAttributedString:attributedString];
			[attributedString release];
		}
		
		// calculat average line height.
		NSTextContainer *textContainer = [[[NSTextContainer alloc]
										   initWithContainerSize: NSMakeSize(FLT_MAX, FLT_MAX)] autorelease];
		NSLayoutManager *layoutManager = [[[NSLayoutManager alloc] init]
										  autorelease];
		[layoutManager addTextContainer:textContainer];
		[textStorage addLayoutManager:layoutManager];
		[textContainer setLineFragmentPadding:0.0];
		[layoutManager glyphRangeForTextContainer:textContainer];
		lineHeight = [layoutManager usedRectForTextContainer:textContainer].size.height / [lyricsPool count];
		
	}
	
}



- (void)showWindow:(id)sender
{
	[super showWindow:sender];
	[self.window makeFirstResponder:nil];
}

- (void)dealloc
{
	[lyricsPool release];
	[lyricsTextView release];
	//[scrollview release];
	[statusText release];
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
