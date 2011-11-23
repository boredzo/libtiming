//
//  TestAbsoluteTimeConversions.m
//  libtiming
//
//  Created by Peter Hosey on 2011-11-23.
//  Copyright (c) 2011 Peter Hosey. All rights reserved.
//

#import "TestAbsoluteTimeConversions.h"

#import "PRHAbsoluteTimeToNanoseconds.h"
@implementation TestAbsoluteTimeConversions

- (void) testNanosecondsToAbsoluteTimeAndBack {
	uint64_t nanoseconds = 40;
	uint64_t convertedValue = PRHAbsoluteTimeToNanoseconds(PRHNanosecondsToAbsoluteTime(nanoseconds));
	STAssertEquals(nanoseconds, convertedValue, @"Round trip from nanoseconds (%llu) to absolute time and back returned a wrong number of nanoseconds (%llu)", nanoseconds, convertedValue);
}
- (void) testSecondsToAbsoluteTimeAndBack {
	NSTimeInterval seconds = 40.0;
	NSTimeInterval convertedValue = PRHAbsoluteTimeToSeconds(PRHSecondsToAbsoluteTime(seconds));
	STAssertEquals(seconds, convertedValue, @"Round trip from seconds (%g) to absolute time and back returned a wrong number of seconds (%g)", seconds, convertedValue);
}

@end
