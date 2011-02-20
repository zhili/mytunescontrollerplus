//
//  LrcSearch.h
//  MyTunesControllerPlus
//
//  Created by zhili hu on 2/20/11.
//  Copyright 2011 scut. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol LrcSearchDelegate;

@interface LrcSearch : NSObject {
	NSOperationQueue *_queue;
	NSString *_artist;
	NSString *_title;
	NSError *_error;
	BOOL done;
	id<LrcSearchDelegate> delegate;
}

@property (nonatomic, copy) NSString *artist;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy, readonly) NSError *error;
@property (nonatomic, assign) BOOL done;
@property (readwrite, assign) id<LrcSearchDelegate> delegate;

- (id)initWithArtist:(NSString*)artist
			   Title:(NSString*)title;
- (BOOL)start;
- (void)stop;

@end


@protocol LrcSearchDelegate <NSObject>
-(void)searchDone:(NSArray *)lrcList;
@end

