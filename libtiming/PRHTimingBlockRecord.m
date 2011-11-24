//
//  PRHTimingBlockRecord.m
//  libtiming
//
//  Created by Peter Hosey on 2011-11-22.
//  Copyright (c) 2011 Peter Hosey. All rights reserved.
//

#import "PRHTimingBlockRecord.h"

#import "PRHAbsoluteTimeToNanoseconds.h"

@implementation PRHTimingBlockRecord
{
	uint64_t lastRunTime, timeOfCompletion;
	uint64_t timeTakenInAbsoluteUnits;
}

@synthesize block;
@synthesize name;

@synthesize runsExecuted;
- (void) incrementRunsExecuted {
	self.runsExecuted = self.runsExecuted + 1;
}

- (void) run {
	uint64_t start, end;
	start = mach_absolute_time();
	self.block();
	end = mach_absolute_time();

	timeTakenInAbsoluteUnits += end - start;

	lastRunTime = end;
	[self incrementRunsExecuted];
}

- (void) markAsCompleted {
	timeOfCompletion = lastRunTime;
}

- (NSTimeInterval) timeTaken {
	return PRHAbsoluteTimeToSeconds(self->timeTakenInAbsoluteUnits);
}

@end
