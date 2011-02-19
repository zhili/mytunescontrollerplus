#import "HttpConnectionDelegate.h"



@interface PageGetDelegate : HttpConnectionDelegate
{

}

- (id)initWithTarget:(id)target action:(SEL)action context:(id)context;
@end