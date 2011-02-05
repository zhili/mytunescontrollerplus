
#import "LRCLinkFinder.h"

#include <libxml/HTMLparser.h>

#define SOGOU_LRC_FOOTPRINT "downlrc.jsp"
#define BAIDU_LRC_FOOTPRINT ".lrc"
#define LRC123_LRC_FOOTPRINT "/download/lrc"
#define LRC123_BASEURL @"http://www.lrc123.com"
#define SOGOU_BASEURL @"http://mp3.sogou.com/"
// If we're building with the 10.5 SDK, define our own version of this symbol.

#if LIBXML_VERSION < 20703
enum {
    HTML_PARSE_RECOVER  = 1<<0, /* Relaxed parsing */
};
#endif



@interface QHTMLLinkFinder ()

// Read/write versions of public properties

@property (copy, readwrite) NSError *error;

// Internal properties

@property (retain, readwrite) NSMutableArray *mutableLrcURLs;

@end

@implementation QHTMLLinkFinder

@synthesize data  = _data;
@synthesize URL   = _URL;
@synthesize error = _error;
@synthesize mutableLrcURLs = _mutableLrcURLs;
@synthesize useRelaxedParsing = _useRelaxedParsing;
@synthesize useSogouEngine = _useSogouEngine;

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
		//self->_baseLrcURL = [[NSURL alloc] initWithString:LRC123_BASEURL];
    }
    return self;
}

- (void)dealloc
{
	// [self->_baseLrcURL release];
    [self->_mutableLrcURLs release];
    [self->_error release];
    [self->_URL release];
    [self->_data release];
    [super dealloc];
}

- (NSArray *)lrcURLs
// This getter returns a snapshot of the current parser state so that, 
// if you call it before the parse is done, you don't get a mutable array 
// that's still being mutated.
{
    return [[self->_mutableLrcURLs copy] autorelease];
}


- (void)addURLForCString:(const char *)cStr toArray:(NSMutableArray *)array
// Adds a URL to the specified array, handling lots of wacky edge cases.
{
    NSString *  str;
    NSURL *     url;
    
    // cStr should be ASCII but, just to be permissive, we'll accept UTF-8. 
    // Handle the case where cStr is not valid UTF-8.
    
    str = [NSString stringWithUTF8String:cStr];
    if (str == nil) {
        assert(NO);
    } else {
		
        // Construct a relativel URL based on our base URL and the string. 
        // This can and does fail on real world systems (curse those users 
        // and their bogus HTML!).
		NSURL *baseLrcURL;
		if (self.useSogouEngine) {
			baseLrcURL = [NSURL URLWithString:SOGOU_BASEURL];
		} else {
			baseLrcURL = [NSURL URLWithString:LRC123_BASEURL];
		}

        url = [NSURL URLWithString:str relativeToURL:baseLrcURL];
        if (url == nil) {
            NSLog(@"Could not construct URL from '%@' relative to '%@'.", str, self.URL);
        } else {
            [array addObject:url];
			NSLog(@"new lrc download url: %@", url);
		}
    }
}

static void StartElementSAXFunc(
								void *          ctx,
								const xmlChar * name,
								const xmlChar **attrs
								)
{
    QHTMLLinkFinder *obj;
    size_t attrIndex;
    
    obj = (QHTMLLinkFinder *) ctx;
    assert([obj isKindOfClass:[QHTMLLinkFinder class]]);
    
    // libxml2's HTML parser lower cases tag and attribute names, so 
    // strcmp (rather than strcasecmp) is correct here.
    
    // Tags without attributes are not useful to us.
    
    if (attrs != NULL) {
		
        // Check for the tags we care about and, within them, check for 
        // the attributes we care about.
        
        if ( strcmp( (const char *) name, "a") == 0 ) {
            attrIndex = 0;
            while (attrs[attrIndex] != NULL) {
                if ( strcmp( (const char *) attrs[attrIndex], "href") == 0 ) {
					
					if ( strlen((const char*) attrs[attrIndex + 1]) >= 11 && strncmp((const char*) attrs[attrIndex + 1], SOGOU_LRC_FOOTPRINT, 11) == 0 ||
						 strlen((const char*) attrs[attrIndex + 1]) >= 13 && strncmp((const char*) attrs[attrIndex+1], LRC123_LRC_FOOTPRINT, 13) == 0)
						[obj addURLForCString:(const char *) attrs[attrIndex + 1] toArray:obj.mutableLrcURLs];
				
                }
                attrIndex += 2;
            }
        }
    }
}

static xmlSAXHandler gSAXHandler = {
    .initialized  = XML_SAX2_MAGIC,
    .startElement = StartElementSAXFunc
};

- (void)main
{
    struct _xmlParserCtxt * context;
	
    // Create and run a libxml2 HTML parser.
    
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
        int     err;
        
        // If the client has specified relaxed parsing, set that up in the 
        // libxml2 parser.  First try with HTML_PARSE_RECOVER and, if that 
        // fails, retry without it.
        
        if (self.useRelaxedParsing) {
            err = htmlCtxtUseOptions(context, HTML_PARSE_RECOVER | HTML_PARSE_NOERROR | HTML_PARSE_NOWARNING);
            if (err != 0) {
                (void) htmlCtxtUseOptions(context, HTML_PARSE_NOERROR | HTML_PARSE_NOWARNING);
            }
            // We really don't care if this stuff fails.  err gets overwritten by the call 
            // to htmlParseChunk below.
        }
		
        // htmlParseChunk will only accept an int as the data length. On 64-bit builds, 
        // that's a problem, because [self.data length] is an NSUInteger, which might be greater 
        // than 2 GB.  I could address this properly (by calling htmlParseChunk repeatedly on 
        // 2 GB chunks) but IMO that's not a great solution; if you're parsing data that big, 
        // you really don't want to hold it all in memory even in a 64-bit process.  So, for 
        // the sake of simplicity, I've just added the following assert.
        
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
                // The libxml2 HTML parser shares the same errors as the XML parser, so we just 
                // borrow NSXMLParser's error domain.  Keep in mind that you might encounter 
                // errors that aren't explicitly listed in <Foundation/NSXMLParser.h>, such 
                // as XML_HTML_UNKNOWN_TAG.  See xmlParserErrors in <libxml/xmlerror.h> for 
                // the full list.
                self.error = [NSError errorWithDomain:NSXMLParserErrorDomain code:err userInfo:nil];
            }
        }
		
        // Clean up.
        
        htmlFreeParserCtxt(context);
    }
}

@end