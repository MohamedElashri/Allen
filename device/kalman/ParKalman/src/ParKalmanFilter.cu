/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "ParKalmanFilter.cuh"

void kalman_filter::kalman_filter_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_kf_tracks_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
}

void kalman_filter::kalman_filter_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  const Allen::Context& context) const
{
  global_function(kalman_filter)(dim3(first<host_number_of_events_t>(arguments)), property<block_dim_t>(), stream)(
    arguments, constants.dev_scifi_geometry, constants.dev_inv_clus_res, constants.dev_kalman_params);

  if (runtime_options.do_check) {
    assign_to_host_buffer<dev_kf_tracks_t>(host_buffers.host_kf_tracks, arguments, stream);
  }
}

namespace ParKalmanFilter {
  //----------------------------------------------------------------------
  // Create the output track.
  __device__ void MakeTrack(
    const unsigned n_velo_hits,
    const unsigned n_ut_layers,
    const unsigned n_scifi_layers,
    const Vector5& x,
    const SymMatrix5x5& C,
    const KalmanFloat& z,
    const trackInfo& tI,
    FittedTrack& track)
  {
    track.chi2 = tI.m_chi2;
    track.chi2V = tI.m_chi2V;
    track.chi2T = tI.m_chi2T;
    track.ndof = tI.m_ndof - 5;
    track.ndofV = tI.m_ndofV - 5;
    track.ndofT = tI.m_ndofT - 5;
    track.state = x;
    track.cov = C;
    track.z = z;
    track.first_qop = tI.m_FirstMomEst;
    track.best_qop = tI.m_BestMomEst;
    int n_hits = n_velo_hits + n_ut_layers + n_scifi_layers;
    track.nhits = n_hits;
  }

  //----------------------------------------------------------------------
  // Run the Kalman filter.
  __device__ void fit(
    Velo::Consolidated::ConstHits& velo_hits,
    const unsigned n_velo_hits,
    UT::Consolidated::ConstHits& ut_hits,
    const unsigned n_ut_hits,
    SciFi::Consolidated::ConstExtendedHits& scifi_hits,
    const unsigned n_scifi_hits,
    const KalmanFloat init_qop,
    const KalmanParametrizations* kalman_params,
    FittedTrack& track)
  {
    // Fit information.
    trackInfo tI;
    tI.m_extr = kalman_params;
    tI.m_BestMomEst = init_qop;
    tI.m_FirstMomEst = init_qop;

    // Get UT hit indices.
    uint32_t n_ut_layers = n_ut_hits;
    for (unsigned i_ut = 0; i_ut < n_ut_hits; i_ut++) {
      uint8_t layer = ut_hits.plane_code(i_ut);
      tI.m_UTLayerIdxs[layer] = i_ut;
    }

    // Get SciFi hit indices.
    unsigned n_scifi_layers = n_scifi_hits;
    for (unsigned i_scifi = 0; i_scifi < n_scifi_hits; i_scifi++) {
      uint32_t layer = scifi_hits.planeCode(i_scifi);
      if (tI.m_SciFiLayerIdxs[layer / 2] >= 0) {
        n_scifi_layers--;
      }
      else
        tI.m_SciFiLayerIdxs[layer / 2] = i_scifi;
    }

    unsigned n_total_hits = n_velo_hits + n_ut_layers + n_scifi_layers;
    tI.m_NHits = n_total_hits;
    tI.m_NHitsV = n_velo_hits;
    tI.m_NHitsUT = n_ut_layers;
    tI.m_NHitsT = n_scifi_layers;
    tI.m_ndof = n_scifi_layers + n_ut_layers + 2 * n_velo_hits;
    tI.m_ndofT = n_scifi_layers;
    tI.m_ndofUT = n_ut_layers;
    tI.m_ndofV = 2 * n_velo_hits;

    // Initialize the reference propogation matrix.
    // tI.m_RefPropForwardTotal.SetElements(F_diag);

    // Run the fit.
    KalmanFloat lastz = -1.;
    Vector5 x;
    SymMatrix5x5 C;

    // Best state is closest to the beamline.
    KalmanFloat zBest = 0.;
    Vector5 xBest;
    SymMatrix5x5 CBest;

    // Do a forward iteration.
    CreateVeloSeedState(velo_hits, n_velo_hits, 0, x, C, lastz, tI);
    tI.m_chi2 = 0;
    tI.m_chi2V = 0;

    //------------------------------ Start forward fit.
    // Velo loop.
    UpdateStateV(velo_hits, 1, n_velo_hits - 1, x, C, tI);
    for (unsigned i_hit = 1; i_hit < n_velo_hits; i_hit++) {
      PredictStateV(velo_hits, n_velo_hits - 1 - i_hit, x, C, lastz, tI);
      UpdateStateV(velo_hits, 1, n_velo_hits - 1 - i_hit, x, C, tI);
    }
    __syncthreads();
    KalmanFloat endVeloZ = lastz;

    // Velo -> UT.
    PredictStateVUT(ut_hits, x, C, lastz, tI);
    tI.m_PrevUTLayer = 0;
    while (tI.m_PrevUTLayer < 3 && tI.m_UTLayerIdxs[tI.m_PrevUTLayer] < 0) {
      tI.m_PrevUTLayer++;
      PredictStateUT(ut_hits, tI.m_PrevUTLayer, x, C, lastz, tI);
    }
    __syncthreads();

    // UT loop.
    UpdateStateUT(ut_hits, tI.m_PrevUTLayer, x, C, lastz, tI);
    for (unsigned i_hit = 1; i_hit < n_ut_layers; i_hit++) {
      tI.m_PrevUTLayer++;
      PredictStateUT(ut_hits, tI.m_PrevUTLayer, x, C, lastz, tI);
      while (tI.m_PrevUTLayer < 3 && tI.m_UTLayerIdxs[tI.m_PrevUTLayer] < 0) {
        tI.m_PrevUTLayer++;
        PredictStateUT(ut_hits, tI.m_PrevUTLayer, x, C, lastz, tI);
      }
      UpdateStateUT(ut_hits, tI.m_PrevUTLayer, x, C, lastz, tI);
    }
    __syncthreads();

    // UT -> SciFi.
    while (tI.m_PrevUTLayer < 3) {
      tI.m_PrevUTLayer++;
      PredictStateUT(ut_hits, tI.m_PrevUTLayer, x, C, lastz, tI);
    }
    PredictStateUTT(x, C, lastz, tI);
    tI.m_PrevSciFiLayer = 0;
    while (tI.m_SciFiLayerIdxs[tI.m_PrevSciFiLayer] < 0) {
      tI.m_PrevSciFiLayer++;
      PredictStateT(scifi_hits, tI.m_PrevSciFiLayer, x, C, lastz, tI);
    }
    __syncthreads();

    // SciFi loop.
    UpdateStateT(scifi_hits, tI.m_PrevSciFiLayer, x, C, lastz, tI);
    for (unsigned i_hit = 1; i_hit < n_scifi_layers; i_hit++) {
      tI.m_PrevSciFiLayer++;
      PredictStateT(scifi_hits, tI.m_PrevSciFiLayer, x, C, lastz, tI);
      while (tI.m_PrevSciFiLayer < 11 && tI.m_SciFiLayerIdxs[tI.m_PrevSciFiLayer] < 0) {
        tI.m_PrevSciFiLayer++;
        PredictStateT(scifi_hits, tI.m_PrevSciFiLayer, x, C, lastz, tI);
      }
      UpdateStateT(scifi_hits, tI.m_PrevSciFiLayer, x, C, lastz, tI);
    }
    __syncthreads();
    //------------------------------ End forward fit.

    // Set state and covariance for VELO-only backward fit
    tI.m_BestMomEst = x[4];
    tI.m_RefStateForwardV[4] = x[4];
    x = tI.m_RefStateForwardV;
    C = similarity_5_5(inverse(tI.m_RefPropForwardTotal), C);
    lastz = endVeloZ;

    //------------------------------ Start backward fit.
    // Velo loop.
    UpdateStateV(velo_hits, -1, 0, x, C, tI);
    for (int i_hit = n_velo_hits - 2; i_hit >= 0; i_hit--) {
      PredictStateV(velo_hits, n_velo_hits - 1 - i_hit, x, C, lastz, tI);
      UpdateStateV(velo_hits, -1, n_velo_hits - 1 - i_hit, x, C, tI);
    }
    __syncthreads();
    //------------------------------ End backward fit.

    xBest = x;
    CBest = C;
    zBest = lastz;

    // Straight line extrapolation to the closest point to the beamline.
    // NOTE: Don't do this for now. The track is extrapolated again
    // when calculating IP info anyway.
    // ExtrapolateToVertex(xBest, C, lastz);

    MakeTrack(n_velo_hits, n_ut_layers, n_scifi_layers, xBest, CBest, zBest, tI, track);
  }
} // End namespace ParKalmanFilter.

//----------------------------------------------------------------------
// Kalman filter kernel.
__global__ void kalman_filter::kalman_filter(
  kalman_filter::Parameters parameters,
  const char* dev_scifi_geometry,
  const float* dev_inv_clus_res,
  const ParKalmanFilter::KalmanParametrizations* dev_kalman_params)
{

  const unsigned number_of_events = gridDim.x;
  const unsigned event_number = blockIdx.x;

  // Create velo tracks.
  Velo::Consolidated::ConstTracks velo_tracks {
    parameters.dev_atomics_velo, parameters.dev_velo_track_hit_number, event_number, number_of_events};

  // Create UT tracks.
  UT::Consolidated::ConstExtendedTracks ut_tracks {parameters.dev_atomics_ut,
                                                   parameters.dev_ut_track_hit_number,
                                                   parameters.dev_ut_qop,
                                                   parameters.dev_ut_track_velo_indices,
                                                   event_number,
                                                   number_of_events};

  // Create SciFi tracks.
  SciFi::Consolidated::ConstTracks scifi_tracks {parameters.dev_atomics_scifi,
                                                 parameters.dev_scifi_track_hit_number,
                                                 parameters.dev_scifi_qop,
                                                 parameters.dev_scifi_states,
                                                 parameters.dev_scifi_track_ut_indices,
                                                 event_number,
                                                 number_of_events};

  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};

  // Loop over SciFi tracks and get associated UT and VELO tracks.
  const unsigned n_scifi_tracks = scifi_tracks.number_of_tracks(event_number);
  for (unsigned i_scifi_track = threadIdx.x; i_scifi_track < n_scifi_tracks; i_scifi_track += blockDim.x) {
    // Prepare fit input.
    SciFi::Consolidated::ConstExtendedHits scifi_hits =
      scifi_tracks.get_hits(parameters.dev_scifi_track_hits, i_scifi_track, &scifi_geometry, dev_inv_clus_res);

    const unsigned n_scifi_hits = scifi_tracks.number_of_hits(i_scifi_track);
    const int i_ut_track = scifi_tracks.ut_track(i_scifi_track);
    UT::Consolidated::ConstHits ut_hits = ut_tracks.get_hits(parameters.dev_ut_track_hits, i_ut_track);
    const unsigned n_ut_hits = ut_tracks.number_of_hits(i_ut_track);
    const int i_velo_track = ut_tracks.velo_track(i_ut_track);
    Velo::Consolidated::ConstHits velo_hits = velo_tracks.get_hits(parameters.dev_velo_track_hits, i_velo_track);
    const unsigned n_velo_hits = velo_tracks.number_of_hits(i_velo_track);
    const KalmanFloat init_qop = (KalmanFloat) scifi_tracks.qop(i_scifi_track);
    fit(
      velo_hits,
      n_velo_hits,
      ut_hits,
      n_ut_hits,
      scifi_hits,
      n_scifi_hits,
      init_qop,
      dev_kalman_params,
      parameters.dev_kf_tracks[scifi_tracks.tracks_offset(event_number) + i_scifi_track]);
  }
}
