#import "HttpConnectionDelegate.h"

@interface HttpConnectionDelegate ()

// Read/write versions of public properties
@property (copy,   readwrite) NSURLRequest *lastRequest;
@property (copy,   readwrite) NSHTTPURLResponse *lastResponse;
// Internal properties
@property (assign, readwrite) BOOL firstData;
@property (retain, readwrite) NSMutableData *dataAccumulator;

@end

@implementation HttpConnectionDelegate

@synthesize isExecuting = _isExecuting;
@synthesize isFinished = _isFinished;
@synthesize error = _error;
@synthesize lastRequest     = _lastRequest;
@synthesize lastResponse    = _lastResponse;
@synthesize responseBody    = _responseBody;
@synthesize firstData       = _firstData;
@synthesize dataAccumulator = _dataAccumulator;
@synthesize acceptableStatusCodes = _acceptableStatusCodes;

#pragma mark * Initialise and finalise
- (id)initWithTarget:(id)target action:(SEL)action context:(id)context
{
	
	if (self = [super init])
	{
		_target	= [target retain];
		_action	= action;
		_context	= [context retain];
#if TARGET_OS_EMBEDDED || TARGET_IPHONE_SIMULATOR
		static const NSUInteger kPlatformReductionFactor = 4;
#else
		static const NSUInteger kPlatformReductionFactor = 1;
#endif
		_defaultResponseSize = 1 * 1024 * 1024 / kPlatformReductionFactor;
        _maximumResponseSize = 4 * 1024 * 1024 / kPlatformReductionFactor;
        _firstData = YES;
	}
	return self;
}

- (void)dealloc
{
	[_error release];
	[_target release];
	[_context release];
    [_acceptableStatusCodes release];
    [_acceptableContentTypes release];
    [_responseOutputStream release];
    [_dataAccumulator release];
    [_lastRequest release];
    [_lastResponse release];
    [_responseBody release];
    [super dealloc];
}

#pragma mark * Properties

// We write our own settings for many properties because we want to bounce 
// sets that occur in the wrong state.  And, given that we've written the 
// setter anyway, we also avoid KVO notifications when the value doesn't change.



+ (BOOL)automaticallyNotifiesObserversOfAcceptableStatusCodes
{
    return NO;
}

- (void)setAcceptableStatusCodes:(NSIndexSet *)newValue
{
	if (newValue != self->_acceptableStatusCodes) {
		[self willChangeValueForKey:@"acceptableStatusCodes"];
		[self->_acceptableStatusCodes autorelease];
		self->_acceptableStatusCodes = [newValue copy];
		[self didChangeValueForKey:@"acceptableStatusCodes"];
	}
}

@synthesize acceptableContentTypes = _acceptableContentTypes;

+ (BOOL)automaticallyNotifiesObserversOfAcceptableContentTypes
{
    return NO;
}

- (void)setAcceptableContentTypes:(NSSet *)newValue
{
	if (newValue != self->_acceptableContentTypes) {
		[self willChangeValueForKey:@"acceptableContentTypes"];
		[self->_acceptableContentTypes autorelease];
		self->_acceptableContentTypes = [newValue copy];
		[self didChangeValueForKey:@"acceptableContentTypes"];
	}
}

@synthesize responseOutputStream = _responseOutputStream;

+ (BOOL)automaticallyNotifiesObserversOfResponseOutputStream
{
    return NO;
}

- (void)setResponseOutputStream:(NSOutputStream *)newValue
{
    if (self.dataAccumulator != nil) {
        assert(NO);
    } else {
        if (newValue != self->_responseOutputStream) {
            [self willChangeValueForKey:@"responseOutputStream"];
            [self->_responseOutputStream autorelease];
            self->_responseOutputStream = [newValue retain];
            [self didChangeValueForKey:@"responseOutputStream"];
        }
    }
}

@synthesize defaultResponseSize   = _defaultResponseSize;

+ (BOOL)automaticallyNotifiesObserversOfDefaultResponseSize
{
    return NO;
}

- (void)setDefaultResponseSize:(NSUInteger)newValue
{
    if (self.dataAccumulator != nil) {
        assert(NO);
    } else {
        if (newValue != self->_defaultResponseSize) {
            [self willChangeValueForKey:@"defaultResponseSize"];
            self->_defaultResponseSize = newValue;
            [self didChangeValueForKey:@"defaultResponseSize"];
        }
    }
}

@synthesize maximumResponseSize = _maximumResponseSize;

+ (BOOL)automaticallyNotifiesObserversOfMaximumResponseSize
{
    return NO;
}

- (void)setMaximumResponseSize:(NSUInteger)newValue
{
    if (self.dataAccumulator != nil) {
        assert(NO);
    } else {
        if (newValue != self->_maximumResponseSize) {
            [self willChangeValueForKey:@"maximumResponseSize"];
            self->_maximumResponseSize = newValue;
            [self didChangeValueForKey:@"maximumResponseSize"];
        }
    }
}



- (BOOL)isStatusCodeAcceptable
{
    NSIndexSet *    acceptableStatusCodes;
    NSInteger       statusCode;
    
    assert(self.lastResponse != nil);
    
    acceptableStatusCodes = self.acceptableStatusCodes;
    if (acceptableStatusCodes == nil) {
        acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
    }
    assert(acceptableStatusCodes != nil);
    
    statusCode = [self.lastResponse statusCode];
    return (statusCode >= 0) && [acceptableStatusCodes containsIndex: (NSUInteger) statusCode];
}

- (BOOL)isContentTypeAcceptable
{
    NSString *  contentType;
    
    assert(self.lastResponse != nil);
    contentType = [self.lastResponse MIMEType];
    return (self.acceptableContentTypes == nil) || ((contentType != nil) && [self.acceptableContentTypes containsObject:contentType]);
}



#pragma mark * NSURLConnection delegate callbacks

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    assert( (response == nil) || [response isKindOfClass:[NSHTTPURLResponse class]] );
	
    self.lastRequest  = request;
    self.lastResponse = (NSHTTPURLResponse *) response;
    return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{

    assert([response isKindOfClass:[NSHTTPURLResponse class]]);
	
    self.lastResponse = (NSHTTPURLResponse *)response;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    BOOL    success;
    assert(data != nil);
    
    // If we don't yet have a destination for the data, calculate one.  Note that, even 
    // if there is an output stream, we don't use it for error responses.
    
    success = YES;
    if (self.firstData) {
        assert(self.dataAccumulator == nil);
        
        if ( (self.responseOutputStream == nil) || ! self.isStatusCodeAcceptable ) {
            long long   length;
            
            assert(self.dataAccumulator == nil);
            
            length = [self.lastResponse expectedContentLength];
            if (length == NSURLResponseUnknownLength) {
                length = self.defaultResponseSize;
            }
            if (length <= (long long) self.maximumResponseSize) {
                self.dataAccumulator = [NSMutableData dataWithCapacity:(NSUInteger)length];
            } else {
                _error = [NSError errorWithDomain:HttpConnectionDelegateErrorDomain code:httpConnectionDelegateErrorResponseTooLarge userInfo:nil];
                success = NO;
            }
        }
        
        // If the data is going to an output stream, open it.
        
        if (success) {
            if (self.dataAccumulator == nil) {
                assert(self.responseOutputStream != nil);
                [self.responseOutputStream open];
            }
        }
        
        self.firstData = NO;
    }
    
    // Write the data to its destination.
	
    if (success) {
        if (self.dataAccumulator != nil) {
            if ( ([self.dataAccumulator length] + [data length]) <= self.maximumResponseSize ) {
                [self.dataAccumulator appendData:data];
            } else {
				_error = [NSError errorWithDomain:HttpConnectionDelegateErrorDomain code:httpConnectionDelegateErrorResponseTooLarge userInfo:nil];
            }
        } else {
            NSUInteger      dataOffset;
            NSUInteger      dataLength;
            const uint8_t * dataPtr;
            NSError *       error;
            NSInteger       bytesWritten;
			
            assert(self.responseOutputStream != nil);
			
            dataOffset = 0;
            dataLength = [data length];
            dataPtr    = [data bytes];
            error      = nil;
            do {
                if (dataOffset == dataLength) {
                    break;
                }
                bytesWritten = [self.responseOutputStream write:&dataPtr[dataOffset] maxLength:dataLength - dataOffset];
                if (bytesWritten <= 0) {
                    error = [self.responseOutputStream streamError];
                    if (error == nil) {
                        error = [NSError errorWithDomain:HttpConnectionDelegateErrorDomain code:httpConnectionDelegateErrorOnOutputStream userInfo:nil];
                    }
                    break;
                } else {
                    dataOffset += bytesWritten;
                }
            } while (YES);
            
            if (error != nil) {
                _error = [error	copy];
            }
        }
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    assert(self.lastResponse != nil);
	
    // Swap the data accumulator over to the response data so that we don't trigger a copy.
    assert(self->_responseBody == nil);
	
    self->_responseBody = self->_dataAccumulator;
    self->_dataAccumulator = nil;
    
    if ( ! self.isStatusCodeAcceptable ) {
        _error = [NSError errorWithDomain:HttpConnectionDelegateErrorDomain code:self.lastResponse.statusCode userInfo:nil];
    } else if( ! self.isContentTypeAcceptable ) {
        _error = [NSError errorWithDomain:HttpConnectionDelegateErrorDomain code:httpConnectionDelegateErrorBadContentType userInfo:nil];
    } else {
		
	}
	[_target performSelector:_action
				 withObject:[NSDictionary dictionaryWithObjectsAndKeys:_lastResponse,@"lastResponse",_responseBody, @"responseBody",nil]
				 withObject:_context];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    assert(error != nil);
	_error = [error copy];
	[_target performSelector:_action withObject:_error withObject:_context];
}

@end

NSString *HttpConnectionDelegateErrorDomain = @"HttpConnectionDelegateErrorDomain";