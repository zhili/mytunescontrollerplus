//
//  LrcSearch.m
//  MyTunesControllerPlus
//
//  Created by zhili hu on 2/20/11.
//  Copyright 2011 scut. All rights reserved.
//

#import "LrcSearch.h"
#import "basictypes.h"
#import "NSString+URLArguments.h"
#import "PageGetOperation.h"
#import "SosoLrcInfoParser.h"

@interface LrcSearch () <PageGetOperationDelegate, SosoLrcInfoParserDelegate>

@property (nonatomic, retain, readonly) NSOperationQueue *queue;
@property (nonatomic, copy, readwrite) NSError *error;

- (void)stopWithError:(NSError *)error;
@end


@implementation LrcSearch


@synthesize artist = _artist;
@synthesize title = _title;
@synthesize error = _error;
@synthesize done;
@synthesize delegate;

- (id)initWithArtist:(NSString*)artist
			   Title:(NSString*)title
{
	assert(title != nil || artist != nil);
	
	self = [super init];
	if (self != nil) {
		_title = [title copy];
		_artist = [artist copy];
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

- (BOOL)start
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
	
//    if (op.error != nil) {
//		DeLog(@"parse error.%@", op.error);
//		[self stopWithError:op.error];
//	} else {
//		 
//		 NSURL *thisURL;
//		 NSURL *thisURLAbsolute;
//		 NSError *noLRCLinkError = nil;
		 
		 DeLog(@"parsed links.");
		if ([self.delegate respondsToSelector:@selector(searchDone:)]) {
			[self.delegate searchDone:op.lrcURLs];
		} 
		
//		 for (thisURL in op.lrcURLs) {
//			 if ([op.lrcURLs count] > 0) {
//				 thisURL = [op.lrcURLs objectAtIndex:0];
//				 thisURLAbsolute = [thisURL absoluteURL];
//				 assert(thisURLAbsolute != nil);
//				 DeLog(@"%@", thisURL);
//			 } else {
//				 
//				 NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"No LRC Link is Founded Error"
//																	  forKey:NSLocalizedDescriptionKey];
//				 noLRCLinkError = [NSError errorWithDomain:NSCocoaErrorDomain
//													  code:-50
//												  userInfo:userInfo];
//				 [self stopWithError:noLRCLinkError];
//			 }
//		 }
//	 }
}

- (void)stopWithError:(NSError *)error
{
    assert(error != nil);
    [self.queue cancelAllOperations];
	self.error = error;
    self.done = YES;
}

- (void)stop
{
	[self stopWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
}


@end
