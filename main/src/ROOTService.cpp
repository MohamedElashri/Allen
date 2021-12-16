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

ROOTService::~ROOTService()
{
  for (auto& [file_name, f] : m_files) {
    for (auto& [tree_name, entry] : f.trees) {
      auto& [dir, tree] = entry;
      dir->WriteTObject(tree.get(), tree->GetName());
      tree.reset();
    }
    f.file->Close();
  }
}

TDirectory* ROOTService::file(std::string const& root_file, std::string const& dir_name)
{
  fs::create_directory(m_output_dir);
  auto full_name = m_output_dir + "/" + root_file;
  if (root_file.find('/') != std::string::npos) {
    throw StrException {"ROOT file name "s + root_file + " must not contain /"};
  }
  else if (dir_name.find('/') != std::string::npos) {
    throw StrException {"ROOT directory name "s + dir_name + " must not contain /"};
  }

  auto it = m_files.find(root_file);
  bool success = false;
  if (it == m_files.end()) {
    std::tie(it, success) = m_files.emplace(
      root_file, ROOTFile {std::make_unique<TFile>(full_name.c_str(), "RECREATE", root_file.c_str()), {}});
  }
  auto* dir = it->second.file->mkdir(dir_name.c_str(), "", true);
  dir->cd();
  return dir;
}

TTree* ROOTService::tree(TDirectory* dir, std::string const& name)
{
  if (dir == nullptr) return nullptr;

  std::string root_file = dir->GetFile()->GetTitle();
  auto file_it = m_files.find(root_file);
  if (file_it == m_files.end()) {
    throw StrException {"Could not find "s + root_file + "; make sure you requested it."};
  }

  auto& trees = file_it->second.trees;
  auto tree_it = trees.find(name);
  bool success = false;
  if (tree_it == trees.end()) {
    std::tie(tree_it, success) =
      trees.emplace(name, std::tuple {dir, std::make_unique<TTree>(name.c_str(), name.c_str())});
  }
  return std::get<1>(tree_it->second).get();
}

void ROOTService::enter_service() { m_mutex.lock(); }
void ROOTService::exit_service() { m_mutex.unlock(); }

handleROOTSvc ROOTService::handle(std::string const& name) { return handleROOTSvc {this, name}; }
#endif
