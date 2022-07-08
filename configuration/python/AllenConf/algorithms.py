from AllenCore.AllenKernel import AllenAlgorithm, AllenDataHandle
from collections import OrderedDict
from enum import Enum


class AlgorithmCategory(Enum):
    HostAlgorithm = 0
    DeviceAlgorithm = 1
    SelectionAlgorithm = 2
    HostDataProvider = 3
    DataProvider = 4
    ValidationAlgorithm = 5


class pv_beamline_calculate_denom_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_reconstructed_velo_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_velo_tracks_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_velo_tracks_view_t = AllenDataHandle("device", [], "dev_velo_tracks_view_t", "R", "unknown_t"),
    dev_pvtracks_t = AllenDataHandle("device", [], "dev_pvtracks_t", "R", "PVTrack"),
    dev_zpeaks_t = AllenDataHandle("device", [], "dev_zpeaks_t", "R", "float"),
    dev_number_of_zpeaks_t = AllenDataHandle("device", [], "dev_number_of_zpeaks_t", "R", "unsigned int"),
    dev_pvtracks_denom_t = AllenDataHandle("device", [], "dev_pvtracks_denom_t", "W", "float"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "pv_beamline_calculate_denom"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/PV/beamlinePV/include/pv_beamline_calculate_denom.cuh"

  @classmethod
  def getType(cls):
    return "pv_beamline_calculate_denom_t"


class pv_beamline_cleanup_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_multi_fit_vertices_t = AllenDataHandle("device", [], "dev_multi_fit_vertices_t", "R", "unknown_t"),
    dev_number_of_multi_fit_vertices_t = AllenDataHandle("device", [], "dev_number_of_multi_fit_vertices_t", "R", "unsigned int"),
    dev_multi_final_vertices_t = AllenDataHandle("device", [], "dev_multi_final_vertices_t", "W", "unknown_t"),
    dev_number_of_multi_final_vertices_t = AllenDataHandle("device", [], "dev_number_of_multi_final_vertices_t", "W", "unsigned int"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "pv_beamline_cleanup"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/PV/beamlinePV/include/pv_beamline_cleanup.cuh"

  @classmethod
  def getType(cls):
    return "pv_beamline_cleanup_t"


class pv_beamline_extrapolate_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_reconstructed_velo_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_velo_tracks_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_velo_tracks_view_t = AllenDataHandle("device", [], "dev_velo_tracks_view_t", "R", "unknown_t"),
    dev_velo_states_view_t = AllenDataHandle("device", [], "dev_velo_states_view_t", "R", "unknown_t"),
    dev_pvtracks_t = AllenDataHandle("device", [], "dev_pvtracks_t", "W", "PVTrack"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "pv_beamline_extrapolate"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/PV/beamlinePV/include/pv_beamline_extrapolate.cuh"

  @classmethod
  def getType(cls):
    return "pv_beamline_extrapolate_t"


class pv_beamline_histo_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_velo_tracks_view_t = AllenDataHandle("device", [], "dev_velo_tracks_view_t", "R", "unknown_t"),
    dev_pvtracks_t = AllenDataHandle("device", [], "dev_pvtracks_t", "R", "PVTrack"),
    dev_zhisto_t = AllenDataHandle("device", [], "dev_zhisto_t", "W", "float"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "pv_beamline_histo"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/PV/beamlinePV/include/pv_beamline_histo.cuh"

  @classmethod
  def getType(cls):
    return "pv_beamline_histo_t"


class pv_beamline_multi_fitter_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_reconstructed_velo_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_velo_tracks_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_velo_tracks_view_t = AllenDataHandle("device", [], "dev_velo_tracks_view_t", "R", "unknown_t"),
    dev_pvtracks_t = AllenDataHandle("device", [], "dev_pvtracks_t", "R", "PVTrack"),
    dev_pvtracks_denom_t = AllenDataHandle("device", [], "dev_pvtracks_denom_t", "R", "float"),
    dev_zpeaks_t = AllenDataHandle("device", [], "dev_zpeaks_t", "R", "float"),
    dev_number_of_zpeaks_t = AllenDataHandle("device", [], "dev_number_of_zpeaks_t", "R", "unsigned int"),
    dev_multi_fit_vertices_t = AllenDataHandle("device", [], "dev_multi_fit_vertices_t", "W", "unknown_t"),
    dev_number_of_multi_fit_vertices_t = AllenDataHandle("device", [], "dev_number_of_multi_fit_vertices_t", "W", "unsigned int"),
    verbosity = "",
    block_dim_y = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "pv_beamline_multi_fitter"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/PV/beamlinePV/include/pv_beamline_multi_fitter.cuh"

  @classmethod
  def getType(cls):
    return "pv_beamline_multi_fitter_t"


class pv_beamline_peak_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_zhisto_t = AllenDataHandle("device", [], "dev_zhisto_t", "R", "float"),
    dev_zpeaks_t = AllenDataHandle("device", [], "dev_zpeaks_t", "W", "float"),
    dev_number_of_zpeaks_t = AllenDataHandle("device", [], "dev_number_of_zpeaks_t", "W", "unsigned int"),
    verbosity = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "pv_beamline_peak"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/PV/beamlinePV/include/pv_beamline_peak.cuh"

  @classmethod
  def getType(cls):
    return "pv_beamline_peak_t"


class scifi_consolidate_tracks_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_accumulated_number_of_hits_in_scifi_tracks_t = AllenDataHandle("host", [], "host_accumulated_number_of_hits_in_scifi_tracks_t", "R", "unsigned int"),
    host_number_of_reconstructed_scifi_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_scifi_tracks_t", "R", "unsigned int"),
    dev_velo_states_view_t = AllenDataHandle("device", [], "dev_velo_states_view_t", "R", "unknown_t"),
    dev_velo_tracks_view_t = AllenDataHandle("device", [], "dev_velo_tracks_view_t", "R", "unknown_t"),
    dev_ut_tracks_view_t = AllenDataHandle("device", [], "dev_ut_tracks_view_t", "R", "unknown_t"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_scifi_hits_t = AllenDataHandle("device", [], "dev_scifi_hits_t", "R", "char"),
    dev_scifi_hit_offsets_t = AllenDataHandle("device", [], "dev_scifi_hit_offsets_t", "R", "unsigned int"),
    dev_offsets_forward_tracks_t = AllenDataHandle("device", [], "dev_offsets_forward_tracks_t", "R", "unsigned int"),
    dev_offsets_scifi_track_hit_number_t = AllenDataHandle("device", [], "dev_offsets_scifi_track_hit_number_t", "R", "unsigned int"),
    dev_scifi_tracks_t = AllenDataHandle("device", [], "dev_scifi_tracks_t", "R", "unknown_t"),
    dev_scifi_lf_parametrization_consolidate_t = AllenDataHandle("device", [], "dev_scifi_lf_parametrization_consolidate_t", "R", "float"),
    dev_scifi_track_hits_t = AllenDataHandle("device", [], "dev_scifi_track_hits_t", "W", "char"),
    dev_scifi_qop_t = AllenDataHandle("device", [], "dev_scifi_qop_t", "W", "float"),
    dev_scifi_states_t = AllenDataHandle("device", [], "dev_scifi_states_t", "W", "unknown_t"),
    dev_scifi_track_ut_indices_t = AllenDataHandle("device", [], "dev_scifi_track_ut_indices_t", "W", "unsigned int"),
    dev_scifi_hits_view_t = AllenDataHandle("device", ["dev_scifi_track_hits_t"], "dev_scifi_hits_view_t", "W", "unknown_t"),
    dev_scifi_track_view_t = AllenDataHandle("device", ["dev_scifi_hits_view_t", "dev_ut_tracks_view_t", "dev_scifi_qop_t"], "dev_scifi_track_view_t", "W", "unknown_t"),
    dev_scifi_tracks_view_t = AllenDataHandle("device", ["dev_scifi_track_view_t"], "dev_scifi_tracks_view_t", "W", "unknown_t"),
    dev_scifi_multi_event_tracks_view_t = AllenDataHandle("device", ["dev_scifi_tracks_view_t"], "dev_scifi_multi_event_tracks_view_t", "W", "unknown_t"),
    dev_long_track_view_t = AllenDataHandle("device", ["dev_scifi_multi_event_tracks_view_t", "dev_ut_tracks_view_t"], "dev_long_track_view_t", "W", "unknown_t"),
    dev_long_tracks_view_t = AllenDataHandle("device", ["dev_long_track_view_t"], "dev_long_tracks_view_t", "W", "unknown_t"),
    dev_multi_event_long_tracks_view_t = AllenDataHandle("device", ["dev_long_tracks_view_t"], "dev_multi_event_long_tracks_view_t", "W", "unknown_t"),
    dev_multi_event_long_tracks_ptr_t = AllenDataHandle("device", ["dev_multi_event_long_tracks_view_t"], "dev_multi_event_long_tracks_ptr_t", "W", "unknown_t"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "scifi_consolidate_tracks"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/SciFi/consolidate/include/ConsolidateSciFi.cuh"

  @classmethod
  def getType(cls):
    return "scifi_consolidate_tracks_t"


class scifi_copy_track_hit_number_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_reconstructed_scifi_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_scifi_tracks_t", "R", "unsigned int"),
    dev_offsets_ut_tracks_t = AllenDataHandle("device", [], "dev_offsets_ut_tracks_t", "R", "unsigned int"),
    dev_scifi_tracks_t = AllenDataHandle("device", [], "dev_scifi_tracks_t", "R", "unknown_t"),
    dev_offsets_forward_tracks_t = AllenDataHandle("device", [], "dev_offsets_forward_tracks_t", "R", "unsigned int"),
    dev_scifi_track_hit_number_t = AllenDataHandle("device", [], "dev_scifi_track_hit_number_t", "W", "unsigned int"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "scifi_copy_track_hit_number"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/SciFi/consolidate/include/SciFiCopyTrackHitNumber.cuh"

  @classmethod
  def getType(cls):
    return "scifi_copy_track_hit_number_t"


class lf_create_tracks_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_reconstructed_ut_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_ut_tracks_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_scifi_lf_initial_windows_t = AllenDataHandle("device", [], "dev_scifi_lf_initial_windows_t", "R", "unknown_t"),
    dev_scifi_lf_process_track_t = AllenDataHandle("device", [], "dev_scifi_lf_process_track_t", "R", "bool"),
    dev_scifi_lf_found_triplets_t = AllenDataHandle("device", [], "dev_scifi_lf_found_triplets_t", "R", "unknown_t"),
    dev_scifi_lf_number_of_found_triplets_t = AllenDataHandle("device", [], "dev_scifi_lf_number_of_found_triplets_t", "R", "unknown_t"),
    dev_scifi_hits_t = AllenDataHandle("device", [], "dev_scifi_hits_t", "R", "char"),
    dev_scifi_hit_offsets_t = AllenDataHandle("device", [], "dev_scifi_hit_offsets_t", "R", "unsigned int"),
    dev_velo_tracks_view_t = AllenDataHandle("device", [], "dev_velo_tracks_view_t", "R", "unknown_t"),
    dev_velo_states_view_t = AllenDataHandle("device", [], "dev_velo_states_view_t", "R", "unknown_t"),
    dev_ut_tracks_view_t = AllenDataHandle("device", [], "dev_ut_tracks_view_t", "R", "unknown_t"),
    dev_ut_states_t = AllenDataHandle("device", [], "dev_ut_states_t", "R", "unknown_t"),
    dev_scifi_lf_tracks_t = AllenDataHandle("device", [], "dev_scifi_lf_tracks_t", "W", "unknown_t"),
    dev_scifi_lf_atomics_t = AllenDataHandle("device", [], "dev_scifi_lf_atomics_t", "W", "unsigned int"),
    dev_scifi_lf_total_number_of_found_triplets_t = AllenDataHandle("device", [], "dev_scifi_lf_total_number_of_found_triplets_t", "W", "unsigned int"),
    dev_scifi_lf_parametrization_t = AllenDataHandle("device", [], "dev_scifi_lf_parametrization_t", "W", "float"),
    verbosity = "",
    triplet_keep_best_block_dim = "",
    calculate_parametrization_block_dim = "",
    extend_tracks_block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "lf_create_tracks"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/SciFi/looking_forward/include/LFCreateTracks.cuh"

  @classmethod
  def getType(cls):
    return "lf_create_tracks_t"


class lf_least_mean_square_fit_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    dev_scifi_hits_t = AllenDataHandle("device", [], "dev_scifi_hits_t", "R", "char"),
    dev_scifi_hit_count_t = AllenDataHandle("device", [], "dev_scifi_hit_count_t", "R", "unsigned int"),
    dev_atomics_ut_t = AllenDataHandle("device", [], "dev_atomics_ut_t", "R", "unsigned int"),
    dev_scifi_tracks_t = AllenDataHandle("device", [], "dev_scifi_tracks_t", "W", "unknown_t"),
    dev_atomics_scifi_t = AllenDataHandle("device", [], "dev_atomics_scifi_t", "R", "unsigned int"),
    dev_scifi_lf_parametrization_x_filter_t = AllenDataHandle("device", [], "dev_scifi_lf_parametrization_x_filter_t", "W", "float"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "lf_least_mean_square_fit"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/SciFi/looking_forward/include/LFLeastMeanSquareFit.cuh"

  @classmethod
  def getType(cls):
    return "lf_least_mean_square_fit_t"


class lf_quality_filter_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_reconstructed_ut_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_ut_tracks_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_scifi_hits_t = AllenDataHandle("device", [], "dev_scifi_hits_t", "R", "char"),
    dev_scifi_hit_offsets_t = AllenDataHandle("device", [], "dev_scifi_hit_offsets_t", "R", "unsigned int"),
    dev_ut_tracks_view_t = AllenDataHandle("device", [], "dev_ut_tracks_view_t", "R", "unknown_t"),
    dev_scifi_lf_length_filtered_tracks_t = AllenDataHandle("device", [], "dev_scifi_lf_length_filtered_tracks_t", "R", "unknown_t"),
    dev_scifi_lf_length_filtered_atomics_t = AllenDataHandle("device", [], "dev_scifi_lf_length_filtered_atomics_t", "R", "unsigned int"),
    dev_scifi_lf_parametrization_length_filter_t = AllenDataHandle("device", [], "dev_scifi_lf_parametrization_length_filter_t", "R", "float"),
    dev_ut_states_t = AllenDataHandle("device", [], "dev_ut_states_t", "R", "unknown_t"),
    dev_lf_quality_of_tracks_t = AllenDataHandle("device", [], "dev_lf_quality_of_tracks_t", "W", "float"),
    dev_atomics_scifi_t = AllenDataHandle("device", [], "dev_atomics_scifi_t", "W", "unsigned int"),
    dev_scifi_tracks_t = AllenDataHandle("device", [], "dev_scifi_tracks_t", "W", "unknown_t"),
    dev_scifi_lf_y_parametrization_length_filter_t = AllenDataHandle("device", [], "dev_scifi_lf_y_parametrization_length_filter_t", "W", "float"),
    dev_scifi_lf_parametrization_consolidate_t = AllenDataHandle("device", [], "dev_scifi_lf_parametrization_consolidate_t", "W", "float"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "lf_quality_filter"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/SciFi/looking_forward/include/LFQualityFilter.cuh"

  @classmethod
  def getType(cls):
    return "lf_quality_filter_t"


class lf_quality_filter_length_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_reconstructed_ut_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_ut_tracks_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_ut_tracks_view_t = AllenDataHandle("device", [], "dev_ut_tracks_view_t", "R", "unknown_t"),
    dev_scifi_lf_tracks_t = AllenDataHandle("device", [], "dev_scifi_lf_tracks_t", "R", "unknown_t"),
    dev_scifi_lf_atomics_t = AllenDataHandle("device", [], "dev_scifi_lf_atomics_t", "R", "unsigned int"),
    dev_scifi_lf_parametrization_t = AllenDataHandle("device", [], "dev_scifi_lf_parametrization_t", "R", "float"),
    dev_scifi_lf_length_filtered_tracks_t = AllenDataHandle("device", [], "dev_scifi_lf_length_filtered_tracks_t", "W", "unknown_t"),
    dev_scifi_lf_length_filtered_atomics_t = AllenDataHandle("device", [], "dev_scifi_lf_length_filtered_atomics_t", "W", "unsigned int"),
    dev_scifi_lf_parametrization_length_filter_t = AllenDataHandle("device", [], "dev_scifi_lf_parametrization_length_filter_t", "W", "float"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "lf_quality_filter_length"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/SciFi/looking_forward/include/LFQualityFilterLength.cuh"

  @classmethod
  def getType(cls):
    return "lf_quality_filter_length_t"


class lf_search_initial_windows_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_reconstructed_ut_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_ut_tracks_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_scifi_hits_t = AllenDataHandle("device", [], "dev_scifi_hits_t", "R", "char"),
    dev_scifi_hit_offsets_t = AllenDataHandle("device", [], "dev_scifi_hit_offsets_t", "R", "unsigned int"),
    dev_ut_tracks_view_t = AllenDataHandle("device", [], "dev_ut_tracks_view_t", "R", "unknown_t"),
    dev_velo_states_view_t = AllenDataHandle("device", [], "dev_velo_states_view_t", "R", "unknown_t"),
    dev_velo_tracks_view_t = AllenDataHandle("device", [], "dev_velo_tracks_view_t", "R", "unknown_t"),
    dev_scifi_lf_initial_windows_t = AllenDataHandle("device", [], "dev_scifi_lf_initial_windows_t", "W", "unknown_t"),
    dev_ut_states_t = AllenDataHandle("device", [], "dev_ut_states_t", "W", "unknown_t"),
    dev_scifi_lf_process_track_t = AllenDataHandle("device", [], "dev_scifi_lf_process_track_t", "W", "bool"),
    verbosity = "",
    hit_window_size = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "lf_search_initial_windows"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/SciFi/looking_forward/include/LFSearchInitialWindows.cuh"

  @classmethod
  def getType(cls):
    return "lf_search_initial_windows_t"


class lf_triplet_seeding_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_reconstructed_ut_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_ut_tracks_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_scifi_hits_t = AllenDataHandle("device", [], "dev_scifi_hits_t", "R", "char"),
    dev_scifi_hit_offsets_t = AllenDataHandle("device", [], "dev_scifi_hit_offsets_t", "R", "unsigned int"),
    dev_offsets_all_velo_tracks_t = AllenDataHandle("device", [], "dev_offsets_all_velo_tracks_t", "R", "unsigned int"),
    dev_velo_states_view_t = AllenDataHandle("device", [], "dev_velo_states_view_t", "R", "unknown_t"),
    dev_ut_tracks_view_t = AllenDataHandle("device", [], "dev_ut_tracks_view_t", "R", "unknown_t"),
    dev_scifi_lf_initial_windows_t = AllenDataHandle("device", [], "dev_scifi_lf_initial_windows_t", "R", "unknown_t"),
    dev_ut_states_t = AllenDataHandle("device", [], "dev_ut_states_t", "R", "unknown_t"),
    dev_scifi_lf_process_track_t = AllenDataHandle("device", [], "dev_scifi_lf_process_track_t", "R", "bool"),
    dev_scifi_lf_found_triplets_t = AllenDataHandle("device", [], "dev_scifi_lf_found_triplets_t", "W", "unknown_t"),
    dev_scifi_lf_number_of_found_triplets_t = AllenDataHandle("device", [], "dev_scifi_lf_number_of_found_triplets_t", "W", "unknown_t"),
    verbosity = "",
    hit_window_size = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "lf_triplet_seeding"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/SciFi/looking_forward/include/LFTripletSeeding.cuh"

  @classmethod
  def getType(cls):
    return "lf_triplet_seeding_t"


class scifi_calculate_cluster_count_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_raw_bank_version_t = AllenDataHandle("host", [], "host_raw_bank_version_t", "R", "unknown_t"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_scifi_raw_input_t = AllenDataHandle("device", [], "dev_scifi_raw_input_t", "R", "char"),
    dev_scifi_raw_input_offsets_t = AllenDataHandle("device", [], "dev_scifi_raw_input_offsets_t", "R", "unsigned int"),
    dev_scifi_raw_input_sizes_t = AllenDataHandle("device", [], "dev_scifi_raw_input_sizes_t", "R", "unsigned int"),
    dev_scifi_hit_count_t = AllenDataHandle("device", [], "dev_scifi_hit_count_t", "W", "unsigned int"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "scifi_calculate_cluster_count"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/SciFi/preprocessing/include/SciFiCalculateClusterCount.cuh"

  @classmethod
  def getType(cls):
    return "scifi_calculate_cluster_count_t"


class scifi_pre_decode_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_raw_bank_version_t = AllenDataHandle("host", [], "host_raw_bank_version_t", "R", "unknown_t"),
    host_accumulated_number_of_scifi_hits_t = AllenDataHandle("host", [], "host_accumulated_number_of_scifi_hits_t", "R", "unsigned int"),
    dev_scifi_raw_input_t = AllenDataHandle("device", [], "dev_scifi_raw_input_t", "R", "char"),
    dev_scifi_raw_input_offsets_t = AllenDataHandle("device", [], "dev_scifi_raw_input_offsets_t", "R", "unsigned int"),
    dev_scifi_raw_input_sizes_t = AllenDataHandle("device", [], "dev_scifi_raw_input_sizes_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_scifi_hit_offsets_t = AllenDataHandle("device", [], "dev_scifi_hit_offsets_t", "R", "unsigned int"),
    dev_cluster_references_t = AllenDataHandle("device", [], "dev_cluster_references_t", "W", "unsigned int"),
    verbosity = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "scifi_pre_decode"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/SciFi/preprocessing/include/SciFiPreDecode.cuh"

  @classmethod
  def getType(cls):
    return "scifi_pre_decode_t"


class scifi_raw_bank_decoder_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_raw_bank_version_t = AllenDataHandle("host", [], "host_raw_bank_version_t", "R", "unknown_t"),
    host_accumulated_number_of_scifi_hits_t = AllenDataHandle("host", [], "host_accumulated_number_of_scifi_hits_t", "R", "unsigned int"),
    dev_scifi_raw_input_t = AllenDataHandle("device", [], "dev_scifi_raw_input_t", "R", "char"),
    dev_scifi_raw_input_offsets_t = AllenDataHandle("device", [], "dev_scifi_raw_input_offsets_t", "R", "unsigned int"),
    dev_scifi_raw_input_sizes_t = AllenDataHandle("device", [], "dev_scifi_raw_input_sizes_t", "R", "unsigned int"),
    dev_scifi_hit_offsets_t = AllenDataHandle("device", [], "dev_scifi_hit_offsets_t", "R", "unsigned int"),
    dev_cluster_references_t = AllenDataHandle("device", [], "dev_cluster_references_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_scifi_hits_t = AllenDataHandle("device", [], "dev_scifi_hits_t", "W", "char"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "scifi_raw_bank_decoder"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/SciFi/preprocessing/include/SciFiRawBankDecoder.cuh"

  @classmethod
  def getType(cls):
    return "scifi_raw_bank_decoder_t"


class ut_calculate_number_of_hits_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_raw_bank_version_t = AllenDataHandle("host", [], "host_raw_bank_version_t", "R", "unknown_t"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_ut_raw_input_t = AllenDataHandle("device", [], "dev_ut_raw_input_t", "R", "char"),
    dev_ut_raw_input_offsets_t = AllenDataHandle("device", [], "dev_ut_raw_input_offsets_t", "R", "unsigned int"),
    dev_ut_raw_input_sizes_t = AllenDataHandle("device", [], "dev_ut_raw_input_sizes_t", "R", "unsigned int"),
    dev_ut_hit_sizes_t = AllenDataHandle("device", [], "dev_ut_hit_sizes_t", "W", "unsigned int"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "ut_calculate_number_of_hits"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/UT/UTDecoding/include/UTCalculateNumberOfHits.cuh"

  @classmethod
  def getType(cls):
    return "ut_calculate_number_of_hits_t"


class ut_decode_raw_banks_in_order_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_accumulated_number_of_ut_hits_t = AllenDataHandle("host", [], "host_accumulated_number_of_ut_hits_t", "R", "unsigned int"),
    host_raw_bank_version_t = AllenDataHandle("host", [], "host_raw_bank_version_t", "R", "unknown_t"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_ut_raw_input_t = AllenDataHandle("device", [], "dev_ut_raw_input_t", "R", "char"),
    dev_ut_raw_input_offsets_t = AllenDataHandle("device", [], "dev_ut_raw_input_offsets_t", "R", "unsigned int"),
    dev_ut_raw_input_sizes_t = AllenDataHandle("device", [], "dev_ut_raw_input_sizes_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_ut_hit_offsets_t = AllenDataHandle("device", [], "dev_ut_hit_offsets_t", "R", "unsigned int"),
    dev_ut_pre_decoded_hits_t = AllenDataHandle("device", [], "dev_ut_pre_decoded_hits_t", "R", "char"),
    dev_ut_hits_t = AllenDataHandle("device", [], "dev_ut_hits_t", "W", "char"),
    dev_ut_hit_permutations_t = AllenDataHandle("device", [], "dev_ut_hit_permutations_t", "R", "unsigned int"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "ut_decode_raw_banks_in_order"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/UT/UTDecoding/include/UTDecodeRawBanksInOrder.cuh"

  @classmethod
  def getType(cls):
    return "ut_decode_raw_banks_in_order_t"


class ut_find_permutation_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_accumulated_number_of_ut_hits_t = AllenDataHandle("host", [], "host_accumulated_number_of_ut_hits_t", "R", "unsigned int"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_ut_pre_decoded_hits_t = AllenDataHandle("device", [], "dev_ut_pre_decoded_hits_t", "R", "char"),
    dev_ut_hit_offsets_t = AllenDataHandle("device", [], "dev_ut_hit_offsets_t", "R", "unsigned int"),
    dev_ut_hit_permutations_t = AllenDataHandle("device", [], "dev_ut_hit_permutations_t", "W", "unsigned int"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "ut_find_permutation"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/UT/UTDecoding/include/UTFindPermutation.cuh"

  @classmethod
  def getType(cls):
    return "ut_find_permutation_t"


class ut_pre_decode_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_accumulated_number_of_ut_hits_t = AllenDataHandle("host", [], "host_accumulated_number_of_ut_hits_t", "R", "unsigned int"),
    host_raw_bank_version_t = AllenDataHandle("host", [], "host_raw_bank_version_t", "R", "unknown_t"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_ut_raw_input_t = AllenDataHandle("device", [], "dev_ut_raw_input_t", "R", "char"),
    dev_ut_raw_input_offsets_t = AllenDataHandle("device", [], "dev_ut_raw_input_offsets_t", "R", "unsigned int"),
    dev_ut_raw_input_sizes_t = AllenDataHandle("device", [], "dev_ut_raw_input_sizes_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_ut_hit_offsets_t = AllenDataHandle("device", [], "dev_ut_hit_offsets_t", "R", "unsigned int"),
    dev_ut_pre_decoded_hits_t = AllenDataHandle("device", [], "dev_ut_pre_decoded_hits_t", "W", "char"),
    dev_ut_hit_count_t = AllenDataHandle("device", [], "dev_ut_hit_count_t", "W", "unsigned int"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "ut_pre_decode"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/UT/UTDecoding/include/UTPreDecode.cuh"

  @classmethod
  def getType(cls):
    return "ut_pre_decode_t"


class compass_ut_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_ut_hits_t = AllenDataHandle("device", [], "dev_ut_hits_t", "R", "char"),
    dev_ut_hit_offsets_t = AllenDataHandle("device", [], "dev_ut_hit_offsets_t", "R", "unsigned int"),
    dev_velo_tracks_view_t = AllenDataHandle("device", [], "dev_velo_tracks_view_t", "R", "unknown_t"),
    dev_velo_states_view_t = AllenDataHandle("device", [], "dev_velo_states_view_t", "R", "unknown_t"),
    dev_ut_windows_layers_t = AllenDataHandle("device", [], "dev_ut_windows_layers_t", "R", "short"),
    dev_ut_number_of_selected_velo_tracks_with_windows_t = AllenDataHandle("device", [], "dev_ut_number_of_selected_velo_tracks_with_windows_t", "R", "unsigned int"),
    dev_ut_selected_velo_tracks_with_windows_t = AllenDataHandle("device", [], "dev_ut_selected_velo_tracks_with_windows_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_ut_tracks_t = AllenDataHandle("device", [], "dev_ut_tracks_t", "W", "unknown_t"),
    dev_atomics_ut_t = AllenDataHandle("device", [], "dev_atomics_ut_t", "W", "unsigned int"),
    verbosity = "",
    sigma_velo_slope = "",
    min_momentum_final = "",
    min_pt_final = "",
    hit_tol_2 = "",
    delta_tx_2 = "",
    max_considered_before_found = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "compass_ut"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/UT/compassUT/include/CompassUT.cuh"

  @classmethod
  def getType(cls):
    return "compass_ut_t"


class ut_search_windows_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_reconstructed_velo_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_velo_tracks_t", "R", "unsigned int"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_ut_hits_t = AllenDataHandle("device", [], "dev_ut_hits_t", "R", "char"),
    dev_ut_hit_offsets_t = AllenDataHandle("device", [], "dev_ut_hit_offsets_t", "R", "unsigned int"),
    dev_velo_tracks_view_t = AllenDataHandle("device", [], "dev_velo_tracks_view_t", "R", "unknown_t"),
    dev_velo_states_view_t = AllenDataHandle("device", [], "dev_velo_states_view_t", "R", "unknown_t"),
    dev_ut_number_of_selected_velo_tracks_t = AllenDataHandle("device", [], "dev_ut_number_of_selected_velo_tracks_t", "R", "unsigned int"),
    dev_ut_selected_velo_tracks_t = AllenDataHandle("device", [], "dev_ut_selected_velo_tracks_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_ut_windows_layers_t = AllenDataHandle("device", [], "dev_ut_windows_layers_t", "W", "short"),
    verbosity = "",
    min_momentum = "",
    min_pt = "",
    y_tol = "",
    y_tol_slope = "",
    block_dim_y_t = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "ut_search_windows"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/UT/compassUT/include/SearchWindows.cuh"

  @classmethod
  def getType(cls):
    return "ut_search_windows_t"


class ut_select_velo_tracks_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_reconstructed_velo_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_velo_tracks_t", "R", "unsigned int"),
    dev_velo_tracks_view_t = AllenDataHandle("device", [], "dev_velo_tracks_view_t", "R", "unknown_t"),
    dev_velo_states_view_t = AllenDataHandle("device", [], "dev_velo_states_view_t", "R", "unknown_t"),
    dev_accepted_velo_tracks_t = AllenDataHandle("device", [], "dev_accepted_velo_tracks_t", "R", "bool"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_ut_number_of_selected_velo_tracks_t = AllenDataHandle("device", [], "dev_ut_number_of_selected_velo_tracks_t", "W", "unsigned int"),
    dev_ut_selected_velo_tracks_t = AllenDataHandle("device", [], "dev_ut_selected_velo_tracks_t", "W", "unsigned int"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "ut_select_velo_tracks"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/UT/compassUT/include/UTSelectVeloTracks.cuh"

  @classmethod
  def getType(cls):
    return "ut_select_velo_tracks_t"


class ut_select_velo_tracks_with_windows_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_reconstructed_velo_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_velo_tracks_t", "R", "unsigned int"),
    dev_velo_tracks_view_t = AllenDataHandle("device", [], "dev_velo_tracks_view_t", "R", "unknown_t"),
    dev_accepted_velo_tracks_t = AllenDataHandle("device", [], "dev_accepted_velo_tracks_t", "R", "bool"),
    dev_ut_number_of_selected_velo_tracks_t = AllenDataHandle("device", [], "dev_ut_number_of_selected_velo_tracks_t", "R", "unsigned int"),
    dev_ut_selected_velo_tracks_t = AllenDataHandle("device", [], "dev_ut_selected_velo_tracks_t", "R", "unsigned int"),
    dev_ut_windows_layers_t = AllenDataHandle("device", [], "dev_ut_windows_layers_t", "R", "short"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_ut_number_of_selected_velo_tracks_with_windows_t = AllenDataHandle("device", [], "dev_ut_number_of_selected_velo_tracks_with_windows_t", "W", "unsigned int"),
    dev_ut_selected_velo_tracks_with_windows_t = AllenDataHandle("device", [], "dev_ut_selected_velo_tracks_with_windows_t", "W", "unsigned int"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "ut_select_velo_tracks_with_windows"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/UT/compassUT/include/UTSelectVeloTracksWithWindows.cuh"

  @classmethod
  def getType(cls):
    return "ut_select_velo_tracks_with_windows_t"


class ut_consolidate_tracks_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_accumulated_number_of_ut_hits_t = AllenDataHandle("host", [], "host_accumulated_number_of_ut_hits_t", "R", "unsigned int"),
    host_number_of_reconstructed_ut_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_ut_tracks_t", "R", "unsigned int"),
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_accumulated_number_of_hits_in_ut_tracks_t = AllenDataHandle("host", [], "host_accumulated_number_of_hits_in_ut_tracks_t", "R", "unsigned int"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_ut_hits_t = AllenDataHandle("device", [], "dev_ut_hits_t", "R", "char"),
    dev_ut_hit_offsets_t = AllenDataHandle("device", [], "dev_ut_hit_offsets_t", "R", "unsigned int"),
    dev_offsets_ut_tracks_t = AllenDataHandle("device", [], "dev_offsets_ut_tracks_t", "R", "unsigned int"),
    dev_offsets_ut_track_hit_number_t = AllenDataHandle("device", [], "dev_offsets_ut_track_hit_number_t", "R", "unsigned int"),
    dev_ut_tracks_t = AllenDataHandle("device", [], "dev_ut_tracks_t", "R", "unknown_t"),
    dev_velo_tracks_view_t = AllenDataHandle("device", [], "dev_velo_tracks_view_t", "R", "unknown_t"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_ut_track_hits_t = AllenDataHandle("device", [], "dev_ut_track_hits_t", "W", "char"),
    dev_ut_track_params_t = AllenDataHandle("device", [], "dev_ut_track_params_t", "W", "float"),
    dev_ut_qop_t = AllenDataHandle("device", [], "dev_ut_qop_t", "W", "float"),
    dev_ut_track_velo_indices_t = AllenDataHandle("device", [], "dev_ut_track_velo_indices_t", "W", "unsigned int"),
    dev_ut_hits_view_t = AllenDataHandle("device", ["dev_ut_track_hits_t"], "dev_ut_hits_view_t", "W", "unknown_t"),
    dev_ut_track_view_t = AllenDataHandle("device", ["dev_ut_hits_view_t", "dev_velo_tracks_view_t", "dev_ut_track_velo_indices_t", "dev_ut_track_params_t"], "dev_ut_track_view_t", "W", "unknown_t"),
    dev_ut_tracks_view_t = AllenDataHandle("device", ["dev_ut_track_view_t"], "dev_ut_tracks_view_t", "W", "unknown_t"),
    dev_ut_multi_event_tracks_view_t = AllenDataHandle("device", ["dev_ut_tracks_view_t"], "dev_ut_multi_event_tracks_view_t", "W", "unknown_t"),
    dev_ut_multi_event_lhcb_id_container_t = AllenDataHandle("device", ["dev_ut_multi_event_tracks_view_t"], "dev_ut_multi_event_lhcb_id_container_t", "W", "unknown_t"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "ut_consolidate_tracks"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/UT/consolidate/include/ConsolidateUT.cuh"

  @classmethod
  def getType(cls):
    return "ut_consolidate_tracks_t"


class ut_copy_track_hit_number_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_reconstructed_ut_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_ut_tracks_t", "R", "unsigned int"),
    dev_ut_tracks_t = AllenDataHandle("device", [], "dev_ut_tracks_t", "R", "unknown_t"),
    dev_offsets_ut_tracks_t = AllenDataHandle("device", [], "dev_offsets_ut_tracks_t", "R", "unsigned int"),
    dev_ut_track_hit_number_t = AllenDataHandle("device", [], "dev_ut_track_hit_number_t", "W", "unsigned int"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "ut_copy_track_hit_number"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/UT/consolidate/include/UTCopyTrackHitNumber.cuh"

  @classmethod
  def getType(cls):
    return "ut_copy_track_hit_number_t"


class velo_pv_ip_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_reconstructed_velo_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_velo_tracks_t", "R", "unsigned int"),
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_offsets_all_velo_tracks_t = AllenDataHandle("device", [], "dev_offsets_all_velo_tracks_t", "R", "unsigned int"),
    dev_velo_tracks_view_t = AllenDataHandle("device", [], "dev_velo_tracks_view_t", "R", "unknown_t"),
    dev_velo_kalman_beamline_states_view_t = AllenDataHandle("device", [], "dev_velo_kalman_beamline_states_view_t", "R", "unknown_t"),
    dev_multi_final_vertices_t = AllenDataHandle("device", [], "dev_multi_final_vertices_t", "R", "unknown_t"),
    dev_number_of_multi_final_vertices_t = AllenDataHandle("device", [], "dev_number_of_multi_final_vertices_t", "R", "unsigned int"),
    dev_velo_pv_ip_t = AllenDataHandle("device", [], "dev_velo_pv_ip_t", "W", "char"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "velo_pv_ip"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/associate/include/VeloPVIP.cuh"

  @classmethod
  def getType(cls):
    return "velo_pv_ip_t"


class calo_find_clusters_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_ecal_number_of_clusters_t = AllenDataHandle("host", [], "host_ecal_number_of_clusters_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_ecal_digits_t = AllenDataHandle("device", [], "dev_ecal_digits_t", "R", "unknown_t"),
    dev_ecal_digits_offsets_t = AllenDataHandle("device", [], "dev_ecal_digits_offsets_t", "R", "unsigned int"),
    dev_ecal_seed_clusters_t = AllenDataHandle("device", [], "dev_ecal_seed_clusters_t", "R", "unknown_t"),
    dev_ecal_cluster_offsets_t = AllenDataHandle("device", [], "dev_ecal_cluster_offsets_t", "R", "unsigned int"),
    dev_ecal_clusters_t = AllenDataHandle("device", [], "dev_ecal_clusters_t", "W", "unknown_t"),
    verbosity = "",
    block_dim_x = "",
    ecal_min_adc = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "calo_find_clusters"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/calo/clustering/include/CaloFindClusters.cuh"

  @classmethod
  def getType(cls):
    return "calo_find_clusters_t"


class calo_seed_clusters_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_ecal_digits_t = AllenDataHandle("device", [], "dev_ecal_digits_t", "R", "unknown_t"),
    dev_ecal_digits_offsets_t = AllenDataHandle("device", [], "dev_ecal_digits_offsets_t", "R", "unsigned int"),
    dev_ecal_num_clusters_t = AllenDataHandle("device", [], "dev_ecal_num_clusters_t", "W", "unsigned int"),
    dev_ecal_seed_clusters_t = AllenDataHandle("device", [], "dev_ecal_seed_clusters_t", "W", "unknown_t"),
    verbosity = "",
    block_dim_x = "",
    ecal_min_adc = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "calo_seed_clusters"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/calo/clustering/include/CaloSeedClusters.cuh"

  @classmethod
  def getType(cls):
    return "calo_seed_clusters_t"


class add_electron_id_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_tracks_t = AllenDataHandle("host", [], "host_number_of_tracks_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_kf_tracks_t = AllenDataHandle("device", [], "dev_kf_tracks_t", "R", "unknown_t"),
    dev_kf_track_offsets_t = AllenDataHandle("device", [], "dev_kf_track_offsets_t", "R", "unsigned int"),
    dev_is_electron_t = AllenDataHandle("device", [], "dev_is_electron_t", "R", "bool"),
    dev_kf_tracks_with_electron_id_t = AllenDataHandle("device", [], "dev_kf_tracks_with_electron_id_t", "W", "unknown_t"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "add_electron_id"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/calo/decoding/include/AddElectronID.cuh"

  @classmethod
  def getType(cls):
    return "add_electron_id_t"


class calo_count_digits_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_ecal_num_digits_t = AllenDataHandle("device", [], "dev_ecal_num_digits_t", "W", "unsigned int"),
    verbosity = "",
    block_dim_x = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "calo_count_digits"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/calo/decoding/include/CaloCountDigits.cuh"

  @classmethod
  def getType(cls):
    return "calo_count_digits_t"


class calo_decode_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_ecal_number_of_digits_t = AllenDataHandle("host", [], "host_ecal_number_of_digits_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_ecal_raw_input_t = AllenDataHandle("device", [], "dev_ecal_raw_input_t", "R", "char"),
    dev_ecal_raw_input_offsets_t = AllenDataHandle("device", [], "dev_ecal_raw_input_offsets_t", "R", "unsigned int"),
    dev_ecal_raw_input_sizes_t = AllenDataHandle("device", [], "dev_ecal_raw_input_sizes_t", "R", "unsigned int"),
    dev_ecal_raw_input_types_t = AllenDataHandle("device", [], "dev_ecal_raw_input_types_t", "R", "unsigned int"),
    dev_ecal_digits_offsets_t = AllenDataHandle("device", [], "dev_ecal_digits_offsets_t", "R", "unsigned int"),
    dev_ecal_digits_t = AllenDataHandle("device", [], "dev_ecal_digits_t", "W", "unknown_t"),
    verbosity = "",
    block_dim_x = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "calo_decode"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/calo/decoding/include/CaloDecode.cuh"

  @classmethod
  def getType(cls):
    return "calo_decode_t"


class brem_recovery_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_reconstructed_velo_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_velo_tracks_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_offsets_all_velo_tracks_t = AllenDataHandle("device", [], "dev_offsets_all_velo_tracks_t", "R", "unsigned int"),
    dev_offsets_velo_track_hit_number_t = AllenDataHandle("device", [], "dev_offsets_velo_track_hit_number_t", "R", "unsigned int"),
    dev_velo_kalman_beamline_states_t = AllenDataHandle("device", [], "dev_velo_kalman_beamline_states_t", "R", "char"),
    dev_ecal_digits_t = AllenDataHandle("device", [], "dev_ecal_digits_t", "R", "unknown_t"),
    dev_ecal_digits_offsets_t = AllenDataHandle("device", [], "dev_ecal_digits_offsets_t", "R", "unsigned int"),
    dev_brem_E_t = AllenDataHandle("device", [], "dev_brem_E_t", "W", "float"),
    dev_brem_ET_t = AllenDataHandle("device", [], "dev_brem_ET_t", "W", "float"),
    dev_brem_inECALacc_t = AllenDataHandle("device", [], "dev_brem_inECALacc_t", "W", "bool"),
    dev_brem_ecal_digits_size_t = AllenDataHandle("device", [], "dev_brem_ecal_digits_size_t", "W", "unsigned int"),
    dev_brem_ecal_digits_t = AllenDataHandle("device", [], "dev_brem_ecal_digits_t", "W", "unknown_t"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "brem_recovery"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/calo/tools/include/BremRecovery.cuh"

  @classmethod
  def getType(cls):
    return "brem_recovery_t"


class momentum_brem_correction_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_reconstructed_scifi_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_scifi_tracks_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_kf_tracks_t = AllenDataHandle("device", [], "dev_kf_tracks_t", "R", "unknown_t"),
    dev_offsets_forward_tracks_t = AllenDataHandle("device", [], "dev_offsets_forward_tracks_t", "R", "unsigned int"),
    dev_velo_tracks_offsets_t = AllenDataHandle("device", [], "dev_velo_tracks_offsets_t", "R", "unsigned int"),
    dev_ut_tracks_velo_indices_t = AllenDataHandle("device", [], "dev_ut_tracks_velo_indices_t", "R", "unsigned int"),
    dev_ut_tracks_offsets_t = AllenDataHandle("device", [], "dev_ut_tracks_offsets_t", "R", "unsigned int"),
    dev_scifi_tracks_ut_indices_t = AllenDataHandle("device", [], "dev_scifi_tracks_ut_indices_t", "R", "unsigned int"),
    dev_brem_E_t = AllenDataHandle("device", [], "dev_brem_E_t", "R", "float"),
    dev_brem_ET_t = AllenDataHandle("device", [], "dev_brem_ET_t", "R", "float"),
    dev_brem_corrected_p_t = AllenDataHandle("device", [], "dev_brem_corrected_p_t", "W", "float"),
    dev_brem_corrected_pt_t = AllenDataHandle("device", [], "dev_brem_corrected_pt_t", "W", "float"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "momentum_brem_correction"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/calo/tools/include/MomentumBremCorrection.cuh"

  @classmethod
  def getType(cls):
    return "momentum_brem_correction_t"


class track_digit_selective_matching_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_reconstructed_scifi_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_scifi_tracks_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_offsets_forward_tracks_t = AllenDataHandle("device", [], "dev_offsets_forward_tracks_t", "R", "unsigned int"),
    dev_offsets_scifi_track_hit_number_t = AllenDataHandle("device", [], "dev_offsets_scifi_track_hit_number_t", "R", "unsigned int"),
    dev_scifi_qop_t = AllenDataHandle("device", [], "dev_scifi_qop_t", "R", "float"),
    dev_scifi_track_ut_indices_t = AllenDataHandle("device", [], "dev_scifi_track_ut_indices_t", "R", "unsigned int"),
    dev_scifi_states_t = AllenDataHandle("device", [], "dev_scifi_states_t", "R", "unknown_t"),
    dev_ecal_digits_t = AllenDataHandle("device", [], "dev_ecal_digits_t", "R", "unknown_t"),
    dev_ecal_digits_offsets_t = AllenDataHandle("device", [], "dev_ecal_digits_offsets_t", "R", "unsigned int"),
    dev_matched_ecal_energy_t = AllenDataHandle("device", [], "dev_matched_ecal_energy_t", "W", "float"),
    dev_matched_ecal_digits_size_t = AllenDataHandle("device", [], "dev_matched_ecal_digits_size_t", "W", "unsigned int"),
    dev_matched_ecal_digits_t = AllenDataHandle("device", [], "dev_matched_ecal_digits_t", "W", "unknown_t"),
    dev_track_inEcalAcc_t = AllenDataHandle("device", [], "dev_track_inEcalAcc_t", "W", "bool"),
    dev_track_Eop_t = AllenDataHandle("device", [], "dev_track_Eop_t", "W", "float"),
    dev_track_isElectron_t = AllenDataHandle("device", [], "dev_track_isElectron_t", "W", "unknown_t"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "track_digit_selective_matching"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/calo/tools/include/TrackDigitSelectiveMatching.cuh"

  @classmethod
  def getType(cls):
    return "track_digit_selective_matching_t"


class saxpy_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_offsets_all_velo_tracks_t = AllenDataHandle("device", [], "dev_offsets_all_velo_tracks_t", "R", "unsigned int"),
    dev_offsets_velo_track_hit_number_t = AllenDataHandle("device", [], "dev_offsets_velo_track_hit_number_t", "R", "unsigned int"),
    dev_saxpy_output_t = AllenDataHandle("device", [], "dev_saxpy_output_t", "W", "float"),
    verbosity = "",
    saxpy_scale_factor = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "saxpy"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/example/include/SAXPY_example.cuh"

  @classmethod
  def getType(cls):
    return "saxpy_t"


class make_lepton_id_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_scifi_tracks_t = AllenDataHandle("host", [], "host_number_of_scifi_tracks_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_scifi_tracks_view_t = AllenDataHandle("device", [], "dev_scifi_tracks_view_t", "R", "unknown_t"),
    dev_is_muon_t = AllenDataHandle("device", [], "dev_is_muon_t", "R", "unknown_t"),
    dev_is_electron_t = AllenDataHandle("device", [], "dev_is_electron_t", "R", "unknown_t"),
    dev_lepton_id_t = AllenDataHandle("device", [], "dev_lepton_id_t", "W", "unknown_t"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "make_lepton_id"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/kalman/ParKalman/include/MakeLeptonID.cuh"

  @classmethod
  def getType(cls):
    return "make_lepton_id_t"


class make_long_track_particles_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_reconstructed_scifi_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_scifi_tracks_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_offsets_forward_tracks_t = AllenDataHandle("device", [], "dev_offsets_forward_tracks_t", "R", "unsigned int"),
    dev_lepton_id_t = AllenDataHandle("device", [], "dev_lepton_id_t", "R", "unknown_t"),
    dev_multi_final_vertices_t = AllenDataHandle("device", [], "dev_multi_final_vertices_t", "R", "unknown_t"),
    dev_kalman_states_view_t = AllenDataHandle("device", [], "dev_kalman_states_view_t", "R", "unknown_t"),
    dev_kalman_pv_tables_t = AllenDataHandle("device", [], "dev_kalman_pv_tables_t", "R", "unknown_t"),
    dev_multi_event_long_tracks_t = AllenDataHandle("device", [], "dev_multi_event_long_tracks_t", "R", "int *"),
    dev_long_track_particle_view_t = AllenDataHandle("device", ["dev_multi_event_long_tracks_t", "dev_kalman_states_view_t", "dev_multi_final_vertices_t", "dev_kalman_pv_tables_t", "dev_lepton_id_t"], "dev_long_track_particle_view_t", "W", "unknown_t"),
    dev_long_track_particles_view_t = AllenDataHandle("device", ["dev_long_track_particle_view_t"], "dev_long_track_particles_view_t", "W", "unknown_t"),
    dev_multi_event_basic_particles_view_t = AllenDataHandle("device", ["dev_long_track_particles_view_t"], "dev_multi_event_basic_particles_view_t", "W", "unknown_t"),
    dev_multi_event_container_basic_particles_t = AllenDataHandle("device", ["dev_multi_event_basic_particles_view_t"], "dev_multi_event_container_basic_particles_t", "W", "unknown_t"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "make_long_track_particles"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/kalman/ParKalman/include/MakeLongTrackParticles.cuh"

  @classmethod
  def getType(cls):
    return "make_long_track_particles_t"


class package_kalman_tracks_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_reconstructed_scifi_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_scifi_tracks_t", "R", "unsigned int"),
    dev_atomics_velo_t = AllenDataHandle("device", [], "dev_atomics_velo_t", "R", "unsigned int"),
    dev_velo_track_hit_number_t = AllenDataHandle("device", [], "dev_velo_track_hit_number_t", "R", "unsigned int"),
    dev_atomics_ut_t = AllenDataHandle("device", [], "dev_atomics_ut_t", "R", "unsigned int"),
    dev_ut_track_hit_number_t = AllenDataHandle("device", [], "dev_ut_track_hit_number_t", "R", "unsigned int"),
    dev_ut_qop_t = AllenDataHandle("device", [], "dev_ut_qop_t", "R", "float"),
    dev_ut_track_velo_indices_t = AllenDataHandle("device", [], "dev_ut_track_velo_indices_t", "R", "unsigned int"),
    dev_atomics_scifi_t = AllenDataHandle("device", [], "dev_atomics_scifi_t", "R", "unsigned int"),
    dev_scifi_track_hit_number_t = AllenDataHandle("device", [], "dev_scifi_track_hit_number_t", "R", "unsigned int"),
    dev_scifi_qop_t = AllenDataHandle("device", [], "dev_scifi_qop_t", "R", "float"),
    dev_scifi_states_t = AllenDataHandle("device", [], "dev_scifi_states_t", "R", "unknown_t"),
    dev_scifi_track_ut_indices_t = AllenDataHandle("device", [], "dev_scifi_track_ut_indices_t", "R", "unsigned int"),
    dev_velo_kalman_beamline_states_t = AllenDataHandle("device", [], "dev_velo_kalman_beamline_states_t", "R", "char"),
    dev_is_muon_t = AllenDataHandle("device", [], "dev_is_muon_t", "R", "bool"),
    dev_kf_tracks_t = AllenDataHandle("device", [], "dev_kf_tracks_t", "W", "unknown_t"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "package_kalman_tracks"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/kalman/ParKalman/include/PackageKalman.cuh"

  @classmethod
  def getType(cls):
    return "package_kalman_tracks_t"


class package_mf_tracks_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_mf_tracks_t = AllenDataHandle("host", [], "host_number_of_mf_tracks_t", "R", "unsigned int"),
    host_selected_events_mf_t = AllenDataHandle("host", [], "host_selected_events_mf_t", "W", "unsigned int"),
    dev_offsets_all_velo_tracks_t = AllenDataHandle("device", [], "dev_offsets_all_velo_tracks_t", "R", "unsigned int"),
    dev_offsets_velo_track_hit_number_t = AllenDataHandle("device", [], "dev_offsets_velo_track_hit_number_t", "R", "unsigned int"),
    dev_offsets_ut_tracks_t = AllenDataHandle("device", [], "dev_offsets_ut_tracks_t", "R", "unsigned int"),
    dev_offsets_ut_track_hit_number_t = AllenDataHandle("device", [], "dev_offsets_ut_track_hit_number_t", "R", "unsigned int"),
    dev_ut_qop_t = AllenDataHandle("device", [], "dev_ut_qop_t", "R", "float"),
    dev_ut_track_velo_indices_t = AllenDataHandle("device", [], "dev_ut_track_velo_indices_t", "R", "unsigned int"),
    dev_velo_kalman_beamline_states_t = AllenDataHandle("device", [], "dev_velo_kalman_beamline_states_t", "R", "char"),
    dev_match_upstream_muon_t = AllenDataHandle("device", [], "dev_match_upstream_muon_t", "R", "bool"),
    dev_event_list_mf_t = AllenDataHandle("device", [], "dev_event_list_mf_t", "R", "unsigned int"),
    dev_mf_track_offsets_t = AllenDataHandle("device", [], "dev_mf_track_offsets_t", "R", "unsigned int"),
    dev_mf_tracks_t = AllenDataHandle("device", [], "dev_mf_tracks_t", "W", "unknown_t"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "package_mf_tracks"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/kalman/ParKalman/include/PackageMFTracks.cuh"

  @classmethod
  def getType(cls):
    return "package_mf_tracks_t"


class kalman_filter_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_reconstructed_scifi_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_scifi_tracks_t", "R", "unsigned int"),
    dev_atomics_velo_t = AllenDataHandle("device", [], "dev_atomics_velo_t", "R", "unsigned int"),
    dev_velo_track_hit_number_t = AllenDataHandle("device", [], "dev_velo_track_hit_number_t", "R", "unsigned int"),
    dev_velo_track_hits_t = AllenDataHandle("device", [], "dev_velo_track_hits_t", "R", "char"),
    dev_atomics_ut_t = AllenDataHandle("device", [], "dev_atomics_ut_t", "R", "unsigned int"),
    dev_ut_track_hit_number_t = AllenDataHandle("device", [], "dev_ut_track_hit_number_t", "R", "unsigned int"),
    dev_ut_track_hits_t = AllenDataHandle("device", [], "dev_ut_track_hits_t", "R", "char"),
    dev_ut_qop_t = AllenDataHandle("device", [], "dev_ut_qop_t", "R", "float"),
    dev_ut_track_velo_indices_t = AllenDataHandle("device", [], "dev_ut_track_velo_indices_t", "R", "unsigned int"),
    dev_atomics_scifi_t = AllenDataHandle("device", [], "dev_atomics_scifi_t", "R", "unsigned int"),
    dev_scifi_track_hit_number_t = AllenDataHandle("device", [], "dev_scifi_track_hit_number_t", "R", "unsigned int"),
    dev_scifi_track_hits_t = AllenDataHandle("device", [], "dev_scifi_track_hits_t", "R", "char"),
    dev_scifi_qop_t = AllenDataHandle("device", [], "dev_scifi_qop_t", "R", "float"),
    dev_scifi_states_t = AllenDataHandle("device", [], "dev_scifi_states_t", "R", "unknown_t"),
    dev_scifi_track_ut_indices_t = AllenDataHandle("device", [], "dev_scifi_track_ut_indices_t", "R", "unsigned int"),
    dev_kf_tracks_t = AllenDataHandle("device", [], "dev_kf_tracks_t", "W", "unknown_t"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "kalman_filter"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/kalman/ParKalman/include/ParKalmanFilter.cuh"

  @classmethod
  def getType(cls):
    return "kalman_filter_t"


class kalman_velo_only_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_reconstructed_scifi_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_scifi_tracks_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_scifi_tracks_view_t = AllenDataHandle("device", [], "dev_scifi_tracks_view_t", "R", "unknown_t"),
    dev_offsets_forward_tracks_t = AllenDataHandle("device", [], "dev_offsets_forward_tracks_t", "R", "unsigned int"),
    dev_multi_final_vertices_t = AllenDataHandle("device", [], "dev_multi_final_vertices_t", "R", "unknown_t"),
    dev_number_of_multi_final_vertices_t = AllenDataHandle("device", [], "dev_number_of_multi_final_vertices_t", "R", "unsigned int"),
    dev_is_muon_t = AllenDataHandle("device", [], "dev_is_muon_t", "R", "bool"),
    dev_kf_tracks_t = AllenDataHandle("device", [], "dev_kf_tracks_t", "W", "unknown_t"),
    dev_kalman_pv_ipchi2_t = AllenDataHandle("device", [], "dev_kalman_pv_ipchi2_t", "W", "char"),
    dev_kalman_fit_results_t = AllenDataHandle("device", [], "dev_kalman_fit_results_t", "W", "char"),
    dev_kalman_states_view_t = AllenDataHandle("device", ["dev_kalman_fit_results_t"], "dev_kalman_states_view_t", "W", "unknown_t"),
    dev_kalman_pv_tables_t = AllenDataHandle("device", ["dev_kalman_pv_ipchi2_t"], "dev_kalman_pv_tables_t", "W", "unknown_t"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "kalman_velo_only"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/kalman/ParKalman/include/ParKalmanVeloOnly.cuh"

  @classmethod
  def getType(cls):
    return "kalman_velo_only_t"


class muon_catboost_evaluator_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_reconstructed_scifi_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_scifi_tracks_t", "R", "unsigned int"),
    dev_muon_catboost_features_t = AllenDataHandle("device", [], "dev_muon_catboost_features_t", "R", "float"),
    dev_muon_catboost_output_t = AllenDataHandle("device", [], "dev_muon_catboost_output_t", "W", "float"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "muon_catboost_evaluator"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/muon/classification/include/MuonCatboostEvaluator.cuh"

  @classmethod
  def getType(cls):
    return "muon_catboost_evaluator_t"


class muon_add_coords_crossing_maps_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_muon_total_number_of_tiles_t = AllenDataHandle("host", [], "host_muon_total_number_of_tiles_t", "R", "unsigned int"),
    dev_storage_station_region_quarter_offsets_t = AllenDataHandle("device", [], "dev_storage_station_region_quarter_offsets_t", "R", "unsigned int"),
    dev_storage_tile_id_t = AllenDataHandle("device", [], "dev_storage_tile_id_t", "R", "unsigned int"),
    dev_muon_raw_to_hits_t = AllenDataHandle("device", [], "dev_muon_raw_to_hits_t", "R", "unknown_t"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_atomics_index_insert_t = AllenDataHandle("device", [], "dev_atomics_index_insert_t", "W", "unsigned int"),
    dev_muon_compact_hit_t = AllenDataHandle("device", [], "dev_muon_compact_hit_t", "W", "unknown_t"),
    dev_muon_tile_used_t = AllenDataHandle("device", [], "dev_muon_tile_used_t", "W", "bool"),
    dev_station_ocurrences_sizes_t = AllenDataHandle("device", [], "dev_station_ocurrences_sizes_t", "W", "unsigned int"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "muon_add_coords_crossing_maps"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/muon/decoding/include/MuonAddCoordsCrossingMaps.cuh"

  @classmethod
  def getType(cls):
    return "muon_add_coords_crossing_maps_t"


class muon_calculate_srq_size_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_muon_raw_t = AllenDataHandle("device", [], "dev_muon_raw_t", "R", "char"),
    dev_muon_raw_offsets_t = AllenDataHandle("device", [], "dev_muon_raw_offsets_t", "R", "unsigned int"),
    dev_muon_raw_sizes_t = AllenDataHandle("device", [], "dev_muon_raw_sizes_t", "R", "unsigned int"),
    dev_muon_raw_to_hits_t = AllenDataHandle("device", [], "dev_muon_raw_to_hits_t", "W", "unknown_t"),
    dev_storage_station_region_quarter_sizes_t = AllenDataHandle("device", [], "dev_storage_station_region_quarter_sizes_t", "W", "unsigned int"),
    verbosity = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "muon_calculate_srq_size"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/muon/decoding/include/MuonCalculateSRQSize.cuh"

  @classmethod
  def getType(cls):
    return "muon_calculate_srq_size_t"


class muon_populate_hits_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_muon_total_number_of_hits_t = AllenDataHandle("host", [], "host_muon_total_number_of_hits_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_storage_tile_id_t = AllenDataHandle("device", [], "dev_storage_tile_id_t", "R", "unsigned int"),
    dev_storage_tdc_value_t = AllenDataHandle("device", [], "dev_storage_tdc_value_t", "R", "unsigned int"),
    dev_station_ocurrences_offset_t = AllenDataHandle("device", [], "dev_station_ocurrences_offset_t", "R", "unsigned int"),
    dev_muon_compact_hit_t = AllenDataHandle("device", [], "dev_muon_compact_hit_t", "R", "unknown_t"),
    dev_muon_raw_to_hits_t = AllenDataHandle("device", [], "dev_muon_raw_to_hits_t", "R", "unknown_t"),
    dev_storage_station_region_quarter_offsets_t = AllenDataHandle("device", [], "dev_storage_station_region_quarter_offsets_t", "R", "unsigned int"),
    dev_permutation_station_t = AllenDataHandle("device", [], "dev_permutation_station_t", "W", "unsigned int"),
    dev_muon_hits_t = AllenDataHandle("device", [], "dev_muon_hits_t", "W", "char"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "muon_populate_hits"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/muon/decoding/include/MuonPopulateHits.cuh"

  @classmethod
  def getType(cls):
    return "muon_populate_hits_t"


class muon_populate_tile_and_tdc_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_muon_total_number_of_tiles_t = AllenDataHandle("host", [], "host_muon_total_number_of_tiles_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_muon_raw_t = AllenDataHandle("device", [], "dev_muon_raw_t", "R", "char"),
    dev_muon_raw_offsets_t = AllenDataHandle("device", [], "dev_muon_raw_offsets_t", "R", "unsigned int"),
    dev_muon_raw_sizes_t = AllenDataHandle("device", [], "dev_muon_raw_sizes_t", "R", "unsigned int"),
    dev_muon_raw_to_hits_t = AllenDataHandle("device", [], "dev_muon_raw_to_hits_t", "R", "unknown_t"),
    dev_storage_station_region_quarter_offsets_t = AllenDataHandle("device", [], "dev_storage_station_region_quarter_offsets_t", "R", "unsigned int"),
    dev_storage_tile_id_t = AllenDataHandle("device", [], "dev_storage_tile_id_t", "W", "unsigned int"),
    dev_storage_tdc_value_t = AllenDataHandle("device", [], "dev_storage_tdc_value_t", "W", "unsigned int"),
    dev_atomics_muon_t = AllenDataHandle("device", [], "dev_atomics_muon_t", "W", "unsigned int"),
    verbosity = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "muon_populate_tile_and_tdc"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/muon/decoding/include/MuonPopulateTileAndTDC.cuh"

  @classmethod
  def getType(cls):
    return "muon_populate_tile_and_tdc_t"


class is_muon_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_reconstructed_scifi_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_scifi_tracks_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_scifi_tracks_view_t = AllenDataHandle("device", [], "dev_scifi_tracks_view_t", "R", "unknown_t"),
    dev_scifi_states_t = AllenDataHandle("device", [], "dev_scifi_states_t", "R", "unknown_t"),
    dev_station_ocurrences_offset_t = AllenDataHandle("device", [], "dev_station_ocurrences_offset_t", "R", "unsigned int"),
    dev_muon_hits_t = AllenDataHandle("device", [], "dev_muon_hits_t", "R", "char"),
    dev_is_muon_t = AllenDataHandle("device", [], "dev_is_muon_t", "W", "unknown_t"),
    verbosity = "",
    block_dim_x = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "is_muon"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/muon/is_muon/include/IsMuon.cuh"

  @classmethod
  def getType(cls):
    return "is_muon_t"


class muon_filter_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_selected_events_mf_t = AllenDataHandle("host", [], "host_selected_events_mf_t", "W", "unsigned int"),
    dev_offsets_all_velo_tracks_t = AllenDataHandle("device", [], "dev_offsets_all_velo_tracks_t", "R", "unsigned int"),
    dev_offsets_velo_track_hit_number_t = AllenDataHandle("device", [], "dev_offsets_velo_track_hit_number_t", "R", "unsigned int"),
    dev_velo_kalman_beamline_states_t = AllenDataHandle("device", [], "dev_velo_kalman_beamline_states_t", "R", "char"),
    dev_velo_track_hits_t = AllenDataHandle("device", [], "dev_velo_track_hits_t", "R", "char"),
    dev_offsets_ut_tracks_t = AllenDataHandle("device", [], "dev_offsets_ut_tracks_t", "R", "unsigned int"),
    dev_offsets_ut_track_hit_number_t = AllenDataHandle("device", [], "dev_offsets_ut_track_hit_number_t", "R", "unsigned int"),
    dev_ut_qop_t = AllenDataHandle("device", [], "dev_ut_qop_t", "R", "float"),
    dev_ut_track_velo_indices_t = AllenDataHandle("device", [], "dev_ut_track_velo_indices_t", "R", "unsigned int"),
    dev_offsets_forward_tracks_t = AllenDataHandle("device", [], "dev_offsets_forward_tracks_t", "R", "unsigned int"),
    dev_offsets_scifi_track_hit_number = AllenDataHandle("device", [], "dev_offsets_scifi_track_hit_number", "R", "unsigned int"),
    dev_scifi_qop_t = AllenDataHandle("device", [], "dev_scifi_qop_t", "R", "float"),
    dev_scifi_states_t = AllenDataHandle("device", [], "dev_scifi_states_t", "R", "unknown_t"),
    dev_scifi_track_ut_indices_t = AllenDataHandle("device", [], "dev_scifi_track_ut_indices_t", "R", "unsigned int"),
    dev_is_muon_t = AllenDataHandle("device", [], "dev_is_muon_t", "R", "bool"),
    dev_kalman_pv_ipchi2_t = AllenDataHandle("device", [], "dev_kalman_pv_ipchi2_t", "R", "char"),
    dev_mf_decisions_t = AllenDataHandle("device", [], "dev_mf_decisions_t", "W", "unsigned int"),
    dev_event_list_mf_t = AllenDataHandle("device", [], "dev_event_list_mf_t", "W", "unsigned int"),
    dev_selected_events_mf_t = AllenDataHandle("device", [], "dev_selected_events_mf_t", "W", "unsigned int"),
    dev_mf_track_atomics_t = AllenDataHandle("device", [], "dev_mf_track_atomics_t", "W", "unsigned int"),
    verbosity = "",
    mf_min_pt = "",
    mf_min_ipchi2 = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "MuonFilter"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/muon/muon_filter/include/MuonFilter.cuh"

  @classmethod
  def getType(cls):
    return "muon_filter_t"


class muon_catboost_features_extraction_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_reconstructed_scifi_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_scifi_tracks_t", "R", "unsigned int"),
    dev_atomics_scifi_t = AllenDataHandle("device", [], "dev_atomics_scifi_t", "R", "unsigned int"),
    dev_scifi_track_hit_number_t = AllenDataHandle("device", [], "dev_scifi_track_hit_number_t", "R", "unsigned int"),
    dev_scifi_qop_t = AllenDataHandle("device", [], "dev_scifi_qop_t", "R", "float"),
    dev_scifi_states_t = AllenDataHandle("device", [], "dev_scifi_states_t", "R", "unknown_t"),
    dev_scifi_track_ut_indices_t = AllenDataHandle("device", [], "dev_scifi_track_ut_indices_t", "R", "unsigned int"),
    dev_station_ocurrences_offset_t = AllenDataHandle("device", [], "dev_station_ocurrences_offset_t", "R", "unsigned int"),
    dev_muon_hits_t = AllenDataHandle("device", [], "dev_muon_hits_t", "R", "char"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_muon_catboost_features_t = AllenDataHandle("device", [], "dev_muon_catboost_features_t", "W", "float"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "muon_catboost_features_extraction"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/muon/preprocessing/include/MuonFeaturesExtraction.cuh"

  @classmethod
  def getType(cls):
    return "muon_catboost_features_extraction_t"


class dec_reporter_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_active_lines_t = AllenDataHandle("host", [], "host_number_of_active_lines_t", "R", "unsigned int"),
    dev_number_of_active_lines_t = AllenDataHandle("device", [], "dev_number_of_active_lines_t", "R", "unsigned int"),
    dev_selections_t = AllenDataHandle("device", [], "dev_selections_t", "R", "bool"),
    dev_selections_offsets_t = AllenDataHandle("device", [], "dev_selections_offsets_t", "R", "unsigned int"),
    dev_dec_reports_t = AllenDataHandle("device", [], "dev_dec_reports_t", "W", "unsigned int"),
    host_dec_reports_t = AllenDataHandle("host", [], "host_dec_reports_t", "W", "unsigned int"),
    verbosity = "",
    block_dim = "",
    tck = "",
    task_is = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "dec_reporter"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/Hlt1/include/DecReporter.cuh"

  @classmethod
  def getType(cls):
    return "dec_reporter_t"


class gather_selections_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_selections_lines_offsets_t = AllenDataHandle("host", [], "host_selections_lines_offsets_t", "W", "unsigned int"),
    host_selections_offsets_t = AllenDataHandle("host", [], "host_selections_offsets_t", "W", "unsigned int"),
    host_number_of_active_lines_t = AllenDataHandle("host", [], "host_number_of_active_lines_t", "W", "unsigned int"),
    host_names_of_active_lines_t = AllenDataHandle("host", [], "host_names_of_active_lines_t", "W", "char"),
    host_decisions_sizes_t = AllenDataHandle("host", [], "host_decisions_sizes_t", "R", "unknown_t"),
    host_input_post_scale_factors_t = AllenDataHandle("host", [], "host_input_post_scale_factors_t", "R", "unknown_t"),
    host_input_post_scale_hashes_t = AllenDataHandle("host", [], "host_input_post_scale_hashes_t", "R", "unknown_t"),
    host_fn_parameters_agg_t = AllenDataHandle("host", [], "host_fn_parameters_agg_t", "R", "unknown_t"),
    dev_fn_parameters_t = AllenDataHandle("device", [], "dev_fn_parameters_t", "W", "char"),
    host_fn_parameter_pointers_t = AllenDataHandle("host", [], "host_fn_parameter_pointers_t", "W", "char *"),
    dev_fn_parameter_pointers_t = AllenDataHandle("device", [], "dev_fn_parameter_pointers_t", "W", "char *"),
    host_fn_indices_t = AllenDataHandle("host", [], "host_fn_indices_t", "W", "unsigned int"),
    dev_fn_indices_t = AllenDataHandle("device", [], "dev_fn_indices_t", "W", "unsigned int"),
    host_fn_parameters_t = AllenDataHandle("host", [], "host_fn_parameters_t", "W", "char"),
    dev_odin_data_t = AllenDataHandle("device", [], "dev_odin_data_t", "R", "unknown_t"),
    dev_selections_t = AllenDataHandle("device", [], "dev_selections_t", "W", "bool"),
    dev_selections_lines_offsets_t = AllenDataHandle("device", [], "dev_selections_lines_offsets_t", "W", "unsigned int"),
    dev_selections_offsets_t = AllenDataHandle("device", [], "dev_selections_offsets_t", "W", "unsigned int"),
    dev_number_of_active_lines_t = AllenDataHandle("device", [], "dev_number_of_active_lines_t", "W", "unsigned int"),
    host_post_scale_factors_t = AllenDataHandle("host", [], "host_post_scale_factors_t", "W", "float"),
    host_post_scale_hashes_t = AllenDataHandle("host", [], "host_post_scale_hashes_t", "W", "unknown_t"),
    dev_post_scale_factors_t = AllenDataHandle("device", [], "dev_post_scale_factors_t", "W", "float"),
    dev_post_scale_hashes_t = AllenDataHandle("device", [], "dev_post_scale_hashes_t", "W", "unknown_t"),
    dev_particle_containers_t = AllenDataHandle("device", ["host_fn_parameters_agg_t"], "dev_particle_containers_t", "W", "unknown_t"),
    verbosity = "",
    block_dim_x = "",
    names_of_active_lines = "",
    names_of_active_line_algorithms = ""
  )
  aggregates = (
    "host_decisions_sizes_t",
    "host_input_post_scale_factors_t",
    "host_input_post_scale_hashes_t",
    "host_fn_parameters_agg_t",)

  @staticmethod
  def category():
    return AlgorithmCategory.HostAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "gather_selections"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/Hlt1/include/GatherSelections.cuh"

  @classmethod
  def getType(cls):
    return "gather_selections_t"


class global_decision_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_active_lines_t = AllenDataHandle("host", [], "host_number_of_active_lines_t", "R", "unsigned int"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_number_of_active_lines_t = AllenDataHandle("device", [], "dev_number_of_active_lines_t", "R", "unsigned int"),
    dev_dec_reports_t = AllenDataHandle("device", [], "dev_dec_reports_t", "R", "unsigned int"),
    dev_global_decision_t = AllenDataHandle("device", [], "dev_global_decision_t", "W", "bool"),
    verbosity = "",
    block_dim_x = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "global_decision"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/Hlt1/include/GlobalDecision.cuh"

  @classmethod
  def getType(cls):
    return "global_decision_t"


class make_selrep_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_selrep_size_t = AllenDataHandle("host", [], "host_selrep_size_t", "R", "unsigned int"),
    dev_selrep_offsets_t = AllenDataHandle("device", [], "dev_selrep_offsets_t", "R", "unsigned int"),
    dev_rb_objtyp_offsets_t = AllenDataHandle("device", [], "dev_rb_objtyp_offsets_t", "R", "unsigned int"),
    dev_rb_hits_offsets_t = AllenDataHandle("device", [], "dev_rb_hits_offsets_t", "R", "unsigned int"),
    dev_rb_substr_offsets_t = AllenDataHandle("device", [], "dev_rb_substr_offsets_t", "R", "unsigned int"),
    dev_rb_stdinfo_offsets_t = AllenDataHandle("device", [], "dev_rb_stdinfo_offsets_t", "R", "unsigned int"),
    dev_rb_objtyp_t = AllenDataHandle("device", [], "dev_rb_objtyp_t", "R", "unsigned int"),
    dev_rb_hits_t = AllenDataHandle("device", [], "dev_rb_hits_t", "R", "unsigned int"),
    dev_rb_substr_t = AllenDataHandle("device", [], "dev_rb_substr_t", "R", "unsigned int"),
    dev_rb_stdinfo_t = AllenDataHandle("device", [], "dev_rb_stdinfo_t", "R", "unsigned int"),
    dev_sel_reports_t = AllenDataHandle("device", [], "dev_sel_reports_t", "W", "unsigned int"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "make_selrep"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/Hlt1/include/MakeSelRep.cuh"

  @classmethod
  def getType(cls):
    return "make_selrep_t"


class make_selected_object_lists_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_active_lines_t = AllenDataHandle("host", [], "host_number_of_active_lines_t", "R", "unsigned int"),
    dev_dec_reports_t = AllenDataHandle("device", [], "dev_dec_reports_t", "R", "unsigned int"),
    dev_number_of_active_lines_t = AllenDataHandle("device", [], "dev_number_of_active_lines_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_multi_event_particle_containers_t = AllenDataHandle("device", [], "dev_multi_event_particle_containers_t", "R", "int *"),
    dev_selections_t = AllenDataHandle("device", [], "dev_selections_t", "R", "bool"),
    dev_selections_offsets_t = AllenDataHandle("device", [], "dev_selections_offsets_t", "R", "unsigned int"),
    dev_candidate_count_t = AllenDataHandle("device", [], "dev_candidate_count_t", "W", "unsigned int"),
    dev_sel_track_count_t = AllenDataHandle("device", [], "dev_sel_track_count_t", "W", "unsigned int"),
    dev_sel_track_indices_t = AllenDataHandle("device", [], "dev_sel_track_indices_t", "W", "unsigned int"),
    dev_sel_sv_count_t = AllenDataHandle("device", [], "dev_sel_sv_count_t", "W", "unsigned int"),
    dev_sel_sv_indices_t = AllenDataHandle("device", [], "dev_sel_sv_indices_t", "W", "unsigned int"),
    dev_track_duplicate_map_t = AllenDataHandle("device", [], "dev_track_duplicate_map_t", "W", "unknown_t"),
    dev_sv_duplicate_map_t = AllenDataHandle("device", [], "dev_sv_duplicate_map_t", "W", "unknown_t"),
    dev_unique_track_list_t = AllenDataHandle("device", [], "dev_unique_track_list_t", "W", "unsigned int"),
    dev_unique_sv_list_t = AllenDataHandle("device", [], "dev_unique_sv_list_t", "W", "unsigned int"),
    dev_unique_track_count_t = AllenDataHandle("device", [], "dev_unique_track_count_t", "W", "unsigned int"),
    dev_unique_sv_count_t = AllenDataHandle("device", [], "dev_unique_sv_count_t", "W", "unsigned int"),
    dev_sel_count_t = AllenDataHandle("device", [], "dev_sel_count_t", "W", "unsigned int"),
    dev_sel_list_t = AllenDataHandle("device", [], "dev_sel_list_t", "W", "unsigned int"),
    dev_hits_bank_size_t = AllenDataHandle("device", [], "dev_hits_bank_size_t", "W", "unsigned int"),
    dev_substr_bank_size_t = AllenDataHandle("device", [], "dev_substr_bank_size_t", "W", "unsigned int"),
    dev_substr_sel_size_t = AllenDataHandle("device", [], "dev_substr_sel_size_t", "W", "unsigned int"),
    dev_substr_sv_size_t = AllenDataHandle("device", [], "dev_substr_sv_size_t", "W", "unsigned int"),
    dev_stdinfo_bank_size_t = AllenDataHandle("device", [], "dev_stdinfo_bank_size_t", "W", "unsigned int"),
    dev_objtyp_bank_size_t = AllenDataHandle("device", [], "dev_objtyp_bank_size_t", "W", "unsigned int"),
    dev_selrep_size_t = AllenDataHandle("device", [], "dev_selrep_size_t", "W", "unsigned int"),
    dev_selected_basic_particle_ptrs_t = AllenDataHandle("device", ["dev_multi_event_particle_containers_t"], "dev_selected_basic_particle_ptrs_t", "W", "unknown_t"),
    dev_selected_composite_particle_ptrs_t = AllenDataHandle("device", ["dev_multi_event_particle_containers_t"], "dev_selected_composite_particle_ptrs_t", "W", "unknown_t"),
    verbosity = "",
    max_selected_tracks = "",
    max_selected_svs = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "make_selected_object_lists"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/Hlt1/include/MakeSelectedObjectLists.cuh"

  @classmethod
  def getType(cls):
    return "make_selected_object_lists_t"


class make_subbanks_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_substr_bank_size_t = AllenDataHandle("host", [], "host_substr_bank_size_t", "R", "unsigned int"),
    host_hits_bank_size_t = AllenDataHandle("host", [], "host_hits_bank_size_t", "R", "unsigned int"),
    host_objtyp_bank_size_t = AllenDataHandle("host", [], "host_objtyp_bank_size_t", "R", "unsigned int"),
    host_stdinfo_bank_size_t = AllenDataHandle("host", [], "host_stdinfo_bank_size_t", "R", "unsigned int"),
    dev_number_of_active_lines_t = AllenDataHandle("device", [], "dev_number_of_active_lines_t", "R", "unsigned int"),
    dev_dec_reports_t = AllenDataHandle("device", [], "dev_dec_reports_t", "R", "unsigned int"),
    dev_selections_t = AllenDataHandle("device", [], "dev_selections_t", "R", "bool"),
    dev_selections_offsets_t = AllenDataHandle("device", [], "dev_selections_offsets_t", "R", "unsigned int"),
    dev_sel_count_t = AllenDataHandle("device", [], "dev_sel_count_t", "R", "unsigned int"),
    dev_sel_list_t = AllenDataHandle("device", [], "dev_sel_list_t", "R", "unsigned int"),
    dev_candidate_count_t = AllenDataHandle("device", [], "dev_candidate_count_t", "R", "unsigned int"),
    dev_candidate_offsets_t = AllenDataHandle("device", [], "dev_candidate_offsets_t", "R", "unsigned int"),
    dev_unique_track_list_t = AllenDataHandle("device", [], "dev_unique_track_list_t", "R", "unsigned int"),
    dev_unique_sv_list_t = AllenDataHandle("device", [], "dev_unique_sv_list_t", "R", "unsigned int"),
    dev_unique_track_count_t = AllenDataHandle("device", [], "dev_unique_track_count_t", "R", "unsigned int"),
    dev_unique_sv_count_t = AllenDataHandle("device", [], "dev_unique_sv_count_t", "R", "unsigned int"),
    dev_track_duplicate_map_t = AllenDataHandle("device", [], "dev_track_duplicate_map_t", "R", "unknown_t"),
    dev_sv_duplicate_map_t = AllenDataHandle("device", [], "dev_sv_duplicate_map_t", "R", "unknown_t"),
    dev_sel_track_indices_t = AllenDataHandle("device", [], "dev_sel_track_indices_t", "R", "unsigned int"),
    dev_sel_sv_indices_t = AllenDataHandle("device", [], "dev_sel_sv_indices_t", "R", "unsigned int"),
    dev_multi_event_particle_containers_t = AllenDataHandle("device", [], "dev_multi_event_particle_containers_t", "R", "int *"),
    dev_basic_particle_ptrs_t = AllenDataHandle("device", [], "dev_basic_particle_ptrs_t", "R", "int *"),
    dev_composite_particle_ptrs_t = AllenDataHandle("device", [], "dev_composite_particle_ptrs_t", "R", "int *"),
    dev_rb_substr_offsets_t = AllenDataHandle("device", [], "dev_rb_substr_offsets_t", "R", "unsigned int"),
    dev_substr_sel_size_t = AllenDataHandle("device", [], "dev_substr_sel_size_t", "R", "unsigned int"),
    dev_substr_sv_size_t = AllenDataHandle("device", [], "dev_substr_sv_size_t", "R", "unsigned int"),
    dev_rb_hits_offsets_t = AllenDataHandle("device", [], "dev_rb_hits_offsets_t", "R", "unsigned int"),
    dev_rb_objtyp_offsets_t = AllenDataHandle("device", [], "dev_rb_objtyp_offsets_t", "R", "unsigned int"),
    dev_rb_stdinfo_offsets_t = AllenDataHandle("device", [], "dev_rb_stdinfo_offsets_t", "R", "unsigned int"),
    dev_rb_substr_t = AllenDataHandle("device", [], "dev_rb_substr_t", "W", "unsigned int"),
    dev_rb_hits_t = AllenDataHandle("device", [], "dev_rb_hits_t", "W", "unsigned int"),
    dev_rb_objtyp_t = AllenDataHandle("device", [], "dev_rb_objtyp_t", "W", "unsigned int"),
    dev_rb_stdinfo_t = AllenDataHandle("device", [], "dev_rb_stdinfo_t", "W", "unsigned int"),
    verbosity = "",
    max_selected_tracks = "",
    max_selected_svs = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "make_subbanks"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/Hlt1/include/MakeSubBanks.cuh"

  @classmethod
  def getType(cls):
    return "make_subbanks_t"


class d2kpi_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_svs_t = AllenDataHandle("host", [], "host_number_of_svs_t", "R", "unsigned int"),
    dev_particle_container_t = AllenDataHandle("device", [], "dev_particle_container_t", "R", "unknown_t"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", ["dev_particle_container_t"], "host_fn_parameters_t", "W", "unknown_t"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    minComboPt = "",
    maxVertexChi2 = "",
    maxDOCA = "",
    minEta = "",
    maxEta = "",
    minTrackPt = "",
    massWindow = "",
    minTrackIP = "",
    minZ = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "d2kpi_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/calibration/include/D2KPiLine.cuh"

  @classmethod
  def getType(cls):
    return "d2kpi_line_t"


class passthrough_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", [], "host_fn_parameters_t", "W", "char"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "passthrough_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/calibration/include/PassthroughLine.cuh"

  @classmethod
  def getType(cls):
    return "passthrough_line_t"


class rich_1_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_number_of_reconstructed_scifi_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_scifi_tracks_t", "R", "unsigned int"),
    dev_particle_container_t = AllenDataHandle("device", [], "dev_particle_container_t", "R", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", ["dev_particle_container_t"], "host_fn_parameters_t", "W", "unknown_t"),
    dev_decision_t = AllenDataHandle("device", [], "dev_decision_t", "W", "bool"),
    host_decision_t = AllenDataHandle("host", [], "host_decision_t", "W", "bool"),
    dev_pt_t = AllenDataHandle("device", [], "dev_pt_t", "W", "float"),
    host_pt_t = AllenDataHandle("host", [], "host_pt_t", "W", "float"),
    dev_p_t = AllenDataHandle("device", [], "dev_p_t", "W", "float"),
    host_p_t = AllenDataHandle("host", [], "host_p_t", "W", "float"),
    dev_track_chi2_t = AllenDataHandle("device", [], "dev_track_chi2_t", "W", "float"),
    host_track_chi2_t = AllenDataHandle("host", [], "host_track_chi2_t", "W", "float"),
    dev_eta_t = AllenDataHandle("device", [], "dev_eta_t", "W", "float"),
    host_eta_t = AllenDataHandle("host", [], "host_eta_t", "W", "float"),
    dev_phi_t = AllenDataHandle("device", [], "dev_phi_t", "W", "float"),
    host_phi_t = AllenDataHandle("host", [], "host_phi_t", "W", "float"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    minPt = "",
    minP = "",
    maxTrChi2 = "",
    minEta = "",
    maxEta = "",
    minPhi = "",
    maxPhi = "",
    enable_monitoring = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "rich_1_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/calibration/include/RICH1Line.cuh"

  @classmethod
  def getType(cls):
    return "rich_1_line_t"


class rich_2_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_number_of_reconstructed_scifi_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_scifi_tracks_t", "R", "unsigned int"),
    dev_particle_container_t = AllenDataHandle("device", [], "dev_particle_container_t", "R", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", ["dev_particle_container_t"], "host_fn_parameters_t", "W", "unknown_t"),
    dev_decision_t = AllenDataHandle("device", [], "dev_decision_t", "W", "bool"),
    host_decision_t = AllenDataHandle("host", [], "host_decision_t", "W", "bool"),
    dev_pt_t = AllenDataHandle("device", [], "dev_pt_t", "W", "float"),
    host_pt_t = AllenDataHandle("host", [], "host_pt_t", "W", "float"),
    dev_p_t = AllenDataHandle("device", [], "dev_p_t", "W", "float"),
    host_p_t = AllenDataHandle("host", [], "host_p_t", "W", "float"),
    dev_track_chi2_t = AllenDataHandle("device", [], "dev_track_chi2_t", "W", "float"),
    host_track_chi2_t = AllenDataHandle("host", [], "host_track_chi2_t", "W", "float"),
    dev_eta_t = AllenDataHandle("device", [], "dev_eta_t", "W", "float"),
    host_eta_t = AllenDataHandle("host", [], "host_eta_t", "W", "float"),
    dev_phi_t = AllenDataHandle("device", [], "dev_phi_t", "W", "float"),
    host_phi_t = AllenDataHandle("host", [], "host_phi_t", "W", "float"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    minPt = "",
    minP = "",
    maxTrChi2 = "",
    minEta = "",
    maxEta = "",
    minPhi = "",
    maxPhi = "",
    enable_monitoring = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "rich_2_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/calibration/include/RICH2Line.cuh"

  @classmethod
  def getType(cls):
    return "rich_2_line_t"


class error_banks_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_raw_input_offsets_t = AllenDataHandle("host", [], "host_raw_input_offsets_t", "R", "unsigned int"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_raw_input_offsets_t = AllenDataHandle("device", [], "dev_raw_input_offsets_t", "R", "unsigned int"),
    dev_raw_input_types_t = AllenDataHandle("device", [], "dev_raw_input_types_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", [], "host_fn_parameters_t", "W", "char"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "error_banks_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/calibration/include/ErrorBanksLine.cuh"

  @classmethod
  def getType(cls):
    return "error_banks_line_t"


class d2kk_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_svs_t = AllenDataHandle("host", [], "host_number_of_svs_t", "R", "unsigned int"),
    dev_particle_container_t = AllenDataHandle("device", [], "dev_particle_container_t", "R", "unknown_t"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", ["dev_particle_container_t"], "host_fn_parameters_t", "W", "unknown_t"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    minComboPt = "",
    maxVertexChi2 = "",
    maxDOCA = "",
    minEta = "",
    maxEta = "",
    minTrackPt = "",
    massWindow = "",
    minTrackIP = "",
    minZ = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "d2kk_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/charm/include/D2KKLine.cuh"

  @classmethod
  def getType(cls):
    return "d2kk_line_t"


class d2pipi_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_svs_t = AllenDataHandle("host", [], "host_number_of_svs_t", "R", "unsigned int"),
    dev_particle_container_t = AllenDataHandle("device", [], "dev_particle_container_t", "R", "unknown_t"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", ["dev_particle_container_t"], "host_fn_parameters_t", "W", "unknown_t"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    minComboPt = "",
    maxVertexChi2 = "",
    maxDOCA = "",
    minEta = "",
    maxEta = "",
    minTrackPt = "",
    massWindow = "",
    minTrackIP = "",
    minZ = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "d2pipi_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/charm/include/D2PiPiLine.cuh"

  @classmethod
  def getType(cls):
    return "d2pipi_line_t"


class two_ks_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_number_of_svs_t = AllenDataHandle("host", [], "host_number_of_svs_t", "R", "unsigned int"),
    dev_particle_container_t = AllenDataHandle("device", [], "dev_particle_container_t", "R", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", ["dev_particle_container_t"], "host_fn_parameters_t", "W", "unknown_t"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    maxVertexChi2 = "",
    minComboPt_Ks = "",
    minCosDira = "",
    minEta_Ks = "",
    maxEta_Ks = "",
    minTrackPt_piKs = "",
    minTrackP_piKs = "",
    minTrackIPChi2_Ks = "",
    minM_Ks = "",
    maxM_Ks = "",
    minCosOpening = "",
    min_combip = "",
    minZ = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "two_ks_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/charm/include/TwoKsLine.cuh"

  @classmethod
  def getType(cls):
    return "two_ks_line_t"


class two_track_mva_charm_xsec_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_svs_t = AllenDataHandle("host", [], "host_number_of_svs_t", "R", "unsigned int"),
    dev_particle_container_t = AllenDataHandle("device", [], "dev_particle_container_t", "R", "unknown_t"),
    dev_two_track_mva_evaluation_t = AllenDataHandle("device", [], "dev_two_track_mva_evaluation_t", "R", "float"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", ["dev_particle_container_t"], "host_fn_parameters_t", "W", "unknown_t"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    maxVertexChi2 = "",
    minTrackPt = "",
    minTrackP = "",
    minTrackIPChi2 = "",
    maxDOCA = "",
    massWindow = "",
    maxCombKpiMass = "",
    lowSVpt = "",
    minMVAhighPt = "",
    minMVAlowPt = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "two_track_mva_charm_xsec_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/charm/include/TwoTrackMVACharmXSec.cuh"

  @classmethod
  def getType(cls):
    return "two_track_mva_charm_xsec_line_t"


class displaced_dielectron_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_svs_t = AllenDataHandle("host", [], "host_number_of_svs_t", "R", "unsigned int"),
    dev_particle_container_t = AllenDataHandle("device", [], "dev_particle_container_t", "R", "unknown_t"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_track_offsets_t = AllenDataHandle("device", [], "dev_track_offsets_t", "R", "unsigned int"),
    dev_track_isElectron_t = AllenDataHandle("device", [], "dev_track_isElectron_t", "R", "bool"),
    dev_brem_corrected_pt_t = AllenDataHandle("device", [], "dev_brem_corrected_pt_t", "R", "float"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", ["dev_particle_container_t"], "host_fn_parameters_t", "W", "unknown_t"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    MinIPChi2 = "",
    MaxDOCA = "",
    MinPT = "",
    MaxVtxChi2 = "",
    MinZ = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "displaced_dielectron_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/electron/include/DisplacedDielectronLine.cuh"

  @classmethod
  def getType(cls):
    return "displaced_dielectron_line_t"


class displaced_leptons_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_track_container_t = AllenDataHandle("device", [], "dev_track_container_t", "R", "unknown_t"),
    dev_track_isElectron_t = AllenDataHandle("device", [], "dev_track_isElectron_t", "R", "bool"),
    dev_brem_corrected_pt_t = AllenDataHandle("device", [], "dev_brem_corrected_pt_t", "R", "float"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", [], "host_fn_parameters_t", "W", "char"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    min_ipchi2 = "",
    min_pt = "",
    min_BPVz = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "displaced_leptons_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/electron/include/DisplacedLeptonsLine.cuh"

  @classmethod
  def getType(cls):
    return "displaced_leptons_line_t"


class single_high_et_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_reconstructed_velo_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_velo_tracks_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_velo_tracks_offsets_t = AllenDataHandle("device", [], "dev_velo_tracks_offsets_t", "R", "unsigned int"),
    dev_brem_ET_t = AllenDataHandle("device", [], "dev_brem_ET_t", "R", "float"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", [], "host_fn_parameters_t", "W", "char"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    minET = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "single_high_et_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/electron/include/SingleHighETLine.cuh"

  @classmethod
  def getType(cls):
    return "single_high_et_line_t"


class single_high_pt_electron_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_reconstructed_scifi_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_scifi_tracks_t", "R", "unsigned int"),
    dev_particle_container_t = AllenDataHandle("device", [], "dev_particle_container_t", "R", "unknown_t"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_track_isElectron_t = AllenDataHandle("device", [], "dev_track_isElectron_t", "R", "bool"),
    dev_brem_corrected_pt_t = AllenDataHandle("device", [], "dev_brem_corrected_pt_t", "R", "float"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", ["dev_particle_container_t"], "host_fn_parameters_t", "W", "unknown_t"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    maxChi2Ndof = "",
    singleMinPt = "",
    MinZ = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "single_high_pt_electron_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/electron/include/SingleHighPtElectronLine.cuh"

  @classmethod
  def getType(cls):
    return "single_high_pt_electron_line_t"


class track_electron_mva_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_reconstructed_scifi_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_scifi_tracks_t", "R", "unsigned int"),
    dev_particle_container_t = AllenDataHandle("device", [], "dev_particle_container_t", "R", "unknown_t"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_track_isElectron_t = AllenDataHandle("device", [], "dev_track_isElectron_t", "R", "bool"),
    dev_brem_corrected_pt_t = AllenDataHandle("device", [], "dev_brem_corrected_pt_t", "R", "float"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", ["dev_particle_container_t"], "host_fn_parameters_t", "W", "unknown_t"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    maxChi2Ndof = "",
    minPt = "",
    maxPt = "",
    minIPChi2 = "",
    param1 = "",
    param2 = "",
    param3 = "",
    alpha = "",
    min_BPVz = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "track_electron_mva_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/electron/include/TrackElectronMVALine.cuh"

  @classmethod
  def getType(cls):
    return "track_electron_mva_line_t"


class kstopipi_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_svs_t = AllenDataHandle("host", [], "host_number_of_svs_t", "R", "unsigned int"),
    dev_particle_container_t = AllenDataHandle("device", [], "dev_particle_container_t", "R", "unknown_t"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", ["dev_particle_container_t"], "host_fn_parameters_t", "W", "unknown_t"),
    dev_sv_masses_t = AllenDataHandle("device", [], "dev_sv_masses_t", "W", "float"),
    host_sv_masses_t = AllenDataHandle("host", [], "host_sv_masses_t", "W", "float"),
    dev_pt_t = AllenDataHandle("device", [], "dev_pt_t", "W", "float"),
    host_pt_t = AllenDataHandle("host", [], "host_pt_t", "W", "float"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    minIPChi2 = "",
    maxVertexChi2 = "",
    maxIP = "",
    minMass = "",
    maxMass = "",
    minZ = "",
    enable_monitoring = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "kstopipi_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/inclusive_hadron/include/KsToPiPiLine.cuh"

  @classmethod
  def getType(cls):
    return "kstopipi_line_t"


class track_mva_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_reconstructed_scifi_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_scifi_tracks_t", "R", "unsigned int"),
    dev_particle_container_t = AllenDataHandle("device", [], "dev_particle_container_t", "R", "unknown_t"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", ["dev_particle_container_t"], "host_fn_parameters_t", "W", "unknown_t"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    maxChi2Ndof = "",
    minPt = "",
    maxPt = "",
    minIPChi2 = "",
    param1 = "",
    param2 = "",
    param3 = "",
    alpha = "",
    minBPVz = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "track_mva_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/inclusive_hadron/include/TrackMVALine.cuh"

  @classmethod
  def getType(cls):
    return "track_mva_line_t"


class two_track_line_ks_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_number_of_svs_t = AllenDataHandle("host", [], "host_number_of_svs_t", "R", "unsigned int"),
    dev_particle_container_t = AllenDataHandle("device", [], "dev_particle_container_t", "R", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", ["dev_particle_container_t"], "host_fn_parameters_t", "W", "unknown_t"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    maxVertexChi2 = "",
    minComboPt_Ks = "",
    minCosDira = "",
    minEta_Ks = "",
    maxEta_Ks = "",
    minTrackPt_piKs = "",
    minTrackP_piKs = "",
    minTrackIPChi2_Ks = "",
    minM_Ks = "",
    maxM_Ks = "",
    minCosOpening = "",
    min_combip = "",
    minZ = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "two_track_line_ks"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/inclusive_hadron/include/TwoTrackKsLine.cuh"

  @classmethod
  def getType(cls):
    return "two_track_line_ks_t"


class two_track_mva_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_svs_t = AllenDataHandle("host", [], "host_number_of_svs_t", "R", "unsigned int"),
    dev_particle_container_t = AllenDataHandle("device", [], "dev_particle_container_t", "R", "unknown_t"),
    dev_two_track_mva_evaluation_t = AllenDataHandle("device", [], "dev_two_track_mva_evaluation_t", "R", "float"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", ["dev_particle_container_t"], "host_fn_parameters_t", "W", "unknown_t"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    minMVA = "",
    minPt = "",
    minSVpt = "",
    minEta = "",
    maxEta = "",
    minMcor = "",
    maxSVchi2 = "",
    maxDOCA = "",
    minZ = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "two_track_mva_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/inclusive_hadron/include/TwoTrackMVALine.cuh"

  @classmethod
  def getType(cls):
    return "two_track_mva_line_t"


class beam_crossing_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    dev_odin_data_t = AllenDataHandle("device", [], "dev_odin_data_t", "R", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", [], "host_fn_parameters_t", "W", "char"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    beam_crossing_type = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "beam_crossing_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/monitoring/include/BeamCrossingLine.cuh"

  @classmethod
  def getType(cls):
    return "beam_crossing_line_t"


class calo_digits_minADC_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_ecal_number_of_digits_t = AllenDataHandle("host", [], "host_ecal_number_of_digits_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_ecal_digits_t = AllenDataHandle("device", [], "dev_ecal_digits_t", "R", "unknown_t"),
    dev_ecal_digits_offsets_t = AllenDataHandle("device", [], "dev_ecal_digits_offsets_t", "R", "unsigned int"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", [], "host_fn_parameters_t", "W", "char"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    minADC = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "calo_digits_minADC"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/monitoring/include/CaloDigitsMinADCLine.cuh"

  @classmethod
  def getType(cls):
    return "calo_digits_minADC_t"


class odin_event_type_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    dev_odin_data_t = AllenDataHandle("device", [], "dev_odin_data_t", "R", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", [], "host_fn_parameters_t", "W", "char"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    odin_event_type = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "odin_event_type_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/monitoring/include/ODINEventTypeLine.cuh"

  @classmethod
  def getType(cls):
    return "odin_event_type_line_t"


class velo_micro_bias_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_offsets_velo_tracks_t = AllenDataHandle("device", [], "dev_offsets_velo_tracks_t", "R", "unsigned int"),
    dev_offsets_velo_track_hit_number_t = AllenDataHandle("device", [], "dev_offsets_velo_track_hit_number_t", "R", "unsigned int"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", [], "host_fn_parameters_t", "W", "char"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    min_velo_tracks = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "velo_micro_bias_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/monitoring/include/VeloMicroBiasLine.cuh"

  @classmethod
  def getType(cls):
    return "velo_micro_bias_line_t"


class beam_gas_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_reconstructed_velo_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_velo_tracks_t", "R", "unsigned int"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_velo_tracks_view_t = AllenDataHandle("device", [], "dev_velo_tracks_view_t", "R", "unknown_t"),
    dev_velo_states_view_t = AllenDataHandle("device", [], "dev_velo_states_view_t", "R", "unknown_t"),
    dev_offsets_velo_tracks_t = AllenDataHandle("device", [], "dev_offsets_velo_tracks_t", "R", "unsigned int"),
    dev_offsets_velo_track_hit_number_t = AllenDataHandle("device", [], "dev_offsets_velo_track_hit_number_t", "R", "unsigned int"),
    dev_odin_data_t = AllenDataHandle("device", [], "dev_odin_data_t", "R", "unknown_t"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", [], "host_fn_parameters_t", "W", "char"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    min_velo_tracks = "",
    beam_crossing_type = "",
    minNHits = "",
    minZ = "",
    maxZ = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "beam_gas_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/monitoring/include/BeamGasLine.cuh"

  @classmethod
  def getType(cls):
    return "beam_gas_line_t"


class di_muon_mass_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_svs_t = AllenDataHandle("host", [], "host_number_of_svs_t", "R", "unsigned int"),
    dev_particle_container_t = AllenDataHandle("device", [], "dev_particle_container_t", "R", "unknown_t"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", ["dev_particle_container_t"], "host_fn_parameters_t", "W", "unknown_t"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    minHighMassTrackPt = "",
    minHighMassTrackP = "",
    minMass = "",
    maxDoca = "",
    maxVertexChi2 = "",
    minIPChi2 = "",
    minZ = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "di_muon_mass_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/muon/include/DiMuonMassLine.cuh"

  @classmethod
  def getType(cls):
    return "di_muon_mass_line_t"


class di_muon_soft_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_svs_t = AllenDataHandle("host", [], "host_number_of_svs_t", "R", "unsigned int"),
    dev_particle_container_t = AllenDataHandle("device", [], "dev_particle_container_t", "R", "unknown_t"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", ["dev_particle_container_t"], "host_fn_parameters_t", "W", "unknown_t"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    DMSoftM0 = "",
    DMSoftM1 = "",
    DMSoftM2 = "",
    DMSoftMinIPChi2 = "",
    DMSoftMinRho2 = "",
    DMSoftMinZ = "",
    DMSoftMaxZ = "",
    DMSoftMaxDOCA = "",
    DMSoftMaxIPDZ = "",
    DMSoftGhost = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "di_muon_soft_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/muon/include/DiMuonSoftLine.cuh"

  @classmethod
  def getType(cls):
    return "di_muon_soft_line_t"


class di_muon_track_eff_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_svs_t = AllenDataHandle("host", [], "host_number_of_svs_t", "R", "unsigned int"),
    dev_particle_container_t = AllenDataHandle("device", [], "dev_particle_container_t", "R", "unknown_t"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", ["dev_particle_container_t"], "host_fn_parameters_t", "W", "unknown_t"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    DMTrackEffM0 = "",
    DMTrackEffM1 = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "di_muon_track_eff_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/muon/include/DiMuonTrackEffLine.cuh"

  @classmethod
  def getType(cls):
    return "di_muon_track_eff_line_t"


class displaced_di_muon_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_svs_t = AllenDataHandle("host", [], "host_number_of_svs_t", "R", "unsigned int"),
    dev_particle_container_t = AllenDataHandle("device", [], "dev_particle_container_t", "R", "unknown_t"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", ["dev_particle_container_t"], "host_fn_parameters_t", "W", "unknown_t"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    minDispTrackPt = "",
    maxVertexChi2 = "",
    dispMinIPChi2 = "",
    dispMinEta = "",
    dispMaxEta = "",
    minZ = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "displaced_di_muon_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/muon/include/DisplacedDiMuonLine.cuh"

  @classmethod
  def getType(cls):
    return "displaced_di_muon_line_t"


class low_pt_di_muon_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_svs_t = AllenDataHandle("host", [], "host_number_of_svs_t", "R", "unsigned int"),
    dev_particle_container_t = AllenDataHandle("device", [], "dev_particle_container_t", "R", "unknown_t"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", ["dev_particle_container_t"], "host_fn_parameters_t", "W", "unknown_t"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    minTrackIP = "",
    minTrackPt = "",
    minTrackP = "",
    minTrackIPChi2 = "",
    maxDOCA = "",
    maxVertexChi2 = "",
    minMass = "",
    minZ = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "low_pt_di_muon_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/muon/include/LowPtDiMuonLine.cuh"

  @classmethod
  def getType(cls):
    return "low_pt_di_muon_line_t"


class low_pt_muon_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_reconstructed_scifi_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_scifi_tracks_t", "R", "unsigned int"),
    dev_particle_container_t = AllenDataHandle("device", [], "dev_particle_container_t", "R", "unknown_t"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", ["dev_particle_container_t"], "host_fn_parameters_t", "W", "unknown_t"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    maxChi2Ndof = "",
    minPt = "",
    minIP = "",
    minIPChi2 = "",
    minBPVz = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "low_pt_muon_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/muon/include/LowPtMuonLine.cuh"

  @classmethod
  def getType(cls):
    return "low_pt_muon_line_t"


class single_high_pt_muon_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_reconstructed_scifi_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_scifi_tracks_t", "R", "unsigned int"),
    dev_particle_container_t = AllenDataHandle("device", [], "dev_particle_container_t", "R", "unknown_t"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", ["dev_particle_container_t"], "host_fn_parameters_t", "W", "unknown_t"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    maxChi2Ndof = "",
    singleMinPt = "",
    singleMinP = "",
    minZ = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "single_high_pt_muon_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/muon/include/SingleHighPtMuonLine.cuh"

  @classmethod
  def getType(cls):
    return "single_high_pt_muon_line_t"


class track_muon_mva_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_reconstructed_scifi_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_scifi_tracks_t", "R", "unsigned int"),
    dev_particle_container_t = AllenDataHandle("device", [], "dev_particle_container_t", "R", "unknown_t"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", ["dev_particle_container_t"], "host_fn_parameters_t", "W", "unknown_t"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    maxChi2Ndof = "",
    minPt = "",
    maxPt = "",
    minIPChi2 = "",
    param1 = "",
    param2 = "",
    param3 = "",
    alpha = "",
    minBPVz = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "track_muon_mva_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/muon/include/TrackMuonMVALine.cuh"

  @classmethod
  def getType(cls):
    return "track_muon_mva_line_t"


class single_high_pt_muon_no_muid_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_reconstructed_scifi_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_scifi_tracks_t", "R", "unsigned int"),
    dev_particle_container_t = AllenDataHandle("device", [], "dev_particle_container_t", "R", "unknown_t"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", ["dev_particle_container_t"], "host_fn_parameters_t", "W", "unknown_t"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    maxChi2Ndof = "",
    singleMinPt = "",
    singleMinP = "",
    minZ = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "single_high_pt_muon_no_muid_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/muon/include/SingleHighPtMuonLineNoMuID.cuh"

  @classmethod
  def getType(cls):
    return "single_high_pt_muon_no_muid_line_t"


class single_calo_cluster_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_ecal_number_of_clusters_t = AllenDataHandle("host", [], "host_ecal_number_of_clusters_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_ecal_clusters_t = AllenDataHandle("device", [], "dev_ecal_clusters_t", "R", "unknown_t"),
    dev_ecal_cluster_offsets_t = AllenDataHandle("device", [], "dev_ecal_cluster_offsets_t", "R", "unsigned int"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", [], "host_fn_parameters_t", "W", "char"),
    dev_clusters_x_t = AllenDataHandle("device", [], "dev_clusters_x_t", "W", "float"),
    host_clusters_x_t = AllenDataHandle("host", [], "host_clusters_x_t", "W", "float"),
    dev_clusters_y_t = AllenDataHandle("device", [], "dev_clusters_y_t", "W", "float"),
    host_clusters_y_t = AllenDataHandle("host", [], "host_clusters_y_t", "W", "float"),
    dev_clusters_Et_t = AllenDataHandle("device", [], "dev_clusters_Et_t", "W", "float"),
    host_clusters_Et_t = AllenDataHandle("host", [], "host_clusters_Et_t", "W", "float"),
    dev_clusters_Eta_t = AllenDataHandle("device", [], "dev_clusters_Eta_t", "W", "float"),
    host_clusters_Eta_t = AllenDataHandle("host", [], "host_clusters_Eta_t", "W", "float"),
    dev_clusters_Phi_t = AllenDataHandle("device", [], "dev_clusters_Phi_t", "W", "float"),
    host_clusters_Phi_t = AllenDataHandle("host", [], "host_clusters_Phi_t", "W", "float"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    minEt = "",
    maxEt = "",
    enable_monitoring = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "single_calo_cluster_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/photon/include/SingleCaloCluster.cuh"

  @classmethod
  def getType(cls):
    return "single_calo_cluster_line_t"


class SMOG2_dimuon_highmass_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_particle_container_t = AllenDataHandle("device", [], "dev_particle_container_t", "R", "unknown_t"),
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_svs_t = AllenDataHandle("host", [], "host_number_of_svs_t", "R", "unsigned int"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", ["dev_particle_container_t"], "host_fn_parameters_t", "W", "unknown_t"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    minTrackChi2Ndf = "",
    minTrackPt = "",
    minTrackP = "",
    minMass = "",
    maxDoca = "",
    maxVertexChi2 = "",
    minZ = "",
    maxZ = "",
    HighMassCombCharge = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "SMOG2_dimuon_highmass_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/SMOG2/include/SMOG2_DiMuonHighMassLine.cuh"

  @classmethod
  def getType(cls):
    return "SMOG2_dimuon_highmass_line_t"


class SMOG2_ditrack_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_particle_container_t = AllenDataHandle("device", [], "dev_particle_container_t", "R", "unknown_t"),
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_svs_t = AllenDataHandle("host", [], "host_number_of_svs_t", "R", "unsigned int"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", ["dev_particle_container_t"], "host_fn_parameters_t", "W", "unknown_t"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    minTrackChi2Ndf = "",
    minTrackP = "",
    minTrackPt = "",
    maxVertexChi2 = "",
    maxDoca = "",
    minZ = "",
    maxZ = "",
    combCharge = "",
    m1 = "",
    m2 = "",
    mMother = "",
    massWindow = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "SMOG2_ditrack_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/SMOG2/include/SMOG2_DiTrack.cuh"

  @classmethod
  def getType(cls):
    return "SMOG2_ditrack_line_t"


class SMOG2_minimum_bias_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_tracks_container_t = AllenDataHandle("device", [], "dev_tracks_container_t", "R", "unknown_t"),
    dev_velo_states_view_t = AllenDataHandle("device", [], "dev_velo_states_view_t", "R", "unknown_t"),
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_reconstructed_velo_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_velo_tracks_t", "R", "unsigned int"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", ["dev_tracks_container_t"], "host_fn_parameters_t", "W", "unknown_t"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    minNHits = "",
    minZ = "",
    maxZ = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "SMOG2_minimum_bias_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/SMOG2/include/SMOG2_MinimumBiasLine.cuh"

  @classmethod
  def getType(cls):
    return "SMOG2_minimum_bias_line_t"


class SMOG2_singletrack_line_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_particle_container_t = AllenDataHandle("device", [], "dev_particle_container_t", "R", "unknown_t"),
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_reconstructed_scifi_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_scifi_tracks_t", "R", "unsigned int"),
    host_decisions_size_t = AllenDataHandle("host", [], "host_decisions_size_t", "W", "unsigned int"),
    host_post_scaler_t = AllenDataHandle("host", [], "host_post_scaler_t", "W", "float"),
    host_post_scaler_hash_t = AllenDataHandle("host", [], "host_post_scaler_hash_t", "W", "unknown_t"),
    host_fn_parameters_t = AllenDataHandle("host", ["dev_particle_container_t"], "host_fn_parameters_t", "W", "unknown_t"),
    verbosity = "",
    pre_scaler = "",
    post_scaler = "",
    pre_scaler_hash_string = "",
    post_scaler_hash_string = "",
    maxChi2Ndof = "",
    minPt = "",
    minP = "",
    minBPVz = "",
    maxBPVz = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.SelectionAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "SMOG2_singletrack_line"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/lines/SMOG2/include/SMOG2_SingleTrack.cuh"

  @classmethod
  def getType(cls):
    return "SMOG2_singletrack_line_t"


class check_pvs_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_selected_events_t = AllenDataHandle("host", [], "host_number_of_selected_events_t", "W", "unsigned int"),
    dev_multi_final_vertices_t = AllenDataHandle("device", [], "dev_multi_final_vertices_t", "R", "unknown_t"),
    dev_number_of_multi_final_vertices_t = AllenDataHandle("device", [], "dev_number_of_multi_final_vertices_t", "R", "unsigned int"),
    dev_number_of_selected_events_t = AllenDataHandle("device", [], "dev_number_of_selected_events_t", "W", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_event_list_output_t = AllenDataHandle("device", [], "dev_event_list_output_t", "W", "mask_t"),
    verbosity = "",
    minZ = "",
    maxZ = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "check_pvs"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/filters/include/CheckPV.cuh"

  @classmethod
  def getType(cls):
    return "check_pvs_t"


class low_occupancy_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_selected_events_t = AllenDataHandle("host", [], "host_number_of_selected_events_t", "W", "unsigned int"),
    dev_offsets_velo_tracks_t = AllenDataHandle("device", [], "dev_offsets_velo_tracks_t", "R", "unsigned int"),
    dev_offsets_velo_track_hit_number_t = AllenDataHandle("device", [], "dev_offsets_velo_track_hit_number_t", "R", "unsigned int"),
    dev_number_of_selected_events_t = AllenDataHandle("device", [], "dev_number_of_selected_events_t", "W", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_event_list_output_t = AllenDataHandle("device", [], "dev_event_list_output_t", "W", "mask_t"),
    verbosity = "",
    minTracks = "",
    maxTracks = "",
    block_dim_x = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "low_occupancy"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/filters/include/LowOccupancy.cuh"

  @classmethod
  def getType(cls):
    return "low_occupancy_t"


class odin_beamcrossingtype_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_selected_events_t = AllenDataHandle("host", [], "host_number_of_selected_events_t", "W", "unsigned int"),
    dev_odin_data_t = AllenDataHandle("device", [], "dev_odin_data_t", "R", "unknown_t"),
    dev_number_of_selected_events_t = AllenDataHandle("device", [], "dev_number_of_selected_events_t", "W", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_event_list_output_t = AllenDataHandle("device", [], "dev_event_list_output_t", "W", "mask_t"),
    verbosity = "",
    beam_crossing_type = "",
    block_dim_x = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "odin_beamcrossingtype"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/selections/filters/include/ODINBeamCrossingType.cuh"

  @classmethod
  def getType(cls):
    return "odin_beamcrossingtype_t"


class velo_consolidate_tracks_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_accumulated_number_of_hits_in_velo_tracks_t = AllenDataHandle("host", [], "host_accumulated_number_of_hits_in_velo_tracks_t", "R", "unsigned int"),
    host_number_of_reconstructed_velo_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_velo_tracks_t", "R", "unsigned int"),
    host_number_of_three_hit_tracks_filtered_t = AllenDataHandle("host", [], "host_number_of_three_hit_tracks_filtered_t", "R", "unsigned int"),
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_offsets_all_velo_tracks_t = AllenDataHandle("device", [], "dev_offsets_all_velo_tracks_t", "R", "unsigned int"),
    dev_tracks_t = AllenDataHandle("device", [], "dev_tracks_t", "R", "unknown_t"),
    dev_offsets_velo_track_hit_number_t = AllenDataHandle("device", [], "dev_offsets_velo_track_hit_number_t", "R", "unsigned int"),
    dev_sorted_velo_cluster_container_t = AllenDataHandle("device", [], "dev_sorted_velo_cluster_container_t", "R", "char"),
    dev_offsets_estimated_input_size_t = AllenDataHandle("device", [], "dev_offsets_estimated_input_size_t", "R", "unsigned int"),
    dev_three_hit_tracks_output_t = AllenDataHandle("device", [], "dev_three_hit_tracks_output_t", "R", "unknown_t"),
    dev_offsets_number_of_three_hit_tracks_filtered_t = AllenDataHandle("device", [], "dev_offsets_number_of_three_hit_tracks_filtered_t", "R", "unsigned int"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_accepted_velo_tracks_t = AllenDataHandle("device", [], "dev_accepted_velo_tracks_t", "W", "bool"),
    dev_velo_track_hits_t = AllenDataHandle("device", [], "dev_velo_track_hits_t", "W", "char"),
    dev_velo_hits_view_t = AllenDataHandle("device", ["dev_velo_track_hits_t", "dev_offsets_all_velo_tracks_t", "dev_offsets_velo_track_hit_number_t"], "dev_velo_hits_view_t", "W", "unknown_t"),
    dev_velo_track_view_t = AllenDataHandle("device", ["dev_velo_hits_view_t"], "dev_velo_track_view_t", "W", "unknown_t"),
    dev_velo_tracks_view_t = AllenDataHandle("device", ["dev_velo_track_view_t"], "dev_velo_tracks_view_t", "W", "unknown_t"),
    dev_velo_multi_event_tracks_view_t = AllenDataHandle("device", ["dev_velo_tracks_view_t"], "dev_velo_multi_event_tracks_view_t", "W", "unknown_t"),
    dev_velo_multi_event_lhcb_id_container_t = AllenDataHandle("device", ["dev_velo_multi_event_tracks_view_t"], "dev_velo_multi_event_lhcb_id_container_t", "W", "unknown_t"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "velo_consolidate_tracks"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/velo/consolidate_tracks/include/VeloConsolidateTracks.cuh"

  @classmethod
  def getType(cls):
    return "velo_consolidate_tracks_t"


class velo_copy_track_hit_number_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_velo_tracks_at_least_four_hits_t = AllenDataHandle("host", [], "host_number_of_velo_tracks_at_least_four_hits_t", "R", "unsigned int"),
    host_number_of_three_hit_tracks_filtered_t = AllenDataHandle("host", [], "host_number_of_three_hit_tracks_filtered_t", "R", "unsigned int"),
    host_number_of_reconstructed_velo_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_velo_tracks_t", "W", "unsigned int"),
    dev_offsets_estimated_input_size_t = AllenDataHandle("device", [], "dev_offsets_estimated_input_size_t", "R", "unsigned int"),
    dev_tracks_t = AllenDataHandle("device", [], "dev_tracks_t", "R", "unknown_t"),
    dev_offsets_velo_tracks_t = AllenDataHandle("device", [], "dev_offsets_velo_tracks_t", "R", "unsigned int"),
    dev_offsets_number_of_three_hit_tracks_filtered_t = AllenDataHandle("device", [], "dev_offsets_number_of_three_hit_tracks_filtered_t", "R", "unsigned int"),
    dev_velo_track_hit_number_t = AllenDataHandle("device", [], "dev_velo_track_hit_number_t", "W", "unsigned int"),
    dev_offsets_all_velo_tracks_t = AllenDataHandle("device", [], "dev_offsets_all_velo_tracks_t", "W", "unsigned int"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "velo_copy_track_hit_number"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/velo/consolidate_tracks/include/VeloCopyTrackHitNumber.cuh"

  @classmethod
  def getType(cls):
    return "velo_copy_track_hit_number_t"


class velo_estimate_input_size_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_cluster_candidates_t = AllenDataHandle("host", [], "host_number_of_cluster_candidates_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_candidates_offsets_t = AllenDataHandle("device", [], "dev_candidates_offsets_t", "R", "unsigned int"),
    dev_velo_raw_input_t = AllenDataHandle("device", [], "dev_velo_raw_input_t", "R", "char"),
    dev_velo_raw_input_offsets_t = AllenDataHandle("device", [], "dev_velo_raw_input_offsets_t", "R", "unsigned int"),
    dev_velo_raw_input_sizes_t = AllenDataHandle("device", [], "dev_velo_raw_input_sizes_t", "R", "unsigned int"),
    dev_velo_raw_input_types_t = AllenDataHandle("device", [], "dev_velo_raw_input_types_t", "R", "unsigned int"),
    dev_estimated_input_size_t = AllenDataHandle("device", [], "dev_estimated_input_size_t", "W", "unsigned int"),
    dev_module_candidate_num_t = AllenDataHandle("device", [], "dev_module_candidate_num_t", "W", "unsigned int"),
    dev_cluster_candidates_t = AllenDataHandle("device", [], "dev_cluster_candidates_t", "W", "unsigned int"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "velo_estimate_input_size"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/velo/mask_clustering/include/EstimateInputSize.cuh"

  @classmethod
  def getType(cls):
    return "velo_estimate_input_size_t"


class velo_masked_clustering_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_total_number_of_velo_clusters_t = AllenDataHandle("host", [], "host_total_number_of_velo_clusters_t", "R", "unsigned int"),
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    dev_velo_raw_input_t = AllenDataHandle("device", [], "dev_velo_raw_input_t", "R", "char"),
    dev_velo_raw_input_offsets_t = AllenDataHandle("device", [], "dev_velo_raw_input_offsets_t", "R", "unsigned int"),
    dev_velo_raw_input_sizes_t = AllenDataHandle("device", [], "dev_velo_raw_input_sizes_t", "R", "unsigned int"),
    dev_velo_raw_input_types_t = AllenDataHandle("device", [], "dev_velo_raw_input_types_t", "R", "unsigned int"),
    dev_offsets_estimated_input_size_t = AllenDataHandle("device", [], "dev_offsets_estimated_input_size_t", "R", "unsigned int"),
    dev_module_candidate_num_t = AllenDataHandle("device", [], "dev_module_candidate_num_t", "R", "unsigned int"),
    dev_cluster_candidates_t = AllenDataHandle("device", [], "dev_cluster_candidates_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_candidates_offsets_t = AllenDataHandle("device", [], "dev_candidates_offsets_t", "R", "unsigned int"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_module_cluster_num_t = AllenDataHandle("device", [], "dev_module_cluster_num_t", "W", "unsigned int"),
    dev_velo_cluster_container_t = AllenDataHandle("device", [], "dev_velo_cluster_container_t", "W", "char"),
    dev_velo_clusters_t = AllenDataHandle("device", ["dev_velo_cluster_container_t", "dev_module_cluster_num_t", "dev_number_of_events_t"], "dev_velo_clusters_t", "W", "unknown_t"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "velo_masked_clustering"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/velo/mask_clustering/include/MaskedVeloClustering.cuh"

  @classmethod
  def getType(cls):
    return "velo_masked_clustering_t"


class velo_calculate_number_of_candidates_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_velo_raw_input_t = AllenDataHandle("device", [], "dev_velo_raw_input_t", "R", "char"),
    dev_velo_raw_input_offsets_t = AllenDataHandle("device", [], "dev_velo_raw_input_offsets_t", "R", "unsigned int"),
    dev_velo_raw_input_sizes_t = AllenDataHandle("device", [], "dev_velo_raw_input_sizes_t", "R", "unsigned int"),
    dev_velo_raw_input_types_t = AllenDataHandle("device", [], "dev_velo_raw_input_types_t", "R", "unsigned int"),
    dev_number_of_candidates_t = AllenDataHandle("device", [], "dev_number_of_candidates_t", "W", "unsigned int"),
    verbosity = "",
    block_dim_x = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "velo_calculate_number_of_candidates"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/velo/mask_clustering/include/VeloCalculateNumberOfCandidates.cuh"

  @classmethod
  def getType(cls):
    return "velo_calculate_number_of_candidates_t"


class calculate_number_of_retinaclusters_each_sensor_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unknown_t"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_velo_retina_raw_input_t = AllenDataHandle("device", [], "dev_velo_retina_raw_input_t", "R", "char"),
    dev_velo_retina_raw_input_offsets_t = AllenDataHandle("device", [], "dev_velo_retina_raw_input_offsets_t", "R", "unknown_t"),
    dev_velo_retina_raw_input_sizes_t = AllenDataHandle("device", [], "dev_velo_retina_raw_input_sizes_t", "R", "unknown_t"),
    dev_velo_retina_raw_input_types_t = AllenDataHandle("device", [], "dev_velo_retina_raw_input_types_t", "R", "unknown_t"),
    dev_retina_bank_index_t = AllenDataHandle("device", [], "dev_retina_bank_index_t", "W", "unknown_t"),
    dev_each_sensor_size_t = AllenDataHandle("device", [], "dev_each_sensor_size_t", "W", "unknown_t"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "calculate_number_of_retinaclusters_each_sensor"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/velo/retinacluster_decoding/include/CalculateNumberOfRetinaClustersPerSensor.cuh"

  @classmethod
  def getType(cls):
    return "calculate_number_of_retinaclusters_each_sensor_t"


class decode_retinaclusters_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_total_number_of_velo_clusters_t = AllenDataHandle("host", [], "host_total_number_of_velo_clusters_t", "R", "unsigned int"),
    host_raw_bank_version_t = AllenDataHandle("host", [], "host_raw_bank_version_t", "R", "unknown_t"),
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    dev_velo_retina_raw_input_t = AllenDataHandle("device", [], "dev_velo_retina_raw_input_t", "R", "char"),
    dev_velo_retina_raw_input_offsets_t = AllenDataHandle("device", [], "dev_velo_retina_raw_input_offsets_t", "R", "unsigned int"),
    dev_velo_retina_raw_input_sizes_t = AllenDataHandle("device", [], "dev_velo_retina_raw_input_sizes_t", "R", "unsigned int"),
    dev_velo_retina_raw_input_types_t = AllenDataHandle("device", [], "dev_velo_retina_raw_input_types_t", "R", "unsigned int"),
    dev_offsets_each_sensor_size_t = AllenDataHandle("device", [], "dev_offsets_each_sensor_size_t", "R", "unsigned int"),
    dev_retina_bank_index_t = AllenDataHandle("device", [], "dev_retina_bank_index_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_module_cluster_num_t = AllenDataHandle("device", [], "dev_module_cluster_num_t", "W", "unsigned int"),
    dev_offsets_module_pair_cluster_t = AllenDataHandle("device", [], "dev_offsets_module_pair_cluster_t", "W", "unsigned int"),
    dev_velo_cluster_container_t = AllenDataHandle("device", [], "dev_velo_cluster_container_t", "W", "char"),
    dev_hit_permutations_t = AllenDataHandle("device", [], "dev_hit_permutations_t", "W", "unsigned int"),
    dev_hit_sorting_key_t = AllenDataHandle("device", [], "dev_hit_sorting_key_t", "W", "unknown_t"),
    dev_velo_clusters_t = AllenDataHandle("device", ["dev_velo_cluster_container_t", "dev_module_cluster_num_t", "dev_number_of_events_t", "dev_offsets_module_pair_cluster_t"], "dev_velo_clusters_t", "W", "unknown_t"),
    verbosity = "",
    block_dim_x_calculate_key = "",
    block_dim_calculate_permutations = "",
    block_dim_x_decode_retina = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "decode_retinaclusters"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/velo/retinacluster_decoding/include/DecodeRetinaClusters.cuh"

  @classmethod
  def getType(cls):
    return "decode_retinaclusters_t"


class velo_search_by_triplet_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_total_number_of_velo_clusters_t = AllenDataHandle("host", [], "host_total_number_of_velo_clusters_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_sorted_velo_cluster_container_t = AllenDataHandle("device", [], "dev_sorted_velo_cluster_container_t", "R", "char"),
    dev_offsets_estimated_input_size_t = AllenDataHandle("device", [], "dev_offsets_estimated_input_size_t", "R", "unsigned int"),
    dev_module_cluster_num_t = AllenDataHandle("device", [], "dev_module_cluster_num_t", "R", "unsigned int"),
    dev_tracks_t = AllenDataHandle("device", [], "dev_tracks_t", "W", "unknown_t"),
    dev_tracklets_t = AllenDataHandle("device", [], "dev_tracklets_t", "W", "unknown_t"),
    dev_tracks_to_follow_t = AllenDataHandle("device", [], "dev_tracks_to_follow_t", "W", "unsigned int"),
    dev_three_hit_tracks_t = AllenDataHandle("device", [], "dev_three_hit_tracks_t", "W", "unknown_t"),
    dev_hit_used_t = AllenDataHandle("device", [], "dev_hit_used_t", "W", "bool"),
    dev_atomics_velo_t = AllenDataHandle("device", [], "dev_atomics_velo_t", "W", "unsigned int"),
    dev_rel_indices_t = AllenDataHandle("device", [], "dev_rel_indices_t", "W", "unsigned short"),
    dev_number_of_velo_tracks_t = AllenDataHandle("device", [], "dev_number_of_velo_tracks_t", "W", "unsigned int"),
    dev_velo_clusters_t = AllenDataHandle("device", [], "dev_velo_clusters_t", "R", "unknown_t"),
    verbosity = "",
    phi_tolerance = "",
    max_scatter = "",
    max_skipped_modules = "",
    block_dim_x = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "velo_search_by_triplet"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/velo/search_by_triplet/include/SearchByTriplet.cuh"

  @classmethod
  def getType(cls):
    return "velo_search_by_triplet_t"


class velo_sort_by_phi_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_total_number_of_velo_clusters_t = AllenDataHandle("host", [], "host_total_number_of_velo_clusters_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_offsets_estimated_input_size_t = AllenDataHandle("device", [], "dev_offsets_estimated_input_size_t", "R", "unsigned int"),
    dev_module_cluster_num_t = AllenDataHandle("device", [], "dev_module_cluster_num_t", "R", "unsigned int"),
    dev_velo_cluster_container_t = AllenDataHandle("device", [], "dev_velo_cluster_container_t", "R", "char"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_sorted_velo_cluster_container_t = AllenDataHandle("device", [], "dev_sorted_velo_cluster_container_t", "W", "char"),
    dev_hit_permutation_t = AllenDataHandle("device", [], "dev_hit_permutation_t", "W", "unsigned int"),
    dev_velo_clusters_t = AllenDataHandle("device", [], "dev_velo_clusters_t", "R", "unknown_t"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "velo_sort_by_phi"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/velo/search_by_triplet/include/SortByPhi.cuh"

  @classmethod
  def getType(cls):
    return "velo_sort_by_phi_t"


class velo_three_hit_tracks_filter_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_total_number_of_velo_clusters_t = AllenDataHandle("host", [], "host_total_number_of_velo_clusters_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_sorted_velo_cluster_container_t = AllenDataHandle("device", [], "dev_sorted_velo_cluster_container_t", "R", "char"),
    dev_offsets_estimated_input_size_t = AllenDataHandle("device", [], "dev_offsets_estimated_input_size_t", "R", "unsigned int"),
    dev_three_hit_tracks_input_t = AllenDataHandle("device", [], "dev_three_hit_tracks_input_t", "R", "unknown_t"),
    dev_atomics_velo_t = AllenDataHandle("device", [], "dev_atomics_velo_t", "R", "unsigned int"),
    dev_hit_used_t = AllenDataHandle("device", [], "dev_hit_used_t", "R", "bool"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_three_hit_tracks_output_t = AllenDataHandle("device", [], "dev_three_hit_tracks_output_t", "W", "unknown_t"),
    dev_number_of_three_hit_tracks_output_t = AllenDataHandle("device", [], "dev_number_of_three_hit_tracks_output_t", "W", "unsigned int"),
    verbosity = "",
    max_chi2 = "",
    max_weak_tracks = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "velo_three_hit_tracks_filter"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/velo/search_by_triplet/include/ThreeHitTracksFilter.cuh"

  @classmethod
  def getType(cls):
    return "velo_three_hit_tracks_filter_t"


class velo_kalman_filter_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_reconstructed_velo_tracks_t = AllenDataHandle("host", [], "host_number_of_reconstructed_velo_tracks_t", "R", "unsigned int"),
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_offsets_all_velo_tracks_t = AllenDataHandle("device", [], "dev_offsets_all_velo_tracks_t", "R", "unsigned int"),
    dev_velo_tracks_view_t = AllenDataHandle("device", [], "dev_velo_tracks_view_t", "R", "unknown_t"),
    dev_velo_kalman_beamline_states_t = AllenDataHandle("device", [], "dev_velo_kalman_beamline_states_t", "W", "char"),
    dev_velo_kalman_endvelo_states_t = AllenDataHandle("device", [], "dev_velo_kalman_endvelo_states_t", "W", "char"),
    dev_velo_kalman_beamline_states_view_t = AllenDataHandle("device", ["dev_velo_kalman_beamline_states_t", "dev_offsets_all_velo_tracks_t"], "dev_velo_kalman_beamline_states_view_t", "W", "unknown_t"),
    dev_velo_kalman_endvelo_states_view_t = AllenDataHandle("device", ["dev_velo_kalman_endvelo_states_t", "dev_offsets_all_velo_tracks_t"], "dev_velo_kalman_endvelo_states_view_t", "W", "unknown_t"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "velo_kalman_filter"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/velo/simplified_kalman_filter/include/VeloKalmanFilter.cuh"

  @classmethod
  def getType(cls):
    return "velo_kalman_filter_t"


class two_track_mva_evaluator_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    host_number_of_svs_t = AllenDataHandle("host", [], "host_number_of_svs_t", "R", "unsigned int"),
    dev_consolidated_svs_t = AllenDataHandle("device", [], "dev_consolidated_svs_t", "R", "unknown_t"),
    dev_sv_offsets_t = AllenDataHandle("device", [], "dev_sv_offsets_t", "R", "unsigned int"),
    dev_two_track_mva_evaluation_t = AllenDataHandle("device", [], "dev_two_track_mva_evaluation_t", "W", "float"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "two_track_mva_evaluator"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/vertex_fit/two_track_mva/include/TwoTrackMVAEvaluator.cuh"

  @classmethod
  def getType(cls):
    return "two_track_mva_evaluator_t"


class consolidate_svs_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_svs_t = AllenDataHandle("host", [], "host_number_of_svs_t", "R", "unsigned int"),
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    dev_sv_offsets_t = AllenDataHandle("device", [], "dev_sv_offsets_t", "R", "unsigned int"),
    dev_secondary_vertices_t = AllenDataHandle("device", [], "dev_secondary_vertices_t", "R", "unknown_t"),
    dev_consolidated_svs_t = AllenDataHandle("device", [], "dev_consolidated_svs_t", "W", "unknown_t"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "consolidate_svs"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/vertex_fit/vertex_fitter/include/ConsolidateSVs.cuh"

  @classmethod
  def getType(cls):
    return "consolidate_svs_t"


class filter_mf_tracks_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_selected_events_mf_t = AllenDataHandle("host", [], "host_selected_events_mf_t", "R", "unsigned int"),
    dev_kf_tracks_t = AllenDataHandle("device", [], "dev_kf_tracks_t", "R", "unknown_t"),
    dev_mf_tracks_t = AllenDataHandle("device", [], "dev_mf_tracks_t", "R", "unknown_t"),
    dev_offsets_forward_tracks_t = AllenDataHandle("device", [], "dev_offsets_forward_tracks_t", "R", "unsigned int"),
    dev_offsets_scifi_track_hit_number = AllenDataHandle("device", [], "dev_offsets_scifi_track_hit_number", "R", "unsigned int"),
    dev_scifi_qop_t = AllenDataHandle("device", [], "dev_scifi_qop_t", "R", "float"),
    dev_scifi_states_t = AllenDataHandle("device", [], "dev_scifi_states_t", "R", "unknown_t"),
    dev_scifi_track_ut_indices_t = AllenDataHandle("device", [], "dev_scifi_track_ut_indices_t", "R", "unsigned int"),
    dev_mf_track_offsets_t = AllenDataHandle("device", [], "dev_mf_track_offsets_t", "R", "unsigned int"),
    dev_event_list_mf_t = AllenDataHandle("device", [], "dev_event_list_mf_t", "R", "unsigned int"),
    dev_mf_sv_atomics_t = AllenDataHandle("device", [], "dev_mf_sv_atomics_t", "W", "unsigned int"),
    dev_svs_kf_idx_t = AllenDataHandle("device", [], "dev_svs_kf_idx_t", "W", "unsigned int"),
    dev_svs_mf_idx_t = AllenDataHandle("device", [], "dev_svs_mf_idx_t", "W", "unsigned int"),
    verbosity = "",
    kf_track_min_pt = "",
    kf_track_min_ipchi2 = "",
    mf_track_min_pt = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "FilterMFTracks"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/vertex_fit/vertex_fitter/include/FilterMFTracks.cuh"

  @classmethod
  def getType(cls):
    return "filter_mf_tracks_t"


class filter_tracks_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_tracks_t = AllenDataHandle("host", [], "host_number_of_tracks_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_long_track_particles_t = AllenDataHandle("device", [], "dev_long_track_particles_t", "R", "unknown_t"),
    dev_track_prefilter_result_t = AllenDataHandle("device", [], "dev_track_prefilter_result_t", "W", "float"),
    dev_sv_atomics_t = AllenDataHandle("device", [], "dev_sv_atomics_t", "W", "unsigned int"),
    dev_svs_trk1_idx_t = AllenDataHandle("device", [], "dev_svs_trk1_idx_t", "W", "unsigned int"),
    dev_svs_trk2_idx_t = AllenDataHandle("device", [], "dev_svs_trk2_idx_t", "W", "unsigned int"),
    dev_sv_poca_t = AllenDataHandle("device", [], "dev_sv_poca_t", "W", "float"),
    verbosity = "",
    track_min_pt = "",
    track_min_pt_charm = "",
    track_min_ipchi2 = "",
    track_min_ip = "",
    track_muon_min_ipchi2 = "",
    track_max_chi2ndof = "",
    track_muon_max_chi2ndof = "",
    max_assoc_ipchi2 = "",
    block_dim_prefilter = "",
    block_dim_filter = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "FilterTracks"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/vertex_fit/vertex_fitter/include/FilterTracks.cuh"

  @classmethod
  def getType(cls):
    return "filter_tracks_t"


class fit_mf_vertices_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_mf_svs_t = AllenDataHandle("host", [], "host_number_of_mf_svs_t", "R", "unsigned int"),
    host_selected_events_mf_t = AllenDataHandle("host", [], "host_selected_events_mf_t", "R", "unsigned int"),
    dev_kf_particles_t = AllenDataHandle("device", [], "dev_kf_particles_t", "R", "unknown_t"),
    dev_mf_particles_t = AllenDataHandle("device", [], "dev_mf_particles_t", "R", "unknown_t"),
    dev_mf_sv_offsets_t = AllenDataHandle("device", [], "dev_mf_sv_offsets_t", "R", "unsigned int"),
    dev_svs_kf_idx_t = AllenDataHandle("device", [], "dev_svs_kf_idx_t", "R", "unsigned int"),
    dev_svs_mf_idx_t = AllenDataHandle("device", [], "dev_svs_mf_idx_t", "R", "unsigned int"),
    dev_event_list_mf_t = AllenDataHandle("device", [], "dev_event_list_mf_t", "R", "unsigned int"),
    dev_mf_svs_t = AllenDataHandle("device", [], "dev_mf_svs_t", "W", "unknown_t"),
    verbosity = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "MFVertexFit"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/vertex_fit/vertex_fitter/include/MFVertexFitter.cuh"

  @classmethod
  def getType(cls):
    return "fit_mf_vertices_t"


class fit_secondary_vertices_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_number_of_svs_t = AllenDataHandle("host", [], "host_number_of_svs_t", "R", "unsigned int"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "R", "unsigned int"),
    dev_svs_trk1_idx_t = AllenDataHandle("device", [], "dev_svs_trk1_idx_t", "R", "unsigned int"),
    dev_svs_trk2_idx_t = AllenDataHandle("device", [], "dev_svs_trk2_idx_t", "R", "unsigned int"),
    dev_sv_offsets_t = AllenDataHandle("device", [], "dev_sv_offsets_t", "R", "unsigned int"),
    dev_multi_final_vertices_t = AllenDataHandle("device", [], "dev_multi_final_vertices_t", "R", "unknown_t"),
    dev_number_of_multi_final_vertices_t = AllenDataHandle("device", [], "dev_number_of_multi_final_vertices_t", "R", "unsigned int"),
    dev_sv_poca_t = AllenDataHandle("device", [], "dev_sv_poca_t", "R", "float"),
    dev_long_track_particles_t = AllenDataHandle("device", [], "dev_long_track_particles_t", "R", "unknown_t"),
    dev_consolidated_svs_t = AllenDataHandle("device", [], "dev_consolidated_svs_t", "W", "unknown_t"),
    dev_sv_pv_ipchi2_t = AllenDataHandle("device", [], "dev_sv_pv_ipchi2_t", "W", "char"),
    dev_sv_fit_results_t = AllenDataHandle("device", [], "dev_sv_fit_results_t", "W", "char"),
    dev_sv_fit_results_view_t = AllenDataHandle("device", ["dev_sv_fit_results_t"], "dev_sv_fit_results_view_t", "W", "unknown_t"),
    dev_sv_pv_tables_t = AllenDataHandle("device", ["dev_sv_pv_ipchi2_t"], "dev_sv_pv_tables_t", "W", "unknown_t"),
    dev_two_track_sv_track_pointers_t = AllenDataHandle("device", ["dev_long_track_particles_t"], "dev_two_track_sv_track_pointers_t", "W", "unknown_t"),
    dev_two_track_composite_view_t = AllenDataHandle("device", ["dev_two_track_sv_track_pointers_t", "dev_long_track_particles_t", "dev_sv_fit_results_view_t", "dev_sv_pv_tables_t", "dev_multi_final_vertices_t"], "dev_two_track_composite_view_t", "W", "unknown_t"),
    dev_two_track_composites_view_t = AllenDataHandle("device", ["dev_two_track_composite_view_t"], "dev_two_track_composites_view_t", "W", "unknown_t"),
    dev_multi_event_composites_view_t = AllenDataHandle("device", ["dev_two_track_composites_view_t"], "dev_multi_event_composites_view_t", "W", "unknown_t"),
    dev_multi_event_composites_ptr_t = AllenDataHandle("device", ["dev_multi_event_composites_view_t"], "dev_multi_event_composites_ptr_t", "W", "unknown_t"),
    verbosity = "",
    max_assoc_ipchi2 = "",
    block_dim = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DeviceAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "VertexFit"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/device/vertex_fit/vertex_fitter/include/VertexFitter.cuh"

  @classmethod
  def getType(cls):
    return "fit_secondary_vertices_t"


class event_list_intersection_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    dev_event_list_a_t = AllenDataHandle("device", [], "dev_event_list_a_t", "R", "mask_t"),
    dev_event_list_b_t = AllenDataHandle("device", [], "dev_event_list_b_t", "R", "mask_t"),
    host_event_list_a_t = AllenDataHandle("host", [], "host_event_list_a_t", "W", "unsigned int"),
    host_event_list_b_t = AllenDataHandle("host", [], "host_event_list_b_t", "W", "unsigned int"),
    host_event_list_output_t = AllenDataHandle("host", [], "host_event_list_output_t", "W", "unsigned int"),
    dev_event_list_output_t = AllenDataHandle("device", [], "dev_event_list_output_t", "W", "mask_t"),
    verbosity = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.HostAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "event_list_intersection"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/host/combiners/include/EventListIntersection.cuh"

  @classmethod
  def getType(cls):
    return "event_list_intersection_t"


class event_list_inversion_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    dev_event_list_input_t = AllenDataHandle("device", [], "dev_event_list_input_t", "R", "mask_t"),
    host_event_list_t = AllenDataHandle("host", [], "host_event_list_t", "W", "unsigned int"),
    host_event_list_output_t = AllenDataHandle("host", [], "host_event_list_output_t", "W", "unsigned int"),
    dev_event_list_output_t = AllenDataHandle("device", [], "dev_event_list_output_t", "W", "mask_t"),
    verbosity = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.HostAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "event_list_inversion"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/host/combiners/include/EventListInversion.cuh"

  @classmethod
  def getType(cls):
    return "event_list_inversion_t"


class event_list_union_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    dev_event_list_a_t = AllenDataHandle("device", [], "dev_event_list_a_t", "R", "mask_t"),
    dev_event_list_b_t = AllenDataHandle("device", [], "dev_event_list_b_t", "R", "mask_t"),
    host_event_list_a_t = AllenDataHandle("host", [], "host_event_list_a_t", "W", "unsigned int"),
    host_event_list_b_t = AllenDataHandle("host", [], "host_event_list_b_t", "W", "unsigned int"),
    host_event_list_output_t = AllenDataHandle("host", [], "host_event_list_output_t", "W", "unsigned int"),
    dev_event_list_output_t = AllenDataHandle("device", [], "dev_event_list_output_t", "W", "mask_t"),
    verbosity = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.HostAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "event_list_union"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/host/combiners/include/EventListUnion.cuh"

  @classmethod
  def getType(cls):
    return "event_list_union_t"


class data_provider_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    dev_raw_banks_t = AllenDataHandle("device", [], "dev_raw_banks_t", "W", "char"),
    dev_raw_offsets_t = AllenDataHandle("device", [], "dev_raw_offsets_t", "W", "unsigned int"),
    dev_raw_sizes_t = AllenDataHandle("device", [], "dev_raw_sizes_t", "W", "unsigned int"),
    dev_raw_types_t = AllenDataHandle("device", [], "dev_raw_types_t", "W", "unsigned int"),
    host_raw_bank_version_t = AllenDataHandle("host", [], "host_raw_bank_version_t", "W", "unknown_t"),
    verbosity = "",
    bank_type = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.DataProvider

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "data_provider"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/host/data_provider/include/DataProvider.h"

  @classmethod
  def getType(cls):
    return "data_provider_t"


class host_data_provider_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_raw_banks_t = AllenDataHandle("host", [], "host_raw_banks_t", "W", "unknown_t"),
    host_raw_offsets_t = AllenDataHandle("host", [], "host_raw_offsets_t", "W", "unknown_t"),
    host_raw_sizes_t = AllenDataHandle("host", [], "host_raw_sizes_t", "W", "unknown_t"),
    host_raw_types_t = AllenDataHandle("host", [], "host_raw_types_t", "W", "unknown_t"),
    host_raw_bank_version_t = AllenDataHandle("host", [], "host_raw_bank_version_t", "W", "unknown_t"),
    verbosity = "",
    bank_type = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.HostDataProvider

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "host_data_provider"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/host/data_provider/include/HostDataProvider.h"

  @classmethod
  def getType(cls):
    return "host_data_provider_t"


class layout_provider_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_mep_layout_t = AllenDataHandle("host", [], "host_mep_layout_t", "W", "unsigned int"),
    dev_mep_layout_t = AllenDataHandle("device", [], "dev_mep_layout_t", "W", "unsigned int"),
    verbosity = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.HostAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "layout_provider"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/host/data_provider/include/LayoutProvider.h"

  @classmethod
  def getType(cls):
    return "layout_provider_t"


class mc_data_provider_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_mc_particle_banks_t = AllenDataHandle("host", [], "host_mc_particle_banks_t", "R", "unknown_t"),
    host_mc_particle_offsets_t = AllenDataHandle("host", [], "host_mc_particle_offsets_t", "R", "unknown_t"),
    host_mc_particle_sizes_t = AllenDataHandle("host", [], "host_mc_particle_sizes_t", "R", "unknown_t"),
    host_mc_pv_banks_t = AllenDataHandle("host", [], "host_mc_pv_banks_t", "R", "unknown_t"),
    host_mc_pv_offsets_t = AllenDataHandle("host", [], "host_mc_pv_offsets_t", "R", "unknown_t"),
    host_mc_pv_sizes_t = AllenDataHandle("host", [], "host_mc_pv_sizes_t", "R", "unknown_t"),
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_mc_events_t = AllenDataHandle("host", [], "host_mc_events_t", "W", "const int *"),
    verbosity = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.ValidationAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "mc_data_provider"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/host/data_provider/include/MCDataProvider.h"

  @classmethod
  def getType(cls):
    return "mc_data_provider_t"


class odin_provider_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_mep_layout_t = AllenDataHandle("host", [], "host_mep_layout_t", "R", "unsigned int"),
    dev_odin_data_t = AllenDataHandle("device", [], "dev_odin_data_t", "W", "unknown_t"),
    host_odin_data_t = AllenDataHandle("host", [], "host_odin_data_t", "W", "unknown_t"),
    host_raw_bank_version_t = AllenDataHandle("host", [], "host_raw_bank_version_t", "W", "unknown_t"),
    verbosity = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.HostAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "odin_provider"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/host/data_provider/include/ODINProvider.h"

  @classmethod
  def getType(cls):
    return "odin_provider_t"


class bank_types_provider_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    dev_raw_offsets_t = AllenDataHandle("device", [], "dev_raw_offsets_t", "W", "unsigned int"),
    dev_raw_types_t = AllenDataHandle("device", [], "dev_raw_types_t", "W", "unsigned int"),
    host_raw_bank_version_t = AllenDataHandle("host", [], "host_raw_bank_version_t", "W", "unknown_t"),
    host_raw_offsets_t = AllenDataHandle("host", [], "host_raw_offsets_t", "W", "unsigned int"),
    verbosity = "",
    bank_type = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.HostAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "bank_types_provider"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/host/data_provider/include/BankTypesProvider.h"

  @classmethod
  def getType(cls):
    return "bank_types_provider_t"


class host_global_event_cut_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_ut_raw_banks_t = AllenDataHandle("host", [], "host_ut_raw_banks_t", "R", "unknown_t"),
    host_ut_raw_offsets_t = AllenDataHandle("host", [], "host_ut_raw_offsets_t", "R", "unknown_t"),
    host_ut_raw_sizes_t = AllenDataHandle("host", [], "host_ut_raw_sizes_t", "R", "unknown_t"),
    host_ut_raw_types_t = AllenDataHandle("host", [], "host_ut_raw_types_t", "R", "unknown_t"),
    host_ut_raw_bank_version_t = AllenDataHandle("host", [], "host_ut_raw_bank_version_t", "R", "unknown_t"),
    host_scifi_raw_banks_t = AllenDataHandle("host", [], "host_scifi_raw_banks_t", "R", "unknown_t"),
    host_scifi_raw_offsets_t = AllenDataHandle("host", [], "host_scifi_raw_offsets_t", "R", "unknown_t"),
    host_scifi_raw_sizes_t = AllenDataHandle("host", [], "host_scifi_raw_sizes_t", "R", "unknown_t"),
    host_scifi_raw_types_t = AllenDataHandle("host", [], "host_scifi_raw_types_t", "R", "unknown_t"),
    host_event_list_output_t = AllenDataHandle("host", [], "host_event_list_output_t", "W", "unsigned int"),
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "W", "unsigned int"),
    host_number_of_selected_events_t = AllenDataHandle("host", [], "host_number_of_selected_events_t", "W", "unsigned int"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "W", "unsigned int"),
    dev_event_list_output_t = AllenDataHandle("device", [], "dev_event_list_output_t", "W", "mask_t"),
    verbosity = "",
    min_scifi_ut_clusters = "",
    max_scifi_ut_clusters = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.HostAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "host_global_event_cut"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/host/global_event_cut/include/HostGlobalEventCut.h"

  @classmethod
  def getType(cls):
    return "host_global_event_cut_t"


class host_init_event_list_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_event_list_output_t = AllenDataHandle("host", [], "host_event_list_output_t", "W", "unsigned int"),
    dev_event_list_output_t = AllenDataHandle("device", [], "dev_event_list_output_t", "W", "mask_t"),
    verbosity = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.HostAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "host_init_event_list"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/host/init_event_list/include/HostInitEventList.h"

  @classmethod
  def getType(cls):
    return "host_init_event_list_t"


class host_init_number_of_events_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "W", "unsigned int"),
    dev_number_of_events_t = AllenDataHandle("device", [], "dev_number_of_events_t", "W", "unsigned int"),
    verbosity = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.HostAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "host_init_number_of_events"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/host/init_event_list/include/HostInitNumberOfEvents.h"

  @classmethod
  def getType(cls):
    return "host_init_number_of_events_t"


class host_prefix_sum_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_total_sum_holder_t = AllenDataHandle("host", [], "host_total_sum_holder_t", "W", "unsigned int"),
    dev_input_buffer_t = AllenDataHandle("device", [], "dev_input_buffer_t", "R", "unsigned int"),
    host_output_buffer_t = AllenDataHandle("host", [], "host_output_buffer_t", "W", "unsigned int"),
    dev_output_buffer_t = AllenDataHandle("device", [], "dev_output_buffer_t", "W", "unsigned int"),
    verbosity = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.HostAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "host_prefix_sum"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/host/prefix_sum/include/HostPrefixSum.h"

  @classmethod
  def getType(cls):
    return "host_prefix_sum_t"


class host_forward_validator_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    dev_offsets_all_velo_tracks_t = AllenDataHandle("device", [], "dev_offsets_all_velo_tracks_t", "R", "unsigned int"),
    dev_offsets_velo_track_hit_number_t = AllenDataHandle("device", [], "dev_offsets_velo_track_hit_number_t", "R", "unsigned int"),
    dev_velo_track_hits_t = AllenDataHandle("device", [], "dev_velo_track_hits_t", "R", "char"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_velo_kalman_endvelo_states_t = AllenDataHandle("device", [], "dev_velo_kalman_endvelo_states_t", "R", "char"),
    dev_offsets_ut_tracks_t = AllenDataHandle("device", [], "dev_offsets_ut_tracks_t", "R", "unsigned int"),
    dev_offsets_ut_track_hit_number_t = AllenDataHandle("device", [], "dev_offsets_ut_track_hit_number_t", "R", "unsigned int"),
    dev_ut_track_hits_t = AllenDataHandle("device", [], "dev_ut_track_hits_t", "R", "char"),
    dev_ut_track_velo_indices_t = AllenDataHandle("device", [], "dev_ut_track_velo_indices_t", "R", "unsigned int"),
    dev_ut_qop_t = AllenDataHandle("device", [], "dev_ut_qop_t", "R", "float"),
    dev_offsets_forward_tracks_t = AllenDataHandle("device", [], "dev_offsets_forward_tracks_t", "R", "unsigned int"),
    dev_offsets_scifi_track_hit_number_t = AllenDataHandle("device", [], "dev_offsets_scifi_track_hit_number_t", "R", "unsigned int"),
    dev_scifi_track_hits_t = AllenDataHandle("device", [], "dev_scifi_track_hits_t", "R", "char"),
    dev_scifi_track_ut_indices_t = AllenDataHandle("device", [], "dev_scifi_track_ut_indices_t", "R", "unsigned int"),
    dev_scifi_qop_t = AllenDataHandle("device", [], "dev_scifi_qop_t", "R", "float"),
    dev_scifi_states_t = AllenDataHandle("device", [], "dev_scifi_states_t", "R", "unknown_t"),
    host_mc_events_t = AllenDataHandle("host", [], "host_mc_events_t", "R", "const int *"),
    verbosity = "",
    root_output_filename = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.ValidationAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "host_forward_validator"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/host/validators/include/HostForwardValidator.h"

  @classmethod
  def getType(cls):
    return "host_forward_validator_t"


class host_kalman_validator_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    dev_offsets_all_velo_tracks_t = AllenDataHandle("device", [], "dev_offsets_all_velo_tracks_t", "R", "unsigned int"),
    dev_offsets_velo_track_hit_number_t = AllenDataHandle("device", [], "dev_offsets_velo_track_hit_number_t", "R", "unsigned int"),
    dev_velo_track_hits_t = AllenDataHandle("device", [], "dev_velo_track_hits_t", "R", "char"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_velo_kalman_states_t = AllenDataHandle("device", [], "dev_velo_kalman_states_t", "R", "char"),
    dev_offsets_ut_tracks_t = AllenDataHandle("device", [], "dev_offsets_ut_tracks_t", "R", "unsigned int"),
    dev_offsets_ut_track_hit_number_t = AllenDataHandle("device", [], "dev_offsets_ut_track_hit_number_t", "R", "unsigned int"),
    dev_ut_track_hits_t = AllenDataHandle("device", [], "dev_ut_track_hits_t", "R", "char"),
    dev_ut_track_velo_indices_t = AllenDataHandle("device", [], "dev_ut_track_velo_indices_t", "R", "unsigned int"),
    dev_ut_qop_t = AllenDataHandle("device", [], "dev_ut_qop_t", "R", "float"),
    dev_offsets_forward_tracks_t = AllenDataHandle("device", [], "dev_offsets_forward_tracks_t", "R", "unsigned int"),
    dev_offsets_scifi_track_hit_number_t = AllenDataHandle("device", [], "dev_offsets_scifi_track_hit_number_t", "R", "unsigned int"),
    dev_scifi_track_hits_t = AllenDataHandle("device", [], "dev_scifi_track_hits_t", "R", "char"),
    dev_scifi_track_ut_indices_t = AllenDataHandle("device", [], "dev_scifi_track_ut_indices_t", "R", "unsigned int"),
    dev_scifi_qop_t = AllenDataHandle("device", [], "dev_scifi_qop_t", "R", "float"),
    dev_scifi_states_t = AllenDataHandle("device", [], "dev_scifi_states_t", "R", "unknown_t"),
    dev_kf_tracks_t = AllenDataHandle("device", [], "dev_kf_tracks_t", "R", "unknown_t"),
    dev_multi_final_vertices_t = AllenDataHandle("device", [], "dev_multi_final_vertices_t", "R", "unknown_t"),
    dev_number_of_multi_final_vertices_t = AllenDataHandle("device", [], "dev_number_of_multi_final_vertices_t", "R", "unsigned int"),
    host_mc_events_t = AllenDataHandle("host", [], "host_mc_events_t", "R", "const int *"),
    verbosity = "",
    root_output_filename = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.ValidationAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "host_kalman_validator"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/host/validators/include/HostKalmanValidator.h"

  @classmethod
  def getType(cls):
    return "host_kalman_validator_t"


class host_muon_validator_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    dev_offsets_all_velo_tracks_t = AllenDataHandle("device", [], "dev_offsets_all_velo_tracks_t", "R", "unsigned int"),
    dev_offsets_velo_track_hit_number_t = AllenDataHandle("device", [], "dev_offsets_velo_track_hit_number_t", "R", "unsigned int"),
    dev_velo_track_hits_t = AllenDataHandle("device", [], "dev_velo_track_hits_t", "R", "char"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_velo_kalman_endvelo_states_t = AllenDataHandle("device", [], "dev_velo_kalman_endvelo_states_t", "R", "char"),
    dev_offsets_ut_tracks_t = AllenDataHandle("device", [], "dev_offsets_ut_tracks_t", "R", "unsigned int"),
    dev_offsets_ut_track_hit_number_t = AllenDataHandle("device", [], "dev_offsets_ut_track_hit_number_t", "R", "unsigned int"),
    dev_ut_track_hits_t = AllenDataHandle("device", [], "dev_ut_track_hits_t", "R", "char"),
    dev_ut_track_velo_indices_t = AllenDataHandle("device", [], "dev_ut_track_velo_indices_t", "R", "unsigned int"),
    dev_ut_qop_t = AllenDataHandle("device", [], "dev_ut_qop_t", "R", "float"),
    dev_offsets_forward_tracks_t = AllenDataHandle("device", [], "dev_offsets_forward_tracks_t", "R", "unsigned int"),
    dev_offsets_scifi_track_hit_number_t = AllenDataHandle("device", [], "dev_offsets_scifi_track_hit_number_t", "R", "unsigned int"),
    dev_scifi_track_hits_t = AllenDataHandle("device", [], "dev_scifi_track_hits_t", "R", "char"),
    dev_scifi_track_ut_indices_t = AllenDataHandle("device", [], "dev_scifi_track_ut_indices_t", "R", "unsigned int"),
    dev_scifi_qop_t = AllenDataHandle("device", [], "dev_scifi_qop_t", "R", "float"),
    dev_scifi_states_t = AllenDataHandle("device", [], "dev_scifi_states_t", "R", "unknown_t"),
    dev_is_muon_t = AllenDataHandle("device", [], "dev_is_muon_t", "R", "bool"),
    host_mc_events_t = AllenDataHandle("host", [], "host_mc_events_t", "R", "const int *"),
    verbosity = "",
    root_output_filename = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.ValidationAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "host_muon_validator"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/host/validators/include/HostMuonValidator.h"

  @classmethod
  def getType(cls):
    return "host_muon_validator_t"


class host_pv_validator_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_multi_final_vertices_t = AllenDataHandle("device", [], "dev_multi_final_vertices_t", "R", "unknown_t"),
    dev_number_of_multi_final_vertices_t = AllenDataHandle("device", [], "dev_number_of_multi_final_vertices_t", "R", "unsigned int"),
    host_mc_events_t = AllenDataHandle("host", [], "host_mc_events_t", "R", "const int *"),
    verbosity = "",
    root_output_filename = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.ValidationAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "host_pv_validator"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/host/validators/include/HostPVValidator.h"

  @classmethod
  def getType(cls):
    return "host_pv_validator_t"


class host_rate_validator_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_names_of_lines_t = AllenDataHandle("host", [], "host_names_of_lines_t", "R", "char"),
    host_number_of_active_lines_t = AllenDataHandle("host", [], "host_number_of_active_lines_t", "R", "unsigned int"),
    host_dec_reports_t = AllenDataHandle("host", [], "host_dec_reports_t", "R", "unsigned int"),
    verbosity = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.HostAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "host_rate_validator"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/host/validators/include/HostRateValidator.h"

  @classmethod
  def getType(cls):
    return "host_rate_validator_t"


class host_sel_report_validator_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    host_names_of_lines_t = AllenDataHandle("host", [], "host_names_of_lines_t", "R", "char"),
    dev_sel_reports_t = AllenDataHandle("device", [], "dev_sel_reports_t", "R", "unsigned int"),
    dev_sel_report_offsets_t = AllenDataHandle("device", [], "dev_sel_report_offsets_t", "R", "unsigned int"),
    verbosity = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.ValidationAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "host_sel_report_validator"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/host/validators/include/HostSelReportValidator.h"

  @classmethod
  def getType(cls):
    return "host_sel_report_validator_t"


class host_velo_ut_validator_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    dev_offsets_all_velo_tracks_t = AllenDataHandle("device", [], "dev_offsets_all_velo_tracks_t", "R", "unsigned int"),
    dev_offsets_velo_track_hit_number_t = AllenDataHandle("device", [], "dev_offsets_velo_track_hit_number_t", "R", "unsigned int"),
    dev_velo_track_hits_t = AllenDataHandle("device", [], "dev_velo_track_hits_t", "R", "char"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    dev_velo_kalman_endvelo_states_t = AllenDataHandle("device", [], "dev_velo_kalman_endvelo_states_t", "R", "char"),
    dev_offsets_ut_tracks_t = AllenDataHandle("device", [], "dev_offsets_ut_tracks_t", "R", "unsigned int"),
    dev_offsets_ut_track_hit_number_t = AllenDataHandle("device", [], "dev_offsets_ut_track_hit_number_t", "R", "unsigned int"),
    dev_ut_track_hits_t = AllenDataHandle("device", [], "dev_ut_track_hits_t", "R", "char"),
    dev_ut_track_velo_indices_t = AllenDataHandle("device", [], "dev_ut_track_velo_indices_t", "R", "unsigned int"),
    dev_ut_qop_t = AllenDataHandle("device", [], "dev_ut_qop_t", "R", "float"),
    host_mc_events_t = AllenDataHandle("host", [], "host_mc_events_t", "R", "const int *"),
    verbosity = "",
    root_output_filename = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.ValidationAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "host_velo_ut_validator"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/host/validators/include/HostVeloUTValidator.h"

  @classmethod
  def getType(cls):
    return "host_velo_ut_validator_t"


class host_velo_validator_t(AllenAlgorithm):
  __slots__ = OrderedDict(
    host_number_of_events_t = AllenDataHandle("host", [], "host_number_of_events_t", "R", "unsigned int"),
    dev_offsets_all_velo_tracks_t = AllenDataHandle("device", [], "dev_offsets_all_velo_tracks_t", "R", "unsigned int"),
    dev_offsets_velo_track_hit_number_t = AllenDataHandle("device", [], "dev_offsets_velo_track_hit_number_t", "R", "unsigned int"),
    dev_velo_track_hits_t = AllenDataHandle("device", [], "dev_velo_track_hits_t", "R", "char"),
    dev_event_list_t = AllenDataHandle("device", [], "dev_event_list_t", "R", "mask_t"),
    host_mc_events_t = AllenDataHandle("host", [], "host_mc_events_t", "R", "const int *"),
    verbosity = "",
    root_output_filename = ""
  )
  aggregates = ()

  @staticmethod
  def category():
    return AlgorithmCategory.ValidationAlgorithm

  def __new__(self, name, **kwargs):
    instance = AllenAlgorithm.__new__(self, name)
    for n,v in kwargs.items():
      setattr(instance, n, v)
    return instance

  @classmethod
  def namespace(cls):
    return "host_velo_validator"

  @classmethod
  def filename(cls):
    return "/group/hlt/fest_202106/dev-dir-Alessandro/stack/Allen/host/validators/include/HostVeloValidator.h"

  @classmethod
  def getType(cls):
    return "host_velo_validator_t"


