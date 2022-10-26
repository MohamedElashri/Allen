/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "HostDummyMaker.h"

INSTANTIATE_ALGORITHM(host_dummy_maker::host_dummy_maker_t)

void host_dummy_maker::host_dummy_maker_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<host_unsigned_dummy_t>(arguments, 0);
  set_size<dev_unsigned_dummy_t>(arguments, 0);
  set_size<dev_lumi_dummy_t>(arguments, 0);
}

void host_dummy_maker::host_dummy_maker_t::operator()(
  const ArgumentReferences<Parameters>&,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context&) const
{
  if (property<verbosity_t>() >= logger::debug) {
    debug_cout << "Making dummy object" << std::endl;
  }
}
