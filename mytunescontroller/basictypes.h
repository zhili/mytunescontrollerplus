/*
 *  basictypes.h
 *  MyTunesControllerPlus
 *
 *  Created by zhili hu on 2/6/11.
 *  Copyright 2011 zhili hu. All rights reserved.
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

#define SOGOU_QUERY_AT_TEMPLATE @"http://mp3.sogou.com/gecisearch.so?query=%@+%@"
#define BAIDU_QUERY_AT_TEMPLATE @"http://mp3.baidu.com/m?f=ms&tn=baidump3lyric&ct=150994944&lf=2&rn=10&word=%@&lm=-1"
#define LRC123 @"http://www.lrc123.com/?keyword=%@+%@&field=all"
#define SOSO_QUERY_AT_TEMPLATE @"http://cgi.music.soso.com/fcgi-bin/m.q?w=%@+%@&source=1&t=7"

#define SOGOU_LRC_FOOTPRINT "downlrc.jsp"
#define BAIDU_LRC_FOOTPRINT ".lrc"
#define LRC123_LRC_FOOTPRINT "/download/lrc"
#define LRC123_BASEURL @"http://www.lrc123.com"
#define SOGOU_BASEURL @"http://mp3.sogou.com/"
#define SOSO_URL_TEMPLATE @"http://cgi.music.soso.com/fcgi-bin/fcg_download_lrc.q?song=%@&singer=%@&down=1"
