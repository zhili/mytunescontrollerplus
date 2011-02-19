#import "LRCFetcher.h"
#import "basictypes.h"
#import "LrcDownloadDelegate.h"
#import "PageGetDelegate.h"
#import "LRCLinkFinder.h"
#import "NSString+URLArguments.h"
#import "LrcStorage.h"

#define SOGOU_QUERY_AT_TEMPLATE @"http://mp3.sogou.com/gecisearch.so?query=%@+%@"
#define BAIDU_QUERY_AT_TEMPLATE @"http://mp3.baidu.com/m?f=ms&tn=baidump3lyric&ct=150994944&lf=2&rn=10&word=%@&lm=-1"
#define LRC123 @"http://www.lrc123.com/?keyword=%@+%@&field=all"
#define SOSO_QUERY_AT_TEMPLATE @"http://cgi.music.soso.com/fcgi-bin/m.q?w=%@+%@&source=1&t=7"

// from gtm-http-fetcher.
static const NSTimeInterval kGiveUpInterval = 30.0;

@interface lrcFetcher () <QHTMLLinkFinderDelegate, PageGetOperationDelegate, LrcDownloadOperationDelegate>


@property (nonatomic, copy, readwrite) NSError *error;
@property (nonatomic, retain, readonly ) NSOperationQueue *queue;
@property (nonatomic, retain, readonly ) NSMutableDictionary *foundLrcURLToPathMap;
@property (nonatomic, assign, readwrite) NSUInteger runningOperationCount;

- (void)startPageGet:(NSURL *)pageURL;
@end

@implementation lrcFetcher


@synthesize artist = _artist;
@synthesize title = _title;
@synthesize done = _done;
@synthesize foundLrcURLToPathMap = _foundLrcURLToPathMap;
@synthesize lrcDirPath = _lrcDirPath;
@synthesize runningOperationCount = _runningOperationCount;
@synthesize delegate = _delegate;
@synthesize lrcEngine = _lrcEngine;

- (id)initWithArtist:(NSString*)artist
			   Title:(NSString*)title
		  LRCStorage:(LrcStorage*)store
{
	assert(title != nil || artist != nil);

	self = [super init];
	if (self != nil) {
		self->_title = [title copy];
		self->_artist = [artist copy];
		self->_lrcDirPath = [[store lrcStorePath] copy];
		self->_foundLrcURLToPathMap = [[NSMutableDictionary alloc] init];
		_lrcStorage = [store retain];
	}
	return self;

}

- (id)initWithLRCStorage:(LrcStorage*)store
{
	if (self = [super init]) {
		self->_lrcDirPath = [[store lrcStorePath] copy];
		self->_foundLrcURLToPathMap = [[NSMutableDictionary alloc] init];
		_lrcStorage = [store retain];
	}
	return self;
}

- (void)dealloc
{	
	[self->_lrcStorage release];
	[self->_title release];
	[self->_artist release];
	[self->_foundLrcURLToPathMap release];
	[self->_lrcDirPath release];
	[self->_queue cancelAllOperations];
	[self->_queue release];
	[self->_error release];
	[super dealloc];
}

- (NSOperationQueue *)queue
{
	if (self->_queue == nil) {
		self->_queue = [[NSOperationQueue alloc] init];
		assert(self->_queue != nil);
	}
	return self->_queue;
}


- (NSDictionary *)lrcURLToPathMap
// This getter returns a snapshot of the current fetcher state so that, 
// if you call it before the fetcher is done, you don't get a mutable array 
// that's still being mutated.
{
    return [[self.foundLrcURLToPathMap copy] autorelease];
}

- (BOOL)start
{
	NSString *query = nil;
	NSURL *url;
	switch (self.lrcEngine) {
		case LRC123_LRC_ENGINE:
			query = [NSString stringWithFormat:LRC123, 
					 [_artist stringByEscapingForURLArgumentUsingEncodingGB_18030], 
					 [_title stringByEscapingForURLArgumentUsingEncodingGB_18030]];
			DeLog(@"using lrc123.");
			break;
			
		case SOGOU_LRC_ENGINE:
			query = [NSString stringWithFormat:SOGOU_QUERY_AT_TEMPLATE, 
					 [_artist stringByEscapingForURLArgumentUsingEncodingGB_18030], 
					 [_title stringByEscapingForURLArgumentUsingEncodingGB_18030]];
			DeLog(@"using sogou.");
			break;
			
		case SOSO_LRC_ENGINE:
			query = [NSString stringWithFormat:SOSO_QUERY_AT_TEMPLATE, 
					 [_artist stringByEscapingForURLArgumentUsingEncodingGBk], 
					 [_title stringByEscapingForURLArgumentUsingEncodingGBk]];
			DeLog(@"using soso.");
			break;
		default:
			break;
	}

	url = [NSURL URLWithString:query];
	assert(url != nil);
    assert([[[url scheme] lowercaseString] isEqual:@"http"] || [[[url scheme] lowercaseString] isEqual:@"https"]);
    [self startPageGet:url];
    return YES;
}

@synthesize error = _error;

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


- (void)startPageGet:(NSURL *)pageURL
{
    assert([pageURL baseURL] == nil);       // must be an absolute URL
	PageGetOperation *op;
    op = [[[PageGetOperation alloc] initWithURL:pageURL] autorelease];
    op.delegate = self;
    [self.queue addOperation:op];
    // ... continues in -pageGetDone:
}
- (void)pageGetDone:(PageGetOperation *)op
{
    assert([NSThread isMainThread]);
    assert([op isKindOfClass:[PageGetOperation class]]);
    if (op.error != nil) {
        [self stopWithError:op.error];
        DeLog(@"Empty Page.");
		if ([self.delegate respondsToSelector:@selector(lrcPageLoadDidFinish:)]) {
			[self.delegate lrcPageLoadDidFinish:op.error];
		} 
    } else {
        DeLog(@"open page successfully");
        QHTMLLinkFinder* nextOp;
		DeLog(@"%@", [op.lastResponse URL]);

        nextOp = [[[QHTMLLinkFinder alloc] initWithData:op.responseBody 
                                                fromURL:[op.lastResponse URL]] autorelease];
        assert(nextOp != nil);
        nextOp.useRelaxedParsing = YES;
		nextOp.lrcEngine = self.lrcEngine;
		nextOp.delegate = self;
        [self.queue addOperation:nextOp];
    }
}

- (void)parseDone:(QHTMLLinkFinder *)op
{
    assert([op isKindOfClass:[QHTMLLinkFinder class]]);
	
    /*if (op.error != nil) {
			DeLog(@"parse error.%@", op.error);
        // An error parsing the main page is fatal to the entire process; an error 
        [self stopWithError:op.error];
		
    } else */{

        NSURL *thisURL;
        NSURL *thisURLAbsolute;
		NSError *noLRCLinkError = nil;
        
        // Download all of the images in the page, but only if we haven't already 
        // downloaded that image.
		DeLog(@"parsed links.");
        //for (thisURL in op.lrcURLs) {
		if ([op.lrcURLs count] > 0) {
			thisURL = [op.lrcURLs objectAtIndex:0];
            thisURLAbsolute = [thisURL absoluteURL];
            assert(thisURLAbsolute != nil);
			DeLog(@"%@", thisURL);
            if ([self.foundLrcURLToPathMap objectForKey:thisURLAbsolute] != nil) {
				DeLog(@"duplicate");
            } else {
				DeLog(@"start new download op from:%@",thisURLAbsolute);
				LrcDownloadOperation *downloadOperation;
                
                [self.foundLrcURLToPathMap setObject:[NSNull null] forKey:thisURLAbsolute];
				
                downloadOperation = [[[LrcDownloadOperation alloc] initWithURL:thisURLAbsolute 
																	lrcDirPath:self.lrcDirPath 
																   lrcFileName:[NSString stringWithFormat:@"%@-%@", _artist, _title]] autorelease];
                assert(downloadOperation != nil);
				downloadOperation.delegate = self;
                [self.queue addOperation:downloadOperation];
            }
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
    
//    [self operationDidFinish];
}

- (void)downloadDone:(LrcDownloadOperation *)op
{

    assert([op isKindOfClass:[LrcDownloadOperation class]]);
    assert([NSThread isMainThread]);
	
    // Replace the NSNull in the foundImageURLToPathMap with the path to the downloaded 
    // file (on success) or the error.  Note that we use op.URL here, not [op.lastResponse URL], 
    // because this stuff is keyed on the original URL, not the final URL after redirects.
    
    assert([[self.foundLrcURLToPathMap objectForKey:op.URL] isEqual:[NSNull null]]);
    if (op.error != nil) {
		// [self.foundImageURLToPathMap setObject:op.error forKey:op.URL];
        //[self logText:@"image download error" URL:op.URL depth:op.depth error:op.error];
		[self stopWithError:op.error];
    } else {
		[self.foundLrcURLToPathMap setObject:op.lrcFilePath forKey:op.URL];
		[_lrcStorage addLRCFile:[NSString stringWithFormat:@"%@-%@", _artist, _title]];
		NSLog(@"download file: %@ ok", op.lrcFilePath);
		if ([self.delegate respondsToSelector:@selector(lrcDownloadDidFinishWithArtist:Title:)]) {
			[self.delegate lrcDownloadDidFinishWithArtist:_artist Title:_title];
		} 
    }

}

+ (id)fetcherWithArtist:(NSString*)artist
				  Title:(NSString*)title 
			 LRCStorage:(LrcStorage*)store
{
	lrcFetcher *result;
	result = [[[self alloc] initWithArtist:artist Title:title LRCStorage:store] autorelease];
	if (result != nil) {
		DeLog(@"Fired a new fetcher");
	}
	
	return result;
}



@end
