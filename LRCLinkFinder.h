#import <Foundation/Foundation.h>

@interface QHTMLLinkFinder : NSOperation
{
    NSData *            _data;
    NSURL *             _URL;
    BOOL                _useRelaxedParsing;
    NSMutableArray *    _mutableLrcURLs;
    NSError *           _error;
	NSURL *_baseLrcURL;
}

- (id)initWithData:(NSData *)data fromURL:(NSURL *)url;
// Initialises the operation to parse the specific HTML data, calculating 
// links relative to the url.

// Things that are configured by the init method and can't be changed.

@property (copy, readonly) NSData *data;
@property (copy, readonly) NSURL *URL;
@property (copy, readonly) NSURL *baseLrcURL;
// Things you can configure before queuing the operation.

@property (assign, readwrite) BOOL useRelaxedParsing;

// Things that are only really useful after the operation is finished.

@property (copy, readonly) NSError *error;
@property (copy, readonly) NSArray *lrcURLs;

@end