#pragma once

#include "Argument.cuh"

/**
 * @brief Definition of arguments. All arguments should be defined here,
 *        with their associated type.
 */
ARGUMENT(dev_kalman_pv_ipchi2, char)
ARGUMENT(dev_one_track_results, bool)
ARGUMENT(dev_two_track_results, bool)
ARGUMENT(dev_single_muon_results, bool)
ARGUMENT(dev_disp_dimuon_results, bool)
ARGUMENT(dev_high_mass_dimuon_results, bool)
ARGUMENT(dev_dimuon_soft_results, bool)
