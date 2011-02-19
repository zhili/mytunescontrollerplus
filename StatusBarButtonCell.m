//
//  StatusBarButtonCell.m
//  MyTunesController
//
//  Created by Toomas Vahter on 14.11.09.
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

#import "StatusBarButtonCell.h"


@implementation StatusBarButtonCell

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView 
{
	NSBezierPath *path = [NSBezierPath bezierPathWithRect:cellFrame];
	 
	if ([self isHighlighted]) {
		[[NSColor blueColor] set];
	} else {
		[[NSColor clearColor] set];
	}
	[path fill];
	
	// has image
	if(self.image) {

		[self.image setFlipped:YES];
		[self.image drawInRect:[self imageRectForBounds:cellFrame] 
					  fromRect:NSZeroRect 
					 operation:NSCompositeSourceOver 
					  fraction:1.0];
	}
	// has title
	if(self.title) {
		//NSMutableParagraphStyle* style = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
		//[style setAlignment:NSCenterTextAlignment];
		NSDictionary *styleDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
										 [NSColor blackColor], NSForegroundColorAttributeName,
										 [NSFont fontWithName:@"Helvetica" size:(CGFloat)14.0], NSFontAttributeName,
										 //style, NSParagraphStyleAttributeName, 
										 nil];
		NSRect titleRect = [self titleRectForBounds:cellFrame];
		[self.title drawInRect:titleRect withAttributes:styleDictionary];
	}
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView 
{
	[self drawInteriorWithFrame:cellFrame inView:controlView];
}

@end
