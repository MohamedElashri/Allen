#pragma once

#include <tuple>
#include "../../cuda/selections/Hlt1/include/LineTraverser.cuh"
#include "../../cuda/raw_banks/include/PopulateOdinBanks.cuh"
#include "../../x86/global_event_cut/include/HostGlobalEventCut.h"
#include "../../cuda/calo/decoding/include/CaloCountHits.cuh"

struct dev_odin_raw_input_t : populate_odin_banks::Parameters::dev_odin_raw_input_t { constexpr static auto name {"dev_odin_raw_input_t"}; size_t size; char* offset; };
struct dev_odin_raw_input_offsets_t : populate_odin_banks::Parameters::dev_odin_raw_input_offsets_t { constexpr static auto name {"dev_odin_raw_input_offsets_t"}; size_t size; char* offset; };
struct host_total_number_of_events_t : host_global_event_cut::Parameters::host_total_number_of_events_t { constexpr static auto name {"host_total_number_of_events_t"}; size_t size; char* offset; };
struct host_event_list_t : host_global_event_cut::Parameters::host_event_list_t { constexpr static auto name {"host_event_list_t"}; size_t size; char* offset; };
struct host_number_of_selected_events_t : host_global_event_cut::Parameters::host_number_of_selected_events_t, calo_count_hits::Parameters::host_number_of_selected_events_t { constexpr static auto name {"host_number_of_selected_events_t"}; size_t size; char* offset; };
struct dev_event_list_t : host_global_event_cut::Parameters::dev_event_list_t, calo_count_hits::Parameters::dev_event_list_t { constexpr static auto name {"dev_event_list_t"}; size_t size; char* offset; };
struct dev_ecal_raw_input_t : calo_count_hits::Parameters::dev_ecal_raw_input_t { constexpr static auto name {"dev_ecal_raw_input_t"}; size_t size; char* offset; };
struct dev_ecal_raw_input_offsets_t : calo_count_hits::Parameters::dev_ecal_raw_input_offsets_t { constexpr static auto name {"dev_ecal_raw_input_offsets_t"}; size_t size; char* offset; };
struct dev_ecal_number_of_hits_t : calo_count_hits::Parameters::dev_ecal_number_of_hits_t { constexpr static auto name {"dev_ecal_number_of_hits_t"}; size_t size; char* offset; };
struct dev_hcal_raw_input_t : calo_count_hits::Parameters::dev_hcal_raw_input_t { constexpr static auto name {"dev_hcal_raw_input_t"}; size_t size; char* offset; };
struct dev_hcal_raw_input_offsets_t : calo_count_hits::Parameters::dev_hcal_raw_input_offsets_t { constexpr static auto name {"dev_hcal_raw_input_offsets_t"}; size_t size; char* offset; };
struct dev_hcal_number_of_hits_t : calo_count_hits::Parameters::dev_hcal_number_of_hits_t { constexpr static auto name {"dev_hcal_number_of_hits_t"}; size_t size; char* offset; };

using configured_lines_t = std::tuple<>;

using configured_sequence_t = std::tuple<
  populate_odin_banks::populate_odin_banks_t<std::tuple<dev_odin_raw_input_t, dev_odin_raw_input_offsets_t>, configured_lines_t, 'p', 'o', 'p', 'u', 'l', 'a', 't', 'e', '_', 'o', 'd', 'i', 'n', '_', 'b', 'a', 'n', 'k', 's', '_', 't'>,
  host_global_event_cut::host_global_event_cut_t<std::tuple<host_total_number_of_events_t, host_event_list_t, host_number_of_selected_events_t, dev_event_list_t>, 'h', 'o', 's', 't', '_', 'g', 'l', 'o', 'b', 'a', 'l', '_', 'e', 'v', 'e', 'n', 't', '_', 'c', 'u', 't', '_', 't'>,
  calo_count_hits::calo_count_hits_t<std::tuple<host_number_of_selected_events_t, dev_event_list_t, dev_ecal_raw_input_t, dev_ecal_raw_input_offsets_t, dev_ecal_number_of_hits_t, dev_hcal_raw_input_t, dev_hcal_raw_input_offsets_t, dev_hcal_number_of_hits_t>, 'c', 'a', 'l', 'o', '_', 'c', 'o', 'u', 'n', 't', '_', 'h', 'i', 't', 's', '_', 't'>
>;
