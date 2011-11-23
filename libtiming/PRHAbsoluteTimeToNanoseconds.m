//
//  PRHAbsoluteTimeToNanoseconds.m
//  libtiming
//
//  Created by Peter Hosey on 2011-11-23.
//  Copyright (c) 2011 Peter Hosey. All rights reserved.
//

#import "PRHAbsoluteTimeToNanoseconds.h"

static mach_timebase_info_data_t timebase;

static void PRHInitTimebase(void) {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		mach_timebase_info(&timebase);
	});
}

uint64_t PRHAbsoluteTimeToNanoseconds(uint64_t absoluteTime) {
	return NSEC_PER_SEC * PRHAbsoluteTimeToSeconds(absoluteTime);
}
NSTimeInterval PRHAbsoluteTimeToSeconds(uint64_t absoluteTime) {
	PRHInitTimebase();

	return (absoluteTime * (timebase.numer / (NSTimeInterval)timebase.denom)) / NSEC_PER_SEC;
}

uint64_t PRHNanosecondsToAbsoluteTime(uint64_t nanoseconds) {
	PRHInitTimebase();

	return nanoseconds / (timebase.numer / (NSTimeInterval)timebase.denom);
}
uint64_t PRHSecondsToAbsoluteTime(NSTimeInterval seconds) {
	return PRHNanosecondsToAbsoluteTime(seconds * NSEC_PER_SEC);
}
