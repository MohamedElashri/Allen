#include <regex>
#include <ROOTHeaders.h>
#include "CheckerInvoker.h"

CheckerInvoker::~CheckerInvoker() {
#ifdef WITH_ROOT
  for (auto entry : m_files) {
    entry.second->Write();
    entry.second->Close();
    delete entry.second;
  }
#endif
}

TFile* CheckerInvoker::root_file(std::string const& root_file) const {
  if (root_file.empty()) return nullptr;
#ifdef WITH_ROOT
  auto it = m_files.find(root_file);
  if (it == m_files.end()) {
    auto r = m_files.emplace(root_file, new TFile{root_file.c_str(), "RECREATE"});
    it = std::get<0>(r);
  }
  return it->second;
#else
  return nullptr;
#endif
}

MCEvents CheckerInvoker::load(std::string const mc_folder, std::vector<std::tuple<uint, unsigned long>> const& events,
                              std::vector<bool> const& event_mask,
                              std::string const tracks_folder, std::string const pvs_folder) const
{
  auto const mc_tracks_folder = mc_folder + "/" + tracks_folder;
  auto const mc_pvs_folder = mc_folder + "/" + pvs_folder;

  std::unordered_map<std::tuple<unsigned int, unsigned long>, std::string> mc_pvs_files, mc_tracks_files;

  std::regex file_expr{"(\\d+)_(\\d+).*\\.bin"};
  std::smatch result;
  for (auto& [folder, files] : {std::tuple{mc_tracks_folder, std::ref(mc_tracks_files)},
                                std::tuple{mc_pvs_folder, std::ref(mc_pvs_files)}}) {
    for (auto const& file : list_folder(folder)) {
      if (std::regex_match(file, result, file_expr)) {
        files.get().emplace(std::tuple{std::atoi(result[1].str().c_str()), std::atol(result[2].str().c_str())},
                            folder + "/" + file);
      }
    }
  }

  std::vector<MCEvent> input;

  verbose_cout << "Requested " << events.size() << " files" << std::endl;

  // Check if all files are there
  for (auto const event_id : events) {
    auto files = {std::tuple{pvs_folder, mc_pvs_files},
                  std::tuple{tracks_folder, mc_tracks_files}};
    if (std::any_of(files.begin(), files.end(),
                    [event_id](auto const& entry) {
                      auto missing = !std::get<1>(entry).count(event_id);
                      if (missing) {
                        error_cout << "Missing MC " << std::get<0>(entry)
                                   << " for event " << std::get<0>(event_id)
                                   << " " << std::get<1>(event_id) << std::endl;
                      }
                      return missing;
                    })) {
      return input;
    }
  }

  input.reserve(event_mask.size());

  std::vector<char> raw_particles, raw_pvs;

  int readFiles = 0;
  for (size_t i = 0; i < events.size(); ++i) {
    readFiles++;
    if ((readFiles % 100) == 0) {
      info_cout << "." << std::flush;
    }

    if (!event_mask[i]) continue;

    raw_particles.clear();
    raw_pvs.clear();

    // Read event #i in the list and add it to the inputs
    auto event_id = events[i];
    readFileIntoVector(mc_pvs_files[event_id], raw_pvs);
    readFileIntoVector(mc_tracks_files[event_id], raw_particles);

    input.emplace_back(raw_particles, raw_pvs, m_check_events);

  }

  info_cout << std::endl << readFiles << " files read" << std::endl << std::endl;
  return input;
}
