//
//  LrcStorage.m
//  lrcParser
//
//  Created by zhili hu on 1/30/11.
//  Copyright 2011 scut. All rights reserved.
//

#import "LrcStorage.h"

#define DEFAUTL_LRC_LIB @"~/Library/Application Support/MyTunesControllerPlus/lrcLibrary.plist"
#define DEFAUTL_LRC_PATH @"~/Library/Application Support/MyTunesControllerPlus/%@"

@interface LrcStorage ()
- (BOOL)saveLrcLibraryToDisk;
@end

@implementation LrcStorage


-(id)init
{
	if (self = [super init]) {
		NSFileManager *fileManager = [NSFileManager defaultManager];
		if ([fileManager fileExistsAtPath: [DEFAUTL_LRC_LIB stringByExpandingTildeInPath]] == NO) {
			lrcFileStorage_ = [[NSMutableDictionary alloc] init];
			NSString *filePath = [[NSString stringWithFormat:DEFAUTL_LRC_PATH, @""] stringByExpandingTildeInPath];
			
			[fileManager createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:NULL];
			[self saveLrcLibraryToDisk];
		} else {
			lrcFileStorage_ = [[NSDictionary alloc] initWithContentsOfFile: 
							   [DEFAUTL_LRC_LIB stringByExpandingTildeInPath]];
		}
	}
	return self;
}

- (BOOL)saveLrcLibraryToDisk
{
	return [lrcFileStorage_ writeToFile:[DEFAUTL_LRC_LIB stringByExpandingTildeInPath] atomically: TRUE];
}

- (BOOL)addNewLRCFile:(NSString*)fileName Content:(NSData*)lrcContent;
{

	NSString *filePathAndName = [NSString stringWithFormat:DEFAUTL_LRC_PATH, fileName];
	if ([lrcContent writeToFile:[filePathAndName stringByExpandingTildeInPath] atomically:NO]) {
		[lrcFileStorage_ setObject:[filePathAndName stringByExpandingTildeInPath] forKey:fileName];
		[self saveLrcLibraryToDisk];
		return YES;
	}
	return NO;
}

- (NSString*)getLocalLRCFile:(NSString*)fileName
{
	return [lrcFileStorage_ objectForKey:fileName];
}

- (BOOL)deleteLRCFile:(NSString*)fileName
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	[fileManager removeItemAtPath:[lrcFileStorage_ objectForKey:fileName] error:NULL];
	[lrcFileStorage_ removeObjectForKey:fileName];
	[self saveLrcLibraryToDisk];
	return YES;
}

- (void)dealloc
{
	[lrcFileStorage_ release];
	[super dealloc];
}

@end
