#pragma once

#include <string>
#include <list>
#include <vector>
#include "CheckerTypes.h"
#include "MCEvent.h"
#include "InputTools.h"

class TFile;

struct CheckerInvoker {

  CheckerInvoker(std::string output_folder = "output", const bool check_events = false) :
    m_check_events {check_events}, m_output_dir {std::move(output_folder)}
  {}

  ~CheckerInvoker();

  MCEvents load(
    std::string const mc_folder,
    std::vector<std::tuple<unsigned, unsigned long>> const& events,
    std::vector<bool> const& event_mask,
    std::string const tracks_folder = "tracks",
    std::string const pvs_folder = "PVs") const;

  void report(size_t n_events) const;
  TFile* root_file(std::string const& file = std::string {}) const;

  template<typename T>
  T& checker(std::string header, std::string const& root_file = std::string {}) const
  {
    auto const& name = T::subdetector_t::name;
    auto it = m_checkers.find(name);
    if (it == m_checkers.end()) {
      auto r = m_checkers.emplace(name, std::unique_ptr<Checker::BaseChecker> {new T {this, root_file}});
      m_report_order.emplace_back(name, header);
      it = std::get<0>(r);
    }
    return static_cast<T&>(*(it->second));
  }

private:
  bool m_check_events = false;
  std::string const m_output_dir;
  std::map<std::string, std::unique_ptr<Checker::BaseChecker>> mutable m_checkers;
  std::list<std::tuple<std::string, std::string>> mutable m_report_order;
  std::map<std::string, TFile*> mutable m_files;
};
