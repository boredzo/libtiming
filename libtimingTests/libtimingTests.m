//
//  libtimingTests.m
//  libtimingTests
//
//  Created by Peter Hosey on 2011-11-22.
//  Copyright (c) 2011 Peter Hosey. All rights reserved.
//

#import "libtimingTests.h"

#import "libtiming.h"

@implementation libtimingBasicTest
{
	PRHTimingComparator *comparator;
	NSUInteger numberOfOperationsEntered;
}

- (void) setUp {
	[super setUp];

	time_t now = time(NULL);
	NSUInteger numerator = (now & 0xf);
	NSUInteger shiftDistance = 1;
	NSUInteger denominator = 1 << shiftDistance;
	double numerator_fp = numerator, denominator_fp = denominator;
	double multiplier_fp = 1.0 / denominator_fp;

	__block double multiplyResult_fp, divideResult_fp;
	__block NSUInteger divideResult, shiftResult;

	comparator = [PRHTimingComparator new];
	[comparator addBlockWithName:@"Multiply floating-point" block:^{
		multiplyResult_fp = numerator_fp * multiplier_fp;
	}];
	++numberOfOperationsEntered;
	[comparator addBlockWithName:@"Divide floating-point" block:^{
		divideResult_fp = numerator_fp / denominator;
	}];
	++numberOfOperationsEntered;
	[comparator addBlockWithName:@"Divide integer" block:^{
		divideResult = numerator / denominator;
	}];
	++numberOfOperationsEntered;
	[comparator addBlockWithName:@"Shift integer" block:^{
		shiftResult = numerator >> shiftDistance;
	}];
	++numberOfOperationsEntered;
}

- (void) tearDown {
	comparator = nil;

	[super tearDown];
}

- (void) testTiming {
	STAssertNotNil(self->comparator, @"Couldn't create comparator");

	dispatch_queue_t queue = self->comparator.queue;
	STAssertTrue(queue != NULL, @"A comparator should have a queue by default");
	dispatch_debug(queue, "Comparator's queue");

	__block libtimingBasicTest *bself = self;
	__block NSUInteger numberOfOperationsRecorded = 0;
	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0L);
	comparator.timingFinishedBlock = ^void(bool finishedNormally) {
		STAssertEquals(numberOfOperationsRecorded, bself->numberOfOperationsEntered, @"Comparator recorded not enough or too many operations");
		STAssertTrue(finishedNormally, @"Timing did not finish normally");
		dispatch_semaphore_signal(semaphore);
	};

	[comparator startWithReturnBlock:^(NSString *name, NSUInteger iterations, NSTimeInterval timeTaken, NSTimeInterval timePerIteration) {
		STAssertTrue(timeTaken > 0.0, @"Comparator claims that %@ took zero seconds", name);
		STAssertEquals(timePerIteration, timeTaken / iterations, @"Time per iteration makes no sense; should be equal to time taken divided by number of iterations");
		PRHTimingLogToConsoleReturnBlock(name, iterations, timeTaken, timePerIteration);
		++numberOfOperationsRecorded;
	}];

	double timeout = self->comparator.timeLimit + self->comparator.timeLimitHeadroom;
	NSLog(@"Waiting up to %f minutes", timeout / 60.0);
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (timeout * 2) * NSEC_PER_SEC);

	dispatch_after(popTime, queue, ^(void){
		NSLog(@"Time expired");
		comparator.timingFinishedBlock(false);
	});

	dispatch_semaphore_wait(semaphore, popTime);
}

@end
