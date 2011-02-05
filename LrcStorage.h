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
	NSString *lrcStorePath_;
	NSString *lrcLibraryFilePath_;
}

- (id)init;
- (BOOL)addLRCFile:(NSString*)fileName;
- (NSString*)getLocalLRCFile:(NSString*)fileName;
- (BOOL)deleteLRCFile:(NSString*)fileName;
@property (nonatomic, readonly) NSString *lrcStorePath;
@property (nonatomic, readonly) NSString *lrcLibraryFilePath;

@end
