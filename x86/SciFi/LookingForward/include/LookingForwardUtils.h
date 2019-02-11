#pragma once

#include <cmath>
#include <array>
#include <vector>
#include <algorithm>
#include <fstream>

#include <cassert>

#include "SciFiDefinitions.cuh"
#include "SciFiEventModel.cuh"
#include "LookingForwardConstants.h"
#include "MomentumForwardUtils.h"

float x_at_z(const MiniState& state, const float z);

MiniState propagate_state_from_velo(const MiniState& UT_state, float qop, int layer);
