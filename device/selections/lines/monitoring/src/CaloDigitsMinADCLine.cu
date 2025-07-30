/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "CaloDigitsMinADCLine.cuh"

// Explicit instantiation
INSTANTIATE_LINE(calo_digits_minADC::calo_digits_minADC_t, calo_digits_minADC::Parameters)

__device__ bool calo_digits_minADC::calo_digits_minADC_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const CaloDigit> input)
{
  const auto ecal_digits = std::get<0>(input);
  return ecal_digits.is_valid() && ecal_digits.adc >= properties.minADC;
}
