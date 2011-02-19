#import "HttpConnectionDelegate.h"

@interface LrcDownloadDelegate : HttpConnectionDelegate
{
    NSString *_lrcDirPath;
    NSString *_lrcFilePath;
	NSString *_lrcName;
}

@property (copy, readwrite) NSString *lrcDirPath;
@property (copy, readwrite) NSString *lrcFilePath;
@property (copy, readwrite) NSString *lrcName;

@end

