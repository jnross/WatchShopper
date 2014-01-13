#pragma once

#include <pebble.h>

#define DISABLE_MLOG 1
#define DISABLE_DLOG 1

#define LOG(format, args...) APP_LOG(APP_LOG_LEVEL_DEBUG, format , ## args)

#if DISABLE_DLOG
	#define DLOG(format, args...)  {}
#else
	#define DLOG(format, args...)  \
		LOG(format , ## args)
#endif

#if DISABLE_MLOG
	#define MLOG(format, args...)  {}
#else
	#define MLOG(format, args...)  \
		LOG(format , ## args)
#endif
