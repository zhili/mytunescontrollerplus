//
//  LrcOfSong.h
//  MyTunesControllerPlus
//
//  Created by zhili hu on 2/20/11.
//  Copyright 2011 zhili hu. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LrcOfSong : NSObject
{
	NSString *_title;
	NSString *_artist;
	NSURL *_downloadURL;
}

- (id)initWithArtist:(NSString *)artist 
			   title:(NSString *)title
		 downloadURL:(NSURL *)dlURL;

- (id)initWithArtist:(NSString *)artist title:(NSString *)title;

@property (nonatomic, readwrite, retain) NSURL *downloadURL;
@property (nonatomic, readwrite, copy) NSString *title;
@property (nonatomic, readwrite, copy) NSString *artist;

@end

