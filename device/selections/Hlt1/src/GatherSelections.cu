/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
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
  __global__ void
  prescaler(gather_selections::Parameters params, const unsigned number_of_events, const unsigned number_of_lines)
  {
    unsigned line = blockIdx.x;
    auto pre_scaler_hash = params.dev_line_data[line].pre_scaler_hash;
    auto pre_scaler = params.dev_line_data[line].pre_scaler;
    auto event_list = params.dev_line_data[line].event_list;
    auto event_list_size = params.dev_line_data[line].event_list_size;

    if (pre_scaler >= 1.f) { // No prescaler, just copy the event list
      for (unsigned i = threadIdx.x; i < event_list_size; i += blockDim.x) {
        auto event_number = event_list[i];
        params.dev_pre_scale_event_lists[line * number_of_events + i] = event_number;
      }
      if (threadIdx.x == 0) params.dev_pre_scale_event_lists_size[line] = event_list_size;
    }
    else {
      for (unsigned i = threadIdx.x; i < event_list_size; i += blockDim.x) {
        auto event_number = event_list[i];
        LHCb::ODIN odin {params.dev_odin_data[event_number]};

        const uint32_t run_no = odin.runNumber();
        const uint32_t evt_hi = static_cast<uint32_t>(odin.eventNumber() >> 32);
        const uint32_t evt_lo = static_cast<uint32_t>(odin.eventNumber() & 0xffffffff);
        const uint32_t gps_hi = static_cast<uint32_t>(odin.gpsTime() >> 32);
        const uint32_t gps_lo = static_cast<uint32_t>(odin.gpsTime() & 0xffffffff);

        if (deterministic_scaler(pre_scaler_hash, pre_scaler, run_no, evt_hi, evt_lo, gps_hi, gps_lo)) {
          auto index = atomicAdd(&params.dev_pre_scale_event_lists_size[line], 1);
          params.dev_pre_scale_event_lists[line * number_of_events + index] = event_number;
        }
      }
    }

    if (blockIdx.x == 0) {
      for (unsigned i = threadIdx.x; i < number_of_lines; i += blockDim.x) {
        params.dev_particle_containers[i] = params.dev_line_data[i].particle_container_ptr;
      }
    }
  }

  __global__ void
  run_lines(gather_selections::Parameters params, const unsigned number_of_events, const unsigned number_of_lines)
  {
    // Process each line with a different block
    unsigned line = blockIdx.x;
    char* input = params.dev_fn_parameter_pointers[line];
    auto line_offset = params.dev_selections_lines_offsets[line];

    if (input == nullptr) {
      for (unsigned i = threadIdx.x; i < number_of_events; i += blockDim.x) {
        params.dev_selections_offsets[line * number_of_events + i] = line_offset;
      }
    }
    else {
      invoke_line_functions(
        params.dev_fn_indices[line],
        input,
        params.dev_selections,
        params.dev_selections_offsets + line * number_of_events,
        params.dev_line_data + line,
        params.dev_odin_data,
        params.dev_pre_scale_event_lists + line * number_of_events,
        params.dev_pre_scale_event_lists_size[line],
        line_offset,
        line,
        number_of_events);
    }

    if (blockIdx.x == 0 && threadIdx.x == 0) {
      params.dev_selections_offsets[number_of_lines * number_of_events] =
        params.dev_selections_lines_offsets[number_of_lines];
    }
  }

  __global__ void postscaler(
    gather_selections::Parameters params,
    const unsigned number_of_lines,
    bool* dev_decisions_per_event_line,
    bool* dev_postscaled_decisions_per_event_line,
    Allen::Monitoring::Histogram<>::DeviceType dev_histo_line_passes,
    Allen::Monitoring::Histogram<>::DeviceType dev_histo_line_rates)
  {
    const auto number_of_events = gridDim.x;
    const auto event_number = blockIdx.x;

    __shared__ int event_decision;

    if (threadIdx.x == 0) {
      // Initialize event decision
      event_decision = false;
    }

    __syncthreads();

    Selections::Selections sels {params.dev_selections, params.dev_selections_offsets, number_of_events};

    LHCb::ODIN odin {params.dev_odin_data[event_number]};

    const uint32_t run_no = odin.runNumber();
    const uint32_t evt_hi = static_cast<uint32_t>(odin.eventNumber() >> 32);
    const uint32_t evt_lo = static_cast<uint32_t>(odin.eventNumber() & 0xffffffff);
    const uint32_t gps_hi = static_cast<uint32_t>(odin.gpsTime() >> 32);
    const uint32_t gps_lo = static_cast<uint32_t>(odin.gpsTime() & 0xffffffff);

    for (unsigned i = threadIdx.x; i < number_of_lines; i += blockDim.x) {
      if (!sels.is_span_empty(i, event_number)) {
        dev_decisions_per_event_line[event_number * number_of_lines + i] = true;
        dev_histo_line_passes.increment(i);
      }

      if (!deterministic_scaler(
            params.dev_line_data[i].post_scaler_hash,
            params.dev_line_data[i].post_scaler,
            run_no,
            evt_hi,
            evt_lo,
            gps_hi,
            gps_lo)) {
        sels.fill_span(i, event_number, false);
      }

      if (!sels.is_span_empty(i, event_number)) {
        dev_postscaled_decisions_per_event_line[event_number * number_of_lines + i] = true;
        dev_histo_line_rates.increment(i);
        event_decision = true;
      }
    }

    __syncthreads();

    if (threadIdx.x == 0 && event_decision) {
      const auto index = atomicAdd(params.dev_event_list_output_size.data(), 1);
      params.dev_event_list_output[index] = mask_t {event_number};
    }
  }
} // namespace gather_selections

void gather_selections::gather_selections_t::init()
{
  const auto names_of_active_line_algorithms = split(m_names_of_active_line_algorithms, ',');
  for (const auto& name : names_of_active_line_algorithms) {
    const auto it = std::find(std::begin(line_strings), std::end(line_strings), name);
    m_indices_active_line_algorithms.push_back(it - std::begin(line_strings));
  }
  const auto line_names = std::string(m_names_of_active_lines);
  std::istringstream is(line_names);
  std::string line_name;
  std::vector<std::string> line_labels;
  unsigned i = 0;
  while (std::getline(is, line_name, ',')) {
    line_labels.push_back(line_name);
    const std::string pass_counter_name {line_name + "Pass"};
    const std::string rate_counter_name {line_name + "Rate"};
    m_pass_counters.push_back(
      std::make_unique<Allen::Monitoring::HistogramBinAsCounter<Allen::Monitoring::Histogram<>>>(
        this, pass_counter_name, &m_histogram_line_passes, i));
    m_rate_counters.push_back(
      std::make_unique<Allen::Monitoring::HistogramBinAsCounter<Allen::Monitoring::Histogram<>>>(
        this, rate_counter_name, &m_histogram_line_rates, i));
    i++;
  }
  m_histogram_line_passes.x_axis().nBins = line_labels.size();
  m_histogram_line_passes.x_axis().maxValue = line_labels.size();
  m_histogram_line_passes.x_axis().labels = line_labels;

  m_histogram_line_rates.x_axis().nBins = line_labels.size();
  m_histogram_line_rates.x_axis().maxValue = line_labels.size();
  m_histogram_line_rates.x_axis().labels = line_labels;
}

void gather_selections::gather_selections_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  // Sum all the sizes from input selections
  const auto host_fn_parameters_agg = input_aggregate<host_fn_parameters_agg_t>(arguments);
  const auto total_size_host_fn_parameters_agg = [&host_fn_parameters_agg]() {
    size_t total_size = 0;
    for (size_t i = 0; i < host_fn_parameters_agg.size_of_aggregate(); ++i) {
      total_size += host_fn_parameters_agg.size(i);
    }
    return total_size;
  }();

  const auto size_of_aggregates = input_aggregate<host_input_line_data_t>(arguments).size_of_aggregate();

  const auto host_line_data = input_aggregate<host_input_line_data_t>(arguments);
  const auto total_size_host_decisions_sizes = [&host_line_data]() {
    unsigned sum = 0;
    for (unsigned i = 0; i < host_line_data.size_of_aggregate(); ++i) {
      sum += (host_line_data.size(i) > 0) ? host_line_data.first(i).decisions_size : 0;
    }
    return sum;
  }() / 32 + size_of_aggregates * first<host_number_of_events_t>(arguments);

  assert(m_indices_active_line_algorithms.size() == size_of_aggregates);

  set_size<host_number_of_active_lines_t>(arguments, 1);
  set_size<dev_number_of_active_lines_t>(arguments, 1);
  set_size<host_names_of_active_lines_t>(arguments, std::string(m_names_of_active_lines).size() + 1);
  set_size<host_selections_lines_offsets_t>(arguments, size_of_aggregates + 1);
  set_size<dev_selections_lines_offsets_t>(arguments, size_of_aggregates + 1);
  set_size<host_selections_offsets_t>(arguments, first<host_number_of_events_t>(arguments) * size_of_aggregates + 1);
  set_size<dev_selections_offsets_t>(arguments, first<host_number_of_events_t>(arguments) * size_of_aggregates + 1);
  set_size<dev_selections_t>(arguments, total_size_host_decisions_sizes);
  set_size<host_line_data_t>(arguments, size_of_aggregates);
  set_size<dev_line_data_t>(arguments, size_of_aggregates);
  set_size<dev_pre_scale_event_lists_t>(arguments, first<host_number_of_events_t>(arguments) * size_of_aggregates);
  set_size<dev_pre_scale_event_lists_size_t>(arguments, size_of_aggregates);
  set_size<dev_particle_containers_t>(arguments, size_of_aggregates);
  set_size<host_fn_parameters_t>(arguments, total_size_host_fn_parameters_agg);
  set_size<dev_fn_parameters_t>(arguments, total_size_host_fn_parameters_agg);
  set_size<host_fn_parameter_pointers_t>(arguments, size_of_aggregates);
  set_size<dev_fn_parameter_pointers_t>(arguments, size_of_aggregates);
  set_size<host_fn_indices_t>(arguments, size_of_aggregates);
  set_size<dev_fn_indices_t>(arguments, size_of_aggregates);
  set_size<host_event_list_output_size_t>(arguments, 1);
  set_size<dev_event_list_output_size_t>(arguments, 1);
  set_size<dev_event_list_output_t>(arguments, first<host_number_of_events_t>(arguments));

  if (m_verbosity >= logger::debug) {
    info_cout << "Sizes of gather_selections datatypes: " << size<host_selections_offsets_t>(arguments) << ", "
              << size<host_selections_lines_offsets_t>(arguments) << ", " << size<dev_selections_offsets_t>(arguments)
              << ", " << size<dev_selections_t>(arguments) << "\n";
  }
}

void gather_selections::gather_selections_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  [[maybe_unused]] const Constants& constants,
  const Allen::Context& context) const
{
  // * Pass the number of lines for posterior algorithms
  const auto host_line_data = input_aggregate<host_input_line_data_t>(arguments);
  data<host_number_of_active_lines_t>(arguments)[0] = host_line_data.size_of_aggregate();
  Allen::copy_async<dev_number_of_active_lines_t, host_number_of_active_lines_t>(arguments, context);

  // === Run the prescalers
  Allen::aggregate::store_contiguous_async<host_line_data_t, host_input_line_data_t>(arguments, context, true);
  Allen::copy_async<dev_line_data_t, host_line_data_t>(arguments, context);

  Allen::memset_async<dev_pre_scale_event_lists_size_t>(arguments, 0, context);

  global_function(prescaler)(host_line_data.size_of_aggregate(), dim3(m_block_dim_x), context)(
    arguments, first<host_number_of_events_t>(arguments), first<host_number_of_active_lines_t>(arguments));

  // === Run the selection algorithms
  // * Aggregate parameter fns
  Allen::aggregate::store_contiguous_async<host_fn_parameters_t, host_fn_parameters_agg_t>(arguments, context);
  Allen::copy_async<dev_fn_parameters_t, host_fn_parameters_t>(arguments, context);

  // * Prepare pointers to parameters
  unsigned accumulated_offset_params = 0;
  const auto host_fn_parameters_agg = input_aggregate<host_fn_parameters_agg_t>(arguments);
  for (unsigned i = 0; i < host_fn_parameters_agg.size_of_aggregate(); ++i) {
    if (host_fn_parameters_agg.size(i) == 0) {
      data<host_fn_parameter_pointers_t>(arguments)[i] = nullptr;
    }
    else {
      data<host_fn_parameter_pointers_t>(arguments)[i] =
        data<dev_fn_parameters_t>(arguments) + accumulated_offset_params;
      accumulated_offset_params += host_fn_parameters_agg.size(i);
    }
  }
  Allen::copy_async<dev_fn_parameter_pointers_t, host_fn_parameter_pointers_t>(arguments, context);

  // * Calculate prefix sum of host_decisions_sizes_t sizes into host_selections_lines_offsets_t
  auto* container = data<host_selections_lines_offsets_t>(arguments);
  container[0] = 0;
  for (size_t i = 0; i < host_line_data.size_of_aggregate(); ++i) {
    container[i + 1] = container[i] + (host_line_data.size(i) ? host_line_data.first(i).decisions_size : 0);
  }
  Allen::copy_async<dev_selections_lines_offsets_t, host_selections_lines_offsets_t>(arguments, context);

  // * Prepare dev_fn_indices_t, containing all fn indices
  for (unsigned i = 0; i < m_indices_active_line_algorithms.size(); ++i) {
    data<host_fn_indices_t>(arguments)[i] = m_indices_active_line_algorithms[i];
  }
  Allen::copy_async<dev_fn_indices_t, host_fn_indices_t>(arguments, context);

  Allen::memset_async<dev_selections_t>(arguments, 0, context); // <<===

  // * Run all selections in one go
  global_function(gather_selections::run_lines)(host_line_data.size_of_aggregate(), dim3(m_block_dim_x), context)(
    arguments, first<host_number_of_events_t>(arguments), first<host_number_of_active_lines_t>(arguments));

  // Run monitoring if configured
  for (unsigned i = 0; i < m_indices_active_line_algorithms.size(); ++i) {
    line_output_monitor_functions[m_indices_active_line_algorithms[i]](
      host_fn_parameters_agg.data(i), runtime_options, context);
  }

  // Save the names of active lines as output
  Allen::memset_async<host_names_of_active_lines_t>(arguments, 0, context);
  const auto line_names = std::string(m_names_of_active_lines);
  line_names.copy(data<host_names_of_active_lines_t>(arguments), line_names.size());

  // === Run the postscalers

  // Initialize output mask size
  Allen::memset_async<dev_event_list_output_size_t>(arguments, 0, context);

  auto dev_decisions_per_event_line = make_device_buffer<bool>(
    arguments, first<host_number_of_events_t>(arguments) * first<host_number_of_active_lines_t>(arguments));
  auto dev_postscaled_decisions_per_event_line = make_device_buffer<bool>(
    arguments, first<host_number_of_events_t>(arguments) * first<host_number_of_active_lines_t>(arguments));
  Allen::memset_async(dev_decisions_per_event_line.data(), 0, dev_decisions_per_event_line.size_bytes(), context);
  Allen::memset_async(
    dev_postscaled_decisions_per_event_line.data(), 0, dev_decisions_per_event_line.size_bytes(), context);

  global_function(postscaler)(first<host_number_of_events_t>(arguments), dim3(m_block_dim_x), context)(
    arguments,
    first<host_number_of_active_lines_t>(arguments),
    dev_decisions_per_event_line.data(),
    dev_postscaled_decisions_per_event_line.data(),
    m_histogram_line_passes.data(context),
    m_histogram_line_rates.data(context));

  // Reduce output mask to its proper size
  Allen::copy<host_event_list_output_size_t, dev_event_list_output_size_t>(arguments, context);
  reduce_size<dev_event_list_output_t>(arguments, first<host_event_list_output_size_t>(arguments));

  if (m_verbosity >= logger::debug) {
    const auto host_selections = make_host_buffer<dev_selections_t>(arguments, context);
    Allen::copy<host_selections_offsets_t, dev_selections_offsets_t>(arguments, context);

    Selections::ConstSelections sels {
      host_selections.data(), data<host_selections_offsets_t>(arguments), first<host_number_of_events_t>(arguments)};

    std::vector<uint8_t> event_decisions {};
    for (auto i = 0u; i < first<host_number_of_events_t>(arguments); ++i) {
      bool dec = false;
      for (auto j = 0u; j < first<host_number_of_active_lines_t>(arguments); ++j) {
        auto decs = sels.get_span(j, i);
        bool span_decision = !sels.is_span_empty(j, i);
        dec |= span_decision;
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
}
