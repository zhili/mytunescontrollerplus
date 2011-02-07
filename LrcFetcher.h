#import <Foundation/Foundation.h>
#import "QWatchedOperationQueue.h"
#import "LrcStorage.h"
#import "basictypes.h"

@protocol lrcFetcherDelegate;

@interface lrcFetcher : NSObject
{
    NSString *                      _lrcDirPath;
    id<lrcFetcherDelegate>  _delegate;
    QWatchedOperationQueue *        _queue;
    BOOL                            _done;
    NSError *                       _error;
    NSMutableDictionary *           _foundImageURLToPathMap;
    NSUInteger                      _runningOperationCount;
	NSString *_artist;
	NSString *_title;
	LrcStorage *_lrcStorage;
	LRC_ENGINE _lrcEngine;
}

- (id)initWithArtist:(NSString*)artist
			   Title:(NSString*)title
		  LRCStorage:(LrcStorage*)store;

@property (nonatomic, copy, readonly) NSString *artist;
@property (nonatomic, copy, readonly) NSString *title;

// Things you can change before calling -start.
@property LRC_ENGINE lrcEngine;
@property (nonatomic, copy, readwrite) NSString *lrcDirPath;      // defaults to the "images" directory within the temporary directory
// don't change this after calling -startWithURLString:
@property (nonatomic, assign, readwrite) id<lrcFetcherDelegate> delegate;

// Things that are meaningful after you've called -start.

@property (nonatomic, assign, readwrite) BOOL done;               // observable
@property (nonatomic, copy, readonly ) NSError *error;              // nil if no error
@property (nonatomic, copy, readonly ) NSDictionary *imageURLToPathMap;  // NSURL -> NSNull (in progress), NSError (failed), NSString (downloaded)

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
// You can implement this delegate method to do your own logging.
// You're called with some text, the URL that the text relates to, 
// the depth of that URL (0 if the it relates to the main page, 1 
// if it relates to resource directly linked to from the main page, 
// and so on) and an optional error.

@end