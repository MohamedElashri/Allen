/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <string>

#include <ROOTHeaders.h>
#include "ROOTService.h"

#ifdef USE_BOOST_FILESYSTEM
#include <boost/filesystem.hpp>
namespace {
  namespace fs = boost::filesystem;
}
#else
#include <filesystem>
namespace {
  namespace fs = std::filesystem;
}
#endif

namespace {
  using namespace std::string_literals;
}

#ifdef WITH_ROOT

ROOTService::ROOTService(std::string filename)
{
  ROOT::EnableImplicitMT();

  if (!filename.empty()) {
    auto output_dir = fs::path {filename}.parent_path();
    if (!output_dir.empty()) {
      if (fs::exists(output_dir) && !fs::is_directory(output_dir)) {
        throw StrException {"Output directory "s + output_dir.string() + " exists, but is not a directory"};
      }
      else if (!fs::exists(output_dir)) {
        if (!fs::create_directory(output_dir)) {
          throw StrException {"Failed to create ROOT output directory "s + output_dir.string()};
        }
      }
    }
    m_file = std::make_unique<TFile>(filename.c_str(), "RECREATE", filename.c_str());
    if (!m_file->IsOpen() || m_file->IsZombie()) {
      throw StrException {"Failed to open ROOT file "s + filename};
    }
  }
}

ROOTService::~ROOTService()
{
  for (auto& [dir_name, dir] : m_directories) {
    for (auto& [tree_name, tree] : dir.trees) {
      dir.directory->WriteTObject(tree.get(), tree->GetName());
      tree.reset();
    }
  }
  if (m_file) m_file->Close();
}

TDirectory* ROOTService::directory(std::string const& dir_name)
{
  if (!m_file) return nullptr;

  auto it = m_directories.find(dir_name);
  bool success = false;
  if (it == m_directories.end()) {
    std::tie(it, success) = m_directories.emplace(dir_name, ROOTDir {m_file->mkdir(dir_name.c_str(), "", true), {}});
  }
  auto* dir = it->second.directory;
  dir->cd();
  return dir;
}

TTree* ROOTService::tree(TDirectory* dir, std::string const& name)
{
  if (dir == nullptr) return nullptr;

  std::string dir_name = dir->GetName();
  auto dir_it = m_directories.find(dir_name);
  if (dir_it == m_directories.end()) {
    throw StrException {"Could not find directory "s + dir_name + "; make sure you requested it."};
  }

  auto& trees = dir_it->second.trees;
  auto tree_it = trees.find(name);
  bool success = false;
  if (tree_it == trees.end()) {
    std::tie(tree_it, success) = trees.emplace(name, std::make_unique<TTree>(name.c_str(), name.c_str()));
  }
  return tree_it->second.get();
}

void ROOTService::enter_service() { m_mutex.lock(); }
void ROOTService::exit_service() { m_mutex.unlock(); }

handleROOTSvc ROOTService::handle(std::string const& name) { return handleROOTSvc {this, name}; }
#endif
