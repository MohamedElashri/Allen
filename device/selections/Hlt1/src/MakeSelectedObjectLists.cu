#include "MakeSelectedObjectLists.cuh"
#include "SelectionsEventModel.cuh"
#include "LHCbIDContainer.cuh"
#include "HltDecReport.cuh"

INSTANTIATE_ALGORITHM(make_selected_object_lists::make_selected_object_lists_t)

void make_selected_object_lists::make_selected_object_lists_t::set_arguments_size(
    ArgumentReferences<Parameters> arguments,
    const RuntimeOptions&,
    const Constants&,
    const HostBuffers&) const
{
  set_size<dev_candidate_count_t>(
    arguments, first<host_number_of_active_lines_t>(arguments) * first<host_number_of_events_t>(arguments));
  set_size<dev_sel_track_count_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_sel_sv_count_t>(arguments, first<host_number_of_events_t>(arguments));
  // These are effectively 3D arrays. Use the convention: X = candidate, Y = event, Z = line.
  set_size<dev_sel_track_indices_t>(
    arguments, 
    property<max_selected_tracks_t>() * first<host_number_of_events_t>(arguments) * first<host_number_of_active_lines_t>(arguments));
  set_size<dev_sel_sv_indices_t>(
    arguments, 
    property<max_selected_svs_t>() * first<host_number_of_events_t>(arguments)  * first<host_number_of_active_lines_t>(arguments));
  // We could have multiple track and SV containers, so we can either set these
  // sizes arbitrarily, or create an algorithm to calculate them.
  set_size<dev_selected_basic_particle_ptrs_t>(
    arguments, first<host_number_of_events_t>(arguments) * property<max_selected_tracks_t>());
  set_size<dev_selected_composite_particle_ptrs_t>(
    arguments, first<host_number_of_events_t>(arguments) * property<max_selected_svs_t>());
  set_size<dev_track_duplicate_map_t>(
    arguments, first<host_number_of_events_t>(arguments) * property<max_selected_tracks_t>());
  set_size<dev_sv_duplicate_map_t>(
    arguments, first<host_number_of_events_t>(arguments) * property<max_selected_svs_t>());
}

void make_selected_object_lists::make_selected_object_lists_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  initialize<dev_candidate_count_t>(arguments, 0, context);
  initialize<dev_sel_track_count_t>(arguments, 0, context);
  initialize<dev_sel_sv_count_t>(arguments, 0, context);
  initialize<dev_track_duplicate_map_t>(arguments, -1, context);
  initialize<dev_sv_duplicate_map_t>(arguments, -1, context);
  global_function(make_selected_object_lists)(dim3(first<host_number_of_events_t>(arguments)), property<block_dim_t>(), context)(
    arguments, first<host_number_of_events_t>(arguments));
}

__global__ void make_selected_object_lists::make_selected_object_lists(make_selected_object_lists::Parameters parameters, const unsigned total_events)
{
  const auto event_number = blockIdx.x;
  const unsigned selected_track_offset = parameters.max_selected_tracks * event_number;
  const unsigned selected_sv_offset = parameters.max_selected_svs * event_number;
  const unsigned n_lines = parameters.dev_number_of_active_lines[0];
  const uint32_t* event_dec_reports =
    parameters.dev_dec_reports + (2 + parameters.dev_number_of_active_lines[0]) * event_number;
  unsigned* event_candidate_count =
    parameters.dev_candidate_count + event_number * parameters.dev_number_of_active_lines[0];

  Selections::ConstSelections selections {parameters.dev_selections, parameters.dev_selections_offsets, total_events};

  for (unsigned line_index = 0; line_index < n_lines; line_index += 1) {

    HltDecReport dec_report;
    dec_report.setDecReport(event_dec_reports[2 + line_index]);
    if (!dec_report.getDecision()) continue;

    uint8_t sel_type = parameters.dev_lhcbid_containers[line_index];

    // Handle lines that do not select from a particle container.
    if (sel_type == to_integral(LHCbIDContainer::none)) continue;

    // Handle lines that select BasicParticles.
    if (sel_type == to_integral(LHCbIDContainer::track)) {
      auto decs = selections.get_span(line_index, event_number);
      const auto multi_event_track_container = 
        static_cast<const Allen::Views::Physics::MultiEventBasicParticles*>(parameters.dev_multi_event_particle_containers[line_index]);
      const auto event_tracks = 
        static_cast<const Allen::Views::Physics::BasicParticles&>(multi_event_track_container->particle_container(event_number));
      for (unsigned track_index = threadIdx.x; track_index < event_tracks.size(); track_index += blockDim.x) {
        if (decs[track_index]) {
          const unsigned track_candidate_index = atomicAdd(event_candidate_count + line_index, 1);
          const unsigned track_insert_index = atomicAdd(parameters.dev_sel_track_count + event_number, 1);
          parameters.dev_sel_track_indices[
            total_events * (event_number + n_lines * line_index) + track_candidate_index] = track_insert_index;
          parameters.dev_selected_basic_particle_ptrs[selected_track_offset + track_insert_index] =
            const_cast<Allen::Views::Physics::BasicParticle*>(event_tracks.particle_pointer(track_index));
        }
      }
    }

    // Handle lines that select CompositeParticles
    if (sel_type == to_integral(LHCbIDContainer::sv)) {
      auto decs = selections.get_span(line_index, event_number);
      const auto multi_event_sv_container =
        static_cast<const Allen::Views::Physics::MultiEventCompositeParticles*>(parameters.dev_multi_event_particle_containers[line_index]);
      const auto event_svs =
        static_cast<const Allen::Views::Physics::CompositeParticles&>(multi_event_sv_container->particle_container(event_number));
      for (unsigned sv_index = threadIdx.x; sv_index < event_svs.size(); sv_index += blockDim.x) {
        if (decs[sv_index]) {
          const unsigned sv_candidate_index = atomicAdd(event_candidate_count + line_index, 1);
          const unsigned sv_insert_index = atomicAdd(parameters.dev_sel_sv_count + event_number, 1);
          parameters.dev_sel_sv_indices[
            total_events * (event_number + n_lines * line_index) + sv_candidate_index] = sv_insert_index;
          parameters.dev_selected_composite_particle_ptrs[selected_sv_offset + sv_insert_index] =
            const_cast<Allen::Views::Physics::CompositeParticle*>(&event_svs.particle(sv_index));

          // Parse the substructure.
          const auto sv = event_svs.particle(sv_index);
          const auto n_substr = sv.number_of_substructures();
          for (unsigned i_substr = 0; i_substr < n_substr; i_substr++) {
            const auto substr = sv.substructure(i_substr);

            if (substr->number_of_substructures() == 1) { // Handle track substructures.
              const unsigned track_insert_index = atomicAdd(parameters.dev_sel_track_count + event_number, 1);
              const auto basic_substr = static_cast<const Allen::Views::Physics::BasicParticle*>(substr);
              parameters.dev_selected_basic_particle_ptrs[selected_track_offset + track_insert_index] =
                const_cast<Allen::Views::Physics::BasicParticle*>(basic_substr);
            } else { // Handle composite substructures.
              const unsigned sv_insert_index = atomicAdd(parameters.dev_sel_sv_count + event_number, 1);
              const auto composite_substr = static_cast<const Allen::Views::Physics::CompositeParticle*>(substr);
              parameters.dev_selected_composite_particle_ptrs[selected_sv_offset + sv_insert_index] =
                const_cast<Allen::Views::Physics::CompositeParticle*>(composite_substr);

              // Manually handle sub-substructure to avoid recursion.
              const auto n_subsubstr = composite_substr->number_of_substructures();
              for (unsigned i_subsubstr = 0; i_subsubstr < n_subsubstr; i_subsubstr++) {
                const unsigned track_insert_index = atomicAdd(parameters.dev_sel_track_count + event_number, 1);
                // Assume all sub-substructures are BasicParticles.
                const auto basic_subsubstr = 
                  static_cast<const Allen::Views::Physics::BasicParticle*>(composite_substr->substructure(i_subsubstr));
                parameters.dev_selected_basic_particle_ptrs[selected_sv_offset + track_insert_index] =
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
      if (parameters.dev_track_duplicate_map[selected_track_offset + i_track] >= 0) continue;
      const auto trackA = parameters.dev_selected_basic_particle_ptrs[selected_track_offset + i_track];
      // Check for duplicate tracks.
      for (unsigned j_track = i_track + 1; j_track < n_selected_tracks; j_track++) {
        const auto trackB = parameters.dev_selected_basic_particle_ptrs[selected_track_offset + j_track];
        if (trackA == trackB) {
          parameters.dev_track_duplicate_map[selected_track_offset + j_track] = i_track;
        }
      }
    }

    const auto n_selected_svs = parameters.dev_sel_sv_count[event_number];
    for (unsigned i_sv = 0; i_sv < n_selected_svs; i_sv += 1) {
      // Skip SVs that are already marked as duplicates.
      if (parameters.dev_sv_duplicate_map[selected_sv_offset + i_sv] >= 0) continue;
      const auto svA = parameters.dev_selected_composite_particle_ptrs[selected_sv_offset + i_sv];
      // Check for duplicate SVs.
      for (unsigned j_sv = i_sv + 1; j_sv < n_selected_svs; j_sv++) {
        const auto svB = parameters.dev_selected_composite_particle_ptrs[selected_sv_offset + j_sv];
        if (svA == svB) {
          parameters.dev_sv_duplicate_map[selected_sv_offset + j_sv] = i_sv;
        }
      }
    }
  }
  
  

}