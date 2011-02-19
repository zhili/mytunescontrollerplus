//
//  ImageScaler.m
//  MyTunesController
//
//  Created by Toomas Vahter on 30.07.10.
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

#import "ImageScaler.h"


@implementation ImageScaler

+ (NSImage *)scaleImage:(NSImage *)sourceImage fillSize:(NSSize)targetSize
{
	NSSize sourceSize = sourceImage.size;
	
	NSRect sourceRect = NSZeroRect;
	if (sourceSize.height > sourceSize.width) {
		sourceRect = NSMakeRect(0.0, 
								round((sourceSize.height - sourceSize.width) / 2), 
								sourceSize.width, 
								sourceSize.width);
	}
	else {
		sourceRect = NSMakeRect(round((sourceSize.width - sourceSize.height) / 2), 
								0.0, 
								sourceSize.height, 
								sourceSize.height);
	}
	
	NSRect destinationRect = NSZeroRect;
	destinationRect.size = targetSize;
	
	NSImage *final = [[[NSImage alloc] initWithSize:targetSize] autorelease];
	[final lockFocus];
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	[sourceImage drawInRect:destinationRect fromRect:sourceRect operation:NSCompositeSourceOver fraction:1.0];
	[final unlockFocus];
	return final;
}

@end
