//
//  NSScanner+JSON.h
//  lrcParser
//
//  Created by zhili hu on 1/26/11.
//  Copyright 2011 scut. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface NSScanner (GTMNSScannerJSONAdditions)

- (BOOL)scanJSONArrayString:(NSString**)jsonString;

@end
