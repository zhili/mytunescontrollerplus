//
//  LrcStorage.h
//  lrcParser
//
//  Created by zhili hu on 1/30/11.
//  Copyright 2011 scut. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LrcStorage : NSObject {
	NSMutableDictionary *lrcFileStorage_;
}

- (id)init;
- (BOOL)addNewLRCFile:(NSString*)fileName Content:(NSData*)lrcContent;
- (NSString*)getLocalLRCFile:(NSString*)fileName;
- (BOOL)deleteLRCFile:(NSString*)fileName;

@end
