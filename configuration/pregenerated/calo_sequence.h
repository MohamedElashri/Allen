#pragma once

#include <tuple>
#include "ConfiguredLines.h"
#include "../../stream/gear/include/ArgumentManager.cuh"
#include "../../host/data_provider/include/HostDataProvider.h"
#include "../../host/data_provider/include/HostDataProvider.h"
#include "../../host/global_event_cut/include/HostGlobalEventCut.h"
#include "../../host/data_provider/include/DataProvider.h"
#include "../../host/data_provider/include/DataProvider.h"
#include "../../device/calo/decoding/include/CaloDecode.cuh"
#include "../../device/calo/clustering/include/CaloSeedClusters.cuh"
#include "../../host/prefix_sum/include/HostPrefixSum.h"
#include "../../host/prefix_sum/include/HostPrefixSum.h"
#include "../../device/calo/clustering/include/CaloFindClusters.cuh"

struct host_ut_banks__host_raw_banks_t : host_data_provider::Parameters::host_raw_banks_t, host_global_event_cut::Parameters::host_ut_raw_banks_t { void set_size(size_t size) override { m_size = size; } size_t size() const override { return m_size; } std::string name() const override { return "host_ut_banks__host_raw_banks_t"; } void set_offset(char* offset) override { m_offset = offset; } char* offset() const override { return m_offset; } private:     size_t m_size = 0;     char* m_offset = nullptr; };
struct host_ut_banks__host_raw_offsets_t : host_data_provider::Parameters::host_raw_offsets_t, host_global_event_cut::Parameters::host_ut_raw_offsets_t { void set_size(size_t size) override { m_size = size; } size_t size() const override { return m_size; } std::string name() const override { return "host_ut_banks__host_raw_offsets_t"; } void set_offset(char* offset) override { m_offset = offset; } char* offset() const override { return m_offset; } private:     size_t m_size = 0;     char* m_offset = nullptr; };
struct host_scifi_banks__host_raw_banks_t : host_data_provider::Parameters::host_raw_banks_t, host_global_event_cut::Parameters::host_scifi_raw_banks_t { void set_size(size_t size) override { m_size = size; } size_t size() const override { return m_size; } std::string name() const override { return "host_scifi_banks__host_raw_banks_t"; } void set_offset(char* offset) override { m_offset = offset; } char* offset() const override { return m_offset; } private:     size_t m_size = 0;     char* m_offset = nullptr; };
struct host_scifi_banks__host_raw_offsets_t : host_data_provider::Parameters::host_raw_offsets_t, host_global_event_cut::Parameters::host_scifi_raw_offsets_t { void set_size(size_t size) override { m_size = size; } size_t size() const override { return m_size; } std::string name() const override { return "host_scifi_banks__host_raw_offsets_t"; } void set_offset(char* offset) override { m_offset = offset; } char* offset() const override { return m_offset; } private:     size_t m_size = 0;     char* m_offset = nullptr; };
struct initialize_lists__host_total_number_of_events_t : host_global_event_cut::Parameters::host_total_number_of_events_t { void set_size(size_t size) override { m_size = size; } size_t size() const override { return m_size; } std::string name() const override { return "initialize_lists__host_total_number_of_events_t"; } void set_offset(char* offset) override { m_offset = offset; } char* offset() const override { return m_offset; } private:     size_t m_size = 0;     char* m_offset = nullptr; };
struct initialize_lists__host_event_list_t : host_global_event_cut::Parameters::host_event_list_t { void set_size(size_t size) override { m_size = size; } size_t size() const override { return m_size; } std::string name() const override { return "initialize_lists__host_event_list_t"; } void set_offset(char* offset) override { m_offset = offset; } char* offset() const override { return m_offset; } private:     size_t m_size = 0;     char* m_offset = nullptr; };
struct initialize_lists__host_number_of_selected_events_t : host_global_event_cut::Parameters::host_number_of_selected_events_t, calo_decode::Parameters::host_number_of_selected_events_t, calo_seed_clusters::Parameters::host_number_of_selected_events_t, calo_find_clusters::Parameters::host_number_of_selected_events_t { void set_size(size_t size) override { m_size = size; } size_t size() const override { return m_size; } std::string name() const override { return "initialize_lists__host_number_of_selected_events_t"; } void set_offset(char* offset) override { m_offset = offset; } char* offset() const override { return m_offset; } private:     size_t m_size = 0;     char* m_offset = nullptr; };
struct initialize_lists__dev_event_list_t : host_global_event_cut::Parameters::dev_event_list_t, calo_decode::Parameters::dev_event_list_t, calo_seed_clusters::Parameters::dev_event_list_t, calo_find_clusters::Parameters::dev_event_list_t { void set_size(size_t size) override { m_size = size; } size_t size() const override { return m_size; } std::string name() const override { return "initialize_lists__dev_event_list_t"; } void set_offset(char* offset) override { m_offset = offset; } char* offset() const override { return m_offset; } private:     size_t m_size = 0;     char* m_offset = nullptr; };
struct ecal_banks__dev_raw_banks_t : data_provider::Parameters::dev_raw_banks_t, calo_decode::Parameters::dev_ecal_raw_input_t { void set_size(size_t size) override { m_size = size; } size_t size() const override { return m_size; } std::string name() const override { return "ecal_banks__dev_raw_banks_t"; } void set_offset(char* offset) override { m_offset = offset; } char* offset() const override { return m_offset; } private:     size_t m_size = 0;     char* m_offset = nullptr; };
struct ecal_banks__dev_raw_offsets_t : data_provider::Parameters::dev_raw_offsets_t, calo_decode::Parameters::dev_ecal_raw_input_offsets_t { void set_size(size_t size) override { m_size = size; } size_t size() const override { return m_size; } std::string name() const override { return "ecal_banks__dev_raw_offsets_t"; } void set_offset(char* offset) override { m_offset = offset; } char* offset() const override { return m_offset; } private:     size_t m_size = 0;     char* m_offset = nullptr; };
struct hcal_banks__dev_raw_banks_t : data_provider::Parameters::dev_raw_banks_t, calo_decode::Parameters::dev_hcal_raw_input_t { void set_size(size_t size) override { m_size = size; } size_t size() const override { return m_size; } std::string name() const override { return "hcal_banks__dev_raw_banks_t"; } void set_offset(char* offset) override { m_offset = offset; } char* offset() const override { return m_offset; } private:     size_t m_size = 0;     char* m_offset = nullptr; };
struct hcal_banks__dev_raw_offsets_t : data_provider::Parameters::dev_raw_offsets_t, calo_decode::Parameters::dev_hcal_raw_input_offsets_t { void set_size(size_t size) override { m_size = size; } size_t size() const override { return m_size; } std::string name() const override { return "hcal_banks__dev_raw_offsets_t"; } void set_offset(char* offset) override { m_offset = offset; } char* offset() const override { return m_offset; } private:     size_t m_size = 0;     char* m_offset = nullptr; };
struct calo_decode__dev_ecal_digits_t : calo_decode::Parameters::dev_ecal_digits_t, calo_seed_clusters::Parameters::dev_ecal_digits_t, calo_find_clusters::Parameters::dev_ecal_digits_t { void set_size(size_t size) override { m_size = size; } size_t size() const override { return m_size; } std::string name() const override { return "calo_decode__dev_ecal_digits_t"; } void set_offset(char* offset) override { m_offset = offset; } char* offset() const override { return m_offset; } private:     size_t m_size = 0;     char* m_offset = nullptr; };
struct calo_decode__dev_hcal_digits_t : calo_decode::Parameters::dev_hcal_digits_t, calo_seed_clusters::Parameters::dev_hcal_digits_t, calo_find_clusters::Parameters::dev_hcal_digits_t { void set_size(size_t size) override { m_size = size; } size_t size() const override { return m_size; } std::string name() const override { return "calo_decode__dev_hcal_digits_t"; } void set_offset(char* offset) override { m_offset = offset; } char* offset() const override { return m_offset; } private:     size_t m_size = 0;     char* m_offset = nullptr; };
struct calo_seed_clusters__dev_ecal_num_clusters_t : calo_seed_clusters::Parameters::dev_ecal_num_clusters_t, host_prefix_sum::Parameters::dev_input_buffer_t { void set_size(size_t size) override { m_size = size; } size_t size() const override { return m_size; } std::string name() const override { return "calo_seed_clusters__dev_ecal_num_clusters_t"; } void set_offset(char* offset) override { m_offset = offset; } char* offset() const override { return m_offset; } private:     size_t m_size = 0;     char* m_offset = nullptr; };
struct calo_seed_clusters__dev_hcal_num_clusters_t : calo_seed_clusters::Parameters::dev_hcal_num_clusters_t, host_prefix_sum::Parameters::dev_input_buffer_t { void set_size(size_t size) override { m_size = size; } size_t size() const override { return m_size; } std::string name() const override { return "calo_seed_clusters__dev_hcal_num_clusters_t"; } void set_offset(char* offset) override { m_offset = offset; } char* offset() const override { return m_offset; } private:     size_t m_size = 0;     char* m_offset = nullptr; };
struct calo_seed_clusters__dev_ecal_seed_clusters_t : calo_seed_clusters::Parameters::dev_ecal_seed_clusters_t, calo_find_clusters::Parameters::dev_ecal_seed_clusters_t { void set_size(size_t size) override { m_size = size; } size_t size() const override { return m_size; } std::string name() const override { return "calo_seed_clusters__dev_ecal_seed_clusters_t"; } void set_offset(char* offset) override { m_offset = offset; } char* offset() const override { return m_offset; } private:     size_t m_size = 0;     char* m_offset = nullptr; };
struct calo_seed_clusters__dev_hcal_seed_clusters_t : calo_seed_clusters::Parameters::dev_hcal_seed_clusters_t, calo_find_clusters::Parameters::dev_hcal_seed_clusters_t { void set_size(size_t size) override { m_size = size; } size_t size() const override { return m_size; } std::string name() const override { return "calo_seed_clusters__dev_hcal_seed_clusters_t"; } void set_offset(char* offset) override { m_offset = offset; } char* offset() const override { return m_offset; } private:     size_t m_size = 0;     char* m_offset = nullptr; };
struct prefix_sum_ecal_num_clusters__host_total_sum_holder_t : host_prefix_sum::Parameters::host_total_sum_holder_t, calo_find_clusters::Parameters::host_ecal_number_of_clusters_t { void set_size(size_t size) override { m_size = size; } size_t size() const override { return m_size; } std::string name() const override { return "prefix_sum_ecal_num_clusters__host_total_sum_holder_t"; } void set_offset(char* offset) override { m_offset = offset; } char* offset() const override { return m_offset; } private:     size_t m_size = 0;     char* m_offset = nullptr; };
struct prefix_sum_ecal_num_clusters__dev_output_buffer_t : host_prefix_sum::Parameters::dev_output_buffer_t, calo_find_clusters::Parameters::dev_ecal_cluster_offsets_t { void set_size(size_t size) override { m_size = size; } size_t size() const override { return m_size; } std::string name() const override { return "prefix_sum_ecal_num_clusters__dev_output_buffer_t"; } void set_offset(char* offset) override { m_offset = offset; } char* offset() const override { return m_offset; } private:     size_t m_size = 0;     char* m_offset = nullptr; };
struct prefix_sum_hcal_num_clusters__host_total_sum_holder_t : host_prefix_sum::Parameters::host_total_sum_holder_t, calo_find_clusters::Parameters::host_hcal_number_of_clusters_t { void set_size(size_t size) override { m_size = size; } size_t size() const override { return m_size; } std::string name() const override { return "prefix_sum_hcal_num_clusters__host_total_sum_holder_t"; } void set_offset(char* offset) override { m_offset = offset; } char* offset() const override { return m_offset; } private:     size_t m_size = 0;     char* m_offset = nullptr; };
struct prefix_sum_hcal_num_clusters__dev_output_buffer_t : host_prefix_sum::Parameters::dev_output_buffer_t, calo_find_clusters::Parameters::dev_hcal_cluster_offsets_t { void set_size(size_t size) override { m_size = size; } size_t size() const override { return m_size; } std::string name() const override { return "prefix_sum_hcal_num_clusters__dev_output_buffer_t"; } void set_offset(char* offset) override { m_offset = offset; } char* offset() const override { return m_offset; } private:     size_t m_size = 0;     char* m_offset = nullptr; };
struct calo_find_clusters__dev_ecal_digits_clusters_t : calo_find_clusters::Parameters::dev_ecal_digits_clusters_t { void set_size(size_t size) override { m_size = size; } size_t size() const override { return m_size; } std::string name() const override { return "calo_find_clusters__dev_ecal_digits_clusters_t"; } void set_offset(char* offset) override { m_offset = offset; } char* offset() const override { return m_offset; } private:     size_t m_size = 0;     char* m_offset = nullptr; };
struct calo_find_clusters__dev_hcal_digits_clusters_t : calo_find_clusters::Parameters::dev_hcal_digits_clusters_t { void set_size(size_t size) override { m_size = size; } size_t size() const override { return m_size; } std::string name() const override { return "calo_find_clusters__dev_hcal_digits_clusters_t"; } void set_offset(char* offset) override { m_offset = offset; } char* offset() const override { return m_offset; } private:     size_t m_size = 0;     char* m_offset = nullptr; };
struct calo_find_clusters__dev_ecal_clusters_t : calo_find_clusters::Parameters::dev_ecal_clusters_t { void set_size(size_t size) override { m_size = size; } size_t size() const override { return m_size; } std::string name() const override { return "calo_find_clusters__dev_ecal_clusters_t"; } void set_offset(char* offset) override { m_offset = offset; } char* offset() const override { return m_offset; } private:     size_t m_size = 0;     char* m_offset = nullptr; };
struct calo_find_clusters__dev_hcal_clusters_t : calo_find_clusters::Parameters::dev_hcal_clusters_t { void set_size(size_t size) override { m_size = size; } size_t size() const override { return m_size; } std::string name() const override { return "calo_find_clusters__dev_hcal_clusters_t"; } void set_offset(char* offset) override { m_offset = offset; } char* offset() const override { return m_offset; } private:     size_t m_size = 0;     char* m_offset = nullptr; };

using configured_arguments_t = std::tuple<
  host_ut_banks__host_raw_banks_t,
  host_ut_banks__host_raw_offsets_t,
  host_scifi_banks__host_raw_banks_t,
  host_scifi_banks__host_raw_offsets_t,
  initialize_lists__host_total_number_of_events_t,
  initialize_lists__host_event_list_t,
  initialize_lists__host_number_of_selected_events_t,
  initialize_lists__dev_event_list_t,
  ecal_banks__dev_raw_banks_t,
  ecal_banks__dev_raw_offsets_t,
  hcal_banks__dev_raw_banks_t,
  hcal_banks__dev_raw_offsets_t,
  calo_decode__dev_ecal_digits_t,
  calo_decode__dev_hcal_digits_t,
  calo_seed_clusters__dev_ecal_num_clusters_t,
  calo_seed_clusters__dev_hcal_num_clusters_t,
  calo_seed_clusters__dev_ecal_seed_clusters_t,
  calo_seed_clusters__dev_hcal_seed_clusters_t,
  prefix_sum_ecal_num_clusters__host_total_sum_holder_t,
  prefix_sum_ecal_num_clusters__dev_output_buffer_t,
  prefix_sum_hcal_num_clusters__host_total_sum_holder_t,
  prefix_sum_hcal_num_clusters__dev_output_buffer_t,
  calo_find_clusters__dev_ecal_digits_clusters_t,
  calo_find_clusters__dev_hcal_digits_clusters_t,
  calo_find_clusters__dev_ecal_clusters_t,
  calo_find_clusters__dev_hcal_clusters_t>;

using configured_sequence_t = std::tuple<
  host_data_provider::host_data_provider_t,
  host_data_provider::host_data_provider_t,
  host_global_event_cut::host_global_event_cut_t,
  data_provider::data_provider_t,
  data_provider::data_provider_t,
  calo_decode::calo_decode_t,
  calo_seed_clusters::calo_seed_clusters_t,
  host_prefix_sum::host_prefix_sum_t,
  host_prefix_sum::host_prefix_sum_t,
  calo_find_clusters::calo_find_clusters_t>;

using configured_sequence_arguments_t = std::tuple<
  std::tuple<host_ut_banks__host_raw_banks_t, host_ut_banks__host_raw_offsets_t>,
  std::tuple<host_scifi_banks__host_raw_banks_t, host_scifi_banks__host_raw_offsets_t>,
  std::tuple<host_ut_banks__host_raw_banks_t, host_ut_banks__host_raw_offsets_t, host_scifi_banks__host_raw_banks_t, host_scifi_banks__host_raw_offsets_t, initialize_lists__host_total_number_of_events_t, initialize_lists__host_event_list_t, initialize_lists__host_number_of_selected_events_t, initialize_lists__dev_event_list_t>,
  std::tuple<ecal_banks__dev_raw_banks_t, ecal_banks__dev_raw_offsets_t>,
  std::tuple<hcal_banks__dev_raw_banks_t, hcal_banks__dev_raw_offsets_t>,
  std::tuple<initialize_lists__host_number_of_selected_events_t, initialize_lists__dev_event_list_t, ecal_banks__dev_raw_banks_t, ecal_banks__dev_raw_offsets_t, hcal_banks__dev_raw_banks_t, hcal_banks__dev_raw_offsets_t, calo_decode__dev_ecal_digits_t, calo_decode__dev_hcal_digits_t>,
  std::tuple<initialize_lists__host_number_of_selected_events_t, initialize_lists__dev_event_list_t, calo_decode__dev_ecal_digits_t, calo_decode__dev_hcal_digits_t, calo_seed_clusters__dev_ecal_num_clusters_t, calo_seed_clusters__dev_hcal_num_clusters_t, calo_seed_clusters__dev_ecal_seed_clusters_t, calo_seed_clusters__dev_hcal_seed_clusters_t>,
  std::tuple<prefix_sum_ecal_num_clusters__host_total_sum_holder_t, calo_seed_clusters__dev_ecal_num_clusters_t, prefix_sum_ecal_num_clusters__dev_output_buffer_t>,
  std::tuple<prefix_sum_hcal_num_clusters__host_total_sum_holder_t, calo_seed_clusters__dev_hcal_num_clusters_t, prefix_sum_hcal_num_clusters__dev_output_buffer_t>,
  std::tuple<initialize_lists__host_number_of_selected_events_t, prefix_sum_ecal_num_clusters__host_total_sum_holder_t, prefix_sum_hcal_num_clusters__host_total_sum_holder_t, initialize_lists__dev_event_list_t, calo_decode__dev_ecal_digits_t, calo_decode__dev_hcal_digits_t, calo_seed_clusters__dev_ecal_seed_clusters_t, calo_seed_clusters__dev_hcal_seed_clusters_t, prefix_sum_ecal_num_clusters__dev_output_buffer_t, prefix_sum_hcal_num_clusters__dev_output_buffer_t, calo_find_clusters__dev_ecal_digits_clusters_t, calo_find_clusters__dev_hcal_digits_clusters_t, calo_find_clusters__dev_ecal_clusters_t, calo_find_clusters__dev_hcal_clusters_t>>;

void inline populate_sequence_algorithm_names(configured_sequence_t& sequence) {
  std::get<0>(sequence).set_name("host_ut_banks");
  std::get<1>(sequence).set_name("host_scifi_banks");
  std::get<2>(sequence).set_name("initialize_lists");
  std::get<3>(sequence).set_name("ecal_banks");
  std::get<4>(sequence).set_name("hcal_banks");
  std::get<5>(sequence).set_name("calo_decode");
  std::get<6>(sequence).set_name("calo_seed_clusters");
  std::get<7>(sequence).set_name("prefix_sum_ecal_num_clusters");
  std::get<8>(sequence).set_name("prefix_sum_hcal_num_clusters");
  std::get<9>(sequence).set_name("calo_find_clusters");
}
