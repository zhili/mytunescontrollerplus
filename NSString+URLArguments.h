//
//  NSString+URLArguments.h
//  lrcParser
//
//  Created by zhili hu on 1/30/11.
//  Copyright 2011 scut. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Utilities for encoding and decoding URL arguments.
@interface NSString (GTMNSStringURLArgumentsAdditions)

/// Returns a string that is escaped properly to be a URL argument.
//
/// This differs from stringByAddingPercentEscapesUsingEncoding: in that it
/// will escape all the reserved characters (per RFC 3986
/// <http://www.ietf.org/rfc/rfc3986.txt>) which
/// stringByAddingPercentEscapesUsingEncoding would leave.
///
/// This will also escape '%', so this should not be used on a string that has
/// already been escaped unless double-escaping is the desired result.
- (NSString*)stringByEscapingForURLArgumentUsingEncodingGB_18030;

/// Returns the unescaped version of a URL argument
//
/// This has the same behavior as stringByReplacingPercentEscapesUsingEncoding:,
/// except that it will also convert '+' to space.
- (NSString*)gtm_stringByUnescapingFromURLArgument;


@end
