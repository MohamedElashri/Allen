/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "GatherSelections.cuh"
#include "SelectionsEventModel.cuh"
#include "DeterministicScaler.cuh"
#include <algorithm>
#include "ExternLines.cuh"
#include <string>
#include <sstream>
#include <vector>
#include <iterator>

INSTANTIATE_ALGORITHM(gather_selections::gather_selections_t)

template<typename Out>
void split(const std::string& s, char delim, Out result)
{
  std::istringstream iss(s);
  std::string item;
  while (std::getline(iss, item, delim)) {
    *result++ = item;
  }
}

std::vector<std::string> split(const std::string& s, char delim)
{
  std::vector<std::string> elems;
  split(s, delim, std::back_inserter(elems));
  return elems;
}

namespace gather_selections {
  __global__ void run_lines(
    unsigned* line_fn_indices,
    char** parameters,
    bool* dev_decisions,
    unsigned* dev_decisions_offsets,
    Allen::IMultiEventContainer** dev_particle_container_ptr,
    const ODINData* dev_odin_data,
    const unsigned number_of_events,
    const unsigned number_of_lines,
    const unsigned* line_offsets)
  {
    // Process each event with a different block
    // ODIN data
    LHCb::ODIN odin{dev_odin_data[blockIdx.x]};

    const uint32_t run_no = odin.runNumber();
    const uint32_t evt_hi = static_cast<uint32_t>(odin.eventNumber() >> 32);
    const uint32_t evt_lo = static_cast<uint32_t>(odin.eventNumber() & 0xffffffff);
    const uint32_t gps_hi = static_cast<uint32_t>(odin.gpsTime() >> 32);
    const uint32_t gps_lo = static_cast<uint32_t>(odin.gpsTime() & 0xffffffff);

    for (unsigned i = threadIdx.y; i < number_of_lines; i += blockDim.y) {
      invoke_line_functions(
        line_fn_indices[i],
        parameters[i],
        dev_decisions + line_offsets[i],
        dev_decisions_offsets + i * number_of_events,
        dev_particle_container_ptr + i,
        run_no,
        evt_hi,
        evt_lo,
        gps_hi,
        gps_lo,
        line_offsets[i]);
    }

    if (blockIdx.x == 0 && threadIdx.x == 0 && threadIdx.y == 0) {
      dev_decisions_offsets[number_of_lines * number_of_events] = line_offsets[number_of_lines];
    }
  }

  __global__ void postscaler(
    bool* dev_selections,
    const unsigned* dev_selections_offsets,
    const ODINData* dev_odin_data,
    const float* scale_factors,
    const uint32_t* scale_hashes,
    const unsigned number_of_lines)
  {
    const auto number_of_events = gridDim.x;
    const auto event_number = blockIdx.x;

    Selections::Selections sels {dev_selections, dev_selections_offsets, number_of_events};

    LHCb::ODIN odin{dev_odin_data[event_number]};

    const uint32_t run_no = odin.runNumber();
    const uint32_t evt_hi = static_cast<uint32_t>(odin.eventNumber() >> 32);
    const uint32_t evt_lo = static_cast<uint32_t>(odin.eventNumber() & 0xffffffff);
    const uint32_t gps_hi = static_cast<uint32_t>(odin.gpsTime() >> 32);
    const uint32_t gps_lo = static_cast<uint32_t>(odin.gpsTime() & 0xffffffff);

    for (unsigned i = threadIdx.x; i < number_of_lines; i += blockDim.x) {
      auto span = sels.get_span(i, event_number);
      deterministic_post_scaler(
        scale_hashes[i], scale_factors[i], span.size(), span.data(), run_no, evt_hi, evt_lo, gps_hi, gps_lo);
    }
  }
} // namespace gather_selections

void gather_selections::gather_selections_t::init()
{
  const auto names_of_active_line_algorithms = split(property<names_of_active_line_algorithms_t>().get(), ',');
  for (const auto& name : names_of_active_line_algorithms) {
    const auto it = std::find(std::begin(line_strings), std::end(line_strings), name);
    m_indices_active_line_algorithms.push_back(it - std::begin(line_strings));
  }
}

void gather_selections::gather_selections_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  // Sum all the sizes from input selections
  const auto sum_sizes_from_aggregate = [](const auto& agg) {
    size_t total_size = 0;
    for (size_t i = 0; i < agg.size_of_aggregate(); ++i) {
      total_size += agg.size(i);
    }
    return total_size;
  };

  const auto host_decisions_sizes = input_aggregate<host_decisions_sizes_t>(arguments);
  const auto total_size_host_decisions_sizes = [&host_decisions_sizes]() {
    unsigned sum = 0;
    for (unsigned i = 0; i < host_decisions_sizes.size_of_aggregate(); ++i) {
      sum += host_decisions_sizes.first(i);
    }
    return sum;
  }();

  const auto total_size_host_input_post_scale_factors =
    sum_sizes_from_aggregate(input_aggregate<host_input_post_scale_factors_t>(arguments));
  const auto host_input_post_scale_hashes =
    sum_sizes_from_aggregate(input_aggregate<host_input_post_scale_hashes_t>(arguments));

  set_size<host_number_of_active_lines_t>(arguments, 1);
  set_size<dev_number_of_active_lines_t>(arguments, 1);
  set_size<host_names_of_active_lines_t>(arguments, std::string(property<names_of_active_lines_t>().get()).size() + 1);
  set_size<host_selections_lines_offsets_t>(arguments, host_decisions_sizes.size_of_aggregate() + 1);
  set_size<dev_selections_lines_offsets_t>(arguments, host_decisions_sizes.size_of_aggregate() + 1);
  set_size<host_selections_offsets_t>(
    arguments, first<host_number_of_events_t>(arguments) * host_decisions_sizes.size_of_aggregate() + 1);
  set_size<dev_selections_offsets_t>(
    arguments, first<host_number_of_events_t>(arguments) * host_decisions_sizes.size_of_aggregate() + 1);
  set_size<dev_selections_t>(arguments, total_size_host_decisions_sizes);
  set_size<host_post_scale_factors_t>(arguments, total_size_host_input_post_scale_factors);
  set_size<host_post_scale_hashes_t>(arguments, host_input_post_scale_hashes);
  set_size<dev_post_scale_factors_t>(arguments, total_size_host_input_post_scale_factors);
  set_size<dev_post_scale_hashes_t>(arguments, host_input_post_scale_hashes);
  set_size<dev_particle_containers_t>(arguments, host_decisions_sizes.size_of_aggregate());
  set_size<host_fn_parameters_t>(
    arguments, sum_sizes_from_aggregate(input_aggregate<host_fn_parameters_agg_t>(arguments)));
  set_size<dev_fn_parameters_t>(
    arguments, sum_sizes_from_aggregate(input_aggregate<host_fn_parameters_agg_t>(arguments)));
  set_size<host_fn_parameter_pointers_t>(
    arguments, input_aggregate<host_fn_parameters_agg_t>(arguments).size_of_aggregate());
  set_size<dev_fn_parameter_pointers_t>(
    arguments, input_aggregate<host_fn_parameters_agg_t>(arguments).size_of_aggregate());
  set_size<host_fn_indices_t>(arguments, m_indices_active_line_algorithms.size());
  set_size<dev_fn_indices_t>(arguments, m_indices_active_line_algorithms.size());

  if (property<verbosity_t>() >= logger::debug) {
    info_cout << "Sizes of gather_selections datatypes: " << size<host_selections_offsets_t>(arguments) << ", "
              << size<host_selections_lines_offsets_t>(arguments) << ", " << size<dev_selections_offsets_t>(arguments)
              << ", " << size<dev_selections_t>(arguments) << "\n";
  }
}

void gather_selections::gather_selections_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers& host_buffers,
  const Allen::Context& context) const
{
  // Run the selection algorithms
  // * Aggregate parameter fns
  Allen::aggregate::store_contiguous_async<host_fn_parameters_t, host_fn_parameters_agg_t>(arguments, context);
  Allen::copy_async<dev_fn_parameters_t, host_fn_parameters_t>(arguments, context);

  // * Prepare pointers to parameters
  unsigned accumulated_offset_params = 0;
  const auto host_fn_parameters_agg = input_aggregate<host_fn_parameters_agg_t>(arguments);
  for (unsigned i = 0; i < host_fn_parameters_agg.size_of_aggregate(); ++i) {
    data<host_fn_parameter_pointers_t>(arguments)[i] = data<dev_fn_parameters_t>(arguments) + accumulated_offset_params;
    accumulated_offset_params += host_fn_parameters_agg.size(i);
  }
  Allen::copy_async<dev_fn_parameter_pointers_t, host_fn_parameter_pointers_t>(arguments, context);

  // * Pass the number of lines for posterior algorithms
  const auto host_decisions_sizes = input_aggregate<host_decisions_sizes_t>(arguments);
  data<host_number_of_active_lines_t>(arguments)[0] = host_decisions_sizes.size_of_aggregate();
  Allen::copy_async<dev_number_of_active_lines_t, host_number_of_active_lines_t>(arguments, context);

  // * Calculate prefix sum of host_decisions_sizes_t sizes into host_selections_lines_offsets_t
  auto* container = data<host_selections_lines_offsets_t>(arguments);
  container[0] = 0;
  for (size_t i = 0; i < host_decisions_sizes.size_of_aggregate(); ++i) {
    container[i + 1] = container[i] + host_decisions_sizes.first(i);
  }
  Allen::copy_async<dev_selections_lines_offsets_t, host_selections_lines_offsets_t>(arguments, context);

  // * Prepare dev_fn_indices_t, containing all fn indices
  for (unsigned i = 0; i < m_indices_active_line_algorithms.size(); ++i) {
    data<host_fn_indices_t>(arguments)[i] = m_indices_active_line_algorithms[i];
  }
  Allen::copy_async<dev_fn_indices_t, host_fn_indices_t>(arguments, context);

  // * Run all selections in one go
  global_function(gather_selections::run_lines)(
    first<host_number_of_events_t>(arguments), dim3(warp_size, 256 / warp_size), context)(
    data<dev_fn_indices_t>(arguments),
    data<dev_fn_parameter_pointers_t>(arguments),
    data<dev_selections_t>(arguments),
    data<dev_selections_offsets_t>(arguments),
    data<dev_particle_containers_t>(arguments),
    data<dev_odin_data_t>(arguments),
    first<host_number_of_events_t>(arguments),
    first<host_number_of_active_lines_t>(arguments),
    data<dev_selections_lines_offsets_t>(arguments));

  for (unsigned i = 0; i < m_indices_active_line_algorithms.size(); ++i) {
    line_output_monitor_functions[m_indices_active_line_algorithms[i]](
      host_fn_parameters_agg.data(i), runtime_options, context);
  }

  // Save the names of active lines as output
  initialize<host_names_of_active_lines_t>(arguments, 0, context);
  const auto line_names = std::string(property<names_of_active_lines_t>());
  line_names.copy(data<host_names_of_active_lines_t>(arguments), line_names.size());

  // Populate host_post_scale_factors_t
  Allen::aggregate::store_contiguous_async<host_post_scale_factors_t, host_input_post_scale_factors_t>(
    arguments, context);

  // Populate host_post_scale_hashes_t
  Allen::aggregate::store_contiguous_async<host_post_scale_hashes_t, host_input_post_scale_hashes_t>(
    arguments, context);

  // Copy host_post_scale_factors_t to dev_post_scale_factors_t,
  // and host_post_scale_hashes_t to dev_post_scale_hashes_t
  Allen::copy_async<dev_post_scale_factors_t, host_post_scale_factors_t>(arguments, context);
  Allen::copy_async<dev_post_scale_hashes_t, host_post_scale_hashes_t>(arguments, context);

  // Run the postscaler
  global_function(postscaler)(first<host_number_of_events_t>(arguments), property<block_dim_x_t>().get(), context)(
    data<dev_selections_t>(arguments),
    data<dev_selections_offsets_t>(arguments),
    data<dev_odin_data_t>(arguments),
    data<dev_post_scale_factors_t>(arguments),
    data<dev_post_scale_hashes_t>(arguments),
    first<host_number_of_active_lines_t>(arguments));

  if (property<verbosity_t>() >= logger::debug) {
    std::vector<uint8_t> host_selections(size<dev_selections_t>(arguments));
    assign_to_host_buffer<dev_selections_t>(host_selections.data(), arguments, context);
    Allen::copy<host_selections_offsets_t, dev_selections_offsets_t>(arguments, context);

    Selections::ConstSelections sels {reinterpret_cast<bool*>(host_selections.data()),
                                      data<host_selections_offsets_t>(arguments),
                                      first<host_number_of_events_t>(arguments)};

    std::vector<uint8_t> event_decisions {};
    for (auto i = 0u; i < first<host_number_of_events_t>(arguments); ++i) {
      bool dec = false;
      for (auto j = 0u; j < first<host_number_of_active_lines_t>(arguments); ++j) {
        auto decs = sels.get_span(j, i);
        bool span_decision = false;
        for (auto k = 0u; k < decs.size(); ++k) {
          dec |= decs[k];
          span_decision |= decs[k];
        }
        std::cout << "Span (event " << i << ", line " << j << "), size " << decs.size()
                  << ", decision: " << span_decision << "\n";
      }
      event_decisions.emplace_back(dec);
    }

    const float sum_events = std::accumulate(event_decisions.begin(), event_decisions.end(), 0);
    std::cout << sum_events / event_decisions.size() << std::endl;

    const float sum = std::accumulate(host_selections.begin(), host_selections.end(), 0);
    std::cout << sum / host_selections.size() << std::endl;
  }

  // If running the validation, save relevant information
  if (runtime_options.fill_extra_host_buffers) {
    host_buffers.host_names_of_lines = std::string(property<names_of_active_lines_t>());
    host_buffers.host_number_of_lines = first<host_number_of_active_lines_t>(arguments);
    safe_assign_to_host_buffer<dev_selections_t>(host_buffers.host_selections, arguments, context);
    safe_assign_to_host_buffer<dev_selections_offsets_t>(host_buffers.host_selections_offsets, arguments, context);
  }
}
