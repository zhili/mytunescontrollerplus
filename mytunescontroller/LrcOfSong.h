//
//  LrcOfSong.h
//  MyTunesControllerPlus
//
//  Created by zhili hu on 2/20/11.
//  Copyright 2011 scut. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LrcOfSong : NSObject
{
	NSString *_title;
	NSString *_artist;
	NSURL *_downloadURL;
}

- (id)initWithArtist:(NSString *)artist 
			   Title:(NSString *)title
		 DownloadURL:(NSURL*)dlURL;

@property (nonatomic, readwrite, copy) NSString *title;
@property (nonatomic, readwrite, copy) NSString *artist;
@property (nonatomic, readwrite, retain) NSURL *downloadURL;

@end

