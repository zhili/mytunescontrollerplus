#import "HttpOperation.h"

@protocol PageGetOperationDelegate;

@interface PageGetOperation : HttpOperation
{
    id<PageGetOperationDelegate> _delegate;
}

@property (nonatomic, assign, readwrite) id<PageGetOperationDelegate> delegate;
- (id)initWithRequest:(NSURLRequest *)request;
- (id)initWithURL:(NSURL *)url;

@end

@protocol PageGetOperationDelegate <NSObject>

- (void)pageGetDone:(PageGetOperation *)op;

@end
