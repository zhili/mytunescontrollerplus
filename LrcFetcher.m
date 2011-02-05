#import "LRCFetcher.h"

#import "LrcDownloadOperation.h"
#import "PageGetOperation.h"
#import "LRCLinkFinder.h"
#import "NSString+URLArguments.h"
#import "LrcStorage.h"

#define SOGOU_QUERY_AT_TEMPLATE @"http://mp3.sogou.com/gecisearch.so?query=%@-%@"
#define BAIDU_QUERY_AT_TEMPLATE @"http://mp3.baidu.com/m?f=ms&tn=baidump3lyric&ct=150994944&lf=2&rn=10&word=%@&lm=-1"
#define LRC123 @"http://www.lrc123.com/?keyword=%@+%@&field=all"


@interface lrcFetcher ()
@property (nonatomic, copy, readwrite) NSError *error;
@property (nonatomic, retain, readonly ) QWatchedOperationQueue *queue;
@property (nonatomic, retain, readonly ) NSMutableDictionary *foundImageURLToPathMap;
@property (nonatomic, assign, readwrite) NSUInteger runningOperationCount;

- (void)startPageGet:(NSURL *)pageURL;
@end

@implementation lrcFetcher


@synthesize artist = _artist;
@synthesize title = _title;
@synthesize done = _done;
@synthesize foundImageURLToPathMap = _foundImageURLToPathMap;
@synthesize lrcDirPath = _lrcDirPath;
@synthesize runningOperationCount = _runningOperationCount;
@synthesize delegate = _delegate;
@synthesize useSogouEngine = _useSogouEngine;

- (id)initWithArtist:(NSString*)artist
			   Title:(NSString*)title
		  LRCStorage:(LrcStorage*)store
{
	assert(title != nil);

	self = [super init];
	if (self != nil) {
		self->_title = [title copy];
		self->_artist = [artist copy];
		self->_lrcDirPath = [[store lrcStorePath] copy];
		assert(self->_lrcDirPath != nil);
		self->_foundImageURLToPathMap = [[NSMutableDictionary alloc] init];
		assert(self->_foundImageURLToPathMap != nil);
		_lrcStorage = [store retain];
	}
	return self;

}

- (void)dealloc
{
	[self->_lrcStorage release];
	[self->_title release];
	[self->_artist release];
	[self->_foundImageURLToPathMap release];
	[self->_lrcDirPath release];
	[self->_queue invalidate];
	[self->_queue cancelAllOperations];
	[self->_queue release];
	[self->_error release];
	[super dealloc];
}

- (QWatchedOperationQueue *)queue
{
	if (self->_queue == nil) {
		self->_queue = [[QWatchedOperationQueue alloc] initWithTarget:self];
		assert(self->_queue != nil);
	}
	return self->_queue;
}



- (NSDictionary *)imageURLToPathMap
// This getter returns a snapshot of the current fetcher state so that, 
// if you call it before the fetcher is done, you don't get a mutable array 
// that's still being mutated.
{
    return [[self.foundImageURLToPathMap copy] autorelease];
}

- (BOOL)start
{
	NSString *query;
	NSURL *url;
	if (self.useSogouEngine) {
		query = [NSString stringWithFormat:SOGOU_QUERY_AT_TEMPLATE, 
				 [_artist stringByEscapingForURLArgumentUsingEncodingGB_18030], 
				 [_title stringByEscapingForURLArgumentUsingEncodingGB_18030]];
		NSLog(@"using sogou.");
	} else {
		query = [NSString stringWithFormat:LRC123, 
				 [_artist stringByEscapingForURLArgumentUsingEncodingGB_18030], 
				 [_title stringByEscapingForURLArgumentUsingEncodingGB_18030]];
	}

	url = [NSURL URLWithString:query];
	assert(url != nil);
    assert([[[url scheme] lowercaseString] isEqual:@"http"] || [[[url scheme] lowercaseString] isEqual:@"https"]);
	
    [self startPageGet:url];
    return YES;
}

@synthesize error = _error;

- (void)stopWithError:(NSError *)error
// An internal method called to stop the fetch and clean things up.
{
    assert(error != nil);
    [self.queue invalidate];
    [self.queue cancelAllOperations];
    self.error = error;
    self.done = YES;
}

- (void)stop
// See comment in header.
{
    [self stopWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
}


- (void)operationDidStart
// Called when an operation has started to increment runningOperationCount. 
{
    self.runningOperationCount += 1;
}

- (void)operationDidFinish
// Called when an operation has finished to decrement runningOperationCount 
// and complete the whole fetch if it hits zero.
{
    assert(self.runningOperationCount != 0);
    self.runningOperationCount -= 1;
    if (self.runningOperationCount == 0) {
        self.done = YES;
    }    
}

- (void)startPageGet:(NSURL *)pageURL
// Starts the operation to GET an HTML page.  Called for both the 
// initial main page, and for any subsequently linked-to pages.
{
    PageGetOperation *  op;
    
    assert([pageURL baseURL] == nil);       // must be an absolute URL
    
    op = [[[PageGetOperation alloc] initWithURL:pageURL] autorelease];
    
    [self.queue addOperation:op finishedAction:@selector(pageGetDone:)];
    [self operationDidStart];
    
    // ... continues in -pageGetDone:
}

- (void)pageGetDone:(PageGetOperation *)op
// Called when the GET for an HTML page is done.  We start a LinkFinder 
// operation to parse the HTML.
{
    assert([op isKindOfClass:[PageGetOperation class]]);
//    assert([NSThread isMainThread]);
    
    if (op.error != nil) {
		
        // An error getting the main page is fatal to the entire process; an error 
        // getting any subsequent pages is just logged.
		[self stopWithError:op.error];
		if ([self.delegate respondsToSelector:@selector(lrcPageLoadDidFinish:)]) {
			[self.delegate lrcPageLoadDidFinish:op.error];
		} 
		NSLog(@"Page not found:%@", op);
		
    } else {
		NSLog(@"get page successfully");
        QHTMLLinkFinder* nextOp;
		NSLog(@"%@", [op.lastResponse URL]);
        // Don't use op.URL here, but rather [op.lastResponse URL] so that relatives 
        // URLs work in the face of redirection.
        nextOp = [[[QHTMLLinkFinder alloc] initWithData:op.responseBody fromURL:[op.lastResponse URL]] autorelease];
        assert(nextOp != nil);
        
        nextOp.useRelaxedParsing = YES;
        if (self.useSogouEngine) {
			nextOp.useSogouEngine = YES;
		}
        [self.queue addOperation:nextOp finishedAction:@selector(parseDone:)];
        [self operationDidStart];
        
        // ... continues in -parseDone:
    }
    
    [self operationDidFinish];
}

- (void)parseDone:(QHTMLLinkFinder *)op
// Called when the link finder operation is done.  We look at the links 
// and start an appropriate number of page get and image download operations. 
{

#pragma unused(op)
    assert([op isKindOfClass:[QHTMLLinkFinder class]]);
//    assert([NSThread isMainThread]);
	
    /*if (op.error != nil) {
			NSLog(@"parse error.%@", op.error);
        // An error parsing the main page is fatal to the entire process; an error 
        [self stopWithError:op.error];
		
    } else */{

        NSURL *thisURL;
        NSURL *thisURLAbsolute;
		NSError *noLRCLinkError = nil;
        
        // Download all of the images in the page, but only if we haven't already 
        // downloaded that image.
		NSLog(@"parsed links.");
        //for (thisURL in op.lrcURLs) {
		if ([op.lrcURLs count] > 0) {
			thisURL = [op.lrcURLs objectAtIndex:0];
            thisURLAbsolute = [thisURL absoluteURL];
            assert(thisURLAbsolute != nil);
			NSLog(@"%@", thisURL);
            if ([self.foundImageURLToPathMap objectForKey:thisURLAbsolute] != nil) {
				NSLog(@"duplicate");
            } else {
				NSLog(@"start new download op from:%@",thisURLAbsolute);
                LrcDownloadOperation *    downloadOperation;
                
                [self.foundImageURLToPathMap setObject:[NSNull null] forKey:thisURLAbsolute];
				
                downloadOperation = [[[LrcDownloadOperation alloc] initWithURL:thisURLAbsolute 
																	lrcDirPath:self.lrcDirPath 
																   lrcFileName:[NSString stringWithFormat:@"%@-%@", _artist, _title]] autorelease];
                assert(downloadOperation != nil);
				
                [self.queue addOperation:downloadOperation finishedAction:@selector(downloadDone:)];
                [self operationDidStart];
                
                // ... continues in -downloadDone:
            }
			// only use the first link temparaly.
        //}
		} else {
			
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"No LRC Link is Founded Error"
																 forKey:NSLocalizedDescriptionKey];
			noLRCLinkError = [NSError errorWithDomain:NSCocoaErrorDomain
												 code:-50
											 userInfo:userInfo];
			if ([self.delegate respondsToSelector:@selector(lrcPageParseDidFinish:)]) {
				[self.delegate lrcPageParseDidFinish:noLRCLinkError];
			} 
			[self stopWithError:noLRCLinkError];
		}

    }
    
    [self operationDidFinish];
}

- (void)downloadDone:(LrcDownloadOperation *)op
// Called when an image download operation is done.
{
	#pragma unused(op)
    assert([op isKindOfClass:[LrcDownloadOperation class]]);
    //assert([NSThread isMainThread]);
	
    // Replace the NSNull in the foundImageURLToPathMap with the path to the downloaded 
    // file (on success) or the error.  Note that we use op.URL here, not [op.lastResponse URL], 
    // because this stuff is keyed on the original URL, not the final URL after redirects.
    
    assert([[self.foundImageURLToPathMap objectForKey:op.URL] isEqual:[NSNull null]]);
    if (op.error != nil) {
       // [self.foundImageURLToPathMap setObject:op.error forKey:op.URL];
        //[self logText:@"image download error" URL:op.URL depth:op.depth error:op.error];
    } else {
       // [self.foundImageURLToPathMap setObject:op.lrcFilePath forKey:op.URL];
		[_lrcStorage addLRCFile:[NSString stringWithFormat:@"%@-%@", _artist, _title]];
		NSLog(@"download file: %@ ok", op.lrcFilePath);
		//[self lrcDownloadDidFinishWithArtist:_artist Title:_title];
		if ([self.delegate respondsToSelector:@selector(lrcDownloadDidFinishWithArtist:Title:)]) {
			[self.delegate lrcDownloadDidFinishWithArtist:_artist Title:_title];
		} 
    }
    
    [self operationDidFinish];
}

+ (id)fetcherWithArtist:(NSString*)artist
				  Title:(NSString*)title 
			 LRCStorage:(LrcStorage*)store
{
	lrcFetcher *result;
	result = [[[self alloc] initWithArtist:artist Title:title LRCStorage:store] autorelease];
	if (result != nil) {
		NSLog(@"Fired a new fetcher");
	}
	
	return result;
}



@end