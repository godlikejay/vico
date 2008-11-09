#import "ViScope.h"

@implementation ViScope

@synthesize range;
@synthesize scopes;

- (ViScope *)initWithScopes:(NSArray *)scopesArray range:(NSRange)aRange
{
	if ((self = [super init]) != nil)
	{
		scopes = scopesArray;
		range = aRange;
	}
	return self;
}

- (int)compareBegin:(ViScope *)otherContext
{
	if (self == otherContext)
		return 0;

	if (range.location < otherContext.range.location)
		return -1;
	if (range.location > otherContext.range.location)
		return 1;

	if (range.length > otherContext.range.length)
		return -1;
	if (range.length < otherContext.range.length)
		return 1;
	
	return 0;
}

@end

