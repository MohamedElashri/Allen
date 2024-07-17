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
#include "UTFindPermutation.cuh"
#include <cstdio>
#include <SegSort.h>

INSTANTIATE_ALGORITHM(ut_find_permutation::ut_find_permutation_t)

void ut_find_permutation::ut_find_permutation_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_ut_permutations_t>(arguments, first<host_accumulated_number_of_ut_clusters_t>(arguments));
}

void ut_find_permutation::ut_find_permutation_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  SegSort::segsort<uint64_t>(
    *this,
    arguments,
    context,
    (const uint64_t*) data<dev_ut_sort_keys_t>(arguments),
    data<dev_ut_cluster_offsets_t>(arguments),
    size<dev_ut_cluster_offsets_t>(arguments) - 1,
    data<dev_ut_permutations_t>(arguments));
}
