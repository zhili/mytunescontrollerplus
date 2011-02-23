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

//- (BOOL)addTimeToken:(NSString *)token	toArray:(NSMutableArray *)arr isTime:(BOOL *)ti
//{
//	NSCharacterSet *symbolSet = [NSCharacterSet characterSetWithCharactersInString:@":."];
//	
//	NSArray *Items = [token componentsSeparatedByCharactersInSet:symbolSet];
//	BOOL isTimeToken_ = YES;
//	for (NSString *item in Items) {
//		NSUInteger len = [item length];
//		NSUInteger i;
//		for (i = 0; i < len; ++i) {
//			if (!isdigit([item characterAtIndex:i])) {
//				isTimeToken_ = NO;
//				break;
//			}
//		}
//	}
//	
//	if (!isTimeToken_ && [Items count] == 2) {
//		[attributes_ setObject:[Items objectAtIndex:1] forKey:[Items objectAtIndex:0]];
//	}
//	
//	if (isTimeToken_) {
//		NSArray *timeTokens_ = [token componentsSeparatedByString:@":"];
//		NSEnumerator *etor = [timeTokens_ reverseObjectEnumerator];
//		id anObject;
//		NSUInteger lyTime = 0;
//		int nstep = 1;
//		while (anObject = [etor nextObject]) {
//			//NSLog(@"%f", [anObject floatValue]);
//			lyTime += [anObject floatValue] * nstep;
//			nstep *= 60;
//		}
//
//		*ti = YES;
//		[arr addObject: [NSNumber numberWithInteger:lyTime]];
//	}
//	
//	return YES;
//}

- (void)parseAttributeInfo:(NSString *)attr
{
    NSArray *attrs = [attr componentsSeparatedByString:@":"];
    if ([attrs count] == 2) {
        [attributes_ setObject:[attrs objectAtIndex:1] forKey:[attrs objectAtIndex:0]];
    }
}

- (NSNumber *)parseTimeStamp:(NSString *)timeString
{
    NSArray *timeTokens_ = [timeString componentsSeparatedByString:@":"];
    NSEnumerator *rTimeEnumrator = [timeTokens_ reverseObjectEnumerator];
	id anObject;
    NSUInteger lyricsTime = 0;
    int nstep = 1;
    while (anObject = [rTimeEnumrator nextObject]) {
	    lyricsTime += [anObject floatValue] * nstep;
        nstep *= 60;
    }
    return [NSNumber numberWithInteger:lyricsTime];
}

- (void)parseLyrics:(NSString *)lyricsString withTimeArray:(NSSet *)timeArray
{

    for (NSNumber *num in timeArray) {
        LyricItem *lyric = [[LyricItem alloc] initWithLyricsId:0 timeStamp:[num intValue] lyrics:lyricsString];
        [lyricPool_ addObject:lyric];
        [lyric release];
    }
}

- (NSMutableString *)stantardalizeNewLine:(NSString *)oldString
{
	if(oldString == nil)   
		return nil;
	NSMutableString *ms = [NSMutableString stringWithString:oldString];
	[ms replaceOccurrencesOfString:@"\r\n" withString:@"\n" options:0 range:NSMakeRange(0,[ms length])];
	[ms replaceOccurrencesOfString:@"\r" withString:@"\n" options:0 range:NSMakeRange(0,[ms length])];
	return ms;
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
	
	NSString *lrcString =[self stantardalizeNewLine:contents];
	[contents release];
	NSScanner *lrcScanner = [NSScanner scannerWithString:lrcString];
	
    [lrcScanner setCharactersToBeSkipped:nil];
    enum {
        INITIAL,
        OPENED_A,
        LYRICS,
    } state = INITIAL;
	
    NSString *res = nil;
    NSMutableSet *timeArray = [NSMutableSet set];
	NSUInteger backwordLocation;
	
    do {
        switch (state) {
            case INITIAL:
				
				if ([lrcScanner scanString:@"[" intoString:nil] ) {
					// found '['.  
					state = OPENED_A;
				} else if ([lrcScanner scanUpToString:@"[" intoString:nil] && ![lrcScanner isAtEnd]) {
					// if '[' not found we have have to step forward manually. 
					state = OPENED_A;
					[lrcScanner setScanLocation:[lrcScanner scanLocation] + 1];
				}
				
				break;
            case OPENED_A:
				backwordLocation = [lrcScanner scanLocation];
				if ([lrcScanner scanInt:NULL]) {
					// time attribute.
					[lrcScanner setScanLocation:backwordLocation];
					//NSLog(@"at time");
					[lrcScanner scanUpToString:@"]" intoString:&res];
					[timeArray addObject:[self parseTimeStamp:res]];

					if (![lrcScanner isAtEnd]) {
						[lrcScanner setScanLocation:[lrcScanner scanLocation]+1];
					}
					state = LYRICS;

					if ([lrcScanner scanString:@"\n" intoString:nil]) {
						// if newline comes after time, the add an empty new line.
						[self parseLyrics:@"\n" withTimeArray:timeArray];
						[timeArray removeAllObjects];
						state = INITIAL;
					}

				} else {
					// info attribute
					[lrcScanner scanUpToString:@"]" intoString:&res];
					[self parseAttributeInfo:res];
					if (![lrcScanner isAtEnd]) {
						[lrcScanner setScanLocation:[lrcScanner scanLocation]+1];
					}
					state = INITIAL;
				}
				break;
            case LYRICS:
				// not another timetamp, so add new lyrics.
				// and clear up the time containner.
				if (![lrcScanner scanString:@"[" intoString:nil]) {
					[lrcScanner scanUpToString:@"[" intoString:&res];
					[self parseLyrics:res withTimeArray:timeArray];
					// clear time array
					[timeArray removeAllObjects];
					if (![lrcScanner isAtEnd]) {
						[lrcScanner setScanLocation:[lrcScanner scanLocation] + 1];
					}
				}
				state = OPENED_A;

				break;
        }
		
    } while (![lrcScanner isAtEnd]);
//	[attributes_ enumerateKeysAndObjectsUsingBlock: ^(id key, id obj, BOOL *stop) {
//		NSLog(@"Enumerating Key %@ and Value %@", key, obj);
//	}];
	// sort by timestamp.

	NSSortDescriptor *sortDescriptor;
	sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"timeStamp"
												  ascending:YES] autorelease];
	NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
	[lyricPool_ sortUsingDescriptors:sortDescriptors];

	return YES;
}

- (NSString*)getLyricsByTime:(int)trackTime lyricsID:(NSUInteger *)lyid
{
	NSUInteger lyricsCount = [lyricPool_ count];
	if (lyricsCount > 0) {
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
	}
	return @"Lyrics parsing failed!";
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
