/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "ConsolidateSciFi.cuh"

void scifi_consolidate_tracks::scifi_consolidate_tracks_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_scifi_track_hits_t>(
    arguments, first<host_accumulated_number_of_hits_in_scifi_tracks_t>(arguments) * sizeof(SciFi::Hit));
  set_size<dev_scifi_qop_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
  set_size<dev_scifi_track_ut_indices_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
  set_size<dev_scifi_states_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
}

void scifi_consolidate_tracks::scifi_consolidate_tracks_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  const Allen::Context& context) const
{
  global_function(scifi_consolidate_tracks)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments, constants.dev_looking_forward_constants, constants.dev_magnet_polarity.data());

  if (runtime_options.do_check) {
    // Transmission device to host of Scifi consolidated tracks
    assign_to_host_buffer<dev_offsets_forward_tracks_t>(host_buffers.host_atomics_scifi, arguments, context);
    assign_to_host_buffer<dev_offsets_scifi_track_hit_number_t>(
      host_buffers.host_scifi_track_hit_number, arguments, context);
    assign_to_host_buffer<dev_scifi_track_hits_t>(host_buffers.host_scifi_track_hits, arguments, context);
    assign_to_host_buffer<dev_scifi_qop_t>(host_buffers.host_scifi_qop, arguments, context);
    assign_to_host_buffer<dev_scifi_track_ut_indices_t>(host_buffers.host_scifi_track_ut_indices, arguments, context);
    assign_to_host_buffer<dev_scifi_states_t>(host_buffers.host_scifi_states, arguments, context);
  }
}

template<typename F>
__device__ void populate(const SciFi::TrackHits& track, const F& assign)
{
  for (int i = 0; i < track.hitsNum; i++) {
    const auto hit_index = track.hits[i];
    assign(i, hit_index);
  }
}
/*
__device__ float qop_calculation(
  LookingForward::Constants const* dev_looking_forward_constants,
  float const magSign,
  float const z0SciFi,
  float const x0SciFi,
  float const y0SciFi,
  float const xVelo,
  float const yVelo,
  float const zVelo,
  float const txO,
  float const tyO,
  float const txSciFi,
  float const tySciFi) 
{
  const auto zMatch = ( x0SciFi - xVelo + txO*zVelo - txSciFi*z0SciFi )/(txO -txSciFi);
  const auto xMatch = xVelo + txO*(zMatch - zVelo);
  const auto yMatch = yVelo + tyO*(zMatch - zVelo);
  const auto xVelo_at0 = xVelo - txO * zVelo;
  const auto yVelo_at0 = yVelo - tyO * zVelo;
  const auto FLIGHTPATH_MAGNET_SCI_SQ =  (x0SciFi-xMatch)*(x0SciFi-xMatch) + (y0SciFi-yMatch)*(y0SciFi-yMatch)+ (z0SciFi-zMatch)*(z0SciFi-zMatch) ;
  const auto FLIGHTPATH_VELO_MAGNET_SQ =  (xVelo_at0-xMatch)*(xVelo_at0-xMatch) + (yVelo_at0-yMatch)*(yVelo_at0-yMatch)+ (0-zMatch)*(0-zMatch) ;
  const auto FLIGHTPATH = 0.001f*sqrtf( FLIGHTPATH_MAGNET_SCI_SQ +FLIGHTPATH_VELO_MAGNET_SQ );
  const auto MAGFIELD =  FLIGHTPATH * cosf(asinf(tyO));
  const auto DSLOPE = txSciFi/( sqrtf( 1+ txSciFi * txSciFi + tySciFi * tySciFi)) - txO/(sqrtf( 1+ txO*txO + tyO*tyO));

  const auto txO2 = powf(txO, 2);
  const auto txO3 = powf(txO, 3);
  const auto txO4 = powf(txO, 4);
  const auto txO5 = powf(txO, 5);
  const auto txO6 = powf(txO, 6);
  const auto txO7 = powf(txO, 7);   
  const auto tyO2 = powf(tyO, 2);
  const auto tyO4 = powf(tyO, 4);
  const auto tyO5 = powf(tyO, 5);
  const auto tyO6 = powf(tyO, 6);

  const auto C0 = dev_looking_forward_constants->C0[0]+dev_looking_forward_constants->C0[1]*txO2 + dev_looking_forward_constants->C0[2]*txO4 + dev_looking_forward_constants->C0[3]*tyO2 + dev_looking_forward_constants->C0[4]*tyO4 + dev_looking_forward_constants->C0[5]*txO2*tyO2 + dev_looking_forward_constants->C0[6]*txO6 + dev_looking_forward_constants->C0[7]*tyO5 + dev_looking_forward_constants->C0[8]*txO4*tyO2 + dev_looking_forward_constants->C0[9]*txO2*tyO4;
  const auto C1 = dev_looking_forward_constants->C1[0]+dev_looking_forward_constants->C1[1]*txO + dev_looking_forward_constants->C1[2]*txO3 +dev_looking_forward_constants->C1[3]*txO5 +dev_looking_forward_constants->C1[4]*txO7 + dev_looking_forward_constants->C1[5]*tyO2 + dev_looking_forward_constants->C1[6]*tyO4 + dev_looking_forward_constants->C1[7]*tyO6 + dev_looking_forward_constants->C1[8]*txO*tyO2 +dev_looking_forward_constants->C1[9]*txO*tyO4 +dev_looking_forward_constants->C1[10]*txO*tyO6 +dev_looking_forward_constants->C1[11]*txO3*tyO2 + dev_looking_forward_constants->C1[12]*txO3*tyO4 + dev_looking_forward_constants->C1[13]*txO5*tyO2;
  const auto C2 = dev_looking_forward_constants->C2[0]+dev_looking_forward_constants->C2[1]*txO2 + dev_looking_forward_constants->C2[2]*txO4 + dev_looking_forward_constants->C2[3]*tyO2 + dev_looking_forward_constants->C2[4]*tyO4  + dev_looking_forward_constants->C2[5]*txO2*tyO2  + dev_looking_forward_constants->C2[6]*txO6 + dev_looking_forward_constants->C2[7]*tyO5 + dev_looking_forward_constants->C2[8]*txO4*tyO2 + dev_looking_forward_constants->C2[9]*txO2*tyO4;
  const auto C3 = dev_looking_forward_constants->C3[0]+dev_looking_forward_constants->C3[1]*txO + dev_looking_forward_constants->C3[2]*txO3 +dev_looking_forward_constants->C3[3]*txO5 +dev_looking_forward_constants->C3[4]*txO7 + dev_looking_forward_constants->C3[5]*tyO2 + dev_looking_forward_constants->C3[6]*tyO4 + dev_looking_forward_constants->C3[7]*tyO6 + dev_looking_forward_constants->C3[8]*txO*tyO2 +dev_looking_forward_constants->C3[9]*txO*tyO4 +dev_looking_forward_constants->C3[10]*txO*tyO6 +dev_looking_forward_constants->C3[11]*txO3*tyO2 + dev_looking_forward_constants->C3[12]*txO3*tyO4 + dev_looking_forward_constants->C3[13]*txO5*tyO2;
  const auto C4 = dev_looking_forward_constants->C4[0]+dev_looking_forward_constants->C4[1]*txO2 + dev_looking_forward_constants->C4[2]*txO4 + dev_looking_forward_constants->C4[3]*tyO2 + dev_looking_forward_constants->C4[4]*tyO4  + dev_looking_forward_constants->C4[5]*txO2*tyO2  + dev_looking_forward_constants->C4[6]*txO6 + dev_looking_forward_constants->C4[7]*tyO5 + dev_looking_forward_constants->C4[8]*txO4*tyO2 + dev_looking_forward_constants->C4[9]*txO2*tyO4;

  const auto MAGFIELD_updated = MAGFIELD * magSign * ( C0 + C1 * DSLOPE + C2 * DSLOPE*DSLOPE + C3 * DSLOPE*DSLOPE*DSLOPE + C4 * DSLOPE*DSLOPE*DSLOPE*DSLOPE);
  const auto qop = DSLOPE / MAGFIELD_updated;
  return qop;
}*/

__global__ void scifi_consolidate_tracks::scifi_consolidate_tracks(
  scifi_consolidate_tracks::Parameters parameters,
  const LookingForward::Constants* dev_looking_forward_constants, 
  const float* dev_magnet_polarity)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  // UT consolidated tracks
  UT::Consolidated::ConstTracks ut_tracks {
    parameters.dev_atomics_ut, parameters.dev_ut_track_hit_number, event_number, number_of_events};

  const auto ut_event_tracks_offset = ut_tracks.tracks_offset(event_number);
  const auto ut_total_number_of_tracks = ut_tracks.total_number_of_tracks();

  // const SciFi::TrackHits* event_scifi_tracks =
  //   parameters.dev_scifi_tracks + ut_event_tracks_offset *
  //   LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter;
  const SciFi::TrackHits* event_scifi_tracks =
    parameters.dev_scifi_tracks + ut_event_tracks_offset * SciFi::Constants::max_SciFi_tracks_per_UT_track;

  const unsigned total_number_of_scifi_hits =
    parameters.dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];

  SciFi::ConstHits scifi_hits {parameters.dev_scifi_hits, total_number_of_scifi_hits};
  SciFi::ConstHitCount scifi_hit_count {parameters.dev_scifi_hit_count, event_number};
  const Velo::Consolidated::Tracks velo_tracks {     parameters.dev_atomics_velo, parameters.dev_velo_track_hit_number, event_number, number_of_events};
  Velo::Consolidated::ConstStates velo_states {parameters.dev_velo_states, velo_tracks.total_number_of_tracks()};

  // Create consolidated SoAs.
  SciFi::Consolidated::Tracks scifi_tracks {parameters.dev_atomics_scifi,
                                            parameters.dev_scifi_track_hit_number,
                                            parameters.dev_scifi_qop,
                                            parameters.dev_scifi_states,
                                            parameters.dev_scifi_track_ut_indices,
                                            event_number,
                                            number_of_events};

  UT::Consolidated::ConstExtendedTracks ut_extendedtracks {parameters.dev_atomics_ut,
                                                           parameters.dev_ut_track_hit_number,
	                                                   parameters.dev_ut_qop,
	                                                   parameters.dev_ut_track_velo_indices,
		                                           event_number,
		                                           number_of_events};
  
  const unsigned number_of_tracks_event = scifi_tracks.number_of_tracks(event_number);
  const unsigned event_offset = scifi_hit_count.event_offset();
  const unsigned velo_event_tracks_offset = velo_tracks.tracks_offset(event_number);

  // Loop over tracks.
  for (unsigned i = threadIdx.x; i < number_of_tracks_event; i += blockDim.x) {
  
    const int velo_track_index = ut_extendedtracks.velo_track(event_scifi_tracks[i].ut_track_index);
    const unsigned velo_states_index = velo_event_tracks_offset + velo_track_index;
    const MiniState velo_state = velo_states.get(velo_states_index);
  
    scifi_tracks.ut_track(i) = event_scifi_tracks[i].ut_track_index;
    const auto scifi_track_index = ut_event_tracks_offset * SciFi::Constants::max_SciFi_tracks_per_UT_track + i;

    const auto curvature = parameters.dev_scifi_lf_parametrization_consolidate[scifi_track_index];
    const auto tx = parameters.dev_scifi_lf_parametrization_consolidate
                      [ut_total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track + scifi_track_index];
    const auto x0 =
      parameters.dev_scifi_lf_parametrization_consolidate
        [2 * ut_total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track + scifi_track_index];
    const auto d_ratio =
      parameters.dev_scifi_lf_parametrization_consolidate
        [3 * ut_total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track + scifi_track_index];
    const auto y0 =
      parameters.dev_scifi_lf_parametrization_consolidate
        [4 * ut_total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track + scifi_track_index];
    const auto ty =
      parameters.dev_scifi_lf_parametrization_consolidate
        [5 * ut_total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track + scifi_track_index];

    const auto dz = SciFi::Constants::ZEndT - LookingForward::z_mid_t;
    const MiniState scifi_state {x0 + tx * dz + curvature * dz * dz * (1.f + d_ratio * dz),
                                 y0 + ty * SciFi::Constants::ZEndT,
                                 SciFi::Constants::ZEndT,
                                 tx + 2.f * dz * curvature + 3.f * dz * dz * curvature * d_ratio,
                                 ty};

    scifi_tracks.states(i) = scifi_state;

    auto consolidated_hits = scifi_tracks.get_hits(parameters.dev_scifi_track_hits, i);
    const SciFi::TrackHits& track = event_scifi_tracks[i];

    // update qop     
    const float magSign = dev_magnet_polarity[0];     
    const auto z0 = LookingForward::z_mid_t;     
    const auto xVelo = velo_state.x;     
    const auto yVelo = velo_state.y;     
    const auto zVelo = velo_state.z;     
    const auto txO = velo_state.tx;     
    const auto tyO = velo_state.ty;     
    const auto zMatch = ( x0 - xVelo + txO*zVelo - tx*z0 )/(txO -tx);     
    const auto xMatch = xVelo + txO*(zMatch - zVelo);     
    const auto yMatch = yVelo + tyO*(zMatch - zVelo);     
    const auto xVelo_at0 = xVelo - txO * zVelo;     
    const auto yVelo_at0 = yVelo - tyO * zVelo;     
    const auto FLIGHTPATH_MAGNET_SCI_SQ =  (x0-xMatch)*(x0-xMatch) + (y0-yMatch)*(y0-yMatch)+ (z0-zMatch)*(z0-zMatch) ;     
    const auto FLIGHTPATH_VELO_MAGNET_SQ =  (xVelo_at0-xMatch)*(xVelo_at0-xMatch) + (yVelo_at0-yMatch)*(yVelo_at0-yMatch)+ (0-zMatch)*(0-zMatch) ;     
    const auto FLIGHTPATH = 0.001*sqrt( FLIGHTPATH_MAGNET_SCI_SQ +FLIGHTPATH_VELO_MAGNET_SQ );    
    const auto MAGFIELD =  FLIGHTPATH * cos(asin(tyO));     
    const auto DSLOPE = tx/( sqrt( 1+ tx * tx + ty * ty)) - txO/(sqrt( 1+ txO*txO + tyO*tyO));     
    const auto txO2 = pow(txO, 2);     
    const auto txO3 = pow(txO, 3);     
    const auto txO4 = pow(txO, 4);     
    const auto txO5 = pow(txO, 5);     
    const auto txO6 = pow(txO, 6);     
    const auto txO7 = pow(txO, 7);         
    const auto tyO2 = pow(tyO, 2);     
    const auto tyO4 = pow(tyO, 4);     
    const auto tyO5 = pow(tyO, 5);     
    const auto tyO6 = pow(tyO, 6);     
    const auto C0 = dev_looking_forward_constants->C0[0]+dev_looking_forward_constants->C0[1]*txO2 + dev_looking_forward_constants->C0[2]*txO4 + dev_looking_forward_constants->C0[3]*tyO2 + dev_looking_forward_constants->C0[4]*tyO4 + dev_looking_forward_constants->C0[5]*txO2*tyO2 + dev_looking_forward_constants->C0[6]*txO6 + dev_looking_forward_constants->C0[7]*tyO5 + dev_looking_forward_constants->C0[8]*txO4*tyO2 + dev_looking_forward_constants->C0[9]*txO2*tyO4;     
    const auto C1 = dev_looking_forward_constants->C1[0]+dev_looking_forward_constants->C1[1]*txO + dev_looking_forward_constants->C1[2]*txO3 +dev_looking_forward_constants->C1[3]*txO5 +dev_looking_forward_constants->C1[4]*txO7 + dev_looking_forward_constants->C1[5]*tyO2 + dev_looking_forward_constants->C1[6]*tyO4 + dev_looking_forward_constants->C1[7]*tyO6 + dev_looking_forward_constants->C1[8]*txO*tyO2 +dev_looking_forward_constants->C1[9]*txO*tyO4 +dev_looking_forward_constants->C1[10]*txO*tyO6 +dev_looking_forward_constants->C1[11]*txO3*tyO2 + dev_looking_forward_constants->C1[12]*txO3*tyO4 + dev_looking_forward_constants->C1[13]*txO5*tyO2;     
    const auto C2 = dev_looking_forward_constants->C2[0]+dev_looking_forward_constants->C2[1]*txO2 + dev_looking_forward_constants->C2[2]*txO4 + dev_looking_forward_constants->C2[3]*tyO2 + dev_looking_forward_constants->C2[4]*tyO4  + dev_looking_forward_constants->C2[5]*txO2*tyO2  + dev_looking_forward_constants->C2[6]*txO6 + dev_looking_forward_constants->C2[7]*tyO5 + dev_looking_forward_constants->C2[8]*txO4*tyO2 + dev_looking_forward_constants->C2[9]*txO2*tyO4;    
    const auto C3 = dev_looking_forward_constants->C3[0]+dev_looking_forward_constants->C3[1]*txO + dev_looking_forward_constants->C3[2]*txO3 +dev_looking_forward_constants->C3[3]*txO5 +dev_looking_forward_constants->C3[4]*txO7 + dev_looking_forward_constants->C3[5]*tyO2 + dev_looking_forward_constants->C3[6]*tyO4 + dev_looking_forward_constants->C3[7]*tyO6 + dev_looking_forward_constants->C3[8]*txO*tyO2 +dev_looking_forward_constants->C3[9]*txO*tyO4 +dev_looking_forward_constants->C3[10]*txO*tyO6 +dev_looking_forward_constants->C3[11]*txO3*tyO2 + dev_looking_forward_constants->C3[12]*txO3*tyO4 + dev_looking_forward_constants->C3[13]*txO5*tyO2;     
    const auto C4 = dev_looking_forward_constants->C4[0]+dev_looking_forward_constants->C4[1]*txO2 + dev_looking_forward_constants->C4[2]*txO4 + dev_looking_forward_constants->C4[3]*tyO2 + dev_looking_forward_constants->C4[4]*tyO4  + dev_looking_forward_constants->C4[5]*txO2*tyO2  + dev_looking_forward_constants->C4[6]*txO6 + dev_looking_forward_constants->C4[7]*tyO5 + dev_looking_forward_constants->C4[8]*txO4*tyO2 + dev_looking_forward_constants->C4[9]*txO2*tyO4;    
    const auto MAGFIELD_updated = MAGFIELD * magSign * ( C0 + C1 * DSLOPE + C2 * DSLOPE*DSLOPE + C3 * DSLOPE*DSLOPE*DSLOPE + C4 * DSLOPE*DSLOPE*DSLOPE*DSLOPE);    
    const auto qop = DSLOPE / MAGFIELD_updated;     
    scifi_tracks.qop(i) = qop;

/*    const auto magSign = dev_magnet_polarity[0];
    const auto z0 = LookingForward::z_mid_t;
    const auto xVelo = velo_state.x;
    const auto yVelo = velo_state.y;
    const auto zVelo = velo_state.z;
    const auto txO = velo_state.tx;
    const auto tyO = velo_state.ty;

    // update qop
    scifi_tracks.qop(i) = qop_calculation(
      dev_looking_forward_constants,
      magSign,
      z0,
      x0,
      y0,
      xVelo,
      yVelo,
      zVelo,
      txO,
      tyO,
      tx,
      ty);   */
    
    // Populate arrays
    populate(track, [&consolidated_hits, &scifi_hits, &event_offset](const unsigned i, const unsigned hit_index) {
      consolidated_hits.x0(i) = scifi_hits.x0(event_offset + hit_index);
    });

    populate(track, [&consolidated_hits, &scifi_hits, &event_offset](const unsigned i, const unsigned hit_index) {
      consolidated_hits.z0(i) = scifi_hits.z0(event_offset + hit_index);
    });

    populate(track, [&consolidated_hits, &scifi_hits, &event_offset](const unsigned i, const unsigned hit_index) {
      consolidated_hits.endPointY(i) = scifi_hits.endPointY(event_offset + hit_index);
    });

    populate(track, [&consolidated_hits, &scifi_hits, &event_offset](const unsigned i, const unsigned hit_index) {
      consolidated_hits.channel(i) = scifi_hits.channel(event_offset + hit_index);
    });

    populate(track, [&consolidated_hits, &scifi_hits, &event_offset](const unsigned i, const unsigned hit_index) {
      consolidated_hits.assembled_datatype(i) = scifi_hits.assembled_datatype(event_offset + hit_index);
    });
  }
}
