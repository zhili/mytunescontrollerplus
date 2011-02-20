//
//  SosoLrcInfoParser.h
//  MyTunesControllerPlus
//
//  Created by zhili hu on 2/20/11.
//  Copyright 2011 scut. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SosoLrcInfoParserDelegate;

@interface SosoLrcInfoParser : NSOperation {
    NSData *            _data;
    NSURL *             _URL;
    BOOL                _useRelaxedParsing;
    NSMutableArray *    _mutableLrcURLs;
    NSError *           _error;
	NSURL *_baseLrcURL;
	NSMutableData *_characterBuffer;
	BOOL _parsingLRC;
	id<SosoLrcInfoParserDelegate> delegate;
}

- (id)initWithData:(NSData *)data fromURL:(NSURL *)url;
// Initialises the operation to parse the specific HTML data, calculating 
// links relative to the url.
@property (readwrite, assign) id<SosoLrcInfoParserDelegate> delegate;
// Things that are configured by the init method and can't be changed.
@property (copy, readonly) NSData *data;
@property (copy, readonly) NSURL *URL;

@property (assign, readwrite) BOOL useRelaxedParsing;

@property (copy, readonly) NSError *error;
@property (copy, readonly) NSArray *lrcURLs;

@end

@protocol SosoLrcInfoParserDelegate <NSObject>
-(void)parseDone:(SosoLrcInfoParser *)operation;
@end


