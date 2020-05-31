/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "PackageSelReports.cuh"

void package_sel_reports::package_sel_reports_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_sel_rep_raw_banks_t>(arguments, first<host_number_of_sel_rep_words_t>(arguments));
}

void package_sel_reports::package_sel_reports_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers& host_buffers,
  cudaStream_t& stream,
  cudaEvent_t&) const
{
  const auto event_start = std::get<0>(runtime_options.event_interval);
  const auto total_number_of_events =
    std::get<1>(runtime_options.event_interval) - std::get<0>(runtime_options.event_interval);

  initialize<dev_sel_rep_raw_banks_t>(arguments, 0, stream);

  const auto grid_size = dim3((total_number_of_events + property<block_dim_x_t>() - 1) / property<block_dim_x_t>());

  global_function(package_sel_reports)(grid_size, dim3(property<block_dim_x_t>().get()), stream)(
    arguments, total_number_of_events, first<host_number_of_events_t>(arguments), event_start);

  assign_to_host_buffer<dev_sel_rep_offsets_t>(host_buffers.host_sel_rep_offsets, arguments, stream);
  safe_assign_to_host_buffer<dev_sel_rep_raw_banks_t>(
    host_buffers.host_sel_rep_raw_banks, host_buffers.host_sel_rep_raw_banks_size, arguments, stream);
}

__global__ void package_sel_reports::package_sel_reports(
  package_sel_reports::Parameters parameters,
  const unsigned number_of_events,
  const unsigned selected_number_of_events,
  const unsigned event_start)
{
  for (auto selected_event_number = blockIdx.x * blockDim.x + threadIdx.x; selected_event_number < number_of_events;
       selected_event_number += blockDim.x * gridDim.x) {

    const unsigned event_number = parameters.dev_event_list[selected_event_number] - event_start;

    const unsigned event_sel_rb_stdinfo_offset = event_number * Hlt1::maxStdInfoEvent;
    const uint32_t* event_sel_rb_stdinfo = parameters.dev_sel_rb_stdinfo + event_sel_rb_stdinfo_offset;
    const unsigned event_sel_rb_objtyp_offset = event_number * (Hlt1::nObjTyp + 1);
    const uint32_t* event_sel_rb_objtyp = parameters.dev_sel_rb_objtyp + event_sel_rb_objtyp_offset;
    const unsigned event_sel_rb_substr_offset = event_number * Hlt1::subStrDefaultAllocationSize;
    const uint32_t* event_sel_rb_substr = parameters.dev_sel_rb_substr + event_sel_rb_substr_offset;

    HltSelRepRawBank selrep_bank(parameters.dev_sel_rep_raw_banks + parameters.dev_sel_rep_offsets[event_number]);
    selrep_bank.push_back(
      HltSelRepRBEnums::kObjTypID, event_sel_rb_objtyp, HltSelRepRBObjTyp::sizeFromPtr(event_sel_rb_objtyp));
    selrep_bank.push_back(
      HltSelRepRBEnums::kSubstrID, event_sel_rb_substr, HltSelRepRBSubstr::sizeFromPtr(event_sel_rb_substr));

    if (selected_event_number < selected_number_of_events) {
      const unsigned event_sel_rb_hits_offset =
        parameters.dev_offsets_forward_tracks[selected_event_number] * ParKalmanFilter::nMaxMeasurements +
        3 * selected_event_number;
      const uint32_t* event_sel_rb_hits = parameters.dev_sel_rb_hits + event_sel_rb_hits_offset;

      selrep_bank.push_back(
        HltSelRepRBEnums::kHitsID, event_sel_rb_hits, HltSelRepRBHits::sizeFromPtr(event_sel_rb_hits));
    }

    if (HltSelRepRBStdInfo::sizeStoredFromPtr(event_sel_rb_stdinfo) < Hlt1::maxStdInfoEvent) {
      selrep_bank.push_back(
        HltSelRepRBEnums::kStdInfoID, event_sel_rb_stdinfo, HltSelRepRBStdInfo::sizeFromPtr(event_sel_rb_stdinfo));
    }
  }
}