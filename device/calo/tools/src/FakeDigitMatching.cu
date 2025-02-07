/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "FakeDigitMatching.cuh"

INSTANTIATE_ALGORITHM(fake_digit_matching::fake_digit_matching_t)

void fake_digit_matching::fake_digit_matching_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_ecal_digits_isMatched_t>(arguments, first<host_ecal_number_of_digits_t>(arguments));
}

void fake_digit_matching::fake_digit_matching_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_ecal_digits_isMatched_t>(arguments, 0, context);
}
