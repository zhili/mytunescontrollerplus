//
//  lrcParser.h
//  lrcParser
//
//  Created by zhili hu on 1/24/11.
//  Copyright 2011 scut. All rights reserved.
//

#import <Foundation/Foundation.h>


enum LrcTokenType {
	LRC_TOKEN_TEXT = 0,
	LRC_TOKEN_ATTR,          
	LRC_TOKEN_TIME, 
	LRC_TOKEN_INVALID,
};


@interface LrcTextToken : NSObject {
	enum LrcTokenType tokenType;
	NSString *lyrics;
}

@property (nonatomic, readonly) enum LrcTokenType tokenType; 
@property (nonatomic, readwrite, copy) NSString *lyrics;
@end


@interface LrcAttrToken : NSObject {
	enum LrcTokenType tokenType;
	NSString *key_;
	NSString *value_;
}

@property (nonatomic, readonly) enum LrcTokenType tokenType;
@property (nonatomic, readwrite, copy) NSString *key;
@property (nonatomic, readwrite, copy) NSString *value;
@end

@interface LrcTimeToken : NSObject {
	enum LrcTokenType tokenType;
	int timeStamp;
}

@property (nonatomic, readonly) enum LrcTokenType tokenType;
@property (nonatomic, readwrite, assign) int timeStamp;

@end


@interface LyricItem : NSObject {
	int lyid_;
	int timestamp_;
	NSString *lyrics_;
};

- (id)initWithLyricsId:(int)LyID
			 timeStamp:(int)TimeStamp
				lyrics:(NSString*)Lyrics;

@property (nonatomic, readwrite, copy) NSString *lyrics;
@property (nonatomic, readwrite, assign) int timeStamp;
@property (nonatomic, readwrite, assign) int lyid;


@end