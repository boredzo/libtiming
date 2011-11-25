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
	dispatch_source_t timerSource, cancelSource;
	uint64_t lastRunTime, timeOfCompletion;
	uint64_t timeTakenInAbsoluteUnits;
}

@synthesize block;
@synthesize name;

@synthesize runsExecuted;
- (void) incrementRunsExecuted {
	self.runsExecuted = self.runsExecuted + 1;
}

@synthesize returnBlock;

- (void) dealloc {
	[self stopTiming];
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
	bool wasRunning = self->timerSource;
	[self stopTiming];

	if (wasRunning) {
		timeOfCompletion = lastRunTime;

		NSTimeInterval timeTaken = self.timeTaken;
		NSUInteger numberOfRuns = self.runsExecuted;
		self.returnBlock(self.name, numberOfRuns, timeTaken, timeTaken / numberOfRuns);
	}
}

- (NSTimeInterval) timeTaken {
	return PRHAbsoluteTimeToSeconds(self->timeTakenInAbsoluteUnits);
}

- (void) startTimingOnQueue:(dispatch_queue_t)queue
		 minimumNanoseconds:(uint64_t)minimumNanoseconds
				minimumRuns:(NSUInteger)minimumRuns
				maximumRuns:(NSUInteger)maximumRuns
{
	__block PRHTimingBlockRecord *bself = self;
	{
		dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, /*handle*/ 0, /*mask*/ 0, queue);
		dispatch_source_set_timer(source, DISPATCH_TIME_NOW, /*interval*/ 0, /*leeway*/ 0);
		dispatch_source_set_event_handler(source, ^{
			[bself run];
			if (bself->runsExecuted == maximumRuns)
				[bself markAsCompleted];
		});

		self->timerSource = source;
		dispatch_resume(self->timerSource);
	}
	{
		dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, /*handle*/ 0, /*mask*/ 0, queue);
		dispatch_source_set_timer(source, dispatch_time(DISPATCH_TIME_NOW, minimumNanoseconds), /*interval*/ minimumNanoseconds, /*leeway*/ 0);
		dispatch_source_set_event_handler(source, ^{
			if (bself.runsExecuted < minimumRuns) {
				//Keep going. This timer will run again another minimumNanoseconds later. Hopefully we'll have run enough times (or hit a maximum) by then.
			} else {
				//We have both used (at least) the minimum amount of time and run the minimum number of times. We're done!
				[bself markAsCompleted];
			}
		});

		self->cancelSource = source;
		dispatch_resume(self->cancelSource);
	}
}
- (void) stopTiming {
	//Note: This method must be safe to call from our dealloc.

#define END_SOURCE(source)            \
	if (source) {                      \
		dispatch_source_cancel(source); \
		dispatch_release(source);        \
		(source) = nil;                   \
	}

	END_SOURCE(self->timerSource);
	END_SOURCE(self->cancelSource);
}

@end
