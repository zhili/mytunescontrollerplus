#import "HttpOperation.h"

@interface HttpOperation ()

// Read/write versions of public properties
@property (copy, readwrite) NSURLRequest *lastRequest;
@property (copy, readwrite) NSHTTPURLResponse *lastResponse;
// Internal properties
@property (retain, readwrite) NSURLConnection *connection;
@property (assign, readwrite) BOOL firstData;
@property (retain, readwrite) NSMutableData *dataAccumulator;

// Internal methods.
- (void)finish;
- (void)start;

@end

@implementation HttpOperation

@synthesize isExecuting = _isExecuting;
@synthesize isFinished = _isFinished;
@synthesize error = _error;
@synthesize lastRequest = _lastRequest;
@synthesize lastResponse = _lastResponse;
@synthesize responseBody = _responseBody;
@synthesize firstData = _firstData;
@synthesize dataAccumulator = _dataAccumulator;
@synthesize connection = _connection;
@synthesize acceptableStatusCodes = _acceptableStatusCodes;
@synthesize request = _request;

#pragma mark * Initialise and finalise
- (id)initWithRequest:(NSURLRequest *)request;
{
	
	if (self = [super init])
	{
        _request = [request copy];
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

- (id)initWithURL:(NSURL *)url
{
    return [self initWithRequest:[NSURLRequest requestWithURL:url]];
}

- (void)dealloc
{
    [_request release];
	[_error release];
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

- (NSURL *)URL
{
    return [self.request URL];
}

- (void)start
{
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
		return;
	}
	[self willChangeValueForKey:@"isExecuting"];
	_isExecuting = YES;
	[self didChangeValueForKey:@"isExecuting"];

	// init a connection, specially the connection retain it's delegete.
	NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:self.request delegate:self];
	self.connection = conn;
	NSLog(@"init conn retain count: %d", [conn retainCount]);
	[conn release];
	if (self.connection == nil)
		[self finish];

}

- (void)finish
{
    [self.connection cancel];
	[self.connection release];
	NSLog(@"conn retain count: %d", [self.connection retainCount]);
    //self.connection = nil;

    if (self.responseOutputStream != nil) {
        [self.responseOutputStream close];
    }
    [self willChangeValueForKey:@"isExecuting"];
	_isExecuting = NO;
    [self didChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
	_isFinished = YES;
    [self didChangeValueForKey:@"isFinished"];
}

#pragma mark * NSURLConnection delegate callbacks

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    assert( (response == nil) || [response isKindOfClass:[NSHTTPURLResponse class]] );
	//assert(connection == self.connection);
    self.lastRequest  = request;
    self.lastResponse = (NSHTTPURLResponse *) response;
    return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response 
{ 
	assert([response isKindOfClass:[NSHTTPURLResponse class]]);
    //assert(connection == self.connection);	
    self.lastResponse = (NSHTTPURLResponse *)response;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    BOOL    success;
    assert(data != nil);
    //assert(connection == self.connection);
    
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
                _error = [NSError errorWithDomain:HttpErrorOperationDomain code:httpOperationErrorResponseTooLarge userInfo:nil];
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
				_error = [NSError errorWithDomain:HttpErrorOperationDomain code:httpOperationErrorResponseTooLarge userInfo:nil];
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
                        error = [NSError errorWithDomain:HttpErrorOperationDomain code:httpOperationErrorOnOutputStream userInfo:nil];
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
    //assert(connection == self.connection);	
    // Swap the data accumulator over to the response data so that we don't trigger a copy.
    assert(self->_responseBody == nil);
	
    self->_responseBody = self->_dataAccumulator;
    self->_dataAccumulator = nil;
    
    if ( !self.isStatusCodeAcceptable ) {
        _error = [NSError errorWithDomain:HttpErrorOperationDomain code:self.lastResponse.statusCode userInfo:nil];
    } 
    if( !self.isContentTypeAcceptable ) {
        _error = [NSError errorWithDomain:HttpErrorOperationDomain code:httpOperationErrorBadContentType userInfo:nil];
    }

    [self finish];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    assert(connection == self.connection);
    assert(error != nil);
	_error = [error copy];
    [self finish];
}

@end

NSString *HttpErrorOperationDomain = @"HttpErrorOperationErrorDomain";
