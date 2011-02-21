//
//  LrcSearch.h
//  MyTunesControllerPlus
//
//  Created by zhili hu on 2/20/11.
//  Copyright 2011 scut. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LrcOfSong;
@protocol LrcSearchDelegate;

@interface LrcSearch : NSObject {
	NSOperationQueue *_queue;
	NSString *_artist;
	NSString *_title;
	NSError *_error;
	BOOL done;
	id<LrcSearchDelegate> _delegate;
}

@property (nonatomic, copy) NSString *artist;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy, readonly) NSError *error;
@property (nonatomic, assign) BOOL done;
@property (readwrite, assign) id<LrcSearchDelegate> delegate;

- (id)initWithArtist:(NSString*)artist
			   title:(NSString*)title
			delegate:(id)delegate;

- (id)initWithDelegate:(id)delegate;
- (BOOL)startSearch;
- (void)stopAll;

- (BOOL)startDownloadLrc:(LrcOfSong *)lrcOfTheSong;

@end


@protocol LrcSearchDelegate <NSObject>

-(void)searchDone:(NSArray *)lrcList;
-(void)downloadDone:(NSString *)lrcName;

@end

