#import "PageGetDelegate.h"

@implementation PageGetDelegate


- (id)initWithTarget:(id)target action:(SEL)action context:(id)context;
{
    self = [super initWithTarget:target action:action context:context];
    if (self != nil) {
        self.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    }
    return self;
}

@end