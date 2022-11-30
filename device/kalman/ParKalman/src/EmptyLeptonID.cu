/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "EmptyLeptonID.cuh"

INSTANTIATE_ALGORITHM(empty_lepton_id::empty_lepton_id_t)

void empty_lepton_id::empty_lepton_id_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  auto n_scifi_tracks = first<host_number_of_scifi_tracks_t>(arguments);
  set_size<dev_lepton_id_t>(arguments, n_scifi_tracks);
  set_size<dev_is_lepton_t>(arguments, n_scifi_tracks);
}

void empty_lepton_id::empty_lepton_id_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_lepton_id_t>(arguments, 0, context);
  Allen::memset_async<dev_is_lepton_t>(arguments, 0, context);
}
