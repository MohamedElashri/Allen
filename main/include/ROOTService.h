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
};
#else

struct ROOTService {

public:
  ROOTService(std::string output_folder = "output") : m_output_dir {std::move(output_folder)} {}
  friend struct handleROOTSvc;
  handleROOTSvc handle(std::string const& name);

  ~ROOTService();

private:
  std::mutex mutable m_mutex;

  struct ROOTFile {
    std::unique_ptr<TFile> file;
    std::unordered_map<std::string, std::tuple<TDirectory*, std::unique_ptr<TTree>>> trees;
  };

  std::unordered_map<std::string, ROOTFile> m_files;
  std::string const m_output_dir;

  TDirectory* file(std::string const& file, std::string const& dir);
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

  TDirectory* file(std::string const& file_name) { return m_rsvc->file(file_name, m_name); };
  TTree* tree(TDirectory* root_file, std::string const& tree_name) { return m_rsvc->tree(root_file, tree_name); };

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
