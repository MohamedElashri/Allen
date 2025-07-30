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

#include "UTEventModel.cuh"
#include "UTDefinitions.cuh"
#include "AlgorithmTypes.cuh"

namespace ut_find_permutation {
  struct Parameters {
    HOST_INPUT(host_accumulated_number_of_ut_clusters_t, unsigned) host_accumulated_number_of_ut_clusters;
    DEVICE_INPUT(dev_ut_sort_keys_t, uint64_t) dev_ut_sort_keys;
    DEVICE_INPUT(dev_ut_cluster_offsets_t, unsigned) dev_ut_cluster_offsets;
    DEVICE_OUTPUT(dev_ut_permutations_t, unsigned) dev_ut_permutations;
  };

  struct ut_find_permutation_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {32, 1, 1}, "block dimensions"};
  };
} // namespace ut_find_permutation
