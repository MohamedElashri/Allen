#if defined(__NVCC__) || defined(__CUDACC__)

#include "math_constants.h"

#else

#include <math.h>
#define CUDART_PI_F M_PI

#endif