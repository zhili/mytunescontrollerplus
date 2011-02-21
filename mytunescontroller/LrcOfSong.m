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
			   title:(NSString *)title
		 downloadURL:(NSURL*)dlURL;
{
	if (self = [super init]) {
		_artist = [artist copy];
		_title = [title copy];
		_downloadURL = [dlURL retain];
	}
	return self;
}

- (id)initWithArtist:(NSString *)artist title:(NSString *)title
{
	return [self initWithArtist:artist title:title downloadURL:nil];
}

- (void)dealloc
{
	[_downloadURL release];
	[_title release];
	[_artist release];
	[super dealloc];
}

@end