/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <string>
#include <list>
#include <vector>
#include "InputTools.h"
#include <mutex>
#include <ROOTHeaders.h>

struct handleROOTSvc; // forward declarations
#ifndef WITH_ROOT
struct ROOTService {
};
#else
struct ROOTService {

public:
  ROOTService(std::string output_folder = "output") : m_output_dir {std::move(output_folder)} {}
  friend struct handleROOTSvc;
  handleROOTSvc handle();

private:
  std::mutex mutable m_mutex;
  std::unique_ptr<TFile> m_file = nullptr;
  std::unique_ptr<TTree> m_tree = nullptr;
  std::string const m_output_dir;
  std::vector<std::string> mutable m_files;

  void file(std::string const& file = std::string {});
  TTree* ttree(std::string const& name);

  template<typename T>
  void branch(std::string const& name, T& container)
  {

    if (m_tree) {
      if (!m_tree->GetListOfBranches()->Contains(name.c_str())) {
        m_tree->Branch(name.c_str(), &container);
      }
      else {
        m_tree->SetBranchAddress(name.c_str(), &container);
      }
    }
  }
  void close_files();
  void enter_service();
  void exit_service();
};

struct handleROOTSvc {

  handleROOTSvc(ROOTService* RSvc) : m_rsvc(RSvc) { m_rsvc->enter_service(); };
  ~handleROOTSvc() { m_rsvc->exit_service(); };

  void file(std::string const& file = std::string {}) { return m_rsvc->file(file); };
  TTree* ttree(std::string const& name) { return m_rsvc->ttree(name); };

  template<typename T>
  void branch(std::string const& name, T& container)
  {
    m_rsvc->branch<T>(name, container);
  }

private:
  ROOTService* m_rsvc;
};
#endif