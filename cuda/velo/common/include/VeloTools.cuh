#pragma once

#include "math_constants.h" // PI

/**
 * @brief Calculate a single hit phi in odd sensor
 */
__device__ float hit_phi_odd(const float x, const float y);

/**
 * @brief Calculate a single hit phi in even sensor
 */
__device__ float hit_phi_even(const float x, const float y);
