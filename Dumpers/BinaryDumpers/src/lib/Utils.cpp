/*****************************************************************************\
* (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include <boost/filesystem.hpp>
#include <string>

#include <Dumpers/Utils.h>
#include <Dumpers/IUpdater.h>

namespace {
  namespace fs = boost::filesystem;
}

bool DumpUtils::createDirectory(fs::path directory)
{
  if (!fs::exists(directory)) {
    boost::system::error_code ec;
    bool success = fs::create_directories(directory, ec);
    success &= !ec;
    return success;
  }
  return true;
}
