#include "TrackMVALines.cuh"

namespace TrackMVALines {

  __device__ bool OneTrackMVA(const ParKalmanFilter::FittedTrack& track)
  {
    float ptShift = (track.pt() - alpha) / Gaudi::Units::GeV;
    bool decision = track.chi2 / track.ndof < maxChi2Ndof;
    decision &=
      ((ptShift > maxPt && track.ipChi2 > minIPChi2) ||
       (ptShift > minPt && ptShift < maxPt &&
        std::log(track.ipChi2) >
          param1 / (ptShift - param2) / (ptShift - param2) + param3 / maxPt * (maxPt - ptShift) + std::log(minIPChi2)));
    return decision;
  }

  __device__ bool TwoTrackMVA(const VertexFit::TrackMVAVertex& vertex)
  {
    if (vertex.chi2 < 0) {
      return false;
    }
    bool decision = vertex.pt() > minComboPt;
    decision &= vertex.chi2 < maxVertexChi2;
    decision &= vertex.mcor > minMCor;
    decision &= vertex.eta > minEta && vertex.eta < maxEta;
    decision &= vertex.ntrksassoc <= maxNTrksAssoc;
    decision &= vertex.fdchi2 > minFDChi2;
    decision &= vertex.minipchi2 > minTrackIPChi2;
    decision &= vertex.minpt > minTrackPt;
    return decision;
  }

} // namespace TrackMVALines
