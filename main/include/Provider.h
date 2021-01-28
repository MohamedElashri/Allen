/*****************************************************************************\
 * (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <memory>
#include <map>
#include <string>

std::unique_ptr<IInputProvider> make_provider(std::map<std::string, std::string> const& options);
