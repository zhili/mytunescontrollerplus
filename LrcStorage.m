//
//  LrcStorage.m
//  lrcParser
//
//  Created by zhili hu on 1/30/11.
//  Copyright 2011 scut. All rights reserved.
//

#import "LrcStorage.h"

@interface LrcStorage ()
- (BOOL)saveLrcLibraryToDisk;
@end

@implementation LrcStorage

@synthesize lrcStorePath = lrcStorePath_;
@synthesize lrcLibraryFilePath = lrcLibraryFilePath_;

-(id)init
{
	if (self = [super init]) {
		
		lrcStorePath_ = [[@"~/Library/Application Support/MyTunesControllerPlus/" stringByExpandingTildeInPath] copy];

		lrcLibraryFilePath_ = [[@"~/Library/Application Support/MyTunesControllerPlus/MyTunesControllerPlus.plist" stringByExpandingTildeInPath] copy];
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		if ([fileManager fileExistsAtPath:lrcStorePath_] == NO) {
			[fileManager createDirectoryAtPath:lrcStorePath_ withIntermediateDirectories:YES attributes:nil error:NULL];
						
		} 
		if ([fileManager fileExistsAtPath:lrcLibraryFilePath_] == 0) {
			lrcFileStorage_ = [[NSMutableDictionary alloc] init];
			[lrcFileStorage_ writeToFile:[lrcLibraryFilePath_ stringByExpandingTildeInPath] atomically: TRUE];

		} else {
			lrcFileStorage_ = [[NSMutableDictionary alloc] initWithContentsOfFile:lrcLibraryFilePath_];
		}
	}
	return self;
}

- (BOOL)saveLrcLibraryToDisk
{
	return [lrcFileStorage_ writeToFile:[lrcLibraryFilePath_ stringByExpandingTildeInPath] atomically: TRUE];
}

- (BOOL)addLRCFile:(NSString*)fileName
{
	NSString *extension = @"lrc";
	NSString *filePathAndName = [lrcStorePath_ stringByAppendingPathComponent:[fileName stringByAppendingPathExtension:extension]];
	[lrcFileStorage_ setObject:[filePathAndName stringByExpandingTildeInPath] forKey:fileName];
	return [self saveLrcLibraryToDisk];
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
	[lrcLibraryFilePath_ release];
	[lrcStorePath_ release];
	[lrcFileStorage_ release];
	[super dealloc];
}

@end
