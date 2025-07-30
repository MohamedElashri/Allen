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

#include <ROOTHeaders.h>

#include "read_mdf.hpp"

namespace MDF {
  namespace ROOT {
    Allen::IO open(std::string const& filepath, int flags);
    bool close(TFile* f);
    ssize_t read(TFile* f, char* ptr, size_t size);
    ssize_t write(TFile* f, char const* ptr, size_t size);
  } // namespace ROOT
} // namespace MDF
