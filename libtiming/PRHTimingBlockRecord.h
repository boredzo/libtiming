//
//  PRHTimingBlockRecord.h
//  libtiming
//
//  Created by Peter Hosey on 2011-11-22.
//  Copyright (c) 2011 Peter Hosey. All rights reserved.
//

#import "libtiming.h"

@interface PRHTimingBlockRecord : NSObject

@property(copy) dispatch_block_t block;
@property(copy) NSString *name;

@property(assign) NSUInteger runsExecuted;
- (void) incrementRunsExecuted;

- (void) run;

//Called by the timing comparator when this block has been run the maximum number of times.
- (void) markAsCompleted;

@property(nonatomic, readonly) NSTimeInterval timeTaken;

@end
