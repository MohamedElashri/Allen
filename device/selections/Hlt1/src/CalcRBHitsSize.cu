/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "CalcRBHitsSize.cuh"
#include "SelectionsEventModel.cuh"
#include "LHCbIDContainer.cuh"
#include "HltDecReport.cuh"
#include "VertexDefinitions.cuh"

INSTANTIATE_ALGORITHM(calc_rb_hits_size::calc_rb_hits_size_t)

void calc_rb_hits_size::calc_rb_hits_size_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_candidate_count_t>(
    arguments, first<host_number_of_active_lines_t>(arguments) * first<host_number_of_events_t>(arguments));
  set_size<dev_track_tags_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
  set_size<dev_sv_tags_t>(arguments, first<host_number_of_svs_t>(arguments));
  set_size<dev_tag_hits_counts_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
  set_size<dev_sel_track_count_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_sel_track_indices_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
  set_size<dev_sel_track_inserts_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
  set_size<dev_sel_track_tables_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_sel_sv_count_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_sel_sv_indices_t>(arguments, first<host_number_of_svs_t>(arguments));
  set_size<dev_sel_sv_inserts_t>(arguments, first<host_number_of_svs_t>(arguments));
  set_size<dev_sel_sv_tables_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_hits_bank_size_t>(arguments, first<host_number_of_events_t>(arguments));
}

void calc_rb_hits_size::calc_rb_hits_size_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  // Run the tagger.
  initialize<dev_candidate_count_t>(arguments, 0, context);
  initialize<dev_tag_hits_counts_t>(arguments, 0, context);
  initialize<dev_track_tags_t>(arguments, 0, context);
  initialize<dev_sv_tags_t>(arguments, 0, context);
  initialize<dev_sel_track_count_t>(arguments, 0, context);
  initialize<dev_sel_sv_count_t>(arguments, 0, context);
  initialize<dev_hits_bank_size_t>(arguments, 0, context);
  global_function(calc_size)(dim3(first<host_number_of_events_t>(arguments)), property<block_dim_t>(), context)(
    arguments, first<host_number_of_events_t>(arguments));
}

__global__ void calc_rb_hits_size::calc_size(calc_rb_hits_size::Parameters parameters, const unsigned total_events)
{
  const auto event_number = blockIdx.x;
  const auto event_tracks = parameters.dev_long_track_particles[event_number];
  const unsigned track_offset = event_tracks.offset();
  const auto event_svs = parameters.dev_two_track_particles[event_number];
  const unsigned sv_offset = event_svs.offset();
  const uint32_t* event_dec_reports =
    parameters.dev_dec_reports + (2 + parameters.dev_number_of_active_lines[0]) * event_number;
  unsigned* event_candidate_count =
    parameters.dev_candidate_count + event_number * parameters.dev_number_of_active_lines[0];

  Selections::ConstSelections selections {parameters.dev_selections, parameters.dev_selections_offsets, total_events};

  for (unsigned line_index = 0; line_index < parameters.dev_number_of_active_lines[0]; line_index += 1) {

    HltDecReport dec_report;
    dec_report.setDecReport(event_dec_reports[2 + line_index]);
    if (!dec_report.getDecision()) continue;

    uint8_t sel_type = parameters.dev_lhcbid_containers[line_index];

    // Handle lines with no container.
    if (sel_type == to_integral(LHCbIDContainer::none)) continue;

    // Handle 1-track lines.
    if (sel_type == to_integral(LHCbIDContainer::track)) {
      auto decs = selections.get_span(line_index, event_number);
      for (unsigned track_index = threadIdx.x; track_index < event_tracks.size(); track_index += blockDim.x) {
        if (decs[track_index]) {
          parameters.dev_track_tags[track_offset + track_index] = 1;
          atomicAdd(event_candidate_count + line_index, 1);
        }
      }
    }

    // Handle 2-track lines.
    if (sel_type == to_integral(LHCbIDContainer::sv)) {
      auto decs = selections.get_span(line_index, event_number);
      for (unsigned sv_index = threadIdx.x; sv_index < event_svs.size(); sv_index += blockDim.x) {
        if (decs[sv_index]) {
          const auto sv = event_svs.particle(sv_index);
          const Allen::Views::Physics::BasicParticle* track1 =
            static_cast<const Allen::Views::Physics::BasicParticle*>(sv.substructure(0));
          const Allen::Views::Physics::BasicParticle* track2 =
            static_cast<const Allen::Views::Physics::BasicParticle*>(sv.substructure(1));
          const unsigned track1_index = track1->get_index();
          const unsigned track2_index = track2->get_index();
          parameters.dev_sv_tags[sv_offset + sv_index] = 1;
          parameters.dev_track_tags[track_offset + track1_index] = 1;
          parameters.dev_track_tags[track_offset + track2_index] = 1;
          atomicAdd(event_candidate_count + line_index, 1);
        }
      }
    }
  }

  __syncthreads();

  // Populate the tagged track hit numbers, track count, and track list.
  for (unsigned track_index = threadIdx.x; track_index < event_tracks.size(); track_index += blockDim.x) {
    if (parameters.dev_track_tags[track_offset + track_index] == 1) {
      const unsigned track_insert_index = atomicAdd(parameters.dev_sel_track_count + event_number, 1);
      // const unsigned n_hits = parameters.dev_track_hits_offsets[track_offset + track_index + 1] -
      //                         parameters.dev_track_hits_offsets[track_offset + track_index];
      const auto track = event_tracks.particle(track_index);
      const unsigned n_hits = track.number_of_ids();
      parameters.dev_tag_hits_counts[track_offset + track_insert_index] = n_hits;
      atomicAdd(parameters.dev_hits_bank_size + event_number, n_hits);
      parameters.dev_sel_track_indices[track_offset + track_insert_index] = track_index;
      parameters.dev_sel_track_inserts[track_offset + track_index] = track_insert_index;
    }
  }

  __syncthreads();

  // Populate the tagged SV count and list.
  for (unsigned sv_index = threadIdx.x; sv_index < event_svs.size(); sv_index += blockDim.x) {
    if (parameters.dev_sv_tags[sv_offset + sv_index] == 1) {
      const unsigned sv_insert_index = atomicAdd(parameters.dev_sel_sv_count + event_number, 1);
      parameters.dev_sel_sv_indices[sv_offset + sv_insert_index] = sv_index;
      parameters.dev_sel_sv_inserts[sv_offset + sv_index] = sv_insert_index;
    }
  }

  __syncthreads();

  // Calculate hits sub-bank sizes.
  if (threadIdx.x == 0) {
    parameters.dev_hits_bank_size[event_number] += 1 + (parameters.dev_sel_track_count[event_number] / 2);
    Selections::CandidateTable track_table {parameters.dev_sel_track_count[event_number],
                                            parameters.dev_sel_track_indices + track_offset,
                                            parameters.dev_sel_track_inserts + track_offset};
    Selections::CandidateTable sv_table {parameters.dev_sel_sv_count[event_number],
                                         parameters.dev_sel_sv_indices + sv_offset,
                                         parameters.dev_sel_sv_inserts + sv_offset};
    parameters.dev_sel_track_tables[event_number] = track_table;
    parameters.dev_sel_sv_tables[event_number] = sv_table;
  }
}
