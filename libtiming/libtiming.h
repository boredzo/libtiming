//
//  libtiming.h
//  libtiming
//
//  Created by Peter Hosey on 2011-11-22.
//  Copyright (c) 2011 Peter Hosey. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^PRHTimingReturnBlock)(NSString *name, NSUInteger iterations, NSTimeInterval timeTaken, NSTimeInterval timePerIteration);

//Logs to Console something like “<name> ran <iterations> times in <timeTaken> seconds (<timePerIteration> per iteration)”.
extern PRHTimingReturnBlock PRHTimingLogToConsoleReturnBlock;

//finishedNormally is true when one of the limits was reached, false when timing was canceled.
typedef void (^PRHTimingFinishedBlock)(bool finishedNormally);

//You shouldn't rely on these; if you need a specific value, set it yourself. They're defined here in the header as macros so that the values can be both documented and DRY.
#define PRHTimingComparator_DefaultTimeLimit 3
#define PRHTimingComparator_DefaultTimeLimitHeadroomMinutes 5
#define PRHTimingComparator_DefaultTimeLimitHeadroom (PRHTimingComparator_DefaultTimeLimitHeadroomMinutes * 60.0)
#define PRHTimingComparator_DefaultMinimumNumberOfRuns 1.0e+4
#define PRHTimingComparator_DefaultMaximumNumberOfRuns 1.0e+7

@interface PRHTimingComparator : NSObject

/*timeLimit and minimumNumberOfRuns are minimums. Each block must run at least that many times, for at least that much time.
 *The hard time limit (timeLimit + timeLimitHeadroom) and maximumNumberOfRuns are maximums. Of the two, the hard time limit outranks the maximum number of runs. Each block will be run no more than maximumNumberOfRuns times, and if the hard time limit is reached, timing will come to an end, no matter how many times the blocks have run.
 */

//Timing will be aborted normally if it goes at least minimumNumberOfRuns times and either takes longer than timeLimit or reaches maximumNumberOfRuns.
@property(assign) NSTimeInterval timeLimit;
//Timing will be forcibly aborted if it goes over time limit + headroom, even if any blocks have not reached the maximum number of runs.
@property(assign) NSTimeInterval timeLimitHeadroom;
//Each block will be run no fewer than this many times (unless the hard time limit is reached).
@property(assign) NSUInteger minimumNumberOfRuns;
//Each block will be run no more than this many times.
@property(assign) NSUInteger maximumNumberOfRuns;

//Retains using dispatch_retain/dispatch_release.
@property(nonatomic, assign) dispatch_queue_t queue;

@property(copy) PRHTimingFinishedBlock timingFinishedBlock;

//The name is your name for the approach that this block takes.
- (void) addBlock:(dispatch_block_t)block withName:(NSString *)name;
//Or, if you prefer the block to come last:
- (void) addBlockWithName:(NSString *)name block:(dispatch_block_t)block;

//This returns while the blocks are still running. If you want to block until they're all finished, call dispatch_barrier_sync with the comparator's queue.
- (void) startWithReturnBlock:(PRHTimingReturnBlock)returnBlock;

- (void) cancel;

@end
