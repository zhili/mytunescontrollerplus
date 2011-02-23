//
//  lrcParser.m
//  lrcParser
//
//  Created by zhili hu on 1/24/11.
//  Copyright 2011 zhili hu. All rights reserved.
//

#import "LrcToken.h"

@implementation LrcTextToken

@synthesize tokenType;
@synthesize lyrics;

- (id)init {
	if (self = [super init]) {
		tokenType = LRC_TOKEN_TEXT;
	}
	return self;
}
@end

@implementation LrcAttrToken
@synthesize tokenType;
@synthesize key = key_;
@synthesize value = value_;


- (id)init {
	if (self = [super init]) {
		tokenType = LRC_TOKEN_ATTR;
	}
	return self;
}

@end


@implementation LrcTimeToken

@synthesize tokenType;
@synthesize timeStamp;


- (id)init {
	if (self = [super init]) {
		tokenType = LRC_TOKEN_TIME;
	}
	return self;
}

@end



@implementation LyricItem

@synthesize lyrics=lyrics_;
@synthesize timeStamp=timestamp_;
@synthesize lyid=lyid_;

- (id)init {
	if (self = [super init]) {
	}
	return self;
}

- (id)initWithLyricsId:(int)LyID
			 timeStamp:(int)TimeStamp
				lyrics:(NSString*)Lyrics
{
	if (self = [super init]) {
		lyid_ = LyID;
		timestamp_ = TimeStamp;
		lyrics_ = [Lyrics copy];
	}
	return self;
}

- (void)dealloc
{
	[lyrics_ release];
	[super dealloc];
}
@end
