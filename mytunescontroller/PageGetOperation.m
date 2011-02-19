#import "PageGetOperation.h"

@implementation PageGetOperation

@synthesize delegate = _delegate;

- (id)initWithRequest:(NSURLRequest *)request
{
	if (self = [super initWithRequest:request]) {
		self.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
	}
	return self;
}

- (id)initWithURL:(NSURL *)url
{
	if (self = [super initWithURL:url]) {
		self.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
	}
	return self;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[super connectionDidFinishLoading:connection];
	// if is not cancelled perform delegate
	if (![self isCancelled] && [self.delegate respondsToSelector:@selector(pageGetDone:)]) {
	   [self.delegate pageGetDone:self];
	} 
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [super connection:connection didFailWithError:error];
    if (![self isCancelled] && [self.delegate respondsToSelector:@selector(pageGetDone:)]) {
		[self.delegate pageGetDone:self];
    }
}

@end
