#pragma once

#include <string>
#include <vector>
#include "CheckerTypes.h"
#include "MCEvent.h"
#include "InputTools.h"

class TFile;

struct CheckerInvoker {

  CheckerInvoker(const bool check_events = false) :
    m_check_events{check_events}
  {
  }

  ~CheckerInvoker();

  MCEvents load(std::string const mc_folder, std::vector<std::tuple<uint, unsigned long>> const& events,
                std::vector<bool> const& event_mask,
                std::string const tracks_folder = "tracks", std::string const pvs_folder = "PVs") const;

  void report(size_t n_events) const {
    for (auto const& entry : m_checkers) {
      entry.second->report(n_events);
    }
  }

  TFile* root_file(std::string const& file = std::string{}) const;

  template<typename T>
  T& checker(std::string const& root_file = std::string{}) const
  {
    auto const& name = T::subdetector_t::name;
    auto it = m_checkers.find(name);
    if (it == m_checkers.end()) {
      auto r = m_checkers.emplace(name, std::unique_ptr<Checker::BaseChecker>{new T{this, root_file}});
      it = std::get<0>(r);
    }
    return static_cast<T&>(*(it->second));
  }

private:

  long m_input_events = 0;
  bool m_check_events = false;
  mutable std::map<std::string, std::unique_ptr<Checker::BaseChecker>> m_checkers;
  mutable std::map<std::string, TFile*> m_files;

};
