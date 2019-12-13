#include "MuonLines.cuh"

namespace MuonLines {

  __device__ bool SingleMuon(const ParKalmanFilter::FittedTrack& track)
  {
    bool decision = track.chi2 / track.ndof < maxChi2Ndof;
    decision &= track.pt() > singleMinPt;
    decision &= track.is_muon;
    return decision;
  }

  __device__ bool DisplacedDiMuon(const VertexFit::TrackMVAVertex& vertex)
  {
    bool decision = vertex.chi2 > 0;
    decision &= vertex.chi2 < maxVertexChi2;
    decision &= vertex.eta > dispMinEta && vertex.eta < dispMaxEta;
    decision &= vertex.minipchi2 > dispMinIPChi2;
    decision &= vertex.minpt > minDispTrackPt;
    decision &= vertex.is_dimuon;
    return decision;
  }

  __device__ bool HighMassDiMuon(const VertexFit::TrackMVAVertex& vertex)
  {
    bool decision = vertex.chi2 > 0;
    decision &= vertex.chi2 < maxVertexChi2;
    decision &= vertex.mdimu > minMass;
    decision &= vertex.minpt > minHighMassTrackPt;
    decision &= vertex.is_dimuon;
    return decision;
  }

  __device__ bool DiMuonSoft(const VertexFit::TrackMVAVertex& vertex)
  {
    bool decision = vertex.chi2 > 0;
    decision &= vertex.minipchi2 >  DMSoftMinIPChi2 ;
    //decision &= vertex.chi2 < maxVertexChi2;
    decision &= ( vertex.mdimu < DMSoftM0 || vertex.mdimu > DMSoftM1); // KS pipi misid veto
    decision &= vertex.is_dimuon; 
    decision &= vertex.eta > 0; 

    decision &= (vertex.x*vertex.x + vertex.y*vertex.y) > DMSoftMinRho2; 
    decision &= ( vertex.z >  DMSoftMinZ ) &  ( vertex.z <  DMSoftMaxZ );

    return decision;
  }

} // namespace MuonLines
