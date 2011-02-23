//
//  LrcSearch.m
//  MyTunesControllerPlus
//
//  Created by zhili hu on 2/20/11.
//  Copyright 2011 zhili hu. All rights reserved.
//

#import "LrcSearch.h"
#import "basictypes.h"
#import "NSString+URLArguments.h"
#import "PageGetOperation.h"
#import "SosoLrcInfoParser.h"
#import "LrcDownloadOperation.h"
#import "LrcOfSong.h"

@interface LrcSearch () <PageGetOperationDelegate, SosoLrcInfoParserDelegate, LrcDownloadOperationDelegate>

@property (nonatomic, retain, readonly) NSOperationQueue *queue;
@property (nonatomic, copy, readwrite) NSError *error;

- (void)stopWithError:(NSError *)error;
@end


@implementation LrcSearch


@synthesize artist = _artist;
@synthesize title = _title;
@synthesize error = _error;
@synthesize done;
@synthesize delegate = _delegate;

- (id)initWithArtist:(NSString*)artist
			   title:(NSString*)title
			delegate:(id)delegate
{
	assert(title != nil || artist != nil);
	
	self = [super init];
	if (self != nil) {
		_title = [title copy];
		_artist = [artist copy];
		_delegate = delegate;
	}
	return self;
	
}

- (id)initWithDelegate:(id)delegate
{
	if (self = [super init]) {
		_delegate = delegate;
	}
	return self;
}

- (void)dealloc
{
	[_queue cancelAllOperations];
	[_queue release];
	
	[_artist release];
	[_title release];
	[super dealloc];	
}

- (NSOperationQueue *)queue
{
	if (_queue == nil) {
		_queue = [[NSOperationQueue alloc] init];
		assert(_queue != nil);
	}
	return _queue;
}

- (BOOL)startSearch
{

	NSURL *url;

	NSString *query = [NSString stringWithFormat:SOSO_QUERY_AT_TEMPLATE, 
			 [_artist stringByEscapingForURLArgumentUsingEncodingGBk], 
			 [_title stringByEscapingForURLArgumentUsingEncodingGBk]];
	
	url = [NSURL URLWithString:query];
	assert(url != nil);
    assert([[[url scheme] lowercaseString] isEqual:@"http"] || [[[url scheme] lowercaseString] isEqual:@"https"]);
 	PageGetOperation *op;
    op = [[[PageGetOperation alloc] initWithURL:url] autorelease];
    op.delegate = self;
    [self.queue addOperation:op];
    return YES;	
}

- (void)pageGetDone:(PageGetOperation *)op
{
    assert([NSThread isMainThread]);
    assert([op isKindOfClass:[PageGetOperation class]]);
    if (op.error != nil) {
        [self stopWithError:op.error];
		if ([self.delegate respondsToSelector:@selector(searchDone:)]) {
			[self.delegate searchDone:nil];
		} 
        DeLog(@"Empty Page.");
    } else {
        DeLog(@"open page successfully");
        SosoLrcInfoParser* nextOp;
		DeLog(@"%@", [op.lastResponse URL]);
		
        nextOp = [[[SosoLrcInfoParser alloc] initWithData:op.responseBody 
                                                fromURL:[op.lastResponse URL]] autorelease];
        assert(nextOp != nil);
        nextOp.useRelaxedParsing = YES;
		nextOp.delegate = self;
        [self.queue addOperation:nextOp];
    }
}

- (void)parseDone:(SosoLrcInfoParser *)op
{
    assert([op isKindOfClass:[SosoLrcInfoParser class]]);
	DeLog(@"parsed links.");
	if ([self.delegate respondsToSelector:@selector(searchDone:)]) {
		[self.delegate searchDone:op.lrcURLs];
	} 
		
}

- (void)stopWithError:(NSError *)error
{
    assert(error != nil);
    [self.queue cancelAllOperations];
	self.error = error;
    self.done = YES;
}

- (void)stopAll
{
	[self stopWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
}

- (BOOL)startDownloadLrc:(LrcOfSong *)lrcOfTheSong
{
	LrcDownloadOperation *downloadOperation;
	downloadOperation = [[[LrcDownloadOperation alloc] initWithURL:lrcOfTheSong.downloadURL
														lrcDirPath:[@"~/Library/Application Support/MyTunesControllerPlus/" stringByExpandingTildeInPath] 
													   lrcFileName:[NSString stringWithFormat:@"%@-%@", lrcOfTheSong.artist, lrcOfTheSong.title]] autorelease];
	assert(downloadOperation != nil);
	downloadOperation.delegate = self;
	[self.queue addOperation:downloadOperation];
	return YES;
}

- (void)downloadDone:(LrcDownloadOperation *)op
{
	
    assert([op isKindOfClass:[LrcDownloadOperation class]]);
    assert([NSThread isMainThread]);
	
    if (op.error != nil) {
		[self stopWithError:op.error];
		if ([self.delegate respondsToSelector:@selector(downloadDone:)]) {
			[self.delegate downloadDone:nil];
		} 
    } else {
		//NSLog(@"download file: %@ ok", op.lrcFilePath);

		if ([self.delegate respondsToSelector:@selector(downloadDone:)]) {
			[self.delegate downloadDone:op.lrcName];
		} 
    }
	
}


@end
