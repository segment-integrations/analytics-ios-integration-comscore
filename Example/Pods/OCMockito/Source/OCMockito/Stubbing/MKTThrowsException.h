//  OCMockito by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2016 Jonathan M. Reid. See LICENSE.txt

#import "MKTAnswer.h"


/*!
 * @abstract Method answer that throws an exception.
 */
@interface MKTThrowsException : NSObject <MKTAnswer>

- (instancetype)initWithException:(NSException *)exception;

@end
