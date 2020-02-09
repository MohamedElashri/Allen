#include <gsl/gsl>
#include <InputReader.h>

namespace {
  using std::make_pair;
}

Reader::Reader(const std::string& folder_name) : folder_name(folder_name)
{
  if (!exists_test(folder_name)) {
    throw StrException("Folder " + folder_name + " does not exist.");
  }
}

std::vector<char> GeometryReader::read_geometry(const std::string& filename) const
{
  std::vector<char> geometry;
  ::read_geometry(folder_name + "/" + filename, geometry);
  return geometry;
}

std::vector<std::tuple<unsigned int, unsigned long>> EventReader::read_events(
  uint number_of_events_requested,
  uint start_event_offset)
{
  bool first = true;
  std::vector<std::tuple<unsigned int, unsigned long>> event_ids;
  for (auto bank_type : types()) {
    const auto& folder = this->folder(bank_type);

    std::vector<char> events;
    std::vector<uint> event_offsets;

    if (first) {
      event_ids = read_folder(folder, number_of_events_requested, events, event_offsets, start_event_offset);
      first = false;
    }
    else {
      auto ids = read_folder(folder, number_of_events_requested, events, event_offsets, start_event_offset);
      if (event_ids != ids) {
        warning_cout << "Different events for bank type " << bank_name(bank_type) << std::endl;
      }
    }

    check_events(bank_type, events, event_offsets, number_of_events_requested);

    // TODO Remove: Temporal check to understand if number_of_events_requested is the same as number_of_events
    const uint number_of_events = event_offsets.size() - 1;
    if (number_of_events_requested != number_of_events) {
      throw StrException("Number of events requested differs from number of events read.");
    }

    // Copy raw data to pinned host memory
    char* events_mem = nullptr;
    uint* offsets_mem = nullptr;
    cudaCheck(cudaMallocHost((void**) &events_mem, events.size()));
    cudaCheck(cudaMallocHost((void**) &offsets_mem, event_offsets.size() * sizeof(uint)));
    std::copy_n(std::begin(events), events.size(), events_mem);
    std::copy_n(std::begin(event_offsets), event_offsets.size(), offsets_mem);

    m_events[bank_type] = make_pair(
      events_span {events_mem, static_cast<events_size>(events.size())},
      offsets_span {offsets_mem, static_cast<offsets_size>(event_offsets.size())});
  }
  return event_ids;
}

bool EventReader::check_events(
  BankTypes type,
  const std::vector<char>& events,
  const std::vector<uint>& event_offsets,
  uint number_of_events_requested) const
{
  if (type == BankTypes::VP) {
    return check_velopix_events(events, event_offsets, number_of_events_requested);
  }
  else {
    return events.size() == event_offsets.back();
  }
}

CatboostModelReader::CatboostModelReader(const std::string& file_name)
{
  if (!exists_test(file_name)) {
    throw StrException("Catboost model file " + file_name + " does not exist.");
  }
  std::ifstream i(file_name);
  nlohmann::json j;
  i >> j;
  m_num_features = j["features_info"]["float_features"].size();
  m_num_trees = j["oblivious_trees"].size();
  m_tree_offsets.push_back(0);
  m_leaf_offsets.push_back(0);
  for (nlohmann::json::iterator it = j["oblivious_trees"].begin(); it != j["oblivious_trees"].end(); ++it) {
    nlohmann::json tree(*it);
    std::vector<float> tree_split_borders;
    std::vector<int> tree_split_features;
    m_leaf_values.insert(std::end(m_leaf_values), std::begin(tree["leaf_values"]), std::end(tree["leaf_values"]));
    m_tree_depths.push_back(tree["splits"].size());
    m_tree_offsets.push_back(m_tree_offsets.back() + m_tree_depths.back());
    m_leaf_offsets.push_back(m_leaf_offsets.back() + (1 << m_tree_depths.back()));
    for (nlohmann::json::iterator it_spl = tree["splits"].begin(); it_spl != tree["splits"].end(); ++it_spl) {
      nlohmann::json split(*it_spl);
      tree_split_borders.push_back(split["border"]);
      tree_split_features.push_back(split["float_feature_index"]);
    }
    m_split_border.insert(std::end(m_split_border), std::begin(tree_split_borders), std::end(tree_split_borders));
    m_split_feature.insert(std::end(m_split_feature), std::begin(tree_split_features), std::end(tree_split_features));
  }
}

ConfigurationReader::ConfigurationReader(const std::string& file_name)
{
  if (!exists_test(file_name)) {
    throw StrException("Configuration JSON file " + file_name + " does not exist.");
  }
  std::ifstream i(file_name);
  nlohmann::json j;
  i >> j;
  for (auto& el : j.items()) {
    std::string component = el.key();
    for (auto& el2 : el.value().items()) {
      std::string property = el2.key();
      std::string value = "";
      if (el2.value().is_string())
        value = el2.value().get<std::string>();
      else
        throw StrException("Configuration JSON file " + file_name + " contains non-string parameter values.");
      m_params[component][property] = value;
    }
  }

  if (logger::ll.verbosityLevel >= logger::verbose) {
    for (auto it = m_params.begin(); it != m_params.end(); ++it) {
      for (auto it2 = (*it).second.begin(); it2 != (*it).second.end(); ++it2) {
        verbose_cout << (*it).first << ":" << (*it2).first << ":" << (*it2).second << std::endl;
      }
    }
  }
}

void ConfigurationReader::save(std::string file_name)
{
  nlohmann::json j(m_params);
  std::ofstream o(file_name);
  o << j;
  o.close();
}
