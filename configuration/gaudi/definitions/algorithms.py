from GaudiKernel.DataObjectHandleBase import DataObjectHandleBase
from AllenKernel import AllenAlgorithm
from collections import OrderedDict


def algorithm_dict(*algorithms):
    d = OrderedDict([])
    for alg in algorithms:
        d[alg.name] = alg
    return d


class pv_beamline_calculate_denom_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_number_of_reconstructed_velo_tracks_t = DataObjectHandleBase("host_number_of_reconstructed_velo_tracks_t", "R", "uint"),
    dev_offsets_all_velo_tracks_t = DataObjectHandleBase("dev_offsets_all_velo_tracks_t", "R", "uint"),
    dev_offsets_velo_track_hit_number_t = DataObjectHandleBase("dev_offsets_velo_track_hit_number_t", "R", "uint"),
    dev_pvtracks_t = DataObjectHandleBase("dev_pvtracks_t", "R", "PVTrack"),
    dev_pvtracks_denom_t = DataObjectHandleBase("dev_pvtracks_denom_t", "W", "float"),
    dev_zpeaks_t = DataObjectHandleBase("dev_zpeaks_t", "R", "float"),
    dev_number_of_zpeaks_t = DataObjectHandleBase("dev_number_of_zpeaks_t", "R", "uint"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(pv_beamline_calculate_denom_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "pv_beamline_calculate_denom"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/PV/beamlinePV/include/pv_beamline_calculate_denom.cuh"

  @classmethod
  def getType(cls):
    return "pv_beamline_calculate_denom_t"


class pv_beamline_cleanup_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    dev_multi_fit_vertices_t = DataObjectHandleBase("dev_multi_fit_vertices_t", "R", "PV::Vertex"),
    dev_number_of_multi_fit_vertices_t = DataObjectHandleBase("dev_number_of_multi_fit_vertices_t", "R", "uint"),
    dev_multi_final_vertices_t = DataObjectHandleBase("dev_multi_final_vertices_t", "W", "PV::Vertex"),
    dev_number_of_multi_final_vertices_t = DataObjectHandleBase("dev_number_of_multi_final_vertices_t", "W", "uint"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(pv_beamline_cleanup_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "pv_beamline_cleanup"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/PV/beamlinePV/include/pv_beamline_cleanup.cuh"

  @classmethod
  def getType(cls):
    return "pv_beamline_cleanup_t"


class pv_beamline_extrapolate_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_reconstructed_velo_tracks_t = DataObjectHandleBase("host_number_of_reconstructed_velo_tracks_t", "R", "uint"),
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    dev_velo_kalman_beamline_states_t = DataObjectHandleBase("dev_velo_kalman_beamline_states_t", "R", "char"),
    dev_offsets_all_velo_tracks_t = DataObjectHandleBase("dev_offsets_all_velo_tracks_t", "R", "uint"),
    dev_offsets_velo_track_hit_number_t = DataObjectHandleBase("dev_offsets_velo_track_hit_number_t", "R", "uint"),
    dev_pvtracks_t = DataObjectHandleBase("dev_pvtracks_t", "W", "PVTrack"),
    dev_pvtrack_z_t = DataObjectHandleBase("dev_pvtrack_z_t", "W", "float"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(pv_beamline_extrapolate_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "pv_beamline_extrapolate"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/PV/beamlinePV/include/pv_beamline_extrapolate.cuh"

  @classmethod
  def getType(cls):
    return "pv_beamline_extrapolate_t"


class pv_beamline_histo_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    dev_offsets_all_velo_tracks_t = DataObjectHandleBase("dev_offsets_all_velo_tracks_t", "R", "uint"),
    dev_offsets_velo_track_hit_number_t = DataObjectHandleBase("dev_offsets_velo_track_hit_number_t", "R", "uint"),
    dev_pvtracks_t = DataObjectHandleBase("dev_pvtracks_t", "R", "PVTrack"),
    dev_zhisto_t = DataObjectHandleBase("dev_zhisto_t", "W", "float"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(pv_beamline_histo_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "pv_beamline_histo"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/PV/beamlinePV/include/pv_beamline_histo.cuh"

  @classmethod
  def getType(cls):
    return "pv_beamline_histo_t"


class pv_beamline_multi_fitter_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_number_of_reconstructed_velo_tracks_t = DataObjectHandleBase("host_number_of_reconstructed_velo_tracks_t", "R", "uint"),
    dev_offsets_all_velo_tracks_t = DataObjectHandleBase("dev_offsets_all_velo_tracks_t", "R", "uint"),
    dev_offsets_velo_track_hit_number_t = DataObjectHandleBase("dev_offsets_velo_track_hit_number_t", "R", "uint"),
    dev_pvtracks_t = DataObjectHandleBase("dev_pvtracks_t", "R", "PVTrack"),
    dev_pvtracks_denom_t = DataObjectHandleBase("dev_pvtracks_denom_t", "R", "float"),
    dev_zpeaks_t = DataObjectHandleBase("dev_zpeaks_t", "R", "float"),
    dev_number_of_zpeaks_t = DataObjectHandleBase("dev_number_of_zpeaks_t", "R", "uint"),
    dev_multi_fit_vertices_t = DataObjectHandleBase("dev_multi_fit_vertices_t", "W", "PV::Vertex"),
    dev_number_of_multi_fit_vertices_t = DataObjectHandleBase("dev_number_of_multi_fit_vertices_t", "W", "uint"),
    dev_pvtrack_z_t = DataObjectHandleBase("dev_pvtrack_z_t", "R", "float"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(pv_beamline_multi_fitter_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "pv_beamline_multi_fitter"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/PV/beamlinePV/include/pv_beamline_multi_fitter.cuh"

  @classmethod
  def getType(cls):
    return "pv_beamline_multi_fitter_t"


class pv_beamline_peak_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    dev_zhisto_t = DataObjectHandleBase("dev_zhisto_t", "R", "float"),
    dev_zpeaks_t = DataObjectHandleBase("dev_zpeaks_t", "W", "float"),
    dev_number_of_zpeaks_t = DataObjectHandleBase("dev_number_of_zpeaks_t", "W", "uint")
  )

  def __init__(self, name, **kwargs):
    super(pv_beamline_peak_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "pv_beamline_peak"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/PV/beamlinePV/include/pv_beamline_peak.cuh"

  @classmethod
  def getType(cls):
    return "pv_beamline_peak_t"


class pv_fit_seeds_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    dev_vertex_t = DataObjectHandleBase("dev_vertex_t", "W", "PV::Vertex"),
    dev_number_vertex_t = DataObjectHandleBase("dev_number_vertex_t", "W", "int"),
    dev_seeds_t = DataObjectHandleBase("dev_seeds_t", "R", "PatPV::XYZPoint"),
    dev_number_seeds_t = DataObjectHandleBase("dev_number_seeds_t", "R", "uint"),
    dev_velo_kalman_beamline_states_t = DataObjectHandleBase("dev_velo_kalman_beamline_states_t", "R", "char"),
    dev_atomics_velo_t = DataObjectHandleBase("dev_atomics_velo_t", "R", "uint"),
    dev_velo_track_hit_number_t = DataObjectHandleBase("dev_velo_track_hit_number_t", "R", "uint"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(pv_fit_seeds_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "fit_seeds"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/PV/patPV/include/FitSeeds.cuh"

  @classmethod
  def getType(cls):
    return "pv_fit_seeds_t"


class pv_get_seeds_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_number_of_reconstructed_velo_tracks_t = DataObjectHandleBase("host_number_of_reconstructed_velo_tracks_t", "R", "uint"),
    dev_velo_kalman_beamline_states_t = DataObjectHandleBase("dev_velo_kalman_beamline_states_t", "R", "char"),
    dev_atomics_velo_t = DataObjectHandleBase("dev_atomics_velo_t", "R", "uint"),
    dev_velo_track_hit_number_t = DataObjectHandleBase("dev_velo_track_hit_number_t", "R", "uint"),
    dev_seeds_t = DataObjectHandleBase("dev_seeds_t", "W", "PatPV::XYZPoint"),
    dev_number_seeds_t = DataObjectHandleBase("dev_number_seeds_t", "W", "uint"),
    max_chi2_merge = "",
    factor_to_increase_errors = "",
    min_cluster_mult = "",
    min_close_tracks_in_cluster = "",
    dz_close_tracks_in_cluster = "",
    high_mult = "",
    ratio_sig2_high_mult = "",
    ratio_sig2_low_mult = "",
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(pv_get_seeds_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "pv_get_seeds"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/PV/patPV/include/GetSeeds.cuh"

  @classmethod
  def getType(cls):
    return "pv_get_seeds_t"


class scifi_consolidate_tracks_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_accumulated_number_of_hits_in_scifi_tracks_t = DataObjectHandleBase("host_accumulated_number_of_hits_in_scifi_tracks_t", "R", "uint"),
    host_number_of_reconstructed_scifi_tracks_t = DataObjectHandleBase("host_number_of_reconstructed_scifi_tracks_t", "R", "uint"),
    dev_scifi_hits_t = DataObjectHandleBase("dev_scifi_hits_t", "R", "char"),
    dev_scifi_hit_offsets_t = DataObjectHandleBase("dev_scifi_hit_offsets_t", "R", "uint"),
    dev_scifi_track_hits_t = DataObjectHandleBase("dev_scifi_track_hits_t", "W", "char"),
    dev_offsets_forward_tracks_t = DataObjectHandleBase("dev_offsets_forward_tracks_t", "R", "uint"),
    dev_offsets_scifi_track_hit_number = DataObjectHandleBase("dev_offsets_scifi_track_hit_number", "R", "uint"),
    dev_scifi_qop_t = DataObjectHandleBase("dev_scifi_qop_t", "W", "float"),
    dev_scifi_states_t = DataObjectHandleBase("dev_scifi_states_t", "W", "MiniState"),
    dev_scifi_track_ut_indices_t = DataObjectHandleBase("dev_scifi_track_ut_indices_t", "W", "uint"),
    dev_offsets_ut_tracks_t = DataObjectHandleBase("dev_offsets_ut_tracks_t", "R", "uint"),
    dev_offsets_ut_track_hit_number_t = DataObjectHandleBase("dev_offsets_ut_track_hit_number_t", "R", "uint"),
    dev_scifi_tracks_t = DataObjectHandleBase("dev_scifi_tracks_t", "R", "SciFi::TrackHits"),
    dev_scifi_lf_parametrization_consolidate_t = DataObjectHandleBase("dev_scifi_lf_parametrization_consolidate_t", "R", "float"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(scifi_consolidate_tracks_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "scifi_consolidate_tracks"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/SciFi/consolidate/include/ConsolidateSciFi.cuh"

  @classmethod
  def getType(cls):
    return "scifi_consolidate_tracks_t"


class scifi_copy_track_hit_number_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_number_of_reconstructed_scifi_tracks_t = DataObjectHandleBase("host_number_of_reconstructed_scifi_tracks_t", "R", "uint"),
    dev_offsets_ut_tracks_t = DataObjectHandleBase("dev_offsets_ut_tracks_t", "R", "uint"),
    dev_scifi_tracks_t = DataObjectHandleBase("dev_scifi_tracks_t", "R", "SciFi::TrackHits"),
    dev_offsets_forward_tracks_t = DataObjectHandleBase("dev_offsets_forward_tracks_t", "R", "uint"),
    dev_scifi_track_hit_number_t = DataObjectHandleBase("dev_scifi_track_hit_number_t", "W", "uint"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(scifi_copy_track_hit_number_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "scifi_copy_track_hit_number"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/SciFi/consolidate/include/SciFiCopyTrackHitNumber.cuh"

  @classmethod
  def getType(cls):
    return "scifi_copy_track_hit_number_t"


class lf_create_tracks_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_number_of_reconstructed_ut_tracks_t = DataObjectHandleBase("host_number_of_reconstructed_ut_tracks_t", "R", "uint"),
    dev_offsets_ut_tracks_t = DataObjectHandleBase("dev_offsets_ut_tracks_t", "R", "uint"),
    dev_offsets_ut_track_hit_number_t = DataObjectHandleBase("dev_offsets_ut_track_hit_number_t", "R", "uint"),
    dev_scifi_lf_tracks_t = DataObjectHandleBase("dev_scifi_lf_tracks_t", "W", "SciFi::TrackHits"),
    dev_scifi_lf_atomics_t = DataObjectHandleBase("dev_scifi_lf_atomics_t", "W", "uint"),
    dev_scifi_lf_initial_windows_t = DataObjectHandleBase("dev_scifi_lf_initial_windows_t", "R", "int"),
    dev_scifi_lf_process_track_t = DataObjectHandleBase("dev_scifi_lf_process_track_t", "R", "bool"),
    dev_scifi_lf_found_triplets_t = DataObjectHandleBase("dev_scifi_lf_found_triplets_t", "R", "int"),
    dev_scifi_lf_number_of_found_triplets_t = DataObjectHandleBase("dev_scifi_lf_number_of_found_triplets_t", "R", "int8_t"),
    dev_scifi_lf_total_number_of_found_triplets_t = DataObjectHandleBase("dev_scifi_lf_total_number_of_found_triplets_t", "W", "uint"),
    dev_scifi_hits_t = DataObjectHandleBase("dev_scifi_hits_t", "R", "char"),
    dev_scifi_hit_offsets_t = DataObjectHandleBase("dev_scifi_hit_offsets_t", "R", "uint"),
    dev_offsets_all_velo_tracks_t = DataObjectHandleBase("dev_offsets_all_velo_tracks_t", "R", "uint"),
    dev_offsets_velo_track_hit_number_t = DataObjectHandleBase("dev_offsets_velo_track_hit_number_t", "R", "uint"),
    dev_velo_states_t = DataObjectHandleBase("dev_velo_states_t", "R", "char"),
    dev_ut_track_velo_indices_t = DataObjectHandleBase("dev_ut_track_velo_indices_t", "R", "uint"),
    dev_ut_qop_t = DataObjectHandleBase("dev_ut_qop_t", "R", "float"),
    dev_scifi_lf_parametrization_t = DataObjectHandleBase("dev_scifi_lf_parametrization_t", "W", "float"),
    dev_ut_states_t = DataObjectHandleBase("dev_ut_states_t", "R", "MiniState"),
    triplet_keep_best_block_dim = "",
    calculate_parametrization_block_dim = "",
    extend_tracks_block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(lf_create_tracks_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "lf_create_tracks"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/SciFi/looking_forward/include/LFCreateTracks.cuh"

  @classmethod
  def getType(cls):
    return "lf_create_tracks_t"


class lf_least_mean_square_fit_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    dev_scifi_hits_t = DataObjectHandleBase("dev_scifi_hits_t", "R", "char"),
    dev_scifi_hit_count_t = DataObjectHandleBase("dev_scifi_hit_count_t", "R", "uint"),
    dev_atomics_ut_t = DataObjectHandleBase("dev_atomics_ut_t", "R", "uint"),
    dev_scifi_tracks_t = DataObjectHandleBase("dev_scifi_tracks_t", "W", "SciFi::TrackHits"),
    dev_atomics_scifi_t = DataObjectHandleBase("dev_atomics_scifi_t", "R", "uint"),
    dev_scifi_lf_parametrization_x_filter_t = DataObjectHandleBase("dev_scifi_lf_parametrization_x_filter_t", "W", "float"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(lf_least_mean_square_fit_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "lf_least_mean_square_fit"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/SciFi/looking_forward/include/LFLeastMeanSquareFit.cuh"

  @classmethod
  def getType(cls):
    return "lf_least_mean_square_fit_t"


class lf_quality_filter_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_number_of_reconstructed_ut_tracks_t = DataObjectHandleBase("host_number_of_reconstructed_ut_tracks_t", "R", "uint"),
    dev_scifi_hits_t = DataObjectHandleBase("dev_scifi_hits_t", "R", "char"),
    dev_scifi_hit_offsets_t = DataObjectHandleBase("dev_scifi_hit_offsets_t", "R", "uint"),
    dev_offsets_ut_tracks_t = DataObjectHandleBase("dev_offsets_ut_tracks_t", "R", "uint"),
    dev_offsets_ut_track_hit_number_t = DataObjectHandleBase("dev_offsets_ut_track_hit_number_t", "R", "uint"),
    dev_scifi_lf_length_filtered_tracks_t = DataObjectHandleBase("dev_scifi_lf_length_filtered_tracks_t", "R", "SciFi::TrackHits"),
    dev_scifi_lf_length_filtered_atomics_t = DataObjectHandleBase("dev_scifi_lf_length_filtered_atomics_t", "R", "uint"),
    dev_lf_quality_of_tracks_t = DataObjectHandleBase("dev_lf_quality_of_tracks_t", "W", "float"),
    dev_atomics_scifi_t = DataObjectHandleBase("dev_atomics_scifi_t", "W", "uint"),
    dev_scifi_tracks_t = DataObjectHandleBase("dev_scifi_tracks_t", "W", "SciFi::TrackHits"),
    dev_scifi_lf_parametrization_length_filter_t = DataObjectHandleBase("dev_scifi_lf_parametrization_length_filter_t", "R", "float"),
    dev_scifi_lf_y_parametrization_length_filter_t = DataObjectHandleBase("dev_scifi_lf_y_parametrization_length_filter_t", "W", "float"),
    dev_scifi_lf_parametrization_consolidate_t = DataObjectHandleBase("dev_scifi_lf_parametrization_consolidate_t", "W", "float"),
    dev_ut_states_t = DataObjectHandleBase("dev_ut_states_t", "R", "MiniState"),
    dev_velo_states_t = DataObjectHandleBase("dev_velo_states_t", "R", "char"),
    dev_offsets_all_velo_tracks_t = DataObjectHandleBase("dev_offsets_all_velo_tracks_t", "R", "uint"),
    dev_offsets_velo_track_hit_number_t = DataObjectHandleBase("dev_offsets_velo_track_hit_number_t", "R", "uint"),
    dev_ut_track_velo_indices_t = DataObjectHandleBase("dev_ut_track_velo_indices_t", "R", "uint"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(lf_quality_filter_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "lf_quality_filter"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/SciFi/looking_forward/include/LFQualityFilter.cuh"

  @classmethod
  def getType(cls):
    return "lf_quality_filter_t"


class lf_quality_filter_length_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_number_of_reconstructed_ut_tracks_t = DataObjectHandleBase("host_number_of_reconstructed_ut_tracks_t", "R", "uint"),
    dev_offsets_ut_tracks_t = DataObjectHandleBase("dev_offsets_ut_tracks_t", "R", "uint"),
    dev_offsets_ut_track_hit_number_t = DataObjectHandleBase("dev_offsets_ut_track_hit_number_t", "R", "uint"),
    dev_scifi_lf_tracks_t = DataObjectHandleBase("dev_scifi_lf_tracks_t", "R", "SciFi::TrackHits"),
    dev_scifi_lf_atomics_t = DataObjectHandleBase("dev_scifi_lf_atomics_t", "R", "uint"),
    dev_scifi_lf_length_filtered_tracks_t = DataObjectHandleBase("dev_scifi_lf_length_filtered_tracks_t", "W", "SciFi::TrackHits"),
    dev_scifi_lf_length_filtered_atomics_t = DataObjectHandleBase("dev_scifi_lf_length_filtered_atomics_t", "W", "uint"),
    dev_scifi_lf_parametrization_t = DataObjectHandleBase("dev_scifi_lf_parametrization_t", "R", "float"),
    dev_scifi_lf_parametrization_length_filter_t = DataObjectHandleBase("dev_scifi_lf_parametrization_length_filter_t", "W", "float"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(lf_quality_filter_length_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "lf_quality_filter_length"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/SciFi/looking_forward/include/LFQualityFilterLength.cuh"

  @classmethod
  def getType(cls):
    return "lf_quality_filter_length_t"


class lf_quality_filter_x_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_number_of_reconstructed_ut_tracks_t = DataObjectHandleBase("host_number_of_reconstructed_ut_tracks_t", "R", "uint"),
    dev_atomics_ut_t = DataObjectHandleBase("dev_atomics_ut_t", "R", "uint"),
    dev_scifi_lf_tracks_t = DataObjectHandleBase("dev_scifi_lf_tracks_t", "R", "SciFi::TrackHits"),
    dev_scifi_lf_atomics_t = DataObjectHandleBase("dev_scifi_lf_atomics_t", "R", "uint"),
    dev_scifi_lf_x_filtered_tracks_t = DataObjectHandleBase("dev_scifi_lf_x_filtered_tracks_t", "W", "SciFi::TrackHits"),
    dev_scifi_lf_x_filtered_atomics_t = DataObjectHandleBase("dev_scifi_lf_x_filtered_atomics_t", "W", "uint"),
    dev_scifi_lf_parametrization_t = DataObjectHandleBase("dev_scifi_lf_parametrization_t", "R", "float"),
    dev_scifi_lf_parametrization_x_filter_t = DataObjectHandleBase("dev_scifi_lf_parametrization_x_filter_t", "W", "float"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(lf_quality_filter_x_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "lf_quality_filter_x"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/SciFi/looking_forward/include/LFQualityFilterX.cuh"

  @classmethod
  def getType(cls):
    return "lf_quality_filter_x_t"


class lf_search_initial_windows_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_number_of_reconstructed_ut_tracks_t = DataObjectHandleBase("host_number_of_reconstructed_ut_tracks_t", "R", "uint"),
    dev_scifi_hits_t = DataObjectHandleBase("dev_scifi_hits_t", "R", "char"),
    dev_scifi_hit_offsets_t = DataObjectHandleBase("dev_scifi_hit_offsets_t", "R", "uint"),
    dev_offsets_all_velo_tracks_t = DataObjectHandleBase("dev_offsets_all_velo_tracks_t", "R", "uint"),
    dev_offsets_velo_track_hit_number_t = DataObjectHandleBase("dev_offsets_velo_track_hit_number_t", "R", "uint"),
    dev_velo_states_t = DataObjectHandleBase("dev_velo_states_t", "R", "char"),
    dev_offsets_ut_tracks_t = DataObjectHandleBase("dev_offsets_ut_tracks_t", "R", "uint"),
    dev_offsets_ut_track_hit_number_t = DataObjectHandleBase("dev_offsets_ut_track_hit_number_t", "R", "uint"),
    dev_ut_x_t = DataObjectHandleBase("dev_ut_x_t", "R", "float"),
    dev_ut_tx_t = DataObjectHandleBase("dev_ut_tx_t", "R", "float"),
    dev_ut_z_t = DataObjectHandleBase("dev_ut_z_t", "R", "float"),
    dev_ut_qop_t = DataObjectHandleBase("dev_ut_qop_t", "R", "float"),
    dev_ut_track_velo_indices_t = DataObjectHandleBase("dev_ut_track_velo_indices_t", "R", "uint"),
    dev_scifi_lf_initial_windows_t = DataObjectHandleBase("dev_scifi_lf_initial_windows_t", "W", "int"),
    dev_ut_states_t = DataObjectHandleBase("dev_ut_states_t", "W", "MiniState"),
    dev_scifi_lf_process_track_t = DataObjectHandleBase("dev_scifi_lf_process_track_t", "W", "bool"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(lf_search_initial_windows_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "lf_search_initial_windows"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/SciFi/looking_forward/include/LFSearchInitialWindows.cuh"

  @classmethod
  def getType(cls):
    return "lf_search_initial_windows_t"


class lf_triplet_seeding_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_number_of_reconstructed_ut_tracks_t = DataObjectHandleBase("host_number_of_reconstructed_ut_tracks_t", "R", "uint"),
    dev_scifi_hits_t = DataObjectHandleBase("dev_scifi_hits_t", "R", "char"),
    dev_scifi_hit_offsets_t = DataObjectHandleBase("dev_scifi_hit_offsets_t", "R", "uint"),
    dev_offsets_all_velo_tracks_t = DataObjectHandleBase("dev_offsets_all_velo_tracks_t", "R", "uint"),
    dev_velo_states_t = DataObjectHandleBase("dev_velo_states_t", "R", "char"),
    dev_offsets_ut_tracks_t = DataObjectHandleBase("dev_offsets_ut_tracks_t", "R", "uint"),
    dev_offsets_ut_track_hit_number_t = DataObjectHandleBase("dev_offsets_ut_track_hit_number_t", "R", "uint"),
    dev_ut_track_velo_indices_t = DataObjectHandleBase("dev_ut_track_velo_indices_t", "R", "uint"),
    dev_ut_qop_t = DataObjectHandleBase("dev_ut_qop_t", "R", "float"),
    dev_scifi_lf_initial_windows_t = DataObjectHandleBase("dev_scifi_lf_initial_windows_t", "R", "int"),
    dev_ut_states_t = DataObjectHandleBase("dev_ut_states_t", "R", "MiniState"),
    dev_scifi_lf_process_track_t = DataObjectHandleBase("dev_scifi_lf_process_track_t", "R", "bool"),
    dev_scifi_lf_found_triplets_t = DataObjectHandleBase("dev_scifi_lf_found_triplets_t", "W", "int"),
    dev_scifi_lf_number_of_found_triplets_t = DataObjectHandleBase("dev_scifi_lf_number_of_found_triplets_t", "W", "int8_t")
  )

  def __init__(self, name, **kwargs):
    super(lf_triplet_seeding_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "lf_triplet_seeding"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/SciFi/looking_forward/include/LFTripletSeeding.cuh"

  @classmethod
  def getType(cls):
    return "lf_triplet_seeding_t"


class scifi_calculate_cluster_count_v4_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    dev_event_list_t = DataObjectHandleBase("dev_event_list_t", "R", "uint"),
    dev_scifi_raw_input_t = DataObjectHandleBase("dev_scifi_raw_input_t", "R", "char"),
    dev_scifi_raw_input_offsets_t = DataObjectHandleBase("dev_scifi_raw_input_offsets_t", "R", "uint"),
    dev_scifi_hit_count_t = DataObjectHandleBase("dev_scifi_hit_count_t", "W", "uint"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(scifi_calculate_cluster_count_v4_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "scifi_calculate_cluster_count_v4"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/SciFi/preprocessing/include/SciFiCalculateClusterCountV4.cuh"

  @classmethod
  def getType(cls):
    return "scifi_calculate_cluster_count_v4_t"


class scifi_calculate_cluster_count_v6_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    dev_event_list_t = DataObjectHandleBase("dev_event_list_t", "R", "uint"),
    dev_scifi_raw_input_t = DataObjectHandleBase("dev_scifi_raw_input_t", "R", "char"),
    dev_scifi_raw_input_offsets_t = DataObjectHandleBase("dev_scifi_raw_input_offsets_t", "R", "uint"),
    dev_scifi_hit_count_t = DataObjectHandleBase("dev_scifi_hit_count_t", "W", "uint")
  )

  def __init__(self, name, **kwargs):
    super(scifi_calculate_cluster_count_v6_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "scifi_calculate_cluster_count_v6"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/SciFi/preprocessing/include/SciFiCalculateClusterCountV6.cuh"

  @classmethod
  def getType(cls):
    return "scifi_calculate_cluster_count_v6_t"


class scifi_pre_decode_v4_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_accumulated_number_of_scifi_hits_t = DataObjectHandleBase("host_accumulated_number_of_scifi_hits_t", "R", "uint"),
    dev_scifi_raw_input_t = DataObjectHandleBase("dev_scifi_raw_input_t", "R", "char"),
    dev_scifi_raw_input_offsets_t = DataObjectHandleBase("dev_scifi_raw_input_offsets_t", "R", "uint"),
    dev_event_list_t = DataObjectHandleBase("dev_event_list_t", "R", "uint"),
    dev_scifi_hit_offsets_t = DataObjectHandleBase("dev_scifi_hit_offsets_t", "R", "uint"),
    dev_cluster_references_t = DataObjectHandleBase("dev_cluster_references_t", "W", "uint")
  )

  def __init__(self, name, **kwargs):
    super(scifi_pre_decode_v4_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "scifi_pre_decode_v4"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/SciFi/preprocessing/include/SciFiPreDecodeV4.cuh"

  @classmethod
  def getType(cls):
    return "scifi_pre_decode_v4_t"


class scifi_pre_decode_v6_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_accumulated_number_of_scifi_hits_t = DataObjectHandleBase("host_accumulated_number_of_scifi_hits_t", "R", "uint"),
    dev_scifi_raw_input_t = DataObjectHandleBase("dev_scifi_raw_input_t", "R", "char"),
    dev_scifi_raw_input_offsets_t = DataObjectHandleBase("dev_scifi_raw_input_offsets_t", "R", "uint"),
    dev_event_list_t = DataObjectHandleBase("dev_event_list_t", "R", "uint"),
    dev_scifi_hit_offsets_t = DataObjectHandleBase("dev_scifi_hit_offsets_t", "R", "uint"),
    dev_cluster_references_t = DataObjectHandleBase("dev_cluster_references_t", "W", "uint")
  )

  def __init__(self, name, **kwargs):
    super(scifi_pre_decode_v6_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "scifi_pre_decode_v6"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/SciFi/preprocessing/include/SciFiPreDecodeV6.cuh"

  @classmethod
  def getType(cls):
    return "scifi_pre_decode_v6_t"


class scifi_raw_bank_decoder_v4_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_accumulated_number_of_scifi_hits_t = DataObjectHandleBase("host_accumulated_number_of_scifi_hits_t", "R", "uint"),
    dev_scifi_raw_input_t = DataObjectHandleBase("dev_scifi_raw_input_t", "R", "char"),
    dev_scifi_raw_input_offsets_t = DataObjectHandleBase("dev_scifi_raw_input_offsets_t", "R", "uint"),
    dev_scifi_hit_offsets_t = DataObjectHandleBase("dev_scifi_hit_offsets_t", "R", "uint"),
    dev_cluster_references_t = DataObjectHandleBase("dev_cluster_references_t", "R", "uint"),
    dev_scifi_hits_t = DataObjectHandleBase("dev_scifi_hits_t", "W", "char"),
    dev_event_list_t = DataObjectHandleBase("dev_event_list_t", "R", "uint"),
    raw_bank_decoder_block_dim = "",
    direct_decoder_block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(scifi_raw_bank_decoder_v4_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "scifi_raw_bank_decoder_v4"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/SciFi/preprocessing/include/SciFiRawBankDecoderV4.cuh"

  @classmethod
  def getType(cls):
    return "scifi_raw_bank_decoder_v4_t"


class scifi_raw_bank_decoder_v6_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_accumulated_number_of_scifi_hits_t = DataObjectHandleBase("host_accumulated_number_of_scifi_hits_t", "R", "uint"),
    dev_scifi_raw_input_t = DataObjectHandleBase("dev_scifi_raw_input_t", "R", "char"),
    dev_scifi_raw_input_offsets_t = DataObjectHandleBase("dev_scifi_raw_input_offsets_t", "R", "uint"),
    dev_scifi_hit_offsets_t = DataObjectHandleBase("dev_scifi_hit_offsets_t", "R", "uint"),
    dev_cluster_references_t = DataObjectHandleBase("dev_cluster_references_t", "R", "uint"),
    dev_scifi_hits_t = DataObjectHandleBase("dev_scifi_hits_t", "W", "char"),
    dev_event_list_t = DataObjectHandleBase("dev_event_list_t", "R", "uint"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(scifi_raw_bank_decoder_v6_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "scifi_raw_bank_decoder_v6"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/SciFi/preprocessing/include/SciFiRawBankDecoderV6.cuh"

  @classmethod
  def getType(cls):
    return "scifi_raw_bank_decoder_v6_t"


class ut_calculate_number_of_hits_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    dev_event_list_t = DataObjectHandleBase("dev_event_list_t", "R", "uint"),
    dev_ut_raw_input_t = DataObjectHandleBase("dev_ut_raw_input_t", "R", "char"),
    dev_ut_raw_input_offsets_t = DataObjectHandleBase("dev_ut_raw_input_offsets_t", "R", "uint"),
    dev_ut_hit_sizes_t = DataObjectHandleBase("dev_ut_hit_sizes_t", "W", "uint"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(ut_calculate_number_of_hits_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "ut_calculate_number_of_hits"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/UT/UTDecoding/include/UTCalculateNumberOfHits.cuh"

  @classmethod
  def getType(cls):
    return "ut_calculate_number_of_hits_t"


class ut_decode_raw_banks_in_order_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_accumulated_number_of_ut_hits_t = DataObjectHandleBase("host_accumulated_number_of_ut_hits_t", "R", "uint"),
    dev_ut_raw_input_t = DataObjectHandleBase("dev_ut_raw_input_t", "R", "char"),
    dev_ut_raw_input_offsets_t = DataObjectHandleBase("dev_ut_raw_input_offsets_t", "R", "uint"),
    dev_event_list_t = DataObjectHandleBase("dev_event_list_t", "R", "uint"),
    dev_ut_hit_offsets_t = DataObjectHandleBase("dev_ut_hit_offsets_t", "R", "uint"),
    dev_ut_pre_decoded_hits_t = DataObjectHandleBase("dev_ut_pre_decoded_hits_t", "R", "char"),
    dev_ut_hits_t = DataObjectHandleBase("dev_ut_hits_t", "W", "char"),
    dev_ut_hit_permutations_t = DataObjectHandleBase("dev_ut_hit_permutations_t", "R", "uint"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(ut_decode_raw_banks_in_order_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "ut_decode_raw_banks_in_order"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/UT/UTDecoding/include/UTDecodeRawBanksInOrder.cuh"

  @classmethod
  def getType(cls):
    return "ut_decode_raw_banks_in_order_t"


class ut_find_permutation_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_accumulated_number_of_ut_hits_t = DataObjectHandleBase("host_accumulated_number_of_ut_hits_t", "R", "uint"),
    dev_ut_pre_decoded_hits_t = DataObjectHandleBase("dev_ut_pre_decoded_hits_t", "R", "char"),
    dev_ut_hit_offsets_t = DataObjectHandleBase("dev_ut_hit_offsets_t", "R", "uint"),
    dev_ut_hit_permutations_t = DataObjectHandleBase("dev_ut_hit_permutations_t", "W", "uint"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(ut_find_permutation_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "ut_find_permutation"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/UT/UTDecoding/include/UTFindPermutation.cuh"

  @classmethod
  def getType(cls):
    return "ut_find_permutation_t"


class ut_pre_decode_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_accumulated_number_of_ut_hits_t = DataObjectHandleBase("host_accumulated_number_of_ut_hits_t", "R", "uint"),
    dev_ut_raw_input_t = DataObjectHandleBase("dev_ut_raw_input_t", "R", "char"),
    dev_ut_raw_input_offsets_t = DataObjectHandleBase("dev_ut_raw_input_offsets_t", "R", "uint"),
    dev_event_list_t = DataObjectHandleBase("dev_event_list_t", "R", "uint"),
    dev_ut_hit_offsets_t = DataObjectHandleBase("dev_ut_hit_offsets_t", "R", "uint"),
    dev_ut_pre_decoded_hits_t = DataObjectHandleBase("dev_ut_pre_decoded_hits_t", "W", "char"),
    dev_ut_hit_count_t = DataObjectHandleBase("dev_ut_hit_count_t", "W", "uint"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(ut_pre_decode_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "ut_pre_decode"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/UT/UTDecoding/include/UTPreDecode.cuh"

  @classmethod
  def getType(cls):
    return "ut_pre_decode_t"


class compass_ut_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    dev_ut_hits_t = DataObjectHandleBase("dev_ut_hits_t", "R", "char"),
    dev_ut_hit_offsets_t = DataObjectHandleBase("dev_ut_hit_offsets_t", "R", "uint"),
    dev_offsets_all_velo_tracks_t = DataObjectHandleBase("dev_offsets_all_velo_tracks_t", "R", "uint"),
    dev_offsets_velo_track_hit_number_t = DataObjectHandleBase("dev_offsets_velo_track_hit_number_t", "R", "uint"),
    dev_velo_states_t = DataObjectHandleBase("dev_velo_states_t", "R", "char"),
    dev_ut_tracks_t = DataObjectHandleBase("dev_ut_tracks_t", "W", "UT::TrackHits"),
    dev_atomics_ut_t = DataObjectHandleBase("dev_atomics_ut_t", "W", "uint"),
    dev_ut_windows_layers_t = DataObjectHandleBase("dev_ut_windows_layers_t", "R", "short"),
    dev_ut_number_of_selected_velo_tracks_with_windows_t = DataObjectHandleBase("dev_ut_number_of_selected_velo_tracks_with_windows_t", "R", "uint"),
    dev_ut_selected_velo_tracks_with_windows_t = DataObjectHandleBase("dev_ut_selected_velo_tracks_with_windows_t", "R", "uint"),
    sigma_velo_slope = "",
    min_momentum_final = "",
    min_pt_final = "",
    hit_tol_2 = "",
    delta_tx_2 = "",
    max_considered_before_found = ""
  )

  def __init__(self, name, **kwargs):
    super(compass_ut_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "compass_ut"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/UT/compassUT/include/CompassUT.cuh"

  @classmethod
  def getType(cls):
    return "compass_ut_t"


class ut_search_windows_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_number_of_reconstructed_velo_tracks_t = DataObjectHandleBase("host_number_of_reconstructed_velo_tracks_t", "R", "uint"),
    dev_ut_hits_t = DataObjectHandleBase("dev_ut_hits_t", "R", "char"),
    dev_ut_hit_offsets_t = DataObjectHandleBase("dev_ut_hit_offsets_t", "R", "uint"),
    dev_offsets_all_velo_tracks_t = DataObjectHandleBase("dev_offsets_all_velo_tracks_t", "R", "uint"),
    dev_offsets_velo_track_hit_number_t = DataObjectHandleBase("dev_offsets_velo_track_hit_number_t", "R", "uint"),
    dev_velo_states_t = DataObjectHandleBase("dev_velo_states_t", "R", "char"),
    dev_ut_number_of_selected_velo_tracks_t = DataObjectHandleBase("dev_ut_number_of_selected_velo_tracks_t", "R", "uint"),
    dev_ut_selected_velo_tracks_t = DataObjectHandleBase("dev_ut_selected_velo_tracks_t", "R", "uint"),
    dev_ut_windows_layers_t = DataObjectHandleBase("dev_ut_windows_layers_t", "W", "short"),
    min_momentum = "",
    min_pt = "",
    y_tol = "",
    y_tol_slope = "",
    block_dim_y_t = ""
  )

  def __init__(self, name, **kwargs):
    super(ut_search_windows_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "ut_search_windows"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/UT/compassUT/include/SearchWindows.cuh"

  @classmethod
  def getType(cls):
    return "ut_search_windows_t"


class ut_select_velo_tracks_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_number_of_reconstructed_velo_tracks_t = DataObjectHandleBase("host_number_of_reconstructed_velo_tracks_t", "R", "uint"),
    dev_offsets_all_velo_tracks_t = DataObjectHandleBase("dev_offsets_all_velo_tracks_t", "R", "uint"),
    dev_offsets_velo_track_hit_number_t = DataObjectHandleBase("dev_offsets_velo_track_hit_number_t", "R", "uint"),
    dev_velo_states_t = DataObjectHandleBase("dev_velo_states_t", "R", "char"),
    dev_accepted_velo_tracks_t = DataObjectHandleBase("dev_accepted_velo_tracks_t", "R", "bool"),
    dev_ut_number_of_selected_velo_tracks_t = DataObjectHandleBase("dev_ut_number_of_selected_velo_tracks_t", "W", "uint"),
    dev_ut_selected_velo_tracks_t = DataObjectHandleBase("dev_ut_selected_velo_tracks_t", "W", "uint"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(ut_select_velo_tracks_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "ut_select_velo_tracks"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/UT/compassUT/include/UTSelectVeloTracks.cuh"

  @classmethod
  def getType(cls):
    return "ut_select_velo_tracks_t"


class ut_select_velo_tracks_with_windows_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_number_of_reconstructed_velo_tracks_t = DataObjectHandleBase("host_number_of_reconstructed_velo_tracks_t", "R", "uint"),
    dev_offsets_all_velo_tracks_t = DataObjectHandleBase("dev_offsets_all_velo_tracks_t", "R", "uint"),
    dev_offsets_velo_track_hit_number_t = DataObjectHandleBase("dev_offsets_velo_track_hit_number_t", "R", "uint"),
    dev_velo_states_t = DataObjectHandleBase("dev_velo_states_t", "R", "char"),
    dev_accepted_velo_tracks_t = DataObjectHandleBase("dev_accepted_velo_tracks_t", "R", "bool"),
    dev_ut_number_of_selected_velo_tracks_t = DataObjectHandleBase("dev_ut_number_of_selected_velo_tracks_t", "R", "uint"),
    dev_ut_selected_velo_tracks_t = DataObjectHandleBase("dev_ut_selected_velo_tracks_t", "R", "uint"),
    dev_ut_windows_layers_t = DataObjectHandleBase("dev_ut_windows_layers_t", "R", "short"),
    dev_ut_number_of_selected_velo_tracks_with_windows_t = DataObjectHandleBase("dev_ut_number_of_selected_velo_tracks_with_windows_t", "W", "uint"),
    dev_ut_selected_velo_tracks_with_windows_t = DataObjectHandleBase("dev_ut_selected_velo_tracks_with_windows_t", "W", "uint"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(ut_select_velo_tracks_with_windows_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "ut_select_velo_tracks_with_windows"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/UT/compassUT/include/UTSelectVeloTracksWithWindows.cuh"

  @classmethod
  def getType(cls):
    return "ut_select_velo_tracks_with_windows_t"


class ut_consolidate_tracks_t(AllenAlgorithm):
  __slots__ = dict(
    host_accumulated_number_of_ut_hits_t = DataObjectHandleBase("host_accumulated_number_of_ut_hits_t", "R", "uint"),
    host_number_of_reconstructed_ut_tracks_t = DataObjectHandleBase("host_number_of_reconstructed_ut_tracks_t", "R", "uint"),
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_accumulated_number_of_hits_in_ut_tracks_t = DataObjectHandleBase("host_accumulated_number_of_hits_in_ut_tracks_t", "R", "uint"),
    dev_ut_hits_t = DataObjectHandleBase("dev_ut_hits_t", "R", "char"),
    dev_ut_hit_offsets_t = DataObjectHandleBase("dev_ut_hit_offsets_t", "R", "uint"),
    dev_ut_track_hits_t = DataObjectHandleBase("dev_ut_track_hits_t", "W", "char"),
    dev_offsets_ut_tracks_t = DataObjectHandleBase("dev_offsets_ut_tracks_t", "R", "uint"),
    dev_offsets_ut_track_hit_number_t = DataObjectHandleBase("dev_offsets_ut_track_hit_number_t", "R", "uint"),
    dev_ut_qop_t = DataObjectHandleBase("dev_ut_qop_t", "W", "float"),
    dev_ut_x_t = DataObjectHandleBase("dev_ut_x_t", "W", "float"),
    dev_ut_tx_t = DataObjectHandleBase("dev_ut_tx_t", "W", "float"),
    dev_ut_z_t = DataObjectHandleBase("dev_ut_z_t", "W", "float"),
    dev_ut_track_velo_indices_t = DataObjectHandleBase("dev_ut_track_velo_indices_t", "W", "uint"),
    dev_ut_tracks_t = DataObjectHandleBase("dev_ut_tracks_t", "R", "UT::TrackHits"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(ut_consolidate_tracks_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "ut_consolidate_tracks"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/UT/consolidate/include/ConsolidateUT.cuh"

  @classmethod
  def getType(cls):
    return "ut_consolidate_tracks_t"


class ut_copy_track_hit_number_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_number_of_reconstructed_ut_tracks_t = DataObjectHandleBase("host_number_of_reconstructed_ut_tracks_t", "R", "uint"),
    dev_ut_tracks_t = DataObjectHandleBase("dev_ut_tracks_t", "R", "UT::TrackHits"),
    dev_offsets_ut_tracks_t = DataObjectHandleBase("dev_offsets_ut_tracks_t", "R", "uint"),
    dev_ut_track_hit_number_t = DataObjectHandleBase("dev_ut_track_hit_number_t", "W", "uint"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(ut_copy_track_hit_number_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "ut_copy_track_hit_number"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/UT/consolidate/include/UTCopyTrackHitNumber.cuh"

  @classmethod
  def getType(cls):
    return "ut_copy_track_hit_number_t"


class velo_pv_ip_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_reconstructed_velo_tracks_t = DataObjectHandleBase("host_number_of_reconstructed_velo_tracks_t", "R", "uint"),
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    dev_velo_kalman_beamline_states_t = DataObjectHandleBase("dev_velo_kalman_beamline_states_t", "R", "char"),
    dev_offsets_all_velo_tracks_t = DataObjectHandleBase("dev_offsets_all_velo_tracks_t", "R", "uint"),
    dev_offsets_velo_track_hit_number_t = DataObjectHandleBase("dev_offsets_velo_track_hit_number_t", "R", "uint"),
    dev_multi_fit_vertices_t = DataObjectHandleBase("dev_multi_fit_vertices_t", "R", "PV::Vertex"),
    dev_number_of_multi_fit_vertices_t = DataObjectHandleBase("dev_number_of_multi_fit_vertices_t", "R", "uint"),
    dev_velo_pv_ip_t = DataObjectHandleBase("dev_velo_pv_ip_t", "W", "char"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(velo_pv_ip_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "velo_pv_ip"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/associate/include/VeloPVIP.cuh"

  @classmethod
  def getType(cls):
    return "velo_pv_ip_t"


class saxpy_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    dev_offsets_all_velo_tracks_t = DataObjectHandleBase("dev_offsets_all_velo_tracks_t", "R", "uint"),
    dev_offsets_velo_track_hit_number_t = DataObjectHandleBase("dev_offsets_velo_track_hit_number_t", "R", "uint"),
    dev_saxpy_output_t = DataObjectHandleBase("dev_saxpy_output_t", "W", "float"),
    saxpy_scale_factor = "",
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(saxpy_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "saxpy"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/example/include/SAXPY_example.cuh"

  @classmethod
  def getType(cls):
    return "saxpy_t"


class kalman_filter_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_number_of_reconstructed_scifi_tracks_t = DataObjectHandleBase("host_number_of_reconstructed_scifi_tracks_t", "R", "uint"),
    dev_atomics_velo_t = DataObjectHandleBase("dev_atomics_velo_t", "R", "uint"),
    dev_velo_track_hit_number_t = DataObjectHandleBase("dev_velo_track_hit_number_t", "R", "uint"),
    dev_velo_track_hits_t = DataObjectHandleBase("dev_velo_track_hits_t", "R", "char"),
    dev_atomics_ut_t = DataObjectHandleBase("dev_atomics_ut_t", "R", "uint"),
    dev_ut_track_hit_number_t = DataObjectHandleBase("dev_ut_track_hit_number_t", "R", "uint"),
    dev_ut_track_hits_t = DataObjectHandleBase("dev_ut_track_hits_t", "R", "char"),
    dev_ut_qop_t = DataObjectHandleBase("dev_ut_qop_t", "R", "float"),
    dev_ut_track_velo_indices_t = DataObjectHandleBase("dev_ut_track_velo_indices_t", "R", "uint"),
    dev_atomics_scifi_t = DataObjectHandleBase("dev_atomics_scifi_t", "R", "uint"),
    dev_scifi_track_hit_number_t = DataObjectHandleBase("dev_scifi_track_hit_number_t", "R", "uint"),
    dev_scifi_track_hits_t = DataObjectHandleBase("dev_scifi_track_hits_t", "R", "char"),
    dev_scifi_qop_t = DataObjectHandleBase("dev_scifi_qop_t", "R", "float"),
    dev_scifi_states_t = DataObjectHandleBase("dev_scifi_states_t", "R", "MiniState"),
    dev_scifi_track_ut_indices_t = DataObjectHandleBase("dev_scifi_track_ut_indices_t", "R", "uint"),
    dev_kf_tracks_t = DataObjectHandleBase("dev_kf_tracks_t", "W", "ParKalmanFilter::FittedTrack"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(kalman_filter_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "kalman_filter"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/kalman/ParKalman/include/ParKalmanFilter.cuh"

  @classmethod
  def getType(cls):
    return "kalman_filter_t"


class kalman_velo_only_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_number_of_reconstructed_scifi_tracks_t = DataObjectHandleBase("host_number_of_reconstructed_scifi_tracks_t", "R", "uint"),
    dev_offsets_all_velo_tracks_t = DataObjectHandleBase("dev_offsets_all_velo_tracks_t", "R", "uint"),
    dev_offsets_velo_track_hit_number_t = DataObjectHandleBase("dev_offsets_velo_track_hit_number_t", "R", "uint"),
    dev_velo_track_hits_t = DataObjectHandleBase("dev_velo_track_hits_t", "R", "char"),
    dev_offsets_ut_tracks_t = DataObjectHandleBase("dev_offsets_ut_tracks_t", "R", "uint"),
    dev_offsets_ut_track_hit_number_t = DataObjectHandleBase("dev_offsets_ut_track_hit_number_t", "R", "uint"),
    dev_ut_qop_t = DataObjectHandleBase("dev_ut_qop_t", "R", "float"),
    dev_ut_track_velo_indices_t = DataObjectHandleBase("dev_ut_track_velo_indices_t", "R", "uint"),
    dev_offsets_forward_tracks_t = DataObjectHandleBase("dev_offsets_forward_tracks_t", "R", "uint"),
    dev_offsets_scifi_track_hit_number = DataObjectHandleBase("dev_offsets_scifi_track_hit_number", "R", "uint"),
    dev_scifi_qop_t = DataObjectHandleBase("dev_scifi_qop_t", "R", "float"),
    dev_scifi_states_t = DataObjectHandleBase("dev_scifi_states_t", "R", "MiniState"),
    dev_scifi_track_ut_indices_t = DataObjectHandleBase("dev_scifi_track_ut_indices_t", "R", "uint"),
    dev_velo_pv_ip_t = DataObjectHandleBase("dev_velo_pv_ip_t", "R", "char"),
    dev_kf_tracks_t = DataObjectHandleBase("dev_kf_tracks_t", "W", "ParKalmanFilter::FittedTrack"),
    dev_multi_fit_vertices_t = DataObjectHandleBase("dev_multi_fit_vertices_t", "R", "PV::Vertex"),
    dev_number_of_multi_fit_vertices_t = DataObjectHandleBase("dev_number_of_multi_fit_vertices_t", "R", "uint"),
    dev_kalman_pv_ipchi2_t = DataObjectHandleBase("dev_kalman_pv_ipchi2_t", "W", "char"),
    dev_is_muon_t = DataObjectHandleBase("dev_is_muon_t", "R", "bool"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(kalman_velo_only_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "kalman_velo_only"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/kalman/ParKalman/include/ParKalmanVeloOnly.cuh"

  @classmethod
  def getType(cls):
    return "kalman_velo_only_t"


class package_kalman_tracks_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_number_of_reconstructed_scifi_tracks_t = DataObjectHandleBase("host_number_of_reconstructed_scifi_tracks_t", "R", "uint"),
    dev_atomics_velo_t = DataObjectHandleBase("dev_atomics_velo_t", "R", "uint"),
    dev_velo_track_hit_number_t = DataObjectHandleBase("dev_velo_track_hit_number_t", "R", "uint"),
    dev_atomics_ut_t = DataObjectHandleBase("dev_atomics_ut_t", "R", "uint"),
    dev_ut_track_hit_number_t = DataObjectHandleBase("dev_ut_track_hit_number_t", "R", "uint"),
    dev_ut_qop_t = DataObjectHandleBase("dev_ut_qop_t", "R", "float"),
    dev_ut_track_velo_indices_t = DataObjectHandleBase("dev_ut_track_velo_indices_t", "R", "uint"),
    dev_atomics_scifi_t = DataObjectHandleBase("dev_atomics_scifi_t", "R", "uint"),
    dev_scifi_track_hit_number_t = DataObjectHandleBase("dev_scifi_track_hit_number_t", "R", "uint"),
    dev_scifi_qop_t = DataObjectHandleBase("dev_scifi_qop_t", "R", "float"),
    dev_scifi_states_t = DataObjectHandleBase("dev_scifi_states_t", "R", "MiniState"),
    dev_scifi_track_ut_indices_t = DataObjectHandleBase("dev_scifi_track_ut_indices_t", "R", "uint"),
    dev_velo_kalman_beamline_states_t = DataObjectHandleBase("dev_velo_kalman_beamline_states_t", "R", "char"),
    dev_is_muon_t = DataObjectHandleBase("dev_is_muon_t", "R", "bool"),
    dev_kf_tracks_t = DataObjectHandleBase("dev_kf_tracks_t", "W", "ParKalmanFilter::FittedTrack"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(package_kalman_tracks_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "package_kalman_tracks"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/kalman/ParKalman/include/PackageKalman.cuh"

  @classmethod
  def getType(cls):
    return "package_kalman_tracks_t"


class package_mf_tracks_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_number_of_mf_tracks_t = DataObjectHandleBase("host_number_of_mf_tracks_t", "R", "uint"),
    host_selected_events_mf_t = DataObjectHandleBase("host_selected_events_mf_t", "W", "uint"),
    dev_offsets_all_velo_tracks_t = DataObjectHandleBase("dev_offsets_all_velo_tracks_t", "R", "uint"),
    dev_offsets_velo_track_hit_number_t = DataObjectHandleBase("dev_offsets_velo_track_hit_number_t", "R", "uint"),
    dev_offsets_ut_tracks_t = DataObjectHandleBase("dev_offsets_ut_tracks_t", "R", "uint"),
    dev_offsets_ut_track_hit_number_t = DataObjectHandleBase("dev_offsets_ut_track_hit_number_t", "R", "uint"),
    dev_ut_qop_t = DataObjectHandleBase("dev_ut_qop_t", "R", "float"),
    dev_ut_track_velo_indices_t = DataObjectHandleBase("dev_ut_track_velo_indices_t", "R", "uint"),
    dev_velo_kalman_beamline_states_t = DataObjectHandleBase("dev_velo_kalman_beamline_states_t", "R", "char"),
    dev_match_upstream_muon_t = DataObjectHandleBase("dev_match_upstream_muon_t", "R", "bool"),
    dev_event_list_mf_t = DataObjectHandleBase("dev_event_list_mf_t", "R", "uint"),
    dev_mf_track_offsets_t = DataObjectHandleBase("dev_mf_track_offsets_t", "R", "uint"),
    dev_mf_tracks_t = DataObjectHandleBase("dev_mf_tracks_t", "W", "ParKalmanFilter::FittedTrack"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(package_mf_tracks_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "package_mf_tracks"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/kalman/ParKalman/include/PackageMFTracks.cuh"

  @classmethod
  def getType(cls):
    return "package_mf_tracks_t"


class muon_catboost_evaluator_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_reconstructed_scifi_tracks_t = DataObjectHandleBase("host_number_of_reconstructed_scifi_tracks_t", "R", "uint"),
    dev_muon_catboost_features_t = DataObjectHandleBase("dev_muon_catboost_features_t", "R", "float"),
    dev_muon_catboost_output_t = DataObjectHandleBase("dev_muon_catboost_output_t", "W", "float"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(muon_catboost_evaluator_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "muon_catboost_evaluator"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/muon/classification/include/MuonCatboostEvaluator.cuh"

  @classmethod
  def getType(cls):
    return "muon_catboost_evaluator_t"


class muon_populate_tile_and_tdc_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_muon_total_number_of_tiles_t = DataObjectHandleBase("host_muon_total_number_of_tiles_t", "R", "uint"),
    dev_event_list_t = DataObjectHandleBase("dev_event_list_t", "R", "uint"),
    dev_muon_raw_t = DataObjectHandleBase("dev_muon_raw_t", "R", "char"),
    dev_muon_raw_offsets_t = DataObjectHandleBase("dev_muon_raw_offsets_t", "R", "uint"),
    dev_muon_raw_to_hits_t = DataObjectHandleBase("dev_muon_raw_to_hits_t", "R", "Muon::MuonRawToHits"),
    dev_storage_station_region_quarter_offsets_t = DataObjectHandleBase("dev_storage_station_region_quarter_offsets_t", "R", "uint"),
    dev_storage_tile_id_t = DataObjectHandleBase("dev_storage_tile_id_t", "W", "uint"),
    dev_storage_tdc_value_t = DataObjectHandleBase("dev_storage_tdc_value_t", "W", "uint"),
    dev_atomics_muon_t = DataObjectHandleBase("dev_atomics_muon_t", "W", "uint")
  )

  def __init__(self, name, **kwargs):
    super(muon_populate_tile_and_tdc_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "muon_populate_tile_and_tdc"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/muon/decoding/include/MuonPopulateTileAndTDC.cuh"

  @classmethod
  def getType(cls):
    return "muon_populate_tile_and_tdc_t"


class muon_populate_hits_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_muon_total_number_of_hits_t = DataObjectHandleBase("host_muon_total_number_of_hits_t", "R", "uint"),
    dev_storage_tile_id_t = DataObjectHandleBase("dev_storage_tile_id_t", "R", "uint"),
    dev_storage_tdc_value_t = DataObjectHandleBase("dev_storage_tdc_value_t", "R", "uint"),
    dev_permutation_station_t = DataObjectHandleBase("dev_permutation_station_t", "W", "uint"),
    dev_muon_hits_t = DataObjectHandleBase("dev_muon_hits_t", "W", "char"),
    dev_station_ocurrences_offset_t = DataObjectHandleBase("dev_station_ocurrences_offset_t", "R", "uint"),
    dev_muon_compact_hit_t = DataObjectHandleBase("dev_muon_compact_hit_t", "R", "uint64_t"),
    dev_muon_raw_to_hits_t = DataObjectHandleBase("dev_muon_raw_to_hits_t", "R", "Muon::MuonRawToHits"),
    dev_storage_station_region_quarter_offsets_t = DataObjectHandleBase("dev_storage_station_region_quarter_offsets_t", "R", "uint"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(muon_populate_hits_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "muon_populate_hits"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/muon/decoding/include/MuonPopulateHits.cuh"

  @classmethod
  def getType(cls):
    return "muon_populate_hits_t"


class muon_calculate_srq_size_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    dev_event_list_t = DataObjectHandleBase("dev_event_list_t", "R", "uint"),
    dev_muon_raw_t = DataObjectHandleBase("dev_muon_raw_t", "R", "char"),
    dev_muon_raw_offsets_t = DataObjectHandleBase("dev_muon_raw_offsets_t", "R", "uint"),
    dev_muon_raw_to_hits_t = DataObjectHandleBase("dev_muon_raw_to_hits_t", "W", "Muon::MuonRawToHits"),
    dev_storage_station_region_quarter_sizes_t = DataObjectHandleBase("dev_storage_station_region_quarter_sizes_t", "W", "uint")
  )

  def __init__(self, name, **kwargs):
    super(muon_calculate_srq_size_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "muon_calculate_srq_size"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/muon/decoding/include/MuonCalculateSRQSize.cuh"

  @classmethod
  def getType(cls):
    return "muon_calculate_srq_size_t"


class muon_add_coords_crossing_maps_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_muon_total_number_of_tiles_t = DataObjectHandleBase("host_muon_total_number_of_tiles_t", "R", "uint"),
    dev_storage_station_region_quarter_offsets_t = DataObjectHandleBase("dev_storage_station_region_quarter_offsets_t", "R", "uint"),
    dev_storage_tile_id_t = DataObjectHandleBase("dev_storage_tile_id_t", "R", "uint"),
    dev_muon_raw_to_hits_t = DataObjectHandleBase("dev_muon_raw_to_hits_t", "R", "Muon::MuonRawToHits"),
    dev_atomics_index_insert_t = DataObjectHandleBase("dev_atomics_index_insert_t", "W", "uint"),
    dev_muon_compact_hit_t = DataObjectHandleBase("dev_muon_compact_hit_t", "W", "uint64_t"),
    dev_muon_tile_used_t = DataObjectHandleBase("dev_muon_tile_used_t", "W", "bool"),
    dev_station_ocurrences_sizes_t = DataObjectHandleBase("dev_station_ocurrences_sizes_t", "W", "uint"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(muon_add_coords_crossing_maps_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "muon_add_coords_crossing_maps"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/muon/decoding/include/MuonAddCoordsCrossingMaps.cuh"

  @classmethod
  def getType(cls):
    return "muon_add_coords_crossing_maps_t"


class is_muon_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_number_of_reconstructed_scifi_tracks_t = DataObjectHandleBase("host_number_of_reconstructed_scifi_tracks_t", "R", "uint"),
    dev_offsets_forward_tracks_t = DataObjectHandleBase("dev_offsets_forward_tracks_t", "R", "uint"),
    dev_offsets_scifi_track_hit_number = DataObjectHandleBase("dev_offsets_scifi_track_hit_number", "R", "uint"),
    dev_scifi_qop_t = DataObjectHandleBase("dev_scifi_qop_t", "R", "float"),
    dev_scifi_states_t = DataObjectHandleBase("dev_scifi_states_t", "R", "MiniState"),
    dev_scifi_track_ut_indices_t = DataObjectHandleBase("dev_scifi_track_ut_indices_t", "R", "uint"),
    dev_station_ocurrences_offset_t = DataObjectHandleBase("dev_station_ocurrences_offset_t", "R", "uint"),
    dev_muon_hits_t = DataObjectHandleBase("dev_muon_hits_t", "R", "char"),
    dev_muon_track_occupancies_t = DataObjectHandleBase("dev_muon_track_occupancies_t", "W", "int"),
    dev_is_muon_t = DataObjectHandleBase("dev_is_muon_t", "W", "bool")
  )

  def __init__(self, name, **kwargs):
    super(is_muon_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "is_muon"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/muon/is_muon/include/IsMuon.cuh"

  @classmethod
  def getType(cls):
    return "is_muon_t"


class muon_catboost_features_extraction_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_number_of_reconstructed_scifi_tracks_t = DataObjectHandleBase("host_number_of_reconstructed_scifi_tracks_t", "R", "uint"),
    dev_atomics_scifi_t = DataObjectHandleBase("dev_atomics_scifi_t", "R", "uint"),
    dev_scifi_track_hit_number_t = DataObjectHandleBase("dev_scifi_track_hit_number_t", "R", "uint"),
    dev_scifi_qop_t = DataObjectHandleBase("dev_scifi_qop_t", "R", "float"),
    dev_scifi_states_t = DataObjectHandleBase("dev_scifi_states_t", "R", "MiniState"),
    dev_scifi_track_ut_indices_t = DataObjectHandleBase("dev_scifi_track_ut_indices_t", "R", "uint"),
    dev_station_ocurrences_offset_t = DataObjectHandleBase("dev_station_ocurrences_offset_t", "R", "uint"),
    dev_muon_hits_t = DataObjectHandleBase("dev_muon_hits_t", "R", "char"),
    dev_muon_catboost_features_t = DataObjectHandleBase("dev_muon_catboost_features_t", "W", "float"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(muon_catboost_features_extraction_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "muon_catboost_features_extraction"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/muon/preprocessing/include/MuonFeaturesExtraction.cuh"

  @classmethod
  def getType(cls):
    return "muon_catboost_features_extraction_t"


class match_upstream_muon_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_number_of_reconstructed_ut_tracks_t = DataObjectHandleBase("host_number_of_reconstructed_ut_tracks_t", "R", "uint"),
    host_selected_events_mf_t = DataObjectHandleBase("host_selected_events_mf_t", "R", "uint"),
    dev_offsets_all_velo_tracks_t = DataObjectHandleBase("dev_offsets_all_velo_tracks_t", "R", "uint"),
    dev_offsets_velo_track_hit_number_t = DataObjectHandleBase("dev_offsets_velo_track_hit_number_t", "R", "uint"),
    dev_velo_kalman_beamline_states_t = DataObjectHandleBase("dev_velo_kalman_beamline_states_t", "R", "char"),
    dev_offsets_ut_tracks_t = DataObjectHandleBase("dev_offsets_ut_tracks_t", "R", "uint"),
    dev_offsets_ut_track_hit_number_t = DataObjectHandleBase("dev_offsets_ut_track_hit_number_t", "R", "uint"),
    dev_ut_qop_t = DataObjectHandleBase("dev_ut_qop_t", "R", "float"),
    dev_ut_track_velo_indices_t = DataObjectHandleBase("dev_ut_track_velo_indices_t", "R", "uint"),
    dev_station_ocurrences_offset_t = DataObjectHandleBase("dev_station_ocurrences_offset_t", "R", "uint"),
    dev_muon_hits_t = DataObjectHandleBase("dev_muon_hits_t", "R", "char"),
    dev_event_list_mf_t = DataObjectHandleBase("dev_event_list_mf_t", "R", "uint"),
    dev_match_upstream_muon_t = DataObjectHandleBase("dev_match_upstream_muon_t", "W", "bool"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(match_upstream_muon_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "MatchUpstreamMuon"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/muon/match_upstream_muon/include/MatchUpstreamMuon.cuh"

  @classmethod
  def getType(cls):
    return "match_upstream_muon_t"


class muon_filter_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_selected_events_mf_t = DataObjectHandleBase("host_selected_events_mf_t", "W", "uint"),
    dev_offsets_all_velo_tracks_t = DataObjectHandleBase("dev_offsets_all_velo_tracks_t", "R", "uint"),
    dev_offsets_velo_track_hit_number_t = DataObjectHandleBase("dev_offsets_velo_track_hit_number_t", "R", "uint"),
    dev_velo_kalman_beamline_states_t = DataObjectHandleBase("dev_velo_kalman_beamline_states_t", "R", "char"),
    dev_velo_track_hits_t = DataObjectHandleBase("dev_velo_track_hits_t", "R", "char"),
    dev_offsets_ut_tracks_t = DataObjectHandleBase("dev_offsets_ut_tracks_t", "R", "uint"),
    dev_offsets_ut_track_hit_number_t = DataObjectHandleBase("dev_offsets_ut_track_hit_number_t", "R", "uint"),
    dev_ut_qop_t = DataObjectHandleBase("dev_ut_qop_t", "R", "float"),
    dev_ut_track_velo_indices_t = DataObjectHandleBase("dev_ut_track_velo_indices_t", "R", "uint"),
    dev_offsets_forward_tracks_t = DataObjectHandleBase("dev_offsets_forward_tracks_t", "R", "uint"),
    dev_offsets_scifi_track_hit_number = DataObjectHandleBase("dev_offsets_scifi_track_hit_number", "R", "uint"),
    dev_scifi_qop_t = DataObjectHandleBase("dev_scifi_qop_t", "R", "float"),
    dev_scifi_states_t = DataObjectHandleBase("dev_scifi_states_t", "R", "MiniState"),
    dev_scifi_track_ut_indices_t = DataObjectHandleBase("dev_scifi_track_ut_indices_t", "R", "uint"),
    dev_is_muon_t = DataObjectHandleBase("dev_is_muon_t", "R", "bool"),
    dev_kalman_pv_ipchi2_t = DataObjectHandleBase("dev_kalman_pv_ipchi2_t", "R", "char"),
    dev_mf_decisions_t = DataObjectHandleBase("dev_mf_decisions_t", "W", "uint"),
    dev_event_list_mf_t = DataObjectHandleBase("dev_event_list_mf_t", "W", "uint"),
    dev_selected_events_mf_t = DataObjectHandleBase("dev_selected_events_mf_t", "W", "uint"),
    dev_mf_track_atomics_t = DataObjectHandleBase("dev_mf_track_atomics_t", "W", "uint"),
    mf_min_pt = "",
    mf_min_ipchi2 = "",
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(muon_filter_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "MuonFilter"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/muon/muon_filter/include/MuonFilter.cuh"

  @classmethod
  def getType(cls):
    return "muon_filter_t"


class prepare_raw_banks_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_number_of_reconstructed_scifi_tracks_t = DataObjectHandleBase("host_number_of_reconstructed_scifi_tracks_t", "R", "uint"),
    host_number_of_svs_t = DataObjectHandleBase("host_number_of_svs_t", "R", "uint"),
    dev_event_list_t = DataObjectHandleBase("dev_event_list_t", "R", "uint"),
    dev_offsets_all_velo_tracks_t = DataObjectHandleBase("dev_offsets_all_velo_tracks_t", "R", "uint"),
    dev_offsets_velo_track_hit_number_t = DataObjectHandleBase("dev_offsets_velo_track_hit_number_t", "R", "uint"),
    dev_velo_track_hits_t = DataObjectHandleBase("dev_velo_track_hits_t", "R", "char"),
    dev_offsets_ut_tracks_t = DataObjectHandleBase("dev_offsets_ut_tracks_t", "R", "uint"),
    dev_offsets_ut_track_hit_number_t = DataObjectHandleBase("dev_offsets_ut_track_hit_number_t", "R", "uint"),
    dev_ut_qop_t = DataObjectHandleBase("dev_ut_qop_t", "R", "float"),
    dev_ut_track_velo_indices_t = DataObjectHandleBase("dev_ut_track_velo_indices_t", "R", "uint"),
    dev_offsets_scifi_track_hit_number = DataObjectHandleBase("dev_offsets_scifi_track_hit_number", "R", "uint"),
    dev_scifi_qop_t = DataObjectHandleBase("dev_scifi_qop_t", "R", "float"),
    dev_scifi_states_t = DataObjectHandleBase("dev_scifi_states_t", "R", "MiniState"),
    dev_scifi_track_ut_indices_t = DataObjectHandleBase("dev_scifi_track_ut_indices_t", "R", "uint"),
    dev_ut_track_hits_t = DataObjectHandleBase("dev_ut_track_hits_t", "R", "char"),
    dev_scifi_track_hits_t = DataObjectHandleBase("dev_scifi_track_hits_t", "R", "char"),
    dev_kf_tracks_t = DataObjectHandleBase("dev_kf_tracks_t", "R", "ParKalmanFilter::FittedTrack"),
    dev_consolidated_svs_t = DataObjectHandleBase("dev_consolidated_svs_t", "R", "VertexFit::TrackMVAVertex"),
    dev_offsets_forward_tracks_t = DataObjectHandleBase("dev_offsets_forward_tracks_t", "R", "uint"),
    dev_sv_offsets_t = DataObjectHandleBase("dev_sv_offsets_t", "R", "uint"),
    dev_sel_results_t = DataObjectHandleBase("dev_sel_results_t", "R", "bool"),
    dev_sel_results_offsets_t = DataObjectHandleBase("dev_sel_results_offsets_t", "R", "uint"),
    dev_candidate_lists_t = DataObjectHandleBase("dev_candidate_lists_t", "W", "uint"),
    dev_candidate_counts_t = DataObjectHandleBase("dev_candidate_counts_t", "W", "uint"),
    dev_n_passing_decisions_t = DataObjectHandleBase("dev_n_passing_decisions_t", "W", "uint"),
    dev_n_svs_saved_t = DataObjectHandleBase("dev_n_svs_saved_t", "W", "uint"),
    dev_n_tracks_saved_t = DataObjectHandleBase("dev_n_tracks_saved_t", "W", "uint"),
    dev_n_hits_saved_t = DataObjectHandleBase("dev_n_hits_saved_t", "W", "uint"),
    dev_saved_tracks_list_t = DataObjectHandleBase("dev_saved_tracks_list_t", "W", "uint"),
    dev_saved_svs_list_t = DataObjectHandleBase("dev_saved_svs_list_t", "W", "uint"),
    dev_save_track_t = DataObjectHandleBase("dev_save_track_t", "W", "int"),
    dev_save_sv_t = DataObjectHandleBase("dev_save_sv_t", "W", "int"),
    dev_dec_reports_t = DataObjectHandleBase("dev_dec_reports_t", "W", "uint"),
    dev_sel_rb_hits_t = DataObjectHandleBase("dev_sel_rb_hits_t", "W", "uint"),
    dev_sel_rb_stdinfo_t = DataObjectHandleBase("dev_sel_rb_stdinfo_t", "W", "uint"),
    dev_sel_rb_objtyp_t = DataObjectHandleBase("dev_sel_rb_objtyp_t", "W", "uint"),
    dev_sel_rb_substr_t = DataObjectHandleBase("dev_sel_rb_substr_t", "W", "uint"),
    dev_sel_rep_sizes_t = DataObjectHandleBase("dev_sel_rep_sizes_t", "W", "uint"),
    dev_passing_event_list_t = DataObjectHandleBase("dev_passing_event_list_t", "W", "bool"),
    block_dim_x = ""
  )

  def __init__(self, name, **kwargs):
    super(prepare_raw_banks_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "prepare_raw_banks"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/raw_banks/include/PrepareRawBanks.cuh"

  @classmethod
  def getType(cls):
    return "prepare_raw_banks_t"


class package_sel_reports_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_number_of_sel_rep_words_t = DataObjectHandleBase("host_number_of_sel_rep_words_t", "R", "uint"),
    dev_event_list_t = DataObjectHandleBase("dev_event_list_t", "R", "uint"),
    dev_offsets_forward_tracks_t = DataObjectHandleBase("dev_offsets_forward_tracks_t", "R", "uint"),
    dev_sel_rb_hits_t = DataObjectHandleBase("dev_sel_rb_hits_t", "R", "uint"),
    dev_sel_rb_stdinfo_t = DataObjectHandleBase("dev_sel_rb_stdinfo_t", "R", "uint"),
    dev_sel_rb_objtyp_t = DataObjectHandleBase("dev_sel_rb_objtyp_t", "R", "uint"),
    dev_sel_rb_substr_t = DataObjectHandleBase("dev_sel_rb_substr_t", "R", "uint"),
    dev_sel_rep_offsets_t = DataObjectHandleBase("dev_sel_rep_offsets_t", "R", "uint"),
    dev_sel_rep_raw_banks_t = DataObjectHandleBase("dev_sel_rep_raw_banks_t", "W", "uint"),
    block_dim_x = ""
  )

  def __init__(self, name, **kwargs):
    super(package_sel_reports_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "package_sel_reports"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/raw_banks/include/PackageSelReports.cuh"

  @classmethod
  def getType(cls):
    return "package_sel_reports_t"


class run_hlt1_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_number_of_reconstructed_scifi_tracks_t = DataObjectHandleBase("host_number_of_reconstructed_scifi_tracks_t", "R", "uint"),
    host_number_of_svs_t = DataObjectHandleBase("host_number_of_svs_t", "R", "uint"),
    dev_event_list_t = DataObjectHandleBase("dev_event_list_t", "R", "uint"),
    dev_kf_tracks_t = DataObjectHandleBase("dev_kf_tracks_t", "R", "ParKalmanFilter::FittedTrack"),
    dev_consolidated_svs_t = DataObjectHandleBase("dev_consolidated_svs_t", "R", "VertexFit::TrackMVAVertex"),
    dev_offsets_forward_tracks_t = DataObjectHandleBase("dev_offsets_forward_tracks_t", "R", "uint"),
    dev_sv_offsets_t = DataObjectHandleBase("dev_sv_offsets_t", "R", "uint"),
    dev_odin_raw_input_t = DataObjectHandleBase("dev_odin_raw_input_t", "R", "char"),
    dev_odin_raw_input_offsets_t = DataObjectHandleBase("dev_odin_raw_input_offsets_t", "R", "uint"),
    dev_offsets_all_velo_tracks_t = DataObjectHandleBase("dev_offsets_all_velo_tracks_t", "R", "uint"),
    dev_sel_results_t = DataObjectHandleBase("dev_sel_results_t", "W", "bool"),
    dev_sel_results_offsets_t = DataObjectHandleBase("dev_sel_results_offsets_t", "W", "uint"),
    factor_one_track = "",
    factor_single_muon = "",
    factor_two_tracks = "",
    factor_disp_dimuon = "",
    factor_high_mass_dimuon = "",
    factor_dimuon_soft = "",
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(run_hlt1_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "run_hlt1"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/selections/Hlt1/include/RunHlt1.cuh"

  @classmethod
  def getType(cls):
    return "run_hlt1_t"


class velo_calculate_phi_and_sort_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_total_number_of_velo_clusters_t = DataObjectHandleBase("host_total_number_of_velo_clusters_t", "R", "uint"),
    dev_offsets_estimated_input_size_t = DataObjectHandleBase("dev_offsets_estimated_input_size_t", "R", "uint"),
    dev_module_cluster_num_t = DataObjectHandleBase("dev_module_cluster_num_t", "R", "uint"),
    dev_velo_cluster_container_t = DataObjectHandleBase("dev_velo_cluster_container_t", "R", "char"),
    dev_sorted_velo_cluster_container_t = DataObjectHandleBase("dev_sorted_velo_cluster_container_t", "W", "char"),
    dev_hit_permutation_t = DataObjectHandleBase("dev_hit_permutation_t", "W", "uint"),
    dev_hit_phi_t = DataObjectHandleBase("dev_hit_phi_t", "W", "int16_t"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(velo_calculate_phi_and_sort_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "velo_calculate_phi_and_sort"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/velo/calculate_phi_and_sort/include/CalculatePhiAndSort.cuh"

  @classmethod
  def getType(cls):
    return "velo_calculate_phi_and_sort_t"


class velo_consolidate_tracks_t(AllenAlgorithm):
  __slots__ = dict(
    host_accumulated_number_of_hits_in_velo_tracks_t = DataObjectHandleBase("host_accumulated_number_of_hits_in_velo_tracks_t", "R", "uint"),
    host_number_of_reconstructed_velo_tracks_t = DataObjectHandleBase("host_number_of_reconstructed_velo_tracks_t", "R", "uint"),
    host_number_of_three_hit_tracks_filtered_t = DataObjectHandleBase("host_number_of_three_hit_tracks_filtered_t", "R", "uint"),
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    dev_accepted_velo_tracks_t = DataObjectHandleBase("dev_accepted_velo_tracks_t", "W", "bool"),
    dev_offsets_all_velo_tracks_t = DataObjectHandleBase("dev_offsets_all_velo_tracks_t", "R", "uint"),
    dev_tracks_t = DataObjectHandleBase("dev_tracks_t", "R", "Velo::TrackHits"),
    dev_offsets_velo_track_hit_number_t = DataObjectHandleBase("dev_offsets_velo_track_hit_number_t", "R", "uint"),
    dev_sorted_velo_cluster_container_t = DataObjectHandleBase("dev_sorted_velo_cluster_container_t", "R", "char"),
    dev_offsets_estimated_input_size_t = DataObjectHandleBase("dev_offsets_estimated_input_size_t", "R", "uint"),
    dev_velo_states_t = DataObjectHandleBase("dev_velo_states_t", "W", "char"),
    dev_three_hit_tracks_output_t = DataObjectHandleBase("dev_three_hit_tracks_output_t", "R", "Velo::TrackletHits"),
    dev_offsets_number_of_three_hit_tracks_filtered_t = DataObjectHandleBase("dev_offsets_number_of_three_hit_tracks_filtered_t", "R", "uint"),
    dev_velo_track_hits_t = DataObjectHandleBase("dev_velo_track_hits_t", "W", "char"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(velo_consolidate_tracks_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "velo_consolidate_tracks"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/velo/consolidate_tracks/include/VeloConsolidateTracks.cuh"

  @classmethod
  def getType(cls):
    return "velo_consolidate_tracks_t"


class velo_copy_track_hit_number_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_number_of_velo_tracks_at_least_four_hits_t = DataObjectHandleBase("host_number_of_velo_tracks_at_least_four_hits_t", "R", "uint"),
    host_number_of_three_hit_tracks_filtered_t = DataObjectHandleBase("host_number_of_three_hit_tracks_filtered_t", "R", "uint"),
    host_number_of_reconstructed_velo_tracks_t = DataObjectHandleBase("host_number_of_reconstructed_velo_tracks_t", "W", "uint"),
    dev_tracks_t = DataObjectHandleBase("dev_tracks_t", "R", "Velo::TrackHits"),
    dev_offsets_velo_tracks_t = DataObjectHandleBase("dev_offsets_velo_tracks_t", "R", "uint"),
    dev_offsets_number_of_three_hit_tracks_filtered_t = DataObjectHandleBase("dev_offsets_number_of_three_hit_tracks_filtered_t", "R", "uint"),
    dev_velo_track_hit_number_t = DataObjectHandleBase("dev_velo_track_hit_number_t", "W", "uint"),
    dev_offsets_all_velo_tracks_t = DataObjectHandleBase("dev_offsets_all_velo_tracks_t", "W", "uint"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(velo_copy_track_hit_number_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "velo_copy_track_hit_number"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/velo/consolidate_tracks/include/VeloCopyTrackHitNumber.cuh"

  @classmethod
  def getType(cls):
    return "velo_copy_track_hit_number_t"


class velo_estimate_input_size_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_number_of_cluster_candidates_t = DataObjectHandleBase("host_number_of_cluster_candidates_t", "R", "uint"),
    dev_event_list_t = DataObjectHandleBase("dev_event_list_t", "R", "uint"),
    dev_candidates_offsets_t = DataObjectHandleBase("dev_candidates_offsets_t", "R", "uint"),
    dev_velo_raw_input_t = DataObjectHandleBase("dev_velo_raw_input_t", "R", "char"),
    dev_velo_raw_input_offsets_t = DataObjectHandleBase("dev_velo_raw_input_offsets_t", "R", "uint"),
    dev_estimated_input_size_t = DataObjectHandleBase("dev_estimated_input_size_t", "W", "uint"),
    dev_module_candidate_num_t = DataObjectHandleBase("dev_module_candidate_num_t", "W", "uint"),
    dev_cluster_candidates_t = DataObjectHandleBase("dev_cluster_candidates_t", "W", "uint"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(velo_estimate_input_size_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "velo_estimate_input_size"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/velo/mask_clustering/include/EstimateInputSize.cuh"

  @classmethod
  def getType(cls):
    return "velo_estimate_input_size_t"


class velo_masked_clustering_t(AllenAlgorithm):
  __slots__ = dict(
    host_total_number_of_velo_clusters_t = DataObjectHandleBase("host_total_number_of_velo_clusters_t", "R", "uint"),
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    dev_velo_raw_input_t = DataObjectHandleBase("dev_velo_raw_input_t", "R", "char"),
    dev_velo_raw_input_offsets_t = DataObjectHandleBase("dev_velo_raw_input_offsets_t", "R", "uint"),
    dev_offsets_estimated_input_size_t = DataObjectHandleBase("dev_offsets_estimated_input_size_t", "R", "uint"),
    dev_module_candidate_num_t = DataObjectHandleBase("dev_module_candidate_num_t", "R", "uint"),
    dev_cluster_candidates_t = DataObjectHandleBase("dev_cluster_candidates_t", "R", "uint"),
    dev_event_list_t = DataObjectHandleBase("dev_event_list_t", "R", "uint"),
    dev_candidates_offsets_t = DataObjectHandleBase("dev_candidates_offsets_t", "R", "uint"),
    dev_module_cluster_num_t = DataObjectHandleBase("dev_module_cluster_num_t", "W", "uint"),
    dev_velo_cluster_container_t = DataObjectHandleBase("dev_velo_cluster_container_t", "W", "char"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(velo_masked_clustering_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "velo_masked_clustering"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/velo/mask_clustering/include/MaskedVeloClustering.cuh"

  @classmethod
  def getType(cls):
    return "velo_masked_clustering_t"


class velo_calculate_number_of_candidates_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    dev_event_list_t = DataObjectHandleBase("dev_event_list_t", "R", "uint"),
    dev_velo_raw_input_t = DataObjectHandleBase("dev_velo_raw_input_t", "R", "char"),
    dev_velo_raw_input_offsets_t = DataObjectHandleBase("dev_velo_raw_input_offsets_t", "R", "uint"),
    dev_number_of_candidates_t = DataObjectHandleBase("dev_number_of_candidates_t", "W", "uint"),
    block_dim_x = ""
  )

  def __init__(self, name, **kwargs):
    super(velo_calculate_number_of_candidates_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "velo_calculate_number_of_candidates"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/velo/mask_clustering/include/VeloCalculateNumberOfCandidates.cuh"

  @classmethod
  def getType(cls):
    return "velo_calculate_number_of_candidates_t"


class velo_search_by_triplet_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_total_number_of_velo_clusters_t = DataObjectHandleBase("host_total_number_of_velo_clusters_t", "R", "uint"),
    dev_sorted_velo_cluster_container_t = DataObjectHandleBase("dev_sorted_velo_cluster_container_t", "R", "char"),
    dev_offsets_estimated_input_size_t = DataObjectHandleBase("dev_offsets_estimated_input_size_t", "R", "uint"),
    dev_module_cluster_num_t = DataObjectHandleBase("dev_module_cluster_num_t", "R", "uint"),
    dev_hit_phi_t = DataObjectHandleBase("dev_hit_phi_t", "R", "int16_t"),
    dev_tracks_t = DataObjectHandleBase("dev_tracks_t", "W", "Velo::TrackHits"),
    dev_tracklets_t = DataObjectHandleBase("dev_tracklets_t", "W", "Velo::TrackletHits"),
    dev_tracks_to_follow_t = DataObjectHandleBase("dev_tracks_to_follow_t", "W", "uint"),
    dev_three_hit_tracks_t = DataObjectHandleBase("dev_three_hit_tracks_t", "W", "Velo::TrackletHits"),
    dev_hit_used_t = DataObjectHandleBase("dev_hit_used_t", "W", "bool"),
    dev_atomics_velo_t = DataObjectHandleBase("dev_atomics_velo_t", "W", "uint"),
    dev_rel_indices_t = DataObjectHandleBase("dev_rel_indices_t", "W", "unsignedshort"),
    dev_number_of_velo_tracks_t = DataObjectHandleBase("dev_number_of_velo_tracks_t", "W", "uint"),
    phi_tolerance = "",
    max_scatter = "",
    max_skipped_modules = "",
    block_dim_x = ""
  )

  def __init__(self, name, **kwargs):
    super(velo_search_by_triplet_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "velo_search_by_triplet"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/velo/search_by_triplet/include/SearchByTriplet.cuh"

  @classmethod
  def getType(cls):
    return "velo_search_by_triplet_t"


class velo_three_hit_tracks_filter_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    dev_sorted_velo_cluster_container_t = DataObjectHandleBase("dev_sorted_velo_cluster_container_t", "R", "char"),
    dev_offsets_estimated_input_size_t = DataObjectHandleBase("dev_offsets_estimated_input_size_t", "R", "uint"),
    dev_three_hit_tracks_input_t = DataObjectHandleBase("dev_three_hit_tracks_input_t", "R", "Velo::TrackletHits"),
    dev_atomics_velo_t = DataObjectHandleBase("dev_atomics_velo_t", "R", "uint"),
    dev_hit_used_t = DataObjectHandleBase("dev_hit_used_t", "R", "bool"),
    dev_three_hit_tracks_output_t = DataObjectHandleBase("dev_three_hit_tracks_output_t", "W", "Velo::TrackletHits"),
    dev_number_of_three_hit_tracks_output_t = DataObjectHandleBase("dev_number_of_three_hit_tracks_output_t", "W", "uint"),
    max_chi2 = "",
    max_weak_tracks = "",
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(velo_three_hit_tracks_filter_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "velo_three_hit_tracks_filter"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/velo/search_by_triplet/include/ThreeHitTracksFilter.cuh"

  @classmethod
  def getType(cls):
    return "velo_three_hit_tracks_filter_t"


class velo_kalman_filter_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_reconstructed_velo_tracks_t = DataObjectHandleBase("host_number_of_reconstructed_velo_tracks_t", "R", "uint"),
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    dev_offsets_all_velo_tracks_t = DataObjectHandleBase("dev_offsets_all_velo_tracks_t", "R", "uint"),
    dev_offsets_velo_track_hit_number_t = DataObjectHandleBase("dev_offsets_velo_track_hit_number_t", "R", "uint"),
    dev_velo_track_hits_t = DataObjectHandleBase("dev_velo_track_hits_t", "R", "char"),
    dev_velo_states_t = DataObjectHandleBase("dev_velo_states_t", "R", "char"),
    dev_velo_kalman_beamline_states_t = DataObjectHandleBase("dev_velo_kalman_beamline_states_t", "W", "char"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(velo_kalman_filter_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "velo_kalman_filter"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/velo/simplified_kalman_filter/include/VeloKalmanFilter.cuh"

  @classmethod
  def getType(cls):
    return "velo_kalman_filter_t"


class consolidate_svs_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_svs_t = DataObjectHandleBase("host_number_of_svs_t", "R", "uint"),
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    dev_sv_offsets_t = DataObjectHandleBase("dev_sv_offsets_t", "R", "uint"),
    dev_secondary_vertices_t = DataObjectHandleBase("dev_secondary_vertices_t", "R", "VertexFit::TrackMVAVertex"),
    dev_consolidated_svs_t = DataObjectHandleBase("dev_consolidated_svs_t", "W", "VertexFit::TrackMVAVertex"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(consolidate_svs_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "consolidate_svs"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/vertex_fit/vertex_fitter/include/ConsolidateSVs.cuh"

  @classmethod
  def getType(cls):
    return "consolidate_svs_t"


class fit_secondary_vertices_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_number_of_svs_t = DataObjectHandleBase("host_number_of_svs_t", "R", "uint"),
    dev_kf_tracks_t = DataObjectHandleBase("dev_kf_tracks_t", "R", "ParKalmanFilter::FittedTrack"),
    dev_offsets_forward_tracks_t = DataObjectHandleBase("dev_offsets_forward_tracks_t", "R", "uint"),
    dev_offsets_scifi_track_hit_number = DataObjectHandleBase("dev_offsets_scifi_track_hit_number", "R", "uint"),
    dev_scifi_qop_t = DataObjectHandleBase("dev_scifi_qop_t", "R", "float"),
    dev_scifi_states_t = DataObjectHandleBase("dev_scifi_states_t", "R", "MiniState"),
    dev_scifi_track_ut_indices_t = DataObjectHandleBase("dev_scifi_track_ut_indices_t", "R", "uint"),
    dev_multi_fit_vertices_t = DataObjectHandleBase("dev_multi_fit_vertices_t", "R", "PV::Vertex"),
    dev_number_of_multi_fit_vertices_t = DataObjectHandleBase("dev_number_of_multi_fit_vertices_t", "R", "uint"),
    dev_kalman_pv_ipchi2_t = DataObjectHandleBase("dev_kalman_pv_ipchi2_t", "R", "char"),
    dev_svs_trk1_idx_t = DataObjectHandleBase("dev_svs_trk1_idx_t", "R", "uint"),
    dev_svs_trk2_idx_t = DataObjectHandleBase("dev_svs_trk2_idx_t", "R", "uint"),
    dev_sv_offsets_t = DataObjectHandleBase("dev_sv_offsets_t", "R", "uint"),
    dev_consolidated_svs_t = DataObjectHandleBase("dev_consolidated_svs_t", "W", "VertexFit::TrackMVAVertex"),
    max_assoc_ipchi2 = "",
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(fit_secondary_vertices_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "VertexFit"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/vertex_fit/vertex_fitter/include/VertexFitter.cuh"

  @classmethod
  def getType(cls):
    return "fit_secondary_vertices_t"


class filter_mf_tracks_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_selected_events_mf_t = DataObjectHandleBase("host_selected_events_mf_t", "R", "uint"),
    dev_kf_tracks_t = DataObjectHandleBase("dev_kf_tracks_t", "R", "ParKalmanFilter::FittedTrack"),
    dev_mf_tracks_t = DataObjectHandleBase("dev_mf_tracks_t", "R", "ParKalmanFilter::FittedTrack"),
    dev_offsets_forward_tracks_t = DataObjectHandleBase("dev_offsets_forward_tracks_t", "R", "uint"),
    dev_offsets_scifi_track_hit_number = DataObjectHandleBase("dev_offsets_scifi_track_hit_number", "R", "uint"),
    dev_scifi_qop_t = DataObjectHandleBase("dev_scifi_qop_t", "R", "float"),
    dev_scifi_states_t = DataObjectHandleBase("dev_scifi_states_t", "R", "MiniState"),
    dev_scifi_track_ut_indices_t = DataObjectHandleBase("dev_scifi_track_ut_indices_t", "R", "uint"),
    dev_mf_track_offsets_t = DataObjectHandleBase("dev_mf_track_offsets_t", "R", "uint"),
    dev_event_list_mf_t = DataObjectHandleBase("dev_event_list_mf_t", "R", "uint"),
    dev_mf_sv_atomics_t = DataObjectHandleBase("dev_mf_sv_atomics_t", "W", "uint"),
    dev_svs_kf_idx_t = DataObjectHandleBase("dev_svs_kf_idx_t", "W", "uint"),
    dev_svs_mf_idx_t = DataObjectHandleBase("dev_svs_mf_idx_t", "W", "uint"),
    kf_track_min_pt = "",
    kf_track_min_ipchi2 = "",
    mf_track_min_pt = "",
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(filter_mf_tracks_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "FilterMFTracks"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/vertex_fit/vertex_fitter/include/FilterMFTracks.cuh"

  @classmethod
  def getType(cls):
    return "filter_mf_tracks_t"


class filter_tracks_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    dev_kf_tracks_t = DataObjectHandleBase("dev_kf_tracks_t", "R", "ParKalmanFilter::FittedTrack"),
    dev_offsets_forward_tracks_t = DataObjectHandleBase("dev_offsets_forward_tracks_t", "R", "uint"),
    dev_offsets_scifi_track_hit_number = DataObjectHandleBase("dev_offsets_scifi_track_hit_number", "R", "uint"),
    dev_scifi_qop_t = DataObjectHandleBase("dev_scifi_qop_t", "R", "float"),
    dev_scifi_states_t = DataObjectHandleBase("dev_scifi_states_t", "R", "MiniState"),
    dev_scifi_track_ut_indices_t = DataObjectHandleBase("dev_scifi_track_ut_indices_t", "R", "uint"),
    dev_multi_fit_vertices_t = DataObjectHandleBase("dev_multi_fit_vertices_t", "R", "PV::Vertex"),
    dev_number_of_multi_fit_vertices_t = DataObjectHandleBase("dev_number_of_multi_fit_vertices_t", "R", "uint"),
    dev_kalman_pv_ipchi2_t = DataObjectHandleBase("dev_kalman_pv_ipchi2_t", "R", "char"),
    dev_sv_atomics_t = DataObjectHandleBase("dev_sv_atomics_t", "W", "uint"),
    dev_svs_trk1_idx_t = DataObjectHandleBase("dev_svs_trk1_idx_t", "W", "uint"),
    dev_svs_trk2_idx_t = DataObjectHandleBase("dev_svs_trk2_idx_t", "W", "uint"),
    track_min_pt = "",
    track_min_ipchi2 = "",
    track_muon_min_ipchi2 = "",
    track_max_chi2ndof = "",
    track_muon_max_chi2ndof = "",
    max_assoc_ipchi2 = "",
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(filter_tracks_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "FilterTracks"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/vertex_fit/vertex_fitter/include/FilterTracks.cuh"

  @classmethod
  def getType(cls):
    return "filter_tracks_t"


class fit_mf_vertices_t(AllenAlgorithm):
  __slots__ = dict(
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "R", "uint"),
    host_number_of_mf_svs_t = DataObjectHandleBase("host_number_of_mf_svs_t", "R", "uint"),
    host_selected_events_mf_t = DataObjectHandleBase("host_selected_events_mf_t", "R", "uint"),
    dev_kf_tracks_t = DataObjectHandleBase("dev_kf_tracks_t", "R", "ParKalmanFilter::FittedTrack"),
    dev_mf_tracks_t = DataObjectHandleBase("dev_mf_tracks_t", "R", "ParKalmanFilter::FittedTrack"),
    dev_offsets_forward_tracks_t = DataObjectHandleBase("dev_offsets_forward_tracks_t", "R", "uint"),
    dev_mf_track_offsets_t = DataObjectHandleBase("dev_mf_track_offsets_t", "R", "uint"),
    dev_mf_sv_offsets_t = DataObjectHandleBase("dev_mf_sv_offsets_t", "R", "uint"),
    dev_svs_kf_idx_t = DataObjectHandleBase("dev_svs_kf_idx_t", "R", "uint"),
    dev_svs_mf_idx_t = DataObjectHandleBase("dev_svs_mf_idx_t", "R", "uint"),
    dev_event_list_mf_t = DataObjectHandleBase("dev_event_list_mf_t", "R", "uint"),
    dev_mf_svs_t = DataObjectHandleBase("dev_mf_svs_t", "W", "VertexFit::TrackMVAVertex"),
    block_dim = ""
  )

  def __init__(self, name, **kwargs):
    super(fit_mf_vertices_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "MFVertexFit"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/cuda/vertex_fit/vertex_fitter/include/MFVertexFitter.cuh"

  @classmethod
  def getType(cls):
    return "fit_mf_vertices_t"


class host_global_event_cut_t(AllenAlgorithm):
  __slots__ = dict(
    host_ut_raw_banks_t = DataObjectHandleBase("host_ut_raw_banks_t", "R", "gsl::span<charconst>"),
    host_ut_raw_offsets_t = DataObjectHandleBase("host_ut_raw_offsets_t", "R", "gsl::span<unsignedintconst>"),
    host_scifi_raw_banks_t = DataObjectHandleBase("host_scifi_raw_banks_t", "R", "gsl::span<charconst>"),
    host_scifi_raw_offsets_t = DataObjectHandleBase("host_scifi_raw_offsets_t", "R", "gsl::span<unsignedintconst>"),
    host_total_number_of_events_t = DataObjectHandleBase("host_total_number_of_events_t", "W", "uint"),
    host_event_list_t = DataObjectHandleBase("host_event_list_t", "W", "uint"),
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "W", "uint"),
    dev_event_list_t = DataObjectHandleBase("dev_event_list_t", "W", "uint"),
    min_scifi_ut_clusters = "",
    max_scifi_ut_clusters = ""
  )

  def __init__(self, name, **kwargs):
    super(host_global_event_cut_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "host_global_event_cut"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/x86/global_event_cut/include/HostGlobalEventCut.h"

  @classmethod
  def getType(cls):
    return "host_global_event_cut_t"


class host_init_event_list_t(AllenAlgorithm):
  __slots__ = dict(
    host_ut_raw_banks_t = DataObjectHandleBase("host_ut_raw_banks_t", "R", "gsl::span<charconst>"),
    host_ut_raw_offsets_t = DataObjectHandleBase("host_ut_raw_offsets_t", "R", "gsl::span<unsignedintconst>"),
    host_scifi_raw_banks_t = DataObjectHandleBase("host_scifi_raw_banks_t", "R", "gsl::span<charconst>"),
    host_scifi_raw_offsets_t = DataObjectHandleBase("host_scifi_raw_offsets_t", "R", "gsl::span<unsignedintconst>"),
    host_total_number_of_events_t = DataObjectHandleBase("host_total_number_of_events_t", "W", "uint"),
    host_event_list_t = DataObjectHandleBase("host_event_list_t", "W", "uint"),
    host_number_of_selected_events_t = DataObjectHandleBase("host_number_of_selected_events_t", "W", "uint"),
    dev_event_list_t = DataObjectHandleBase("dev_event_list_t", "W", "uint")
  )

  def __init__(self, name, **kwargs):
    super(host_init_event_list_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "host_init_event_list"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/x86/init_event_list/include/HostInitEventList.h"

  @classmethod
  def getType(cls):
    return "host_init_event_list_t"


class host_prefix_sum_t(AllenAlgorithm):
  __slots__ = dict(
    host_total_sum_holder_t = DataObjectHandleBase("host_total_sum_holder_t", "W", "uint"),
    dev_input_buffer_t = DataObjectHandleBase("dev_input_buffer_t", "R", "uint"),
    dev_output_buffer_t = DataObjectHandleBase("dev_output_buffer_t", "W", "uint")
  )

  def __init__(self, name, **kwargs):
    super(host_prefix_sum_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "host_prefix_sum"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/x86/prefix_sum/include/HostPrefixSum.h"

  @classmethod
  def getType(cls):
    return "host_prefix_sum_t"


class data_provider_t(AllenAlgorithm):
  __slots__ = dict(
    dev_raw_banks_t = DataObjectHandleBase("dev_raw_banks_t", "W", "char"),
    dev_raw_offsets_t = DataObjectHandleBase("dev_raw_offsets_t", "W", "uint"),
    bank_type = ""
  )

  def __init__(self, name, **kwargs):
    super(data_provider_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "data_provider"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/x86/data_provider/include/DataProvider.h"

  @classmethod
  def getType(cls):
    return "data_provider_t"


class host_data_provider_t(AllenAlgorithm):
  __slots__ = dict(
    host_raw_banks_t = DataObjectHandleBase("host_raw_banks_t", "W", "gsl::span<charconst>"),
    host_raw_offsets_t = DataObjectHandleBase("host_raw_offsets_t", "W", "gsl::span<unsignedintconst>"),
    bank_type = ""
  )

  def __init__(self, name, **kwargs):
    super(host_data_provider_t, self).__init__(name)
    for n,v in kwargs.items():
      setattr(self, n, v)

  @classmethod
  def namespace(cls):
    return "host_data_provider"

  @classmethod
  def filename(cls):
    return "/home/dcampora/projects/allen/x86/data_provider/include/HostDataProvider.h"

  @classmethod
  def getType(cls):
    return "host_data_provider_t"


