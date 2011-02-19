//
//  iTunesController.m
//  MyTunesController
//
//  Created by Toomas Vahter on 27.07.10.
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

#import "iTunesController.h"
#import "ImageScaler.h"

@implementation iTunesController

@synthesize delegate;

+ (id)sharedInstance 
{	
	static iTunesController *sharedInstance = nil;
	
	if (!sharedInstance)
		sharedInstance = [[iTunesController alloc] init];
	
	return sharedInstance;
}

- (id)init 
{	
	if ((self = [super init])) {
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self
															selector:@selector(_iTunesSongDidChange:)
																name:@"com.apple.iTunes.playerInfo" 
															  object:@"com.apple.iTunes.player"];
		
		iTunesApp = (iTunesApplication *)[[SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"] retain];
	}
	return self;
}

- (void)dealloc 
{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	[iTunesApp release];
	[super dealloc];
}

- (BOOL)isPlaying
{
	if (iTunesApp.isRunning == NO)
		return NO;
	
	if (iTunesApp.playerState == iTunesEPlSPlaying)
		return YES;

	return NO;
}

- (void)playPause
{
	// starts iTunes if not launched
	[iTunesApp playpause];
}

- (void)playPrevious
{
	if (iTunesApp.isRunning) 
		[iTunesApp backTrack];
}

- (void)playNext
{
	if (iTunesApp.isRunning) 
		[iTunesApp nextTrack];
}

- (iTunesTrack *)currentTrack
{	
	if (iTunesApp.isRunning == NO) 
		return nil;
	
	return iTunesApp.currentTrack;
}

- (void)_iTunesSongDidChange:(NSNotification *)aNotification 
{	
	iTunesTrack *track = nil;
	
	if ([[[aNotification userInfo] objectForKey:@"Player State"] isEqualToString:@"Stopped"] == NO) 
		track = self.currentTrack;
	
	if ([self.delegate respondsToSelector:@selector(iTunesTrackDidChange:)])
		[self.delegate iTunesTrackDidChange:track];
}

// current track's playing time.
- (NSInteger)playerPosition
{
	if (iTunesApp.isRunning == NO) 
		return -1;
	return iTunesApp.playerPosition;
}

@end
