//
//  LrcFetcher.m
//  lrcParser
//
//  Created by zhili hu on 1/29/11.
//  Copyright 2011 scut. All rights reserved.
//

#import "LrcFetcher.h"
#import "GTMHTTPFetcher.h"
#import "NSString+URLArguments.h"

#define SOGOU_QUERY_AT_TEMPLATE @"http://mp3.sogou.com/gecisearch.so?query=%@-%@"
#define SOGOU_QUERY_T_TEMPLATE @"http://mp3.sogou.com/gecisearch.so?query=%@"
#define SOGOU_LRC_PATH_KEY @"downlrc.jsp"
#define SOGOU_LRC_URL_TEMPLATE @"http://mp3.sogou.com/%@"

@implementation LrcFetcher

- (id)initWithTitle:(NSString*)title LRCStorage:(LrcStorage*)store
{
	return [self initWithArtist:nil Title:title LRCStorage:store];
}

- (id)initWithArtist:(NSString*)artist
			   Title:(NSString*)title
		  LRCStorage:(LrcStorage*)store

{
	if (self = [super init]) {
		title_ = [title copy];
		artist_ = [artist copy];
		downloadURLs = [[NSMutableArray array] retain];
		fetcherError_ = nil;
		lrcStorage_ = [store retain];
	}
	return self;
}

- (BOOL)startQuery
{
	NSString *query;
	if ([artist_ length]!=0 && [title_ length] != 0) {
		query = [NSString stringWithFormat:SOGOU_QUERY_AT_TEMPLATE, 
						   [artist_ stringByEscapingForURLArgumentUsingEncodingGB_18030], 
						   [title_ stringByEscapingForURLArgumentUsingEncodingGB_18030]];
	} else if ([title_ length]!=0) {
		query = [NSString stringWithFormat:SOGOU_QUERY_T_TEMPLATE, 
				 [title_ stringByEscapingForURLArgumentUsingEncodingGB_18030]];
	} else {
		return NO;
	}

	NSURL *url = [NSURL URLWithString:query];
	NSURLRequest *request = [NSURLRequest requestWithURL:url
											 cachePolicy:NSURLRequestReloadIgnoringCacheData
										 timeoutInterval:30];
	GTMHTTPFetcher* queryLRCFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
	BOOL isFetching  = [queryLRCFetcher beginFetchWithDelegate:self
					didFinishSelector:@selector(queryLRCFetcher:finishedWithData:error:)];
	
	if (isFetching) {
		[queryLRCFetcher waitForCompletionWithTimeout:30.0];
	}
	
	if (fetcherError_ != nil) {
		NSLog(@"fetching query gave error: %@", fetcherError_);
		return NO;
	}
	return YES;
}

- (void)queryLRCFetcher:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)retrievedData error:(NSError *)error {
	if (error != nil) {
		fetcherError_ = [error retain];
	} else {
		// fetch succeeded
		NSString *result_contents;
		result_contents = [[NSString alloc] initWithData: retrievedData
										 encoding: CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)];
		NSScanner *theScanner = [NSScanner scannerWithString:result_contents];
		//NSCharacterSet *semicolonSet;
		//semicolonSet = [NSCharacterSet characterSetWithCharactersInString:@"\""];
		NSString *urlKey;
		while ([theScanner isAtEnd] == NO) {
			if ([theScanner scanUpToString:SOGOU_LRC_PATH_KEY intoString:NULL] &&
				[theScanner scanUpToString:@"\"" intoString:&urlKey]) {
				[downloadURLs addObject:[NSString stringWithFormat:SOGOU_LRC_URL_TEMPLATE, urlKey]];
			}
		}
		[result_contents release];
	}
}

- (BOOL)startDownloadIt
{
	if ([downloadURLs count] <= 0 ) {
		return NO;
	}
	NSString *link = [downloadURLs objectAtIndex:0];
	NSURL *url = [NSURL URLWithString:link];
	NSURLRequest *request = [NSURLRequest requestWithURL:url
											 cachePolicy:NSURLRequestReloadIgnoringCacheData
										 timeoutInterval:30];
	GTMHTTPFetcher* lrcDownloader = [GTMHTTPFetcher fetcherWithRequest:request];
	BOOL isFetching  = [lrcDownloader beginFetchWithDelegate:self
									   didFinishSelector:@selector(lrcDownloader:finishedWithData:error:)];
	
	if (isFetching) {
		[lrcDownloader waitForCompletionWithTimeout:30.0];
	}
	
	if (fetcherError_ != nil) {
		NSLog(@"fetching data gave error: %@", fetcherError_);
		return NO;
	}
	return YES;
}

- (void)lrcDownloader:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)retrievedData error:(NSError *)error 
{
	if (error != nil) {
		fetcherError_ = [error retain];
	} else {
		NSString *lrcFileName;
		if ([artist_ length]!=0 && [title_ length] != 0) {
			lrcFileName = [NSString stringWithFormat:@"%@-%@.lrc", artist_, title_];
		} else {
			lrcFileName = [NSString stringWithFormat:@"%@.lrc", title_];
		} 
		//[retrievedData writeToFile:lrcFileName atomically:NO];
		[lrcStorage_ addNewLRCFile:lrcFileName Content:retrievedData];
	}
}


- (void)dealloc 
{
	if (fetcherError_ != nil) {
		[fetcherError_ release];
	}
	[lrcStorage_ release];
	[downloadURLs release];
	[title_ release];
	[artist_ release];
	[super dealloc];
}

@end
