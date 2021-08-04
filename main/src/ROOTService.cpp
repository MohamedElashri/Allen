/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
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

#ifdef WITH_ROOT
void ROOTService::file(std::string const& root_file)
{
  fs::create_directory(m_output_dir);
  auto full_name = m_output_dir + "/" + root_file;
  if (std::find(m_files.begin(), m_files.end(), root_file) != m_files.end())
    m_file = std::make_unique<TFile>(full_name.c_str(), "UPDATE");
  else {

    m_files.push_back(root_file);
    m_file = std::make_unique<TFile>(full_name.c_str(), "RECREATE");
  }
}

TTree* ROOTService::ttree(std::string const& name)
{
  if (m_file) {
    if (!gDirectory->GetListOfKeys()->Contains(name.c_str())) {
      m_tree = std::make_unique<TTree>(name.c_str(), name.c_str());
    }
    else {
      m_tree = std::unique_ptr<TTree>(static_cast<TTree*>(gDirectory->Get(name.c_str())));
    }
    return m_tree.get();
  }
  else
    return nullptr;
}

void ROOTService::enter_service() { m_mutex.lock(); }
void ROOTService::exit_service()
{
  m_tree.reset();
  m_file.reset();
  m_mutex.unlock();
}

handleROOTSvc ROOTService::handle() { return handleROOTSvc {this}; }
#endif