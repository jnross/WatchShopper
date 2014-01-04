#pragma once

#include <pebble.h>

#define DISABLE_MLOG 1

#if DISABLE_MLOG
	#define MLOG(format, args...)  {}
#else
	#define MLOG(format, args...)  \
		APP_LOG(APP_LOG_LEVEL_DEBUG, format , ## args)
#endif
