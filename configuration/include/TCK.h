/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include <string>
#include <iostream>
#include <HltServices/TCKUtils.h>

namespace Allen {

  namespace TCK {
    static constexpr unsigned config_version = 1u;

    std::map<std::string, std::string> project_dependencies();

    std::tuple<bool, std::string> check_projects(nlohmann::json metadata);

    void create_git_repository(std::string repo);
  } // namespace TCK

  std::tuple<std::string, LHCb::TCK::Info> tck_from_git(std::string repo, std::string tck);

  std::tuple<std::string, LHCb::TCK::Info> sequence_from_git(std::string repo, std::string tck);

} // namespace Allen
