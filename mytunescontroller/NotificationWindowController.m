//
//  NotificationWindowController.m
//  MyTunesController
//
//  Created by Toomas Vahter on 07.11.09.
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

#import "NotificationWindowController.h"
#import "MyTunesControllerAppDelegate.h"
#import <QuartzCore/QuartzCore.h>

@interface NotificationWindowController()
- (CABasicAnimation *)appearAnimation;
- (CABasicAnimation *)disappearAnimation;
- (void)timerFired:(NSTimer *)timer;
@end

@implementation NotificationWindowController

@synthesize delegate, positionCorner, track;

- (id)init 
{
	return [super initWithWindowNibName:@"Notification"];
}

- (void)dealloc 
{
	[hideTimer invalidate];
	[hideTimer release];
	[track release];
	[super dealloc];
}

- (void)awakeFromNib 
{
	// setting main layer to the content view
	NSView *contentView = [self.window contentView];
	CALayer *layer = [CALayer layer]; 
	[contentView setWantsLayer:YES];
	[contentView setLayer:layer];
	
	CALayer *otherLayer = [CALayer layer];
	otherLayer.cornerRadius = 10.0;
	otherLayer.delegate = self;
	otherLayer.masksToBounds = YES;
	
	[subview setWantsLayer:YES];
	[subview setLayer:otherLayer];
	
	[self.window setAlphaValue:0.0];
		
	[[self.window contentView] addSubview:subview];
	
	[otherLayer display];
	
	[self.window setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx 
{	
	CGRect rect = [layer bounds];
	CGFloat firstComponent = 20.0/255.0;
	CGFloat secondComponent = 100.0/255.0;
	CGColorRef firstColor = CGColorCreateGenericRGB(firstComponent, firstComponent, firstComponent, 1.0);
	CGColorRef secondColor = CGColorCreateGenericRGB(secondComponent, secondComponent, secondComponent, 1.0);
	
	CGColorSpaceRef genericColorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	CGFloat gradientLocations[2] = {0.7, 1.0};
	CGColorRef fillColors[2] = {firstColor, secondColor};
	CFArrayRef fillColorsArray = CFArrayCreate(NULL, (void *)fillColors, 2, &kCFTypeArrayCallBacks);
	CGGradientRef gradient = CGGradientCreateWithColors(genericColorSpace,
														fillColorsArray,
														gradientLocations);
	CGPoint startPoint = CGPointMake(0, 0);
	CGPoint endPoint = CGPointMake(0, rect.size.height);
	
	CGContextDrawLinearGradient(ctx, gradient, startPoint, endPoint, 0);
	CGColorRelease(firstColor);
	CGColorRelease(secondColor);
	CFRelease(genericColorSpace);
	CGGradientRelease(gradient);
	CFRelease(fillColorsArray);
}

- (void)close
{
	[hideTimer invalidate];
	[hideTimer release];
	hideTimer = nil;
	[super close];
}

- (IBAction)showWindow:(id)sender 
{
	[super showWindow:sender];
	
	// set anchor back to default
	[subview.layer setAnchorPoint:CGPointMake(0.5, 0.5)];	
	[subview.layer setFrame:NSRectToCGRect(NSIntegralRect([[self.window contentView] frame]))];
	
	[subview.layer removeAllAnimations];
	[subview.layer addAnimation:[self appearAnimation] forKey:@"transform"];
	[[self.window animator] setAlphaValue:0.9];
	
	[hideTimer invalidate];
	[hideTimer release];
	hideTimer = [[NSTimer scheduledTimerWithTimeInterval:5.0 
												 target:self 
												selector:@selector(timerFired:) 
											   userInfo:nil 
												repeats:NO] retain];    
}

- (void)timerFired:(NSTimer *)timer 
{
	[subview.layer removeAllAnimations];
	[subview.layer addAnimation:[self disappearAnimation] forKey:@"transform"];
	[[self.window animator] setAlphaValue:0.0];
}

- (void)disappear
{
	[self timerFired:nil];
}

#define kWindowMinimumWidth 236

- (void)resize 
{
	NSRect newFrame = [self.window frame];
	NSRect unionRect = NSZeroRect;
	
	for (NSTextField *field in [NSArray arrayWithObjects:artistField, nameField, albumField, durationField, nil]) {
		[field sizeToFit];
		unionRect = NSUnionRect(unionRect, [field frame]);
	}
	
	CGFloat rightMargin = 17.0;
	newFrame.size.width = NSMaxX(unionRect) + rightMargin;
	
	if (NSWidth(newFrame) < kWindowMinimumWidth) 
		newFrame.size.width = kWindowMinimumWidth;
		
	[self.window setFrame:newFrame display:YES animate:NO];
}

- (void)setPositionCorner:(NSUInteger)pos 
{
	NSRect visibleFrame = [[NSScreen mainScreen] visibleFrame];
	NSRect windowFrame = [self.window frame];
	NSPoint pointOrigin = NSZeroPoint;
	
	switch (pos) {
		case 0:	// left up
			pointOrigin = NSMakePoint(NSMinX(visibleFrame) + 20.f, NSMaxY(visibleFrame) - NSHeight(windowFrame) - 20.f);
			break;
		case 1:	// left down
			pointOrigin = NSMakePoint(NSMinX(visibleFrame) + 20.f, NSMinY(visibleFrame) + 20.f);
			break;
		case 2: // right up
			pointOrigin = NSMakePoint(NSMaxX(visibleFrame) - NSWidth(windowFrame) - 20.f, NSMaxY(visibleFrame) - NSHeight(windowFrame) - 20.f);
			break;
		case 3: // right down
			pointOrigin = NSMakePoint(NSMaxX(visibleFrame) - NSWidth(windowFrame) - 20.f, NSMinY(visibleFrame) + 20.f);
			break;	
		default:
			break;
	}
	
	[self.window setFrameOrigin:pointOrigin];
	positionCorner = pos;
}

#pragma mark Animations

- (CABasicAnimation *)appearAnimation 
{	
	CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
	
	CATransform3D transform = CATransform3DMakeScale(1.0, 1.0, 1.0);
	[animation setToValue:[NSValue valueWithCATransform3D:transform]];
	
	transform = CATransform3DMakeScale(0.1, 0.1, 0.1);
	[animation setFromValue:[NSValue valueWithCATransform3D:transform]];
	
	animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	animation.duration = 0.5;	
	return animation;
}

- (CABasicAnimation *)disappearAnimation 
{	
	CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
	
	[animation setDelegate:self];
	
	CATransform3D transform = CATransform3DMakeScale(0.1, 0.1, 0.1);
	[animation setToValue:[NSValue valueWithCATransform3D:transform]];
	
	transform = CATransform3DMakeScale(1.0, 1.0, 1.0);
	[animation setFromValue:[NSValue valueWithCATransform3D:transform]];
	
	animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	animation.duration = 0.5;	
	return animation;
}

- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)flag 
{
	if ([delegate respondsToSelector:@selector(notificationCanBeRemoved)]) 
		[delegate performSelector:@selector(notificationCanBeRemoved)];
}

@end
