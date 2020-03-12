Adding selection lines
======================

This will cover how to add trigger lines to Allen. A line can be one of the following types:

* OneTrackLine (taking as input Kalman fitted forward tracks)
* VeloLine (taking as input Velo tracks)
* TwoTrackLine (taking as input fitted secondary vertices)
* SpecialLine (taking for example the ODIN bank as input)

Choose which type of line you wish to create.


Writing the selection
---------------------

The actual selection code is placed in a header file in `lines/include`. The example of the
TrackMVALine is shown here:

```cclike=
#pragma once

#include "LineInfo.cuh"
#include "ParKalmanDefinitions.cuh"
#include "SystemOfUnits.h"

namespace TrackMVA {
  // One track parameters.
  constexpr float maxChi2Ndof =
    100.0f; // Large for now until we better understand the parameterized Kalman fit quality.
  constexpr float minPt = 2000.0f / Gaudi::Units::GeV;
  constexpr float maxPt = 26000.0f / Gaudi::Units::GeV;
  constexpr float minIPChi2 = 7.4f;
  constexpr float param1 = 1.0f;
  constexpr float param2 = 2.0f;
  constexpr float param3 = 1.248f;
  constexpr float alpha = 0.f;

  struct TrackMVA_t : public Hlt1::OneTrackLine {
    constexpr static auto name {"TrackMVA"};

    static __device__ bool function(const ParKalmanFilter::FittedTrack& track)
    {
      float ptShift = (track.pt() - alpha) / Gaudi::Units::GeV;
      const bool decision = track.chi2 / track.ndof < maxChi2Ndof &&
                            ((ptShift > maxPt && track.ipChi2 > minIPChi2) ||
                             (ptShift > minPt && ptShift < maxPt &&
                              logf(track.ipChi2) > param1 / (ptShift - param2) / (ptShift - param2) +
                                                     param3 / maxPt * (maxPt - ptShift) + logf(minIPChi2)));
      return decision;
    }
  };
} // namespace TrackMVA

```

The name of the namespace is given by the line name. This line inherits from `OneTrackLine`.
The actual selection is coded in the `function`.

Instructions for how to schedule a line to run in the sequence are given [here](../../configuration/readme.md).