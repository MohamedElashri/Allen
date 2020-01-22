#pragma once

#include "ParKalmanDefinitions.cuh"
#include "ParKalmanMath.cuh"
#include "VertexDefinitions.cuh"
#include "PV_Definitions.cuh"
#include "SciFiConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "VeloConsolidated.cuh"
#include "AssociateConsolidated.cuh"
#include "States.cuh"
#include "DeviceAlgorithm.cuh"

namespace VertexFit {

  __device__ bool poca(
    const ParKalmanFilter::FittedTrack& trackA,
    const ParKalmanFilter::FittedTrack& trackB,
    float& x,
    float& y,
    float& z);
  __device__ float ip(float x0, float y0, float z0, float x, float y, float z, float tx, float ty);

  __device__ float addToDerivatives(
    const ParKalmanFilter::FittedTrack& track,
    const float& x,
    const float& y,
    const float& z,
    float& halfDChi2_0,
    float& halfDChi2_1,
    float& halfDChi2_2,
    float& halfD2Chi2_00,
    float& halfD2Chi2_11,
    float& halfD2Chi2_20,
    float& halfD2Chi2_21,
    float& halfD2Chi2_22);

  __device__ float solve(
    float& x,
    float& y,
    float& z,
    float& cov00,
    float& cov11,
    float& cov20,
    float& cov21,
    float& cov22,
    const float& halfDChi2_0,
    const float& halfDChi2_1,
    const float& halfDChi2_2,
    const float& halfD2Chi2_00,
    const float& halfD2Chi2_11,
    const float& halfD2Chi2_20,
    const float& halfD2Chi2_21,
    const float& halfD2Chi2_22);

  __device__ bool
  doFit(const ParKalmanFilter::FittedTrack& trackA, const ParKalmanFilter::FittedTrack& trackB, TrackMVAVertex& vertex);

  __device__ void fill_extra_info(
    TrackMVAVertex& sv,
    const ParKalmanFilter::FittedTrack& trackA,
    const ParKalmanFilter::FittedTrack& trackB);

  __device__ void fill_extra_pv_info(
    TrackMVAVertex& sv,
    const PV::Vertex& pv,
    const ParKalmanFilter::FittedTrack& trackA,
    const ParKalmanFilter::FittedTrack& trackB);

} // namespace VertexFit

namespace fit_secondary_vertices {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_number_of_svs_t, uint);
    DEVICE_INPUT(dev_kf_tracks_t, ParKalmanFilter::FittedTrack) dev_kf_tracks;
    DEVICE_INPUT(dev_atomics_scifi_t, uint) dev_atomics_scifi;
    DEVICE_INPUT(dev_scifi_track_hit_number_t, uint) dev_scifi_track_hit_number;
    DEVICE_INPUT(dev_scifi_qop_t, float) dev_scifi_qop;
    DEVICE_INPUT(dev_scifi_states_t, MiniState) dev_scifi_states;
    DEVICE_INPUT(dev_scifi_track_ut_indices_t, uint) dev_scifi_track_ut_indices;
    DEVICE_INPUT(dev_multi_fit_vertices_t, PV::Vertex) dev_multi_fit_vertices;
    DEVICE_INPUT(dev_number_of_multi_fit_vertices_t, uint) dev_number_of_multi_fit_vertices;
    DEVICE_INPUT(dev_kalman_pv_ipchi2_t, char) dev_kalman_pv_ipchi2;
    DEVICE_OUTPUT(dev_sv_atomics_t, uint) dev_sv_atomics;
    DEVICE_OUTPUT(dev_secondary_vertices_t, VertexFit::TrackMVAVertex) dev_secondary_vertices;
  };

  __global__ void fit_secondary_vertices(Parameters);

  template<typename T, char... S>
  struct fit_secondary_vertices_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(fit_secondary_vertices)) function {fit_secondary_vertices};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_secondary_vertices_t>(
        arguments, VertexFit::max_svs * value<host_number_of_selected_events_t>(arguments));
      set_size<dev_sv_atomics_t>(arguments, value<host_number_of_selected_events_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      cudaCheck(
        cudaMemsetAsync(offset<dev_sv_atomics_t>(arguments), 0, size<dev_sv_atomics_t>(arguments), cuda_stream));

      function(dim3(value<host_number_of_selected_events_t>(arguments)), block_dimension(), cuda_stream)(
        Parameters {offset<dev_kf_tracks_t>(arguments),
                    offset<dev_atomics_scifi_t>(arguments),
                    offset<dev_scifi_track_hit_number_t>(arguments),
                    offset<dev_scifi_qop_t>(arguments),
                    offset<dev_scifi_states_t>(arguments),
                    offset<dev_scifi_track_ut_indices_t>(arguments),
                    offset<dev_multi_fit_vertices_t>(arguments),
                    offset<dev_number_of_multi_fit_vertices_t>(arguments),
                    offset<dev_kalman_pv_ipchi2_t>(arguments),
                    offset<dev_sv_atomics_t>(arguments),
                    offset<dev_secondary_vertices_t>(arguments)});

      if (runtime_options.do_check) {
        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_sv_atomics,
          offset<dev_sv_atomics_t>(arguments),
          size<dev_sv_atomics_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));
      }
    }

  private:
    Property<float> m_minpt {this,
                             "track_min_pt",
                             Configuration::fit_secondary_vertices_t::track_min_pt,
                             200.0f,
                             "minimum track pT"};
    Property<float> m_minipchi2 {this,
                                 "track_min_ipchi2",
                                 Configuration::fit_secondary_vertices_t::track_min_ipchi2,
                                 9.0f,
                                 "minimum track IP chi2"};
    Property<float> m_minmuipchi2 {this,
                                   "track_muon_min_ipchi2",
                                   Configuration::fit_secondary_vertices_t::track_muon_min_ipchi2,
                                   4.0f,
                                   "minimum muon IP chi2"};
    Property<float> m_maxassocipchi2 {this,
                                      "max_assoc_ipchi2",
                                      Configuration::fit_secondary_vertices_t::max_assoc_ipchi2,
                                      16.0f,
                                      "maximum IP chi2 to associate to PV"};
  };
} // namespace fit_secondary_vertices
