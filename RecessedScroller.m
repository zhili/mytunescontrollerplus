//
//  RecessedScroller.m
//  MyTunesController
//
//  Created by Toomas Vahter on 06.11.10.
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

#import "RecessedScroller.h"


@implementation RecessedScroller

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect])) {
		[self setArrowsPosition:NSScrollerArrowsNone];
		[self setControlSize:NSSmallControlSize];
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		[self setArrowsPosition:NSScrollerArrowsNone];
		[self setControlSize:NSSmallControlSize];
	}
	
	return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	if ([self usableParts] != NSNoScrollerParts) {
		NSRect rect = [self bounds];
		[self drawKnobSlotInRect:rect highlight:NO];
		[self drawKnob];
	}
}

#define kKnobRadius 5.f

- (void)drawKnobSlotInRect:(NSRect)slotRect highlight:(BOOL)flag
{
	// I only draw slot
	NSRect knobSlot = [self rectForPart:NSScrollerKnobSlot];
	[[NSColor colorWithCalibratedWhite:0.2 alpha:1.f] set];
	[[NSBezierPath bezierPathWithRoundedRect:knobSlot xRadius:kKnobRadius yRadius:kKnobRadius] fill];
}

- (void)drawKnob
{
    NSRect rect = [self rectForPart:NSScrollerKnob];
	[[NSColor colorWithCalibratedWhite:0.3 alpha:1.f] set];
	[[NSBezierPath bezierPathWithRoundedRect:rect xRadius:kKnobRadius yRadius:kKnobRadius] fill];
}

@end
