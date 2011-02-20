//
//  SosoLrcInfoParser.m
//  MyTunesControllerPlus
//
//  Created by zhili hu on 2/20/11.
//  Copyright 2011 scut. All rights reserved.
//

#import "SosoLrcInfoParser.h"
#import "LrcOfSong.h"
#import "LRCLinkFinder.h"
#import "basictypes.h"
#include <libxml/HTMLparser.h>
#import "NSString+URLArguments.h"
#define BUFSIZE	4096



// If we're building with the 10.5 SDK, define our own version of this symbol.

#if LIBXML_VERSION < 20703
enum {
    HTML_PARSE_RECOVER  = 1<<0, /* Relaxed parsing */
};
#endif



@interface SosoLrcInfoParser ()

// Read/write versions of public properties

@property (copy, readwrite) NSError *error;
@property BOOL parsingLRC;
// Internal properties
@property (nonatomic, retain) NSMutableData *characterBuffer;
@property (retain, readwrite) NSMutableArray *mutableLrcURLs;

@end

@implementation SosoLrcInfoParser

@synthesize data  = _data;
@synthesize URL   = _URL;
@synthesize error = _error;
@synthesize mutableLrcURLs = _mutableLrcURLs;
@synthesize useRelaxedParsing = _useRelaxedParsing;
@synthesize parsingLRC = _parsingLRC;
@synthesize characterBuffer = _characterBuffer;
@synthesize delegate;

- (id)initWithData:(NSData *)data fromURL:(NSURL *)url
{
    assert(data != nil);
    assert(url != nil);
    self = [super init];
    if (self != nil) {
        self->_data = [data copy];
        assert(self->_data != nil);
        self->_URL = [url copy];
        assert(self->_URL != nil);
        self->_mutableLrcURLs = [[NSMutableArray alloc] init];
        assert(self->_mutableLrcURLs != nil);
	}
    return self;
}

- (void)dealloc
{
	[self->_characterBuffer release];
    [self->_mutableLrcURLs release];
    [self->_error release];
    [self->_URL release];
    [self->_data release];
    [super dealloc];
}

- (NSArray *)lrcURLs
{
    return [[self->_mutableLrcURLs copy] autorelease];
}


- (void)addURLForCString//:(const char *)cStr toArray:(NSMutableArray *)array
// Adds a URL to the specified array, handling lots of wacky edge cases.
{
    NSURL *url;

	NSString *str = [[NSString alloc] initWithData:_characterBuffer encoding:NSUTF8StringEncoding];
	[_characterBuffer setLength:0];
	if (str == nil) {
        assert(NO);
    } else {
		NSArray *sosoTokens;

		sosoTokens = [str componentsSeparatedByString:@"@@"];
		DeLog(@"%d", [sosoTokens count]);
		if ([sosoTokens count] > 4) {
			NSString *song = [sosoTokens objectAtIndex:1];
			NSString *singer = [sosoTokens objectAtIndex:3];
			NSString *sosoDownloadURLStr = [NSString stringWithFormat:SOSO_URL_TEMPLATE, 
											[song stringByEscapingForURLArgumentUsingEncodingGBk],
											[singer stringByEscapingForURLArgumentUsingEncodingGBk]];
			url = [NSURL URLWithString:sosoDownloadURLStr];
			
			LrcOfSong *aLrc = [[LrcOfSong alloc] initWithArtist:singer
														 Title:song
												   DownloadURL:(NSURL*)url];
			DeLog(@"%@", sosoDownloadURLStr);
			[_mutableLrcURLs addObject:aLrc];
			[aLrc release];
			DeLog(@"new lrc download url: %@", url);
		}

    }
	[str release];
}

- (void)appendCharacters:(const char *)charactersFound length:(NSInteger)length {
    [_characterBuffer appendBytes:charactersFound length:length];
}


static const char *SOSO_LRC_FOOTPRINT = "div";
static const NSUInteger SOSO_LRC_FOOTPRINT_LENGHT = 3;

static const char *SOSO_LRC_FOOTPRINT_ATTR = "class";
static const NSUInteger SOSO_LRC_FOOTPRINT__ATTR_LENGHT = 5;

static const char *SOSO_LRC_FOOTPRINT_ATTR_VALUE = "data";
static const NSUInteger SOSO_LRC_FOOTPRINT_ATTR_VALUE_LENGHT = 4;


static void StartElementSAXFunc(
								void *ctx,
								const xmlChar *name,
								const xmlChar **attrs
								)
{
    SosoLrcInfoParser *obj;
    size_t attrIndex;
    
    obj = (SosoLrcInfoParser *) ctx;
    assert([obj isKindOfClass:[SosoLrcInfoParser class]]);
    
    if (attrs != NULL) {
		
        if (!strncmp((const char *)name, SOSO_LRC_FOOTPRINT, SOSO_LRC_FOOTPRINT_LENGHT) ) {
            attrIndex = 0;
            while (attrs[attrIndex] != NULL) {
                if (!strncmp((const char *)attrs[attrIndex], SOSO_LRC_FOOTPRINT_ATTR, SOSO_LRC_FOOTPRINT__ATTR_LENGHT) &&
					!strncmp((const char *)attrs[attrIndex+1], SOSO_LRC_FOOTPRINT_ATTR_VALUE, SOSO_LRC_FOOTPRINT_ATTR_VALUE_LENGHT)) {
					obj.parsingLRC = YES;
					
                } 
                attrIndex += 2;
            }
        }
    }
}

static void charactersFoundSAXFunc(void *ctx, const xmlChar *ch, int len)
{
	SosoLrcInfoParser *obj;
	obj = (SosoLrcInfoParser *) ctx;
	if (obj.parsingLRC) {
		//[obj addURLForCString:(const char*)ch toArray:obj.mutableLrcURLs];
		[obj appendCharacters:(const char *)ch length:len];
	}
}

static void endElementSAX(void * ctx, const xmlChar *name)
{
	SosoLrcInfoParser *obj;
	obj = (SosoLrcInfoParser *) ctx;
	if (obj.parsingLRC) {
		[obj addURLForCString];
		obj.parsingLRC = NO;
	}
}

static xmlSAXHandler gSAXHandler = {
    .initialized  = XML_SAX2_MAGIC,
	.characters = charactersFoundSAXFunc,
    .startElement = StartElementSAXFunc,
	.endElement = endElementSAX
};

- (void)main
{
    struct _xmlParserCtxt * context;
	
    // Create and run a libxml2 HTML parser.
	self.characterBuffer = [NSMutableData data];
    context = htmlCreatePushParserCtxt(
									   &gSAXHandler,
									   self,
									   NULL,
									   0,
									   nil,
									   XML_CHAR_ENCODING_NONE
									   );
    if (context == NULL) {
        self.error = [NSError errorWithDomain:NSXMLParserErrorDomain code:XML_ERR_INTERNAL_ERROR userInfo:nil];
    } else {
        int err;
        if (self.useRelaxedParsing) {
            err = htmlCtxtUseOptions(context, HTML_PARSE_RECOVER | HTML_PARSE_NOERROR | HTML_PARSE_NOWARNING);
            if (err != 0) {
                (void) htmlCtxtUseOptions(context, HTML_PARSE_NOERROR | HTML_PARSE_NOWARNING);
            }
        }
		
        
        assert( [self.data length] <= (NSUInteger) INT_MAX );
        
        // Parse the data.
        
        err = htmlParseChunk(
							 context, 
							 [self.data bytes], 
							 (int) [self.data length], 
							 YES
							 );
        
        // Handle the result.
        
        if (err != 0) {
            if (self.error == nil) {
                self.error = [NSError errorWithDomain:NSXMLParserErrorDomain code:err userInfo:nil];
            }
        }
		
    }
	
	// Clean up.
	
	htmlFreeParserCtxt(context);
	self.characterBuffer = nil;
	if ([self.delegate respondsToSelector:@selector(parseDone:)]) {
		[self.delegate parseDone:self];
	} 
}

@end
