/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#include "CompositeDumper.h"

CompositeDumper::CompositeDumper(CheckerInvoker const* invoker, std::string const& root_file, std::string const& name) :
  m_directory(name)
{
  // Setup the TTree
  m_file = invoker->root_file(root_file);
  auto dir = m_file->Get<TDirectory>(name.c_str());
  if (!dir) {
    dir = m_file->mkdir(name.c_str());
    dir = m_file->Get<TDirectory>(name.c_str());
  }
  dir->cd();

  m_tree = new TTree("CompositeDumper", "CompositeDumper");
}

void CompositeDumper::report(size_t) const
{
  auto dir = m_file->Get<TDirectory>(m_directory.c_str());
  dir->WriteTObject(m_tree);
}
