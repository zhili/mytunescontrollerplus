//
//  LrcTokensPool.h
//  lrcParser
//
//  Created by zhili hu on 1/25/11.
//  Copyright 2011 scut. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface LrcTokensPool : NSObject {
	NSString *path_;
	NSMutableArray *lyricPool_;
	NSMutableDictionary *attributes_;
}

@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *artist;
@property (nonatomic, readonly) NSString *album;
@property (nonatomic, readonly) NSString *lrcauther;
@property (nonatomic, readonly) NSArray *lyrics;

- (id)initWithFilePath:(NSString *)path;
- (BOOL)parseLyrics;
- (NSString*)getLyricsByTime:(int)trackTime;
- (NSString*)getLyricsByTime:(int)trackTime lyricsID:(NSUInteger *)lyid;
- (id)initWithFilePathAndParseLyrics:(NSString *)path;
- (NSString*)getLyricsByID:(int)lyid;

@end
