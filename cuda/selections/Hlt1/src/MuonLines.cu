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
    if (! vertex.is_dimuon) return false;
    if ( vertex.minipchi2 < dispMinIPChi2) return false;

    bool decision = vertex.chi2 > 0;
    decision &= vertex.chi2 < maxVertexChi2;
    decision &= vertex.eta > dispMinEta && vertex.eta < dispMaxEta;
    decision &= vertex.minpt > minDispTrackPt;
    return decision;
  }

  __device__ bool HighMassDiMuon(const VertexFit::TrackMVAVertex& vertex)
  {
    if (! vertex.is_dimuon) return false;
    if ( vertex.mdimu < minMass) return false;
    if (vertex.minpt < minHighMassTrackPt) return false;

    bool decision = vertex.chi2 > 0;
    decision &= vertex.chi2 < maxVertexChi2;
    return decision;
  }

  __device__ bool DiMuonSoft(const VertexFit::TrackMVAVertex& vertex)
  {
    if (! vertex.is_dimuon) return false; 
    if (vertex.minipchi2 <  DMSoftMinIPChi2) return false; 
    bool decision = vertex.chi2 > 0;
    decision &= ( vertex.mdimu < DMSoftM0 || vertex.mdimu > DMSoftM1); // KS pipi misid veto
    decision &= vertex.eta > 0; 

    decision &= (vertex.x*vertex.x + vertex.y*vertex.y) > DMSoftMinRho2; 
    decision &= ( vertex.z >  DMSoftMinZ ) &  ( vertex.z <  DMSoftMaxZ );
    decision &= vertex.doca < DMSoftMaxDOCA;
    decision &= vertex.dimu_ip/vertex.dz < DMSoftMaxIPDZ;
    decision &= vertex.dimu_clone_sin2 > DMSoftGhost;
    return decision;
  }

} // namespace MuonLines
