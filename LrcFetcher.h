//
//  LrcFetcher.h
//  lrcParser
//
//  Created by zhili hu on 1/29/11.
//  Copyright 2011 scut. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LrcStorage.h"

@interface LrcFetcher : NSObject {
	NSString *artist_;
	NSString *title_;
	NSMutableArray *downloadURLs;
	NSError *fetcherError_;
	LrcStorage *lrcStorage_;
}

- (id)initWithTitle:(NSString*)title
		 LRCStorage:(LrcStorage*)store;

- (id)initWithArtist:(NSString*)artist
			   Title:(NSString*)title
		  LRCStorage:(LrcStorage*)store;

- (BOOL)startQuery;
- (BOOL)startDownloadIt;
@end
