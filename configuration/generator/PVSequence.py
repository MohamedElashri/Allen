from algorithms import *
from VeloConfiguration import VELO_sequence

# PV sequence
velo_kalman_filter = velo_kalman_filter_t()
pv_beamline_extrapolate = pv_beamline_extrapolate_t()
pv_beamline_histo = pv_beamline_histo_t()
pv_beamline_peak = pv_beamline_peak_t()
pv_beamline_calculate_denom = pv_beamline_calculate_denom_t()
pv_beamline_multi_fitter = pv_beamline_multi_fitter_t()
pv_beamline_cleanup = pv_beamline_cleanup_t()

s = VELO_sequence()
s.extend_sequence(velo_kalman_filter,
  pv_beamline_extrapolate,
  pv_beamline_histo,
  pv_beamline_peak,
  pv_beamline_calculate_denom,
  pv_beamline_multi_fitter,
  pv_beamline_cleanup)

s.validate()

s.generate()