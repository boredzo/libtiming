//
//  PRHAbsoluteTimeToNanoseconds.h
//  libtiming
//
//  Created by Peter Hosey on 2011-11-23.
//  Copyright (c) 2011 Peter Hosey. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <mach/mach_time.h>

extern uint64_t PRHAbsoluteTimeToNanoseconds(uint64_t absoluteTime);
extern NSTimeInterval PRHAbsoluteTimeToSeconds(uint64_t absoluteTime);

extern uint64_t PRHNanosecondsToAbsoluteTime(uint64_t nanoseconds);
extern uint64_t PRHSecondsToAbsoluteTime(NSTimeInterval seconds);
