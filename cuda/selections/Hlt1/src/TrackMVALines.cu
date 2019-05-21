#include "TrackMVALines.cuh"

namespace TrackMVALines {

  __device__ void OneTrackMVA(const ParKalmanFilter::FittedTrack& track, bool& decision)
  {
    float ptShift = track.pt() - alpha;
    decision =  track.chi2/track.ndof < maxChi2Ndof;// &&
    decision &= ((ptShift > maxPt && track.ipChi2 > minIPChi2) ||
               (ptShift > minPt && ptShift < maxPt &&
                std::log(track.ipChi2) > param1 / (ptShift/1000. - param2) / (ptShift/1000. - param2)
                + param3 / maxPt * (maxPt - ptShift) + std::log(minIPChi2)));
    return;
  }

  __device__ void TwoTrackMVA(const VertexFit::Vertex& vertex, bool& decision)
  {
    if (vertex.chi2 < 0) {
      decision = false;
      return;
    }
    decision = vertex.pt() > minComboPt;
    decision &= vertex.chi2 < maxVertexChi2;
    decision &= vertex.mcor > minMCor;
    decision &= vertex.eta > minEta && vertex.eta < maxEta;
    decision &= vertex.ntrks16 <= maxNtrks16;
    decision &= vertex.fdchi2 > minFDChi2;
    return;
  }
  
}
