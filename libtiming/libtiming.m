//
//  libtiming.m
//  libtiming
//
//  Created by Peter Hosey on 2011-11-22.
//  Copyright (c) 2011 Peter Hosey. All rights reserved.
//

#import "libtiming.h"

#import "PRHTimingBlockRecord.h"
#import "PRHAbsoluteTimeToNanoseconds.h"

PRHTimingReturnBlock PRHTimingLogToConsoleReturnBlock = ^(NSString *name, NSUInteger iterations, NSTimeInterval timeTaken, NSTimeInterval timePerIteration) {
	NSLog(@"%@ ran %lu times in %f seconds (%f microseconds per iteration)", name, iterations, timeTaken, timePerIteration * USEC_PER_SEC);
};

@interface PRHTimingComparator ()
@property(strong) NSMutableArray *timingBlockRecords;
@property(nonatomic, assign /*dispatch_retain*/) dispatch_source_t timerSource;
@property(nonatomic, assign /*dispatch_retain*/) dispatch_source_t deadlineSource;
@property(assign) bool canceled;

- (void) finished;
@end

@implementation PRHTimingComparator
{
	uint64_t startTime, softDeadline, totalTimeLimit, endTime;
}

@synthesize timingBlockRecords;

@synthesize timeLimit;
@synthesize timeLimitHeadroom;
@synthesize minimumNumberOfRuns;
@synthesize maximumNumberOfRuns;

@synthesize canceled;

@synthesize timingFinishedBlock;

@synthesize queue = _queue;
- (void) setQueue:(dispatch_queue_t)newQueue {
	if (self->_queue != newQueue) {
		if (self->_queue)
			dispatch_release(self->_queue);

		self->_queue  = newQueue;

		if (self->_queue)
			dispatch_retain(self->_queue);
	}
}

@synthesize timerSource = _timerSource;
- (void) setTimerSource:(dispatch_source_t)newSource {
	if (self->_timerSource != newSource) {
		if (self->_timerSource)
			dispatch_release(self->_timerSource);
		
		self->_timerSource  = newSource;
		
		if (self->_timerSource)
			dispatch_retain(self->_timerSource);
	}
}

@synthesize deadlineSource = _deadlineSource;
- (void) setDeadlineSource:(dispatch_source_t)newSource {
	if (self->_deadlineSource != newSource) {
		if (self->_deadlineSource)
			dispatch_release(self->_deadlineSource);
		
		self->_deadlineSource  = newSource;
		
		if (self->_deadlineSource)
			dispatch_retain(self->_deadlineSource);
	}
}

- (id) init {
	if ((self = [super init])) {
		self.timeLimit = PRHTimingComparator_DefaultTimeLimit;
		self.timeLimitHeadroom = PRHTimingComparator_DefaultTimeLimitHeadroom;
		self.minimumNumberOfRuns = PRHTimingComparator_DefaultMinimumNumberOfRuns;
		self.maximumNumberOfRuns = PRHTimingComparator_DefaultMaximumNumberOfRuns;

		self.queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, /*flags*/ 0);

		self.timingBlockRecords = [NSMutableArray new];
	}
	return self;
}

- (void) addBlock:(dispatch_block_t)block withName:(NSString *)name {
	PRHTimingBlockRecord *record = [PRHTimingBlockRecord new];
	record.name = name;
	record.block = block;
	[self.timingBlockRecords addObject:record];
}
- (void) addBlockWithName:(NSString *)name block:(dispatch_block_t)block {
	[self addBlock:block withName:name];
}

- (void) startWithReturnBlock:(PRHTimingReturnBlock)returnBlock {
	__block PRHTimingComparator *bself = self;
	dispatch_queue_t queue = self.queue;

	startTime = mach_absolute_time();
	mach_timebase_info_data_t timebase;
	kern_return_t err = mach_timebase_info(&timebase);
	NSAssert(err == KERN_SUCCESS, @"mach_timebase_info returned %i", err);
	uint64_t timeLimitInAbsoluteTime = PRHSecondsToAbsoluteTime(self.timeLimit);
	softDeadline = startTime + timeLimitInAbsoluteTime;
	int64_t timeLimitHeadroomInNanoseconds = (self.timeLimitHeadroom * NSEC_PER_SEC);
	uint64_t timeLimitHeadroomInAbsoluteTime = PRHNanosecondsToAbsoluteTime(timeLimitHeadroomInNanoseconds);
	totalTimeLimit = timeLimitInAbsoluteTime + timeLimitHeadroomInAbsoluteTime;

	{
		dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, /*handle*/ 0, /*mask*/ 0, queue);
		dispatch_source_set_timer(source, DISPATCH_TIME_NOW, /*interval*/ 0 /*nanosecond*/, /*leeway*/ 0);
		dispatch_group_t group = dispatch_group_create();
		dispatch_source_set_event_handler(source, ^{
			uint64_t now = mach_absolute_time();
			if (now > softDeadline) {
				bool allCompleted = true;
				for (PRHTimingBlockRecord *record in bself.timingBlockRecords) {
					if (record.runsExecuted < bself.minimumNumberOfRuns) {
						allCompleted = false;
						break;
					}
				};
				if (allCompleted) {
					[bself finished];
					return;
				}
			}

			bool startedAnyRuns = false;
			for (PRHTimingBlockRecord *record in bself.timingBlockRecords) {
				if (record.runsExecuted < bself.maximumNumberOfRuns) {
					dispatch_group_async(group, queue, ^{
						[record run];
					});
					startedAnyRuns = true;
				}
			}
			if (startedAnyRuns) {
				dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, timeLimitHeadroomInNanoseconds));
			} else {
				//All blocks have exceeded their maximum number of runs.
				[bself finished];
			}
		});

		dispatch_source_set_cancel_handler(source, ^{
			if (bself.canceled) {
				//XXX ???
			} else {
				for (PRHTimingBlockRecord *record in bself.timingBlockRecords) {
					[record markAsCompleted];

					NSTimeInterval timeTaken = record.timeTaken;
					NSUInteger numberOfRuns = record.runsExecuted;
					returnBlock(record.name, numberOfRuns, timeTaken, timeTaken / numberOfRuns);
				}
			}

			bool finishedNormally = !(bself.canceled);
			if (bself.timingFinishedBlock)
				(bself.timingFinishedBlock)(finishedNormally);
		});

		self.timerSource = source;
		dispatch_release(source);
		dispatch_resume(self.timerSource);
	}

	{
		dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, /*handle*/ 0, /*mask*/ 0, queue);
		dispatch_source_set_timer(source, dispatch_time(DISPATCH_TIME_NOW, totalTimeLimit), /*interval*/ 0, /*leeway*/ 0);
		dispatch_source_set_event_handler(source, ^{
			dispatch_source_cancel(bself.timerSource);
			dispatch_source_cancel(bself.deadlineSource);
		});
		self.deadlineSource = source;
		dispatch_release(source);

		dispatch_resume(self.deadlineSource);
	}
}

- (void) finished {
	self.canceled = false;
	dispatch_source_cancel(self.timerSource);
}
- (void) cancel {
	self.canceled = true;
	dispatch_source_cancel(self.timerSource);
	dispatch_source_cancel(self.deadlineSource);
}

@end
