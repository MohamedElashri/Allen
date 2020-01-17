#include "PackageSelReports.cuh"

__global__ void package_sel_reports(
  const uint* dev_atomics_scifi,
  uint32_t* dev_sel_rb_hits,
  uint32_t* dev_sel_rb_stdinfo,
  uint32_t* dev_sel_rb_objtyp,
  uint32_t* dev_sel_rb_substr,
  uint32_t* dev_sel_rep_raw_banks,
  uint* dev_sel_rep_offsets,
  uint* event_list,
  uint number_of_total_events)
{
  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;
  const uint* event_tracks_offsets = dev_atomics_scifi + number_of_total_events;

  // TODO: Do something less silly. It's sequential, so maybe just do
  // it on the CPU? Either way it should take ~0 time.
  if (threadIdx.x == 0) {
    const uint sel_event_number = event_list[event_number];
    //printf("%i\n", sel_event_number);
    const uint n_tracks_event = dev_atomics_scifi[event_number];
    const uint event_sel_rb_hits_offset =
      event_tracks_offsets[sel_event_number] * ParKalmanFilter::nMaxMeasurements;
    uint32_t* event_sel_rb_hits = dev_sel_rb_hits + event_sel_rb_hits_offset;
    const uint event_sel_rb_stdinfo_offset = sel_event_number * Hlt1::maxStdInfoEvent;
    uint32_t* event_sel_rb_stdinfo = dev_sel_rb_stdinfo + event_sel_rb_stdinfo_offset;
    const uint event_sel_rb_objtyp_offset = sel_event_number * (Hlt1::nObjTyp + 1);
    uint32_t* event_sel_rb_objtyp = dev_sel_rb_objtyp + event_sel_rb_objtyp_offset;
    const uint event_sel_rb_substr_offset =
      sel_event_number * Hlt1::subStrDefaultAllocationSize;
    uint32_t* event_sel_rb_substr = dev_sel_rb_substr + event_sel_rb_substr_offset;

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
      dev_sel_rep_raw_banks + dev_sel_rep_offsets[number_of_events + event_number]);
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