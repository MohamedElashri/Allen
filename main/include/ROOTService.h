/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <string>
#include <list>
#include <vector>
#include <unordered_map>

#include "InputTools.h"
#include <mutex>
#include <ROOTHeaders.h>

struct handleROOTSvc; // forward declarations
#ifndef WITH_ROOT
struct ROOTService {
  ROOTService(std::string) {}
};
#else

struct ROOTService {

public:
  ROOTService(std::string monitor_file);
  friend struct handleROOTSvc;
  handleROOTSvc handle(std::string const& name);

  ~ROOTService();

private:
  std::mutex mutable m_mutex;

  struct ROOTDir {
    TDirectory* directory = nullptr;
    std::unordered_map<std::string, std::unique_ptr<TTree>> trees;
  };

  std::unique_ptr<TFile> m_file;
  std::unordered_map<std::string, ROOTDir> m_directories;

  TDirectory* directory(std::string const& dir);
  TTree* tree(TDirectory* root_file, std::string const& name);

  void close_files();
  void enter_service();
  void exit_service();
};

struct handleROOTSvc {

  handleROOTSvc(ROOTService* RSvc, std::string const& name) : m_rsvc(RSvc), m_name {name} { m_rsvc->enter_service(); };
  ~handleROOTSvc()
  {
    m_rsvc->exit_service();
    m_directory->cd();
  };

  TDirectory* directory() { return m_rsvc->directory(m_name); }

  TTree* tree(std::string const& tree_name)
  {
    auto dir = m_rsvc->directory(m_name);
    if (dir != nullptr) {
      return m_rsvc->tree(dir, tree_name);
    }
    else {
      return nullptr;
    }
  };

  template<typename T>
  void branch(TTree* tree, std::string const& name, T& container)
  {
    if (tree == nullptr) return;

    if (!tree->GetListOfBranches()->Contains(name.c_str())) {
      tree->Branch(name.c_str(), &container);
    }
    else {
      tree->SetBranchAddress(name.c_str(), &container);
    }
  }

private:
  TDirectory* m_directory = gDirectory;
  ROOTService* m_rsvc = nullptr;
  std::string const m_name;
};
#endif
