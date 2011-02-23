//
//  NSScanner+JSON.m
//  lrcParser
//
//  Created by zhili hu on 1/26/11.
//  Copyright 2011 zhili hu. All rights reserved.
//

#import "NSScanner+JSON.h"



@implementation NSScanner (GTMNSScannerJSONAdditions)

- (BOOL)gtm_scanJSONString:(NSString **)jsonString
                 startChar:(unichar)startChar
                   endChar:(unichar)endChar {
	BOOL isGood = NO;
	NSRange jsonRange = { NSNotFound, 0 };
	NSString *scanString = [self string];
	NSUInteger startLocation = [self scanLocation];
	NSUInteger length = [scanString length];
	NSUInteger blockOpen = 0;
	NSCharacterSet *charsToSkip = [self charactersToBeSkipped];
	BOOL inQuoteMode = NO;
	NSUInteger i;
	for (i = startLocation; i < length; ++i) {
		unichar jsonChar = [scanString characterAtIndex:i];
		if (jsonChar == startChar && !inQuoteMode) {
			if (blockOpen == 0) {
				jsonRange.location = i + 1; // get rid of '['
			}
			blockOpen += 1;
		} else if (blockOpen == 0) {
			// If we haven't opened our block skip over any characters in
			// charsToSkip.
			if (![charsToSkip characterIsMember:jsonChar]) {
				break;
			}
		} else if (jsonChar == endChar && !inQuoteMode) {
			blockOpen -= 1;
			if (blockOpen == 0) {
				i += 1; // Move onto next character
				jsonRange.length = i - jsonRange.location - 1; // get rid of ']'
				break;
			}
		} else {
			if (jsonChar == '"') {
				inQuoteMode = !inQuoteMode;
			} else if (inQuoteMode && jsonChar == '\\') {
				// Skip the escaped character if it isn't the last one
				if (i < length - 1) ++i;
			}
		}
	}
	[self setScanLocation:i];
	if (blockOpen == 0 && jsonRange.location != NSNotFound) {
		isGood = YES;
		if (jsonString) {
			*jsonString = [scanString substringWithRange:jsonRange];
		}
	}
	return isGood;
}

- (BOOL)scanJSONArrayString:(NSString**)jsonString {
	return [self gtm_scanJSONString:jsonString startChar:'[' endChar:']'];
}

@end
