#import "HttpOperation.h"

@protocol LrcDownloadOperationDelegate;

@interface LrcDownloadOperation : HttpOperation
{
    NSString *_lrcDirPath;
    NSString *_lrcFilePath;
	NSString *_lrcName;
	id<LrcDownloadOperationDelegate> _delegate;
}

@property (copy, readwrite) NSString *lrcDirPath;
@property (copy, readwrite) NSString *lrcFilePath;
@property (copy, readwrite) NSString *lrcName;
@property (nonatomic, assign, readwrite) id<LrcDownloadOperationDelegate> delegate;

- (id)initWithURL:(NSURL *)url lrcDirPath:(NSString *)lrcDirPath lrcFileName:(NSString*)name;
@end

@protocol LrcDownloadOperationDelegate <NSObject>

- (void)downloadDone:(LrcDownloadOperation *)op;

@end