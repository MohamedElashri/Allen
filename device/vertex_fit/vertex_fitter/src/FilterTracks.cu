/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "FilterTracks.cuh"
#include "VertexFitDeviceFunctions.cuh"
#include "VertexDefinitions.cuh"
#include "ParKalmanMath.cuh"
#include "ParKalmanDefinitions.cuh"

INSTANTIATE_ALGORITHM(FilterTracks::filter_tracks_t)

void FilterTracks::filter_tracks_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_sv_atomics_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_svs_trk1_idx_t>(arguments, 10 * VertexFit::max_svs * first<host_number_of_events_t>(arguments));
  set_size<dev_svs_trk2_idx_t>(arguments, 10 * VertexFit::max_svs * first<host_number_of_events_t>(arguments));
  set_size<dev_sv_poca_t>(arguments, 3 * 10 * VertexFit::max_svs * first<host_number_of_events_t>(arguments));
  set_size<dev_track_prefilter_result_t>(arguments, first<host_number_of_tracks_t>(arguments));
}

void FilterTracks::filter_tracks_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_sv_atomics_t>(arguments, 0, context);

  global_function(prefilter_tracks)(
    dim3(size<dev_event_list_t>(arguments)), property<block_dim_prefilter_t>(), context)(arguments);

  global_function(filter_tracks)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_filter_t>(), context)(
    arguments);
}

__global__ void FilterTracks::prefilter_tracks(FilterTracks::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const auto long_track_particles = parameters.dev_long_track_particles->container(event_number);
  const unsigned n_tracks = long_track_particles.size();
  float* event_prefilter_result = parameters.dev_track_prefilter_result + long_track_particles.offset();

  for (unsigned i_track = threadIdx.x; i_track < n_tracks; i_track += blockDim.x) {
    const auto track = long_track_particles.particle(i_track);
    const auto state = track.state();
    const float pt = state.pt();
    const float ipchi2 = track.ip_chi2();
    const float ip = track.ip();
    const float chi2ndof = track.chi2() / track.ndof();
    const bool dec = pt > parameters.track_min_pt &&
                     (ipchi2 > parameters.track_min_ipchi2 || ip > parameters.track_min_high_ip || track.is_lepton() ||
                      (ip > parameters.track_min_low_ip && pt > parameters.track_min_pt_low_ip)) &&
                     ((chi2ndof < parameters.track_max_chi2ndof && !track.is_lepton()) ||
                      (chi2ndof < parameters.track_muon_max_chi2ndof && track.is_lepton()));
    const bool p_lambda_dec = chi2ndof < parameters.track_max_chi2ndof && pt > parameters.L_p_PT_min &&
                              ipchi2 > parameters.L_p_MIPCHI2_min && ip > parameters.L_p_MIP_min;
    const bool pi_lambda_dec = chi2ndof < parameters.track_max_chi2ndof && pt > parameters.L_pi_PT_min &&
                               ipchi2 > parameters.L_pi_MIPCHI2_min && ip > parameters.L_pi_MIP_min;
    const bool full_dec = dec || p_lambda_dec || pi_lambda_dec;
    event_prefilter_result[i_track] = full_dec ? ipchi2 : -1.f;
  }
}

__global__ void FilterTracks::filter_tracks(FilterTracks::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  const unsigned idx_offset = event_number * 10 * VertexFit::max_svs;
  unsigned* event_sv_number = parameters.dev_sv_atomics + event_number;
  unsigned* event_svs_trk1_idx = parameters.dev_svs_trk1_idx + idx_offset;
  unsigned* event_svs_trk2_idx = parameters.dev_svs_trk2_idx + idx_offset;
  float* event_poca = parameters.dev_sv_poca + 3 * idx_offset;

  const auto long_track_particles = parameters.dev_long_track_particles->container(event_number);
  float* event_prefilter_result = parameters.dev_track_prefilter_result + long_track_particles.offset();
  const unsigned n_scifi_tracks = long_track_particles.size();

  // Loop over tracks.
  for (unsigned i_track = threadIdx.x; i_track < n_scifi_tracks; i_track += blockDim.x) {
    // Filter first track.
    const float ipchi2A = event_prefilter_result[i_track];
    if (ipchi2A < 0) continue;
    const auto trackA = long_track_particles.particle(i_track);

    for (unsigned j_track = threadIdx.y + i_track + 1; j_track < n_scifi_tracks; j_track += blockDim.y) {
      // Filter second track.
      const float ipchi2B = event_prefilter_result[j_track];
      if (ipchi2B < 0) continue;
      const auto trackB = long_track_particles.particle(j_track);
      const auto stateA = trackA.state(), stateB = trackB.state();

      // need to repeat some of the cuts in prefilter_tracks that are not the same for every species.
      const auto chi2A = trackA.chi2() / trackA.ndof();
      const auto chi2B = trackB.chi2() / trackB.ndof();
      const auto ptA = stateA.pt(), ptB = stateB.pt();
      const auto ipA = trackA.ip(), ipB = trackB.ip();
      const bool generic_track_dec_A =
        ptA > parameters.track_min_pt &&
        (ipchi2A > parameters.track_min_ipchi2 || ipA > parameters.track_min_high_ip || trackA.is_lepton() ||
         (ipA > parameters.track_min_low_ip && ptA > parameters.track_min_pt_low_ip)) &&
        ((chi2A < parameters.track_max_chi2ndof && !trackA.is_lepton()) ||
         (chi2A < parameters.track_muon_max_chi2ndof && trackA.is_lepton()));
      const bool generic_track_dec_B =
        ptB > parameters.track_min_pt &&
        (ipchi2B > parameters.track_min_ipchi2 || ipB > parameters.track_min_high_ip || trackB.is_lepton() ||
         (ipB > parameters.track_min_low_ip && ptB > parameters.track_min_pt_low_ip)) &&
        ((chi2B < parameters.track_max_chi2ndof && !trackB.is_lepton()) ||
         (chi2B < parameters.track_muon_max_chi2ndof && trackB.is_lepton()));
      bool track_decision = generic_track_dec_A && generic_track_dec_B;
      // Same PV cut for non-muons.
      // TODO: The comparison between float3s doesn't compile with clang12.
      // Can't we just compare pointers?
      if (
        &(trackA.pv()) != &(trackB.pv()) && ipchi2A < parameters.max_assoc_ipchi2 &&
        ipchi2B < parameters.max_assoc_ipchi2 && (!trackA.is_lepton() || !trackB.is_lepton())) {
        track_decision = false;
      }

      // create lambda combination
      const auto A_is_proton = stateA.p() > stateB.p();
      auto p_PT = 0.f, pi_PT = 0.f, p_ipchi2 = 0.f, pi_ipchi2 = 0.f, p_ip = 0.f, pi_ip = 0.f;
      if (A_is_proton) {
        p_PT = stateA.pt();
        pi_PT = stateB.pt();
        p_ipchi2 = ipchi2A;
        pi_ipchi2 = ipchi2B;
        p_ip = trackA.ip();
        pi_ip = trackB.ip();
      }
      else {
        p_PT = stateB.pt();
        pi_PT = stateA.pt();
        p_ipchi2 = ipchi2B;
        pi_ipchi2 = ipchi2A;
        p_ip = trackB.ip();
        pi_ip = trackA.ip();
      }
      bool lambda_dec = stateA.charge() != stateB.charge() && p_PT > parameters.L_p_PT_min &&
                        p_ipchi2 > parameters.L_p_MIPCHI2_min && p_ip > parameters.L_p_MIP_min &&
                        pi_PT > parameters.L_pi_PT_min && pi_ipchi2 > parameters.L_pi_MIPCHI2_min &&
                        pi_ip > parameters.L_pi_MIP_min;

      if (lambda_dec) {
        const auto ct_energy = A_is_proton ? sqrtf(stateA.p() * stateA.p() + Allen::mP * Allen::mP) +
                                               sqrtf(stateB.p() * stateB.p() + Allen::mPi * Allen::mPi) :
                                             sqrtf(stateA.p() * stateA.p() + Allen::mPi * Allen::mPi) +
                                               sqrtf(stateB.p() * stateB.p() + Allen::mP * Allen::mP);
        const auto L_pt2 = (stateA.px() + stateB.px()) * (stateA.px() + stateB.px()) +
                           (stateA.py() + stateB.py()) * (stateA.py() + stateB.py());
        const auto L_p2 = L_pt2 + (stateA.pz() + stateB.pz()) * (stateA.pz() + stateB.pz());
        const auto L_mass = sqrtf(ct_energy * ct_energy - L_p2);
        lambda_dec = VertexFit::doca(trackA, trackB) < parameters.L_DOCA_max && L_mass < parameters.L_M_max &&
                     L_pt2 > parameters.L_PT2_min;
      }
      if (track_decision || lambda_dec) {
        // Check the POCA.
        float x, y, z;
        if (!VertexFit::poca(trackA, trackB, x, y, z)) continue;
        // fill outputs
        unsigned vertex_idx = atomicAdd(event_sv_number, 1);
        event_poca[3 * vertex_idx] = x;
        event_poca[3 * vertex_idx + 1] = y;
        event_poca[3 * vertex_idx + 2] = z;
        if (lambda_dec) {
          event_svs_trk1_idx[vertex_idx] = A_is_proton ? i_track : j_track;
          event_svs_trk2_idx[vertex_idx] = A_is_proton ? j_track : i_track;
        }
        else {
          event_svs_trk1_idx[vertex_idx] = i_track;
          event_svs_trk2_idx[vertex_idx] = j_track;
        }
      }
    }
  }
}
