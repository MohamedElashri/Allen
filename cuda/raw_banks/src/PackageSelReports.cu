#include "PackageSelReports.cuh"

__global__ void package_sel_reports::package_sel_reports(
  package_sel_reports::Parameters parameters,
  const uint number_of_events)
{
  for (auto event_number = blockIdx.x * blockDim.x + threadIdx.x; event_number < number_of_events;
     event_number += blockDim.x * gridDim.x) {
    const uint sel_event_number = parameters.dev_passing_event_list[event_number];
    const uint n_tracks_event = parameters.dev_offsets_forward_tracks[event_number + 1] - parameters.dev_offsets_forward_tracks[event_number];
    const uint event_sel_rb_hits_offset =
      parameters.dev_offsets_forward_tracks[sel_event_number] * ParKalmanFilter::nMaxMeasurements;
    uint32_t* event_sel_rb_hits = parameters.dev_sel_rb_hits + event_sel_rb_hits_offset;
    const uint event_sel_rb_stdinfo_offset = sel_event_number * Hlt1::maxStdInfoEvent;
    uint32_t* event_sel_rb_stdinfo = parameters.dev_sel_rb_stdinfo + event_sel_rb_stdinfo_offset;
    const uint event_sel_rb_objtyp_offset = sel_event_number * (Hlt1::nObjTyp + 1);
    uint32_t* event_sel_rb_objtyp = parameters.dev_sel_rb_objtyp + event_sel_rb_objtyp_offset;
    const uint event_sel_rb_substr_offset =
      sel_event_number * Hlt1::subStrDefaultAllocationSize;
    uint32_t* event_sel_rb_substr = parameters.dev_sel_rb_substr + event_sel_rb_substr_offset;

    HltSelRepRBHits hits_bank;
    hits_bank.m_location = event_sel_rb_hits;
    HltSelRepRBSubstr substr_bank;
    substr_bank.m_location = event_sel_rb_substr;
    substr_bank.saveSize();
    HltSelRepRBStdInfo stdinfo_bank;
    stdinfo_bank.m_location = event_sel_rb_stdinfo;
    stdinfo_bank.saveSize();
    HltSelRepRBObjTyp objtyp_bank;
    objtyp_bank.m_location = event_sel_rb_objtyp;
    objtyp_bank.saveSize();
    
    HltSelRepRawBank selrep_bank(
      parameters.dev_sel_rep_raw_banks + parameters.dev_sel_rep_offsets[event_number]);
    selrep_bank.push_back(
      HltSelRepRBEnums::kHitsID,
      hits_bank.m_location,
      hits_bank.size());
    selrep_bank.push_back(
      HltSelRepRBEnums::kObjTypID,
      objtyp_bank.m_location,
      objtyp_bank.size());
    selrep_bank.push_back(
      HltSelRepRBEnums::kSubstrID,
      substr_bank.m_location,
      substr_bank.size());
    if (stdinfo_bank.sizeStored() < Hlt1::maxStdInfoEvent) {
      selrep_bank.push_back(
        HltSelRepRBEnums::kStdInfoID,
        stdinfo_bank.m_location,
        stdinfo_bank.size());
    }
  }
}