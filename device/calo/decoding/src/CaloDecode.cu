/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include <MEPTools.h>
#include <CaloDecode.cuh>

void calo_decode::calo_decode_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_ecal_digits_t>(arguments, first<host_ecal_number_of_digits_t>(arguments));
  set_size<dev_hcal_digits_t>(arguments, first<host_hcal_number_of_digits_t>(arguments));
}

void calo_decode::calo_decode_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  const Allen::Context& context) const
{
  initialize<dev_ecal_digits_t>(arguments, SHRT_MAX, context);
  initialize<dev_hcal_digits_t>(arguments, SHRT_MAX, context);

  if (runtime_options.mep_layout) {
    global_function(calo_decode<true>)(
      dim3(size<dev_event_list_t>(arguments)), dim3(property<block_dim_x_t>().get()), context)(
      arguments, constants.dev_ecal_geometry, constants.dev_hcal_geometry);
  }
  else {
    global_function(calo_decode<false>)(
      dim3(size<dev_event_list_t>(arguments)), dim3(property<block_dim_x_t>().get()), context)(
      arguments, constants.dev_ecal_geometry, constants.dev_hcal_geometry);
  }

  if (runtime_options.do_check) {
    safe_assign_to_host_buffer<dev_ecal_digits_offsets_t>(host_buffers.host_ecal_digits_offsets, arguments, context);
    safe_assign_to_host_buffer<dev_hcal_digits_offsets_t>(host_buffers.host_hcal_digits_offsets, arguments, context);
    safe_assign_to_host_buffer<dev_ecal_digits_t>(host_buffers.host_ecal_digits, arguments, context);
    safe_assign_to_host_buffer<dev_hcal_digits_t>(host_buffers.host_hcal_digits, arguments, context);
  }
}
