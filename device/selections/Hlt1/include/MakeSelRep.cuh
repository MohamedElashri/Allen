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
#pragma once

#include "AlgorithmTypes.cuh"

namespace make_selrep {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_selrep_size_t, unsigned) host_selrep_size;
    DEVICE_INPUT(dev_selrep_offsets_t, unsigned) dev_selrep_offsets;
    DEVICE_INPUT(dev_rb_objtyp_offsets_t, unsigned) dev_rb_objtyp_offsets;
    DEVICE_INPUT(dev_rb_hits_offsets_t, unsigned) dev_rb_hits_offsets;
    DEVICE_INPUT(dev_rb_substr_offsets_t, unsigned) dev_rb_substr_offsets;
    DEVICE_INPUT(dev_rb_stdinfo_offsets_t, unsigned) dev_rb_stdinfo_offsets;
    DEVICE_INPUT(dev_rb_objtyp_t, unsigned) dev_rb_objtyp;
    DEVICE_INPUT(dev_rb_hits_t, unsigned) dev_rb_hits;
    DEVICE_INPUT(dev_rb_substr_t, unsigned) dev_rb_substr;
    DEVICE_INPUT(dev_rb_stdinfo_t, unsigned) dev_rb_stdinfo;
    DEVICE_OUTPUT(dev_sel_reports_t, unsigned) dev_sel_reports;
    HOST_OUTPUT(host_selrep_offsets_t, unsigned) host_selrep_offsets;
    HOST_OUTPUT(host_sel_reports_t, unsigned) host_sel_reports;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  __global__ void make_selrep_bank(Parameters, const unsigned number_of_events);

  struct make_selrep_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{32, 1, 1}}};
  };
} // namespace make_selrep