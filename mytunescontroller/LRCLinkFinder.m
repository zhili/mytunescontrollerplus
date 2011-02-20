
#import "LRCLinkFinder.h"
#import "basictypes.h"
#include <libxml/HTMLparser.h>
#import "NSString+URLArguments.h"
//#define SOGOU_LRC_FOOTPRINT "downlrc.jsp"
//#define BAIDU_LRC_FOOTPRINT ".lrc"
//#define LRC123_LRC_FOOTPRINT "/download/lrc"
//#define LRC123_BASEURL @"http://www.lrc123.com"
//#define SOGOU_BASEURL @"http://mp3.sogou.com/"
//#define SOSO_URL_TEMPLATE @"http://cgi.music.soso.com/fcgi-bin/fcg_download_lrc.q?song=%@&singer=%@&down=1"
#define BUFSIZE	4096



// If we're building with the 10.5 SDK, define our own version of this symbol.

#if LIBXML_VERSION < 20703
enum {
    HTML_PARSE_RECOVER  = 1<<0, /* Relaxed parsing */
};
#endif



@interface QHTMLLinkFinder ()

// Read/write versions of public properties

@property (copy, readwrite) NSError *error;
@property BOOL parsingLRC;
// Internal properties
@property (nonatomic, retain) NSMutableData *characterBuffer;
@property (retain, readwrite) NSMutableArray *mutableLrcURLs;

@end

@implementation QHTMLLinkFinder

@synthesize data  = _data;
@synthesize URL   = _URL;
@synthesize error = _error;
@synthesize mutableLrcURLs = _mutableLrcURLs;
@synthesize useRelaxedParsing = _useRelaxedParsing;
@synthesize parsingLRC = _parsingLRC;
@synthesize lrcEngine = _lrcEngine;
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
// This getter returns a snapshot of the current parser state so that, 
// if you call it before the parse is done, you don't get a mutable array 
// that's still being mutated.
{
    return [[self->_mutableLrcURLs copy] autorelease];
}


- (void)addURLForCString//:(const char *)cStr toArray:(NSMutableArray *)array
// Adds a URL to the specified array, handling lots of wacky edge cases.
{
    NSURL *url;
    
    // cStr should be ASCII but, just to be permissive, we'll accept UTF-8. 
    // Handle the case where cStr is not valid UTF-8.
    
    //str = [NSString stringWithCString:cStr encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)];
	//NSLog(@"%d",  detectedEncodingForCstr(cStr));

	NSString *str = [[NSString alloc] initWithData:_characterBuffer encoding:NSUTF8StringEncoding];
	[_characterBuffer setLength:0];
    //str = [NSString stringWithUTF8String:cStr]; //encoding:detectedEncodingForCstr(cStr)];
	if (str == nil) {
        assert(NO);
    } else {
		
        // Construct a relativel URL based on our base URL and the string. 
        // This can and does fail on real world systems (curse those users 
        // and their bogus HTML!).
		NSURL *baseLrcURL;
		NSArray *sosoTokens;
		switch (self.lrcEngine) {
			case LRC123_LRC_ENGINE:
				baseLrcURL = [NSURL URLWithString:LRC123_BASEURL];
				url = [NSURL URLWithString:str relativeToURL:baseLrcURL];
				break;
			case SOGOU_LRC_ENGINE:
				baseLrcURL = [NSURL URLWithString:SOGOU_BASEURL];
				url = [NSURL URLWithString:str relativeToURL:baseLrcURL];
				break;
			case SOSO_LRC_ENGINE:
				DeLog(@"%@", str);
				sosoTokens = [str componentsSeparatedByString:@"@@"];
				DeLog(@"%d", [sosoTokens count]);
				if ([sosoTokens count] > 4) {
					NSString *song = [sosoTokens objectAtIndex:1];
					NSString *singer = [sosoTokens objectAtIndex:3];
					NSString *sosoDownloadURLStr = [NSString stringWithFormat:SOSO_URL_TEMPLATE, 
													[song stringByEscapingForURLArgumentUsingEncodingGBk],
													[singer stringByEscapingForURLArgumentUsingEncodingGBk]];
					url = [NSURL URLWithString:sosoDownloadURLStr];
					DeLog(@"%@", sosoDownloadURLStr);
				} else {
					url = nil;
				}


				break;

			default:
				DeLog(@"never goes here");
				break;
		}
        if (url == nil) {
            DeLog(@"Could not construct URL from '%@' relative to '%@'.", str, self.URL);
        } else {
            [_mutableLrcURLs addObject:url];
			DeLog(@"new lrc download url: %@", url);
		}
    }
	[str release];
}

/*
 Character data is appended to a buffer until the current element ends
 this fix error when parsing some html tag content with &, and splited by libxml
 for example: http://cgi.music.soso.com/fcgi-bin/m.q?w=Bruno%20Mars+Just%20the%20Way%20You%20Are&source=1&t=7
 */
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
		
		if (!strcmp((const char *)name, "a")) {
			attrIndex = 0;
            while (attrs[attrIndex] != NULL) {
				if (strncmp((const char *)attrs[attrIndex], "href", 4) == 0) { 
					if (!strncmp((const char*)attrs[attrIndex+1], SOGOU_LRC_FOOTPRINT, 11) ||
						!strncmp((const char*)attrs[attrIndex+1], LRC123_LRC_FOOTPRINT, 13)) {
						//[obj addURLForCString:(const char *)attrs[attrIndex+1] toArray:obj.mutableLrcURLs];
						[obj appendCharacters:(const char *)attrs[attrIndex+1] length:strlen((const char *)attrs[attrIndex+1])];
						[obj addURLForCString];
					}
				}
				attrIndex += 2;
			}

		}
    }
}

static void charactersFoundSAXFunc(void *ctx, const xmlChar *ch, int len)
{
	QHTMLLinkFinder *obj;
	obj = (QHTMLLinkFinder *) ctx;
	if (obj.parsingLRC) {
		//[obj addURLForCString:(const char*)ch toArray:obj.mutableLrcURLs];
		[obj appendCharacters:(const char *)ch length:len];
	}
}

static void endElementSAX(void * ctx, const xmlChar *name)
{
	QHTMLLinkFinder *obj;
	obj = (QHTMLLinkFinder *) ctx;
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