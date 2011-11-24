//
//  main.m
//  mathtiming
//
//  Created by Peter Hosey on 2011-11-23.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "libtiming.h"

int main(int argc, char *argv[]) {
	@autoreleasepool {
		time_t now = time(NULL);
		NSUInteger numerator = (now & 0xf);
		NSUInteger shiftDistance = 1;
		NSUInteger denominator = 1 << shiftDistance;
		double numerator_fp = numerator, denominator_fp = denominator;
		double multiplier_fp = 1.0 / denominator_fp;

		__block double multiplyResult_fp, divideResult_fp;
		__block NSUInteger divideResult, shiftResult;

		PRHTimingComparator *comparator = [PRHTimingComparator new];

		//PRHTimingComparator supports both style rules. You can have the block first:
		[comparator addBlock:^{
			multiplyResult_fp = numerator_fp * multiplier_fp;
		} withName:@"Multiply floating-point"];
		[comparator addBlock:^{
			divideResult_fp = numerator_fp / denominator;
		} withName:@"Divide floating-point"];

		//Or the block last:
		[comparator addBlockWithName:@"Divide integer" block:^{
			divideResult = numerator / denominator;
		}];
		[comparator addBlockWithName:@"Shift integer" block:^{
			shiftResult = numerator >> shiftDistance;
		}];

		comparator.timingFinishedBlock = ^void(bool finishedNormally){
			exit(!finishedNormally);
		};

		[comparator startWithReturnBlock:PRHTimingLogToConsoleReturnBlock];

		dispatch_main();
	}
    return 0;
}

