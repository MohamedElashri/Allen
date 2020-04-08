from algorithms import *


def PV_sequence():
    velo_kalman_filter = velo_kalman_filter_t()
    pv_beamline_extrapolate = pv_beamline_extrapolate_t()
    pv_beamline_histo = pv_beamline_histo_t()
    pv_beamline_peak = pv_beamline_peak_t()
    pv_beamline_calculate_denom = pv_beamline_calculate_denom_t()
    pv_beamline_multi_fitter = pv_beamline_multi_fitter_t()
    pv_beamline_cleanup = pv_beamline_cleanup_t()

    pv_sequence = Sequence(velo_kalman_filter, pv_beamline_extrapolate,
                           pv_beamline_histo, pv_beamline_peak,
                           pv_beamline_calculate_denom,
                           pv_beamline_multi_fitter, pv_beamline_cleanup)

    return pv_sequence
