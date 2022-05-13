#pragma once

#include "AlgorithmTypes.cuh"
#include "EventLine.cuh"
#include "VeloConsolidated.cuh"
#include "CaloDigit.cuh"
#include "CaloGeometry.cuh"
#include "PV_Definitions.cuh"

namespace heavy_ion_event_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_velo_tracks_t, Allen::Views::Velo::Consolidated::Tracks) dev_velo_tracks;
    DEVICE_INPUT(dev_velo_states_t, Allen::Views::Physics::KalmanStates) dev_velo_states;
    DEVICE_INPUT(dev_ecal_digits_t, CaloDigit) dev_ecal_digits;
    DEVICE_INPUT(dev_ecal_digits_offsets_t, unsigned) dev_ecal_digits_offsets;
    DEVICE_INPUT(dev_pvs_t, PV::Vertex) dev_pvs;
    DEVICE_INPUT(dev_number_of_pvs_t, unsigned) dev_number_of_pvs;
    HOST_OUTPUT(host_decisions_size_t, unsigned) host_decisions_size;
    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;
    HOST_OUTPUT(host_fn_parameters_t, char) host_fn_parameters;
    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(min_velo_tracks_PbPb_t, "min_velo_tracks_PbPb", "Minimum number of VELO tracks in the PbPb region", int) min_velo_tracks_PbPb;
    PROPERTY(max_velo_tracks_PbPb_t, "max_velo_tracks_PbPb", "Maximum number of VELO tracks in the PbPb region", int) max_velo_tracks_PbPb;
    PROPERTY(min_velo_tracks_SMOG_t, "min_velo_tracks_SMOG", "Minimum number of VELO tracks in the SMOG region", int) min_velo_tracks_SMOG;
    PROPERTY(max_velo_tracks_SMOG_t, "max_velo_tracks_SMOG", "Maximum number of VELO tracks in the SMOG region", int) max_velo_tracks_SMOG;
    PROPERTY(min_pvs_PbPb_t, "min_pvs_PbPb", "Minimum number of PVs in the PbPb region", int) min_pvs_PbPb;
    PROPERTY(max_pvs_PbPb_t, "max_pvs_PbPb", "Maximum number of PVs in the PbPb region", int) max_pvs_PbPb;
    PROPERTY(min_pvs_SMOG_t, "min_pvs_SMOG", "Minimum number of PVs in the SMOG region", int) min_pvs_SMOG;
    PROPERTY(max_pvs_SMOG_t, "max_pvs_SMOG", "Maximum number of PVs in the SMOG region", int) max_pvs_SMOG;
    PROPERTY(min_ecal_e_t, "min_ecal_e", "Minimum ECAL energy", float) min_ecal_e;
    PROPERTY(max_ecal_e_t, "max_ecal_e", "Maximum ECAL energy", float) max_ecal_e;
  };

  struct heavy_ion_event_line_t : public SelectionAlgorithm, Parameters, EventLine<heavy_ion_event_line_t, Parameters> {
    // Tuple includes:
    // Number of velo tracks in PbPb region
    // Number of velo tracks in SMOG region
    // Number of PVs in PbPb region
    // Number of PVs in SMOG region
    // Total ECAL energy
    __device__ static std::tuple<const int, const int, const int, const int, const float>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned);

    __device__ static bool select(
      const Parameters& parameters,
      std::tuple<const int, const int, const int, const int, const float> input);

    private:
      Property<pre_scaler_t> m_pre_scaler {this, 1.f};
      Property<post_scaler_t> m_post_scaler {this, 1.f};
      Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
      Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
      Property<min_velo_tracks_PbPb_t> m_min_velo_tracks_PbPb {this, 0};
      Property<max_velo_tracks_PbPb_t> m_max_velo_tracks_PbPb {this, -1};
      Property<min_velo_tracks_SMOG_t> m_min_velo_tracks_SMOG {this, 0};
      Property<max_velo_tracks_SMOG_t> m_max_velo_tracks_SMOG {this, -1};
      Property<min_pvs_PbPb_t> m_min_pvs_PbPb {this, 0};
      Property<max_pvs_PbPb_t> m_max_pvs_PbPb {this, -1};
      Property<min_pvs_SMOG_t> m_min_pvs_SMOG {this, 0};
      Property<max_pvs_SMOG_t> m_max_pvs_SMOG {this, -1};
      Property<min_ecal_e_t> m_min_ecal_e {this, 0.f};
      Property<max_ecal_e_t> m_max_ecal_e {this, -1.f};
  };
}