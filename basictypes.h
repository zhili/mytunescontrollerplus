/*
 *  basictypes.h
 *  MyTunesControllerPlus
 *
 *  Created by zhili hu on 2/6/11.
 *  Copyright 2011 scut. All rights reserved.
 *
 */

#ifdef DEBUG
#   define DeLog(fmt, ...) do {NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);} while(0)
#else
#   define DeLog(...) do { } while(0)
#endif

enum LRC_ENGINE {
	LRC123_LRC_ENGINE = 1,
	SOGOU_LRC_ENGINE,
	SOSO_LRC_ENGINE,
};

typedef enum LRC_ENGINE LRC_ENGINE;