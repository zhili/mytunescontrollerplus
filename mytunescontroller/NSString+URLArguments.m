//
//  NSString+URLArguments.m
//  lrcParser
//
//  Created by zhili hu on 1/30/11.
//  Copyright 2011 zhili hu. All rights reserved.
//

#import "NSString+URLArguments.h"


@implementation NSString (GTMNSStringURLArgumentsAdditions)

- (NSString*)stringByEscapingForURLArgumentUsingEncodingGB_18030 {
	// Encode all the reserved characters, per RFC 3986
	// (<http://www.ietf.org/rfc/rfc3986.txt>)
	NSString *escapeChars = @"!*'();:@&=+$,/?%#[]"; 
	// use chinese gb18030 encoding for sogou.
	return [(NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, 
																(CFStringRef)self, NULL, (CFStringRef)escapeChars, 
																kCFStringEncodingGB_18030_2000) autorelease];
}

- (NSString*)stringByEscapingForURLArgumentUsingEncodingGBk {
	// Encode all the reserved characters, per RFC 3986
	// (<http://www.ietf.org/rfc/rfc3986.txt>)
	NSString *escapeChars = @"!*'();:@&=+$,/?%#[]"; 
	// use chinese gbk encoding for sogou.
	return [(NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, 
																(CFStringRef)self, NULL, (CFStringRef)escapeChars, 
																kCFStringEncodingGBK_95) autorelease];
}


- (NSString*)gtm_stringByEscapingForURLArgument {
	// Encode all the reserved characters, per RFC 3986
	// (<http://www.ietf.org/rfc/rfc3986.txt>)
	NSString *escapeChars = @"!*'();:@&=+$,/?%#[]"; 
	return [(NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, 
																(CFStringRef)self, NULL, (CFStringRef)escapeChars, 
																kCFStringEncodingUTF8) autorelease];
}

- (NSString*)gtm_stringByUnescapingFromURLArgument {
	NSMutableString *resultString = [NSMutableString stringWithString:self];
	[resultString replaceOccurrencesOfString:@"+"
								  withString:@" "
									 options:NSLiteralSearch
									   range:NSMakeRange(0, [resultString length])];
	return [resultString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

@end
