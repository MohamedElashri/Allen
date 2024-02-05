/*****************************************************************************\
 * (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#ifdef USE_BOOST_FILESYSTEM
#include <boost/filesystem.hpp>
#else
#include <filesystem>
#endif

namespace {
#ifdef USE_BOOST_FILESYSTEM
  namespace fs = boost::filesystem;
#else
  namespace fs = std::filesystem;
#endif
} // namespace
