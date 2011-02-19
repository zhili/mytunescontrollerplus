//
//  LrcDownloadOperation.m
//  lrcDownloader
//
//  Created by zhili hu on 2/4/11.
//  Copyright 2011 scut. All rights reserved.
//

#import "LrcDownloadOperation.h"

#include <fcntl.h>
#include <unistd.h>

@implementation LrcDownloadOperation


@synthesize lrcDirPath = _lrcDirPath;
@synthesize lrcFilePath = _lrcFilePath;
@synthesize lrcName = _lrcName;
@synthesize delegate = _delegate;

- (id)initWithURL:(NSURL *)url lrcDirPath:(NSString *)lrcDirPath lrcFileName:(NSString*)name
{
	assert(lrcDirPath != nil);
    self = [super initWithURL:url];
    if (self != nil) {
        _lrcDirPath = [lrcDirPath copy];
		_lrcName = [name copy];
    }
    return self;
}

- (void)dealloc
{
	[_lrcName release];
    [_lrcFilePath release];
    [_lrcDirPath release];
    [super dealloc];
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [super connection:connection didReceiveResponse:response];
    
    if (self.isStatusCodeAcceptable) {
        NSString *  extension;
        assert(self.responseOutputStream == nil);

		NSString *  filePath;
		int         counter;
		int         fd;
		
		extension = @"lrc";
		// Repeatedly try to create a new file with that info, adding a 
		// unique number if we get a conflict.
		counter = 0;
		filePath = [_lrcDirPath stringByAppendingPathComponent:[_lrcName stringByAppendingPathExtension:extension]];
		do {
			int     err;
			int     junk;
			
			err = 0;
			fd = open([filePath UTF8String], O_CREAT | O_EXCL | O_RDWR, 0666);
			if (fd < 0) {
				err = errno;
			} else {
				junk = close(fd);
				assert(junk == 0);
			}
			
			if (err == 0) {
				self.lrcFilePath = filePath;
				self.responseOutputStream = [NSOutputStream outputStreamToFileAtPath:filePath append:NO];
				break;
			} else if (err == EEXIST) {
				counter += 1;
				if (counter > 500) {
					break;
				}
				filePath = [self.lrcDirPath stringByAppendingPathComponent:[[NSString stringWithFormat:@"%@-%d", _lrcName, counter] stringByAppendingPathExtension:extension]];
			} else if (err == EINTR) {
				// do nothing
			} else {
				break;
			}
		} while (YES);
        // If we've failed to create a valid file, redirect the output to the bit bucket.
        
        if (self.responseOutputStream == nil) {
            self.responseOutputStream = [NSOutputStream outputStreamToFileAtPath:@"/dev/null" append:NO];
        }
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [super connectionDidFinishLoading:connection];
	
	if (![self isCancelled] && [self.delegate respondsToSelector:@selector(downloadDone:)]) {
		[self.delegate downloadDone:self];
	} 
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [super connection:connection didFailWithError:error];
    if (![self isCancelled] && [self.delegate respondsToSelector:@selector(downloadDone:)]) {
		[self.delegate downloadDone:self];
    }
}


@end
