
@interface HttpOperation: NSOperation
{
    NSURLRequest *_request;
    NSIndexSet *_acceptableStatusCodes;
    NSSet *_acceptableContentTypes;
    NSOutputStream *_responseOutputStream;
    NSUInteger _defaultResponseSize;
    NSUInteger _maximumResponseSize;
    BOOL _firstData;
    NSMutableData *_dataAccumulator;
    NSURLRequest *_lastRequest;
    NSHTTPURLResponse *_lastResponse;
    NSData *_responseBody;
	NSError *_error;
    NSURLConnection *_connection;
    BOOL _isExecuting;
    BOOL _isFinished;
}

- (id)initWithRequest:(NSURLRequest *)request;
- (id)initWithURL:(NSURL *)url;

@property (readonly, retain) NSError *error;
@property (copy, readonly) NSURLRequest *request;
@property (copy, readonly) NSURL *URL;
// 200~299 status code is acceptable.
@property (copy, readwrite) NSIndexSet *acceptableStatusCodes;  
// default all.
@property (copy, readwrite) NSSet *acceptableContentTypes; 


// IMPORTANT: If you set a response stream, calls the response 
// stream synchronously.  This is fine for file and memory streams, but it would 
// not work well for other types of streams (like a bound pair).

// defaults to nil, which puts response into responseBody
@property (retain, readwrite) NSOutputStream *responseOutputStream;
// default is 1 MB, ignored if responseOutputStream is set
@property (assign, readwrite) NSUInteger defaultResponseSize;    
// default is 4 MB, ignored if responseOutputStream is set
@property (assign, readwrite) NSUInteger maximumResponseSize;

// Things that are only meaningful after a response has been received;
@property (assign, readonly, getter=isStatusCodeAcceptable)  BOOL statusCodeAcceptable;
@property (assign, readonly, getter=isContentTypeAcceptable) BOOL contentTypeAcceptable;

// Things that are only meaningful after the operation is finished.
@property (copy, readonly)  NSURLRequest *lastRequest;       
@property (copy, readonly)  NSHTTPURLResponse *lastResponse;       

@property (copy, readonly)  NSData *responseBody;   
@property (readonly) BOOL isExecuting;
@property (readonly) BOOL isFinished;

@end

@interface HttpOperation (NSURLConnectionDelegate)

// Latches the request and response in lastRequest and lastResponse.
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response;

// Latches the response in lastResponse.
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
// If this is the first chunk of data, it decides whether the data is going to be 
// routed to memory (responseBody) or a stream (responseOutputStream) and makes the 
// appropriate preparations.  For this and subsequent data it then actually shuffles 
// the data to its destination.
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
// Completes the operation with either no error (if the response status code is acceptable) 
// or an error (otherwise).
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
// Completes the operation with the error.
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
@end

extern NSString *HttpErrorOperationDomain;

enum {
    httpOperationErrorResponseTooLarge = -1, 
    httpOperationErrorOnOutputStream   = -2, 
    httpOperationErrorBadContentType   = -3
};
