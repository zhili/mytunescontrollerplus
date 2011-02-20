//
//  LrcOfSong.m
//  MyTunesControllerPlus
//
//  Created by zhili hu on 2/20/11.
//  Copyright 2011 scut. All rights reserved.
//

#import "LrcOfSong.h"



@implementation LrcOfSong

@synthesize title = _title;
@synthesize artist = _artist;
@synthesize downloadURL = _downloadURL;

- (id)initWithArtist:(NSString *)artist 
			   Title:(NSString *)title
		 DownloadURL:(NSURL*)dlURL;
{
	if (self = [super init]) {
		_artist = [artist copy];
		_title = [title copy];
		_downloadURL = [dlURL retain];
	}
	return self;
}

- (void)dealloc
{
	[_downloadURL release];
	[_title release];
	[_artist release];
	[super dealloc];
}

@end