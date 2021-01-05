/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "LayoutProvider.h"

void layout_provider::layout_provider_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<host_mep_layout_t>(arguments, 1);
  set_size<dev_mep_layout_t>(arguments, 1);
}

void layout_provider::layout_provider_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  unsigned int mep_layout = runtime_options.mep_layout;

  // Host output
  initialize<host_mep_layout_t>(arguments, mep_layout, context);

  // Device output
  initialize<dev_mep_layout_t>(arguments, mep_layout, context);
}
