/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "MakeSelectedObjectLists.cuh"
#include "SelectionsEventModel.cuh"
#include "HltDecReport.cuh"

INSTANTIATE_ALGORITHM(make_selected_object_lists::make_selected_object_lists_t)

void make_selected_object_lists::make_selected_object_lists_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  // For keeping track of selections.
  set_size<dev_sel_count_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_sel_list_t>(
    arguments, first<host_number_of_events_t>(arguments) * first<host_number_of_active_lines_t>(arguments));

  // For keeping track of selected candidates.
  set_size<dev_candidate_count_t>(
    arguments, first<host_number_of_active_lines_t>(arguments) * first<host_number_of_events_t>(arguments));
  set_size<dev_sel_track_count_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_sel_sv_count_t>(arguments, first<host_number_of_events_t>(arguments));
  // These are effectively 3D arrays. Use the convention: X = candidate, Y = event, Z = line.
  set_size<dev_sel_track_indices_t>(
    arguments, property<max_children_per_object_t>() * first<host_max_objects_t>(arguments));
  set_size<dev_sel_sv_indices_t>(
    arguments, property<max_children_per_object_t>() * first<host_max_objects_t>(arguments));

  // For saving selected candidates.
  // We could have multiple track and SV containers, so we can either set these
  // sizes arbitrarily, or create an algorithm to calculate them.
  set_size<dev_selected_basic_particle_ptrs_t>(
    arguments, property<max_children_per_object_t>() * first<host_max_objects_t>(arguments));
  set_size<dev_selected_composite_particle_ptrs_t>(
    arguments, property<max_children_per_object_t>() * first<host_max_objects_t>(arguments));

  // For removing duplicates.
  set_size<dev_track_duplicate_map_t>(
    arguments, property<max_children_per_object_t>() * first<host_max_objects_t>(arguments));
  set_size<dev_sv_duplicate_map_t>(
    arguments, property<max_children_per_object_t>() * first<host_max_objects_t>(arguments));
  set_size<dev_unique_track_list_t>(
    arguments, property<max_children_per_object_t>() * first<host_max_objects_t>(arguments));
  set_size<dev_unique_sv_list_t>(
    arguments, property<max_children_per_object_t>() * first<host_max_objects_t>(arguments));
  set_size<dev_unique_track_count_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_unique_sv_count_t>(arguments, first<host_number_of_events_t>(arguments));

  // Bank sizes.
  set_size<dev_selrep_size_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_hits_bank_size_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_substr_bank_size_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_substr_sel_size_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_substr_sv_size_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_stdinfo_bank_size_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_objtyp_bank_size_t>(arguments, first<host_number_of_events_t>(arguments));
}

void make_selected_object_lists::make_selected_object_lists_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_candidate_count_t>(arguments, 0, context);
  Allen::memset_async<dev_sel_track_count_t>(arguments, 0, context);
  Allen::memset_async<dev_sel_sv_count_t>(arguments, 0, context);
  Allen::memset_async<dev_track_duplicate_map_t>(arguments, -1, context);
  Allen::memset_async<dev_sv_duplicate_map_t>(arguments, -1, context);
  Allen::memset_async<dev_unique_track_count_t>(arguments, 0, context);
  Allen::memset_async<dev_unique_sv_count_t>(arguments, 0, context);
  Allen::memset_async<dev_sel_count_t>(arguments, 0, context);
  Allen::memset_async<dev_hits_bank_size_t>(arguments, 0, context);
  Allen::memset_async<dev_substr_bank_size_t>(arguments, 0, context);
  Allen::memset_async<dev_substr_sel_size_t>(arguments, 0, context);
  Allen::memset_async<dev_substr_sv_size_t>(arguments, 0, context);
  Allen::memset_async<dev_stdinfo_bank_size_t>(arguments, 0, context);
  Allen::memset_async<dev_objtyp_bank_size_t>(arguments, 0, context);
  Allen::memset_async<dev_selrep_size_t>(arguments, 0, context);

  global_function(make_selected_object_lists)(
    dim3(first<host_number_of_events_t>(arguments)), property<block_dim_t>(), context)(
    arguments, first<host_number_of_events_t>(arguments));

  // TODO: Look into whether or not these kernels benefit from using different
  // block dimensions.
  global_function(calc_rb_sizes)(dim3(first<host_number_of_events_t>(arguments)), property<block_dim_t>(), context)(
    arguments);
}

__global__ void make_selected_object_lists::make_selected_object_lists(
  make_selected_object_lists::Parameters parameters,
  const unsigned total_events)
{
  const auto event_number = blockIdx.x;
  const unsigned n_lines = parameters.dev_number_of_active_lines[0];
  const unsigned n_children = parameters.max_children_per_object;
  const unsigned* line_selected_object_offsets = parameters.dev_max_objects_offsets + n_lines * event_number;
  const unsigned selected_object_offset = n_children * line_selected_object_offsets[0];
  const uint32_t* event_dec_reports =
    parameters.dev_dec_reports + (2 + parameters.dev_number_of_active_lines[0]) * event_number;
  unsigned* event_candidate_count =
    parameters.dev_candidate_count + event_number * parameters.dev_number_of_active_lines[0];

  Selections::ConstSelections selections {parameters.dev_selections, parameters.dev_selections_offsets, total_events};

  for (unsigned line_index = 0; line_index < n_lines; line_index += 1) {

    HltDecReport dec_report;
    dec_report.setDecReport(event_dec_reports[2 + line_index]);
    if (!dec_report.getDecision()) continue;

    const auto mec = parameters.dev_multi_event_particle_containers[line_index];

    // Handle lines that do not select from a particle container.
    if (mec == nullptr) continue;

    // Handle lines that select BasicParticles.
    const auto basic_particle_mec = Allen::dyn_cast<const Allen::Views::Physics::MultiEventBasicParticles*>(mec);
    if (basic_particle_mec) {
      auto decs = selections.get_span(line_index, event_number);
      const auto event_tracks = basic_particle_mec->container(event_number);
      for (unsigned track_index = threadIdx.x; track_index < event_tracks.size(); track_index += blockDim.x) {
        if (decs[track_index]) {
          const unsigned track_candidate_index = atomicAdd(event_candidate_count + line_index, 1);
          const unsigned track_insert_index = atomicAdd(parameters.dev_sel_track_count + event_number, 1);
          parameters
            .dev_sel_track_indices[n_children * line_selected_object_offsets[line_index] + track_candidate_index] =
            track_insert_index;
          parameters.dev_selected_basic_particle_ptrs[selected_object_offset + track_insert_index] =
            const_cast<Allen::Views::Physics::BasicParticle*>(event_tracks.particle_pointer(track_index));
        }
      }
    }

    // Handle lines that select CompositeParticles
    const auto composite_particle_mec =
      Allen::dyn_cast<const Allen::Views::Physics::MultiEventCompositeParticles*>(mec);
    if (composite_particle_mec) {
      auto decs = selections.get_span(line_index, event_number);
      const auto event_svs = composite_particle_mec->container(event_number);
      for (unsigned sv_index = threadIdx.x; sv_index < event_svs.size(); sv_index += blockDim.x) {
        if (decs[sv_index]) {
          const unsigned sv_candidate_index = atomicAdd(event_candidate_count + line_index, 1);
          const unsigned sv_insert_index = atomicAdd(parameters.dev_sel_sv_count + event_number, 1);
          parameters.dev_sel_sv_indices[n_children * line_selected_object_offsets[line_index] + sv_candidate_index] =
            sv_insert_index;
          parameters.dev_selected_composite_particle_ptrs[selected_object_offset + sv_insert_index] =
            const_cast<Allen::Views::Physics::CompositeParticle*>(&event_svs.particle(sv_index));

          // Parse the substructure.
          const auto sv = event_svs.particle(sv_index);
          const auto n_substr = sv.number_of_children();
          for (unsigned i_substr = 0; i_substr < n_substr; i_substr++) {
            const auto substr = sv.child(i_substr);

            if (substr->type_id() == Allen::TypeIDs::BasicParticle) { // Handle track substructures.
              const unsigned track_insert_index = atomicAdd(parameters.dev_sel_track_count + event_number, 1);
              const auto basic_substr = static_cast<const Allen::Views::Physics::BasicParticle*>(substr);
              parameters.dev_selected_basic_particle_ptrs[selected_object_offset + track_insert_index] =
                const_cast<Allen::Views::Physics::BasicParticle*>(basic_substr);
            }
            else { // Handle composite substructures.
              const unsigned sv_insert_index = atomicAdd(parameters.dev_sel_sv_count + event_number, 1);
              const auto composite_substr = static_cast<const Allen::Views::Physics::CompositeParticle*>(substr);
              parameters.dev_selected_composite_particle_ptrs[selected_object_offset + sv_insert_index] =
                const_cast<Allen::Views::Physics::CompositeParticle*>(composite_substr);

              // Manually handle sub-substructure to avoid recursion.
              const auto n_subsubstr = composite_substr->number_of_children();
              for (unsigned i_subsubstr = 0; i_subsubstr < n_subsubstr; i_subsubstr++) {
                const unsigned track_insert_index = atomicAdd(parameters.dev_sel_track_count + event_number, 1);
                // Assume all sub-substructures are BasicParticles.
                const auto basic_subsubstr =
                  static_cast<const Allen::Views::Physics::BasicParticle*>(composite_substr->child(i_subsubstr));
                parameters.dev_selected_basic_particle_ptrs[selected_object_offset + track_insert_index] =
                  const_cast<Allen::Views::Physics::BasicParticle*>(basic_subsubstr);
              } // End sub-substructure loop.
            }
          } // End substructure loop.
        }
      } // End SV loop.
    }
  } // End line loop.

  __syncthreads();

  // Create duplicate maps. This maps duplicates back to their original
  // occurance in the selected objects arrays. I think this needs to be done
  // sequentially, but there should be few enough selected objects that it
  // doesn't take significant time.
  if (threadIdx.x == 0) {
    const auto n_selected_tracks = parameters.dev_sel_track_count[event_number];
    for (unsigned i_track = 0; i_track < n_selected_tracks; i_track += 1) {
      // Skip tracks that are already marked as duplicates.
      if (parameters.dev_track_duplicate_map[selected_object_offset + i_track] >= 0) continue;
      const unsigned track_insert = atomicAdd(parameters.dev_unique_track_count + event_number, 1);
      parameters.dev_unique_track_list[selected_object_offset + track_insert] = i_track;
      const auto trackA = parameters.dev_selected_basic_particle_ptrs[selected_object_offset + i_track];
      // Check for duplicate tracks.
      for (unsigned j_track = i_track + 1; j_track < n_selected_tracks; j_track++) {
        const auto trackB = parameters.dev_selected_basic_particle_ptrs[selected_object_offset + j_track];
        if (trackA == trackB) {
          parameters.dev_track_duplicate_map[selected_object_offset + j_track] = i_track;
        }
      }
    }

    const auto n_selected_svs = parameters.dev_sel_sv_count[event_number];
    for (unsigned i_sv = 0; i_sv < n_selected_svs; i_sv += 1) {
      // Skip SVs that are already marked as duplicates.
      if (parameters.dev_sv_duplicate_map[selected_object_offset + i_sv] >= 0) continue;
      const unsigned sv_insert = atomicAdd(parameters.dev_unique_sv_count + event_number, 1);
      parameters.dev_unique_sv_list[selected_object_offset + sv_insert] = i_sv;
      const auto svA = parameters.dev_selected_composite_particle_ptrs[selected_object_offset + i_sv];
      // Check for duplicate SVs.
      for (unsigned j_sv = i_sv + 1; j_sv < n_selected_svs; j_sv++) {
        const auto svB = parameters.dev_selected_composite_particle_ptrs[selected_object_offset + j_sv];
        if (svA == svB) {
          parameters.dev_sv_duplicate_map[selected_object_offset + j_sv] = i_sv;
        }
      }
    }
  }
}

__global__ void make_selected_object_lists::calc_rb_sizes(make_selected_object_lists::Parameters parameters)
{
  const auto event_number = blockIdx.x;
  const unsigned n_children = parameters.max_children_per_object;
  const unsigned n_lines = parameters.dev_number_of_active_lines[0];
  const unsigned* line_selected_object_offsets = parameters.dev_max_objects_offsets + n_lines * event_number;
  const unsigned selected_object_offset = n_children * line_selected_object_offsets[0];
  const auto event_track_ptrs = parameters.dev_selected_basic_particle_ptrs + selected_object_offset;
  const auto event_unique_track_list = parameters.dev_unique_track_list + selected_object_offset;
  const auto event_sv_ptrs = parameters.dev_selected_composite_particle_ptrs + selected_object_offset;
  const auto event_unique_sv_list = parameters.dev_unique_sv_list + selected_object_offset;
  const auto n_selected_tracks = parameters.dev_unique_track_count[event_number];
  const auto n_selected_svs = parameters.dev_unique_sv_count[event_number];
  const uint32_t* event_dec_reports = parameters.dev_dec_reports + (2 + n_lines) * event_number;
  unsigned* event_candidate_count = parameters.dev_candidate_count + event_number * n_lines;
  unsigned* event_sel_list = parameters.dev_sel_list + event_number * n_lines;

  // Calculate the size of the hits bank.
  for (unsigned i_track = threadIdx.x; i_track < n_selected_tracks; i_track += blockDim.x) {
    const unsigned track_index = event_unique_track_list[i_track];
    const Allen::Views::Physics::BasicParticle* track = event_track_ptrs[track_index];
    atomicAdd(parameters.dev_hits_bank_size + event_number, track->number_of_ids());
  }
  if (threadIdx.x == 0) {
    parameters.dev_hits_bank_size[event_number] += 1 + (parameters.dev_unique_track_count[event_number] / 2);
  }

  // Calculate the size of the substr bank.
  for (unsigned line_index = threadIdx.x; line_index < parameters.dev_number_of_active_lines[0];
       line_index += blockDim.x) {
    HltDecReport dec_report;
    dec_report.setDecReport(event_dec_reports[2 + line_index]);
    if (dec_report.getDecision()) {
      atomicAdd(parameters.dev_substr_bank_size + event_number, 1 + event_candidate_count[line_index]);
      atomicAdd(parameters.dev_substr_sel_size + event_number, 1 + event_candidate_count[line_index]);
      unsigned insert_index = atomicAdd(parameters.dev_sel_count + event_number, 1);
      event_sel_list[insert_index] = line_index;
    }
  }

  // Add contribution from CompositeParticles to substr size.
  for (unsigned i_sv = threadIdx.x; i_sv < n_selected_svs; i_sv += blockDim.x) {
    const unsigned sv_index = event_unique_sv_list[i_sv];
    const Allen::Views::Physics::CompositeParticle* sv = event_sv_ptrs[sv_index];
    // Each SV structure consists of 1 short that gives the size and 1 short for
    // each substructure.
    atomicAdd(parameters.dev_substr_bank_size + event_number, 1 + sv->number_of_children());
    atomicAdd(parameters.dev_substr_sv_size + event_number, 1 + sv->number_of_children());
  }

  __syncthreads();

  if (threadIdx.x == 0) {

    if (parameters.dev_unique_track_count[event_number] > 0) {
      // Each track structure consists of 1 short that denotes the
      // size and 1 short pointer to hits in the hits bank.
      parameters.dev_substr_bank_size[event_number] += 2 * parameters.dev_unique_track_count[event_number];
    }

    // Get the size of the ObjTyp bank. The ObjTyp bank has 1 word defining the
    // bank structure and 1 word for each object type stored.
    parameters.dev_objtyp_bank_size[event_number] = 1 + (parameters.dev_sel_count[event_number] > 0) +
                                                    (parameters.dev_unique_track_count[event_number] > 0) +
                                                    (parameters.dev_unique_sv_count[event_number] > 0);

    // Convert from number of shorts to number of words. Add 2 shorts for bank size info.
    if (parameters.dev_substr_bank_size[event_number] > 0) {
      parameters.dev_substr_bank_size[event_number] = (parameters.dev_substr_bank_size[event_number] + 3) / 2;
    }

    // Get the size of the StdInfo bank.
    const unsigned n_objects = parameters.dev_sel_count[event_number] +
                               parameters.dev_unique_track_count[event_number] +
                               parameters.dev_unique_sv_count[event_number];

    // StdInfo contains 1 word giving the structure of the bank, 8
    // bits per object with the number of values saved (with possible
    // padding). Saved info includes:
    // Selections: decision ID
    // Tracks: empty
    // SVs: empty
    if (n_objects > 0) {
      parameters.dev_stdinfo_bank_size[event_number] = 2 + n_objects / 4 + parameters.dev_sel_count[event_number] +
                                                       8 * parameters.dev_unique_track_count[event_number] +
                                                       4 * parameters.dev_unique_sv_count[event_number];
    }
    else {
      parameters.dev_stdinfo_bank_size[event_number] = 0;
    }

    // Calculate the total selrep size.
    // Size of the empty extraInfo sub-bank depends on the number of objects.
    const unsigned einfo_size = 2 + n_objects / 4;
    const unsigned header_size = 10;
    parameters.dev_selrep_size[event_number] =
      header_size + parameters.dev_hits_bank_size[event_number] + parameters.dev_substr_bank_size[event_number] +
      parameters.dev_stdinfo_bank_size[event_number] + parameters.dev_objtyp_bank_size[event_number] + einfo_size;
  }
}