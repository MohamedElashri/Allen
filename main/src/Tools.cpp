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
#include "Tools.h"
#include "Common.h"

/**
 * @brief Obtains results statistics.
 */
std::map<std::string, float> calcResults(std::vector<float>& times)
{
  // sqrt ( E( (X - m)2) )
  std::map<std::string, float> results;
  float deviation = 0.0f, variance = 0.0f, mean = 0.0f, min = FLT_MAX, max = 0.0f;

  for (auto it = times.begin(); it != times.end(); it++) {
    const float seconds = (*it);
    mean += seconds;
    variance += seconds * seconds;

    if (seconds < min) min = seconds;
    if (seconds > max) max = seconds;
  }

  mean /= times.size();
  variance = (variance / times.size()) - (mean * mean);
  deviation = std::sqrt(variance);

  results["variance"] = variance;
  results["deviation"] = deviation;
  results["mean"] = mean;
  results["min"] = min;
  results["max"] = max;

  return results;
}
