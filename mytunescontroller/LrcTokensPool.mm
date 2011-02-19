//
//  LrcTokensPool.m
//  lrcParser
//
//  Created by zhili hu on 1/25/11.
//  Copyright 2011 scut. All rights reserved.
//

#import "LrcTokensPool.h"
#import "LrcToken.h"
#import "NSScanner+JSON.h"
#import <UniversalDetector/UniversalDetector.h>


@implementation LrcTokensPool


- (id)initWithFilePath:(NSString*)path
{
	if ((self = [super init])) {
		lyricPool_ = [[NSMutableArray array] retain];
		attributes_ =[[NSMutableDictionary alloc] init];
		path_ = [path copy];
		detector_ = [[UniversalDetector alloc] init];
	}
	return self;
}

- (id)initWithFilePathAndParseLyrics:(NSString *)path
{
	self = [self initWithFilePath:path];
	[self parseLyrics];
	return self;
}

- (BOOL)addTimeToken:(NSString *)token	toArray:(NSMutableArray *)arr isTime:(BOOL *)ti
{
	NSCharacterSet *symbolSet = [NSCharacterSet characterSetWithCharactersInString:@":."];
	
	NSArray *Items = [token componentsSeparatedByCharactersInSet:symbolSet];
	BOOL isTimeToken_ = YES;
	for (NSString *item in Items) {
		NSUInteger len = [item length];
		NSUInteger i;
		for (i = 0; i < len; ++i) {
			if (!isdigit([item characterAtIndex:i])) {
				isTimeToken_ = NO;
				break;
			}
		}
	}
	
	if (!isTimeToken_ && [Items count] == 2) {
		[attributes_ setObject:[Items objectAtIndex:1] forKey:[Items objectAtIndex:0]];
	}
	
	if (isTimeToken_) {
		NSArray *timeTokens_ = [token componentsSeparatedByString:@":"];
		NSEnumerator *etor = [timeTokens_ reverseObjectEnumerator];
		id anObject;
		NSUInteger lyTime = 0;
		int nstep = 1;
		while (anObject = [etor nextObject]) {
			//NSLog(@"%f", [anObject floatValue]);
			lyTime += [anObject floatValue] * nstep;
			nstep *= 60;
		}

		*ti = YES;
		[arr addObject: [NSNumber numberWithInteger:lyTime]];
	}
	
	return YES;
}

- (BOOL)parseLyrics
{
	NSString *contents;
	NSData *data = [[NSFileManager defaultManager] contentsAtPath:path_];

	[detector_ reset];
	[detector_ analyzeData:data];
	NSStringEncoding enc = [detector_ encoding];
	contents = [[NSString alloc] initWithData: data
									 encoding: enc];


	NSArray *lines = [contents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	
	NSEnumerator *enumerator=[lines objectEnumerator];
	NSUInteger itemID = 1;
	for (NSString *element in enumerator) {
		
		NSScanner *scanner = [NSScanner scannerWithString:element];
		
		NSMutableArray *timeArray = [NSMutableArray array];
		NSString *nextValue = nil;
		BOOL hasTime = NO;
		while ([scanner scanJSONArrayString:&nextValue]) {

			[self addTimeToken:nextValue toArray: timeArray isTime:&hasTime];
			
		} 
		if (hasTime == YES) {
			NSString *lyrics = [[scanner string] substringFromIndex:[scanner scanLocation]];
			for (NSNumber *num in timeArray) {
				LyricItem *lyric = [[LyricItem alloc] initWithLyricsId:itemID 
															 timeStamp:[num intValue]
																lyrics:lyrics];
				[lyricPool_ addObject:lyric];
				
				[lyric release];
				itemID += 1;
			}
			
			//NSLog(@"%@", [[scanner string] substringFromIndex:[scanner scanLocation]]);
		}

	}
//	[attributes_ enumerateKeysAndObjectsUsingBlock: ^(id key, id obj, BOOL *stop) {
//		NSLog(@"Enumerating Key %@ and Value %@", key, obj);
//	}];
	// sort by timestamp.
	NSSortDescriptor *sortDescriptor;
	sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"timeStamp"
												  ascending:YES] autorelease];
	NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
	[lyricPool_ sortUsingDescriptors:sortDescriptors];
	
	[contents release];
	return YES;
}

- (NSString*)getLyricsByTime:(int)trackTime lyricsID:(NSUInteger *)lyid
{
	NSUInteger lyricsCount = [lyricPool_ count];
	NSUInteger left = 0;
	NSUInteger right = lyricsCount - 1;
	while (left < right) {
		NSUInteger middle = (left + right) / 2 + 1;
		LyricItem *it = [lyricPool_ objectAtIndex:middle];
		if (it.timeStamp < trackTime) {
			left = middle;
		} else {
			right = middle - 1;
		}
	}
	if (left == right) {
		if (lyid != NULL)
			*lyid = left;

		LyricItem *it = [lyricPool_ objectAtIndex:left];
		NSString *retLyrics = [NSString stringWithString:[it lyrics]];
		return retLyrics;
	}
	return @"Failed!";
}

- (NSString*)getLyricsByTime:(int)trackTime
{
	return [self getLyricsByTime:trackTime lyricsID:NULL];
}

- (NSString*)getLyricsByID:(int)lyid
{
	LyricItem *it = [lyricPool_ objectAtIndex:lyid];
	NSString *retLyrics = [NSString stringWithString:[it lyrics]];
	return retLyrics;
}

- (NSString*)title 
{
	return [attributes_ objectForKey:@"ti"];
}

- (NSString*)artist 
{
	return [attributes_ objectForKey:@"ar"];
}

- (NSString*)album 
{
	return [attributes_ objectForKey:@"al"];
}

- (NSString*)lrcauther
{
	return [attributes_ objectForKey:@"by"];
}

- (NSArray *)lyrics 
{
	NSMutableArray *mStr = [NSMutableArray array];
	for (LyricItem *it in lyricPool_) {
		[mStr addObject:[it lyrics]];
	}
	return mStr;
}

- (void)dealloc
{
	[detector_ release];
	[attributes_ release];
	[lyricPool_ release];
	[path_ release];
	[super dealloc];
}

@end
