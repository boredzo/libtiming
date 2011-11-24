# libtiming

This is a library (currently only a static library) that makes it easy to time multiple implementations of something against each other.

This basically replaces making a command-line tool for each approach. Instead, you write a single tool that uses this library and wraps each implementation in a block. Add all the blocks to a PRHTimingComparator and start it; it will call a block you give it when each timed block finishes.

    PRHTimingComparator *comparator = [PRHTimingComparator new];
    [comparator addBlockWithName:@"Foo" block:^{
    	//Implementation of Foo algorithm
    }];
    [comparator addBlockWithName:@"Bar" block:^{
    	//Implementation of Bar algorithm
    }];
    comparator.timingFinishedBlock = ^void(bool finishedNormally) {
    	exit(!finishedNormally);
    };
    [comparator startWithReturnBlock:PRHTimingLogToConsoleReturnBlock];
    dispatch_main();

(`PRHTimingLogToConsoleReturnBlock` is a predefined block that logs a single result to the Console. You can write your own block and use that instead, or in addition.)

## Other features

- There's a minimum number of runs and a minimum amount of time. These are set to default values that will ensure each block is run enough times to generate a meaningful average.
- There's a maximum number of runs and a maximum amount of time. Each block will be run no more than the maximum number of times, and all timing will be aborted at the end of the hard time limit. These are also set to reasonable default values. This will ensure your timing does not take forever.
- Timing is done in parallel, using GCD.
- By default, a comparator uses the default concurrent queue, but you can change it.

## What's needed?

- More test cases. For example:
  - It would probably be nice to test that the maximums are truly enforced.
  - It would also be good to test it with a serial queue.
