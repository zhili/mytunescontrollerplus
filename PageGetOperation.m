#import "PageGetOperation.h"

@implementation PageGetOperation

- (id)initWithURL:(NSURL *)url 
{
    assert(url != nil);
    self = [super initWithURL:url];
    if (self != nil) {
        self.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    }
    return self;
}

- (id)initWithRequest:(NSURLRequest *)request;
{
    assert(request != nil);
    self = [super initWithRequest:request];
    if (self != nil) {
        self.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    }
    return self;
}

@end