#include "PackageSelReports.cuh"

__global__ void package_sel_reports::package_sel_reports(
  package_sel_reports::Parameters parameters,
  const uint number_of_events,
  const uint selected_number_of_events,
  const uint event_start)
{
  for (auto selected_event_number = blockIdx.x * blockDim.x + threadIdx.x; selected_event_number < number_of_events; selected_event_number += blockDim.x * gridDim.x) {

    const uint event_number = parameters.dev_event_list[selected_event_number] - event_start;
    
    const uint event_sel_rb_stdinfo_offset = event_number * Hlt1::maxStdInfoEvent;
    const uint32_t* event_sel_rb_stdinfo = parameters.dev_sel_rb_stdinfo + event_sel_rb_stdinfo_offset;
    const uint event_sel_rb_objtyp_offset = event_number * (Hlt1::nObjTyp + 1);
    const uint32_t* event_sel_rb_objtyp = parameters.dev_sel_rb_objtyp + event_sel_rb_objtyp_offset;
    const uint event_sel_rb_substr_offset =
      event_number * Hlt1::subStrDefaultAllocationSize;
    const uint32_t* event_sel_rb_substr = parameters.dev_sel_rb_substr + event_sel_rb_substr_offset;

    HltSelRepRawBank selrep_bank(
      parameters.dev_sel_rep_raw_banks + parameters.dev_sel_rep_offsets[event_number]);
    selrep_bank.push_back(
      HltSelRepRBEnums::kObjTypID,
      event_sel_rb_objtyp,
      HltSelRepRBObjTyp::sizeFromPtr(event_sel_rb_objtyp));
    selrep_bank.push_back(
      HltSelRepRBEnums::kSubstrID,
      event_sel_rb_substr,
      HltSelRepRBSubstr::sizeFromPtr(event_sel_rb_substr));

    if (selected_event_number < selected_number_of_events) {
      const uint event_sel_rb_hits_offset =
        parameters.dev_offsets_forward_tracks[selected_event_number] * ParKalmanFilter::nMaxMeasurements +
        3 * selected_event_number;
      const uint32_t* event_sel_rb_hits = parameters.dev_sel_rb_hits + event_sel_rb_hits_offset;

      selrep_bank.push_back(
        HltSelRepRBEnums::kHitsID,
        event_sel_rb_hits,
        HltSelRepRBHits::sizeFromPtr(event_sel_rb_hits));
    }
    
    if (HltSelRepRBStdInfo::sizeStoredFromPtr(event_sel_rb_stdinfo) < Hlt1::maxStdInfoEvent) {
      selrep_bank.push_back(
        HltSelRepRBEnums::kStdInfoID,
        event_sel_rb_stdinfo,
        HltSelRepRBStdInfo::sizeFromPtr(event_sel_rb_stdinfo));
    }
  }
}