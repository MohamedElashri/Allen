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
#include "GetTypeID.cuh"

INSTANTIATE_ALGORITHM(get_type_id::get_type_id_t)

__global__ void get_type_id_kernel(get_type_id::Parameters parameters)
{
  parameters.dev_type_id[0] = (*parameters.dev_imec)->type_id();
}

void get_type_id::get_type_id_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_type_id_t>(arguments, 1);
  set_size<host_type_id_t>(arguments, 1);
}

void get_type_id::get_type_id_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  global_function(get_type_id_kernel)(1, 1, context)(arguments);
  Allen::copy<host_type_id_t, dev_type_id_t>(arguments, context);
}
