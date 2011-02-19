#import <Foundation/Foundation.h>
#import "LrcStorage.h"
#import "basictypes.h"

@protocol lrcFetcherDelegate;

@interface lrcFetcher : NSObject
{
    NSString *                      _lrcDirPath;
    id<lrcFetcherDelegate>  _delegate;
    NSOperationQueue*        _queue;
    BOOL                            _done;
    NSError *                       _error;
    NSMutableDictionary *           _foundLrcURLToPathMap;
    NSUInteger                      _runningOperationCount;
	NSString *_artist;
	NSString *_title;
	LrcStorage *_lrcStorage;
	LRC_ENGINE _lrcEngine;
}

- (id)initWithArtist:(NSString*)artist
			   Title:(NSString*)title
		  LRCStorage:(LrcStorage*)store;

// must set artist or title if initialize with this.
- (id)initWithLRCStorage:(LrcStorage*)store;

@property (nonatomic, copy) NSString *artist;
@property (nonatomic, copy) NSString *title;

// Things you can change before calling -start.
@property LRC_ENGINE lrcEngine;
@property (nonatomic, copy, readwrite) NSString *lrcDirPath;      // defaults to the "images" directory within the temporary directory
// don't change this after calling -startWithURLString:
@property (nonatomic, assign, readwrite) id<lrcFetcherDelegate> delegate;

// Things that are meaningful after you've called -start.

@property (nonatomic, assign, readwrite) BOOL done;               // observable
@property (nonatomic, copy, readonly) NSError *error;              // nil if no error
@property (nonatomic, copy, readonly) NSDictionary *lrcURLToPathMap;  // NSURL -> NSNull (in progress), NSError (failed), NSString (downloaded)

// Methods to start and stop the fetch.  Note that this is a one-shot thing; 
- (BOOL)start;
- (void)stop;
// Convenience method
+ (id)fetcherWithArtist:(NSString*)artist
				  Title:(NSString*)title 
			 LRCStorage:(LrcStorage*)store;
@end

@protocol lrcFetcherDelegate <NSObject>

@optional

- (void)lrcPageParseDidFinish:(NSError *)error;
- (void)lrcDownloadDidFinishWithArtist:(NSString *)artist Title:(NSString *)title;
- (void)lrcPageLoadDidFinish:(NSError *)error;

@end