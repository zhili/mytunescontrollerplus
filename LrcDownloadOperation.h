#import "QHTTPOperation.h"

@interface LrcDownloadOperation : QHTTPOperation
{
    NSString *_lrcDirPath;
    NSString *_lrcFilePath;
	NSString *_lrcName; 
}


- (id)initWithURL:(NSURL *)url lrcDirPath:(NSString *)lrcDirPath lrcFileName:(NSString*)name;

@property (copy, readonly ) NSString *lrcDirPath;
@property (copy, readonly ) NSString *lrcFilePath;

@end