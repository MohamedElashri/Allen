#include "VertexFitter.cuh"
#include "ParKalmanMath.cuh"
#include "ParKalmanDefinitions.cuh"

namespace VertexFit {

  //----------------------------------------------------------------------
  // Point of closest approach. Reimplementation from TrackVertexUtils.
  __device__ bool poca(
    const ParKalmanFilter::FittedTrack& trackA,
    const ParKalmanFilter::FittedTrack& trackB,
    float& x,
    float& y,
    float& z)
  {
    float zA = trackA.z;
    float xA = trackA.state[0];
    float yA = trackA.state[1];
    float txA = trackA.state[2];
    float tyA = trackA.state[3];
    float zB = trackB.z;
    float xB = trackB.state[0];
    float yB = trackB.state[1];
    float txB = trackB.state[2];
    float tyB = trackB.state[3];
    float secondAA = txA * txA + tyA * tyA + 1.0f;
    float secondBB = txB * txB + tyB * tyB + 1.0f;
    float secondAB = -txA * txB - tyA * tyB - 1.0f;
    float det = secondAA * secondBB - secondAB * secondAB;
    if (fabsf(det) > 0) {
      float secondinvAA = secondBB / det;
      float secondinvBB = secondAA / det;
      float secondinvAB = -secondAB / det;
      float firstA = txA * (xA - xB) + tyA * (yA - yB) + (zA - zB);
      float firstB = -txB * (xA - xB) - tyB * (yA - yB) - (zA - zB);
      float muA = -(secondinvAA * firstA + secondinvAB * firstB);
      float muB = -(secondinvBB * firstB + secondinvAB * firstA);
      x = 0.5f * (xA + muA * txA + xB + muB * txB);
      y = 0.5f * (yA + muA * tyA + yB + muB * tyB);
      z = 0.5f * (zA + muA + zB + muB);
      return true;
    }
    return false;
  }
 __device__ float ip (
    float x0,
    float y0,
    float z0,
    float x,
    float y,
    float z,
    float tx,
    float ty)
  {
   float dz = z0 - z;
   float dx = x + dz * tx - x0;
   float dy = y + dz * ty - y0;
   return sqrtf((dx * dx + dy * dy) / (1.0f + tx * tx + ty * ty));
  }

  //----------------------------------------------------------------------
  // Add the contribution from one track to the vertex weight
  // matrix. NB this assumes (x, tx) and (y, ty) are uncorrelated.
  __device__ float addToDerivatives(
    const ParKalmanFilter::FittedTrack& track,
    const float& x,
    const float& y,
    const float& z,
    float& halfDChi2_0,
    float& halfDChi2_1,
    float& halfDChi2_2,
    float& halfD2Chi2_00,
    float& halfD2Chi2_11,
    float& halfD2Chi2_20,
    float& halfD2Chi2_21,
    float& halfD2Chi2_22)
  {
    float dz = z - track.z;
    float rX = track.state[0] + dz * track.state[2] - x;
    float rY = track.state[1] + dz * track.state[3] - y;
    float cov00 = track.cov(0, 0) + dz * dz * track.cov(2, 2) + 2.f * dz * track.cov(2, 0);
    float cov11 = track.cov(1, 1) + dz * dz * track.cov(3, 3) + 2.f * dz * track.cov(3, 1);
    float invcov00 = 1.f / cov00;
    float invcov11 = 1.f / cov11;
    halfDChi2_0 += invcov00 * rX;
    halfDChi2_1 += invcov11 * rY;
    halfDChi2_2 += -(invcov00 * rX * track.state[2] + invcov11 * rY * track.state[3]);
    halfD2Chi2_00 += invcov00;
    halfD2Chi2_11 += invcov11;
    halfD2Chi2_20 += -invcov00 * track.state[2];
    halfD2Chi2_21 += -invcov11 * track.state[3];
    halfD2Chi2_22 += invcov00 * track.state[0] * track.state[0] + invcov11 * track.state[1] * track.state[1];
    return invcov00 * rX * rX + invcov11 * rY * rY;
  }

  //----------------------------------------------------------------------
  // Correct the POCA to find the vertex position.
  __device__ float solve(
    float& x,
    float& y,
    float& z,
    float& cov00,
    float& cov11,
    float& cov20,
    float& cov21,
    float& cov22,
    const float& halfDChi2_0,
    const float& halfDChi2_1,
    const float& halfDChi2_2,
    const float& halfD2Chi2_00,
    const float& halfD2Chi2_11,
    const float& halfD2Chi2_20,
    const float& halfD2Chi2_21,
    const float& halfD2Chi2_22)
  {
    const float det = halfD2Chi2_00 * halfD2Chi2_11 * halfD2Chi2_22 - halfD2Chi2_00 * halfD2Chi2_21 * halfD2Chi2_21 -
                      halfD2Chi2_11 * halfD2Chi2_20 * halfD2Chi2_20;
    const float invdet = 1.f / det;
    cov00 = (halfD2Chi2_11 * halfD2Chi2_22 - halfD2Chi2_21 * halfD2Chi2_21) * invdet;
    cov11 = (halfD2Chi2_00 * halfD2Chi2_22 - halfD2Chi2_20 * halfD2Chi2_20) * invdet;
    cov20 = -halfD2Chi2_11 * halfD2Chi2_20 * invdet;
    cov21 = -halfD2Chi2_00 * halfD2Chi2_21 * invdet;
    cov22 = halfD2Chi2_00 * halfD2Chi2_11 * invdet;
    x += halfDChi2_0 * cov00 + halfDChi2_2 * cov20;
    y += halfDChi2_1 * cov11 + halfDChi2_2 * cov21;
    z += halfDChi2_0 * cov20 + halfDChi2_1 * cov21 + halfDChi2_2 * cov22;
    return -1 * (halfDChi2_0 * (halfDChi2_0 * cov00 + halfDChi2_2 * cov20) +
                 halfDChi2_1 * (halfDChi2_1 * cov11 + halfDChi2_2 * cov21) +
                 halfDChi2_2 * (halfDChi2_0 * cov20 + halfDChi2_1 * cov21 + halfDChi2_2 * cov22));
  }

  //----------------------------------------------------------------------
  // Perform a vertex fit assuming x and y are uncorrelated.
  __device__ bool
  doFit(const ParKalmanFilter::FittedTrack& trackA, const ParKalmanFilter::FittedTrack& trackB, TrackMVAVertex& vertex)
  {
    if (!poca(trackA, trackB, vertex.x, vertex.y, vertex.z)) {
      return false;
    };
    float vertexweight00 = 0.f;
    float vertexweight11 = 0.f;
    float vertexweight20 = 0.f;
    float vertexweight21 = 0.f;
    float vertexweight22 = 0.f;
    float halfDChi2_0 = 0.f;
    float halfDChi2_1 = 0.f;
    float halfDChi2_2 = 0.f;
    /// Add DOCA
    vertex.doca = 2.f * ip ( vertex.x,vertex.y, vertex.z, trackA.state[0], trackA.state[1],trackA.z, trackA.state[2], trackA.state[3]);
    vertex.chi2 = addToDerivatives(
      trackA,
      vertex.x,
      vertex.y,
      vertex.z,
      halfDChi2_0,
      halfDChi2_1,
      halfDChi2_2,
      vertexweight00,
      vertexweight11,
      vertexweight20,
      vertexweight21,
      vertexweight22);
    vertex.chi2 += addToDerivatives(
      trackB,
      vertex.x,
      vertex.y,
      vertex.z,
      halfDChi2_0,
      halfDChi2_1,
      halfDChi2_2,
      vertexweight00,
      vertexweight11,
      vertexweight20,
      vertexweight21,
      vertexweight22);
    vertex.chi2 += solve(
      vertex.x,
      vertex.y,
      vertex.z,
      vertex.cov00,
      vertex.cov11,
      vertex.cov20,
      vertex.cov21,
      vertex.cov22,
      halfDChi2_0,
      halfDChi2_1,
      halfDChi2_2,
      vertexweight00,
      vertexweight11,
      vertexweight20,
      vertexweight21,
      vertexweight22);
    return true;
  }

  __device__ void fill_extra_info(
    TrackMVAVertex& sv,
    const ParKalmanFilter::FittedTrack& trackA,
    const ParKalmanFilter::FittedTrack& trackB)
  {
    // SV momentum.
    sv.px = trackA.px() + trackB.px();
    sv.py = trackA.py() + trackB.py();
    sv.pz = trackA.pz() + trackB.pz();

    // For calculating mass.
    sv.p1 = trackA.p();
    sv.p2 = trackB.p();
    sv.cos = (trackA.px() * trackB.px() + trackA.py() * trackB.py() + trackA.pz() * trackB.pz()) / (sv.p1 * sv.p2);
      
   // Sum of track pT.
    sv.sumpt = trackA.pt() + trackB.pt();

    // Minimum pt of constituent tracks.
    sv.minpt = trackA.pt() < trackB.pt() ? trackA.pt() : trackB.pt();

    // Muon ID.
    sv.is_dimuon = trackA.is_muon && trackB.is_muon;
    sv.trk1_is_muon = trackA.is_muon;
    sv.trk2_is_muon = trackB.is_muon;

    // Minimum IP of constituent tracks.
    sv.minip = trackA.ip < trackB.ip ? trackA.ip : trackB.ip;
    
    // Dimuon mass.
    if (sv.is_dimuon) {
      const float mdimu2 =
        2.f * mMu * mMu + 2.f * (sqrtf((trackA.p() * trackA.p() + mMu * mMu) * (trackB.p() * trackB.p() + mMu * mMu)) -
                                 trackA.px() * trackB.px() - trackA.py() * trackB.py() - trackA.pz() * trackB.pz());
      sv.mdimu = sqrtf(mdimu2);

    }
    else {
      sv.mdimu = -1.f;
    }
  }

  __device__ void fill_extra_pv_info(
    TrackMVAVertex& sv,
    const PV::Vertex& pv,
    const ParKalmanFilter::FittedTrack& trackA,
    const ParKalmanFilter::FittedTrack& trackB,
    const float max_assoc_ipchi2)
  {
    // Number of tracks with ip chi2 < 16.
    sv.ntrks16 = (trackA.ipChi2 < max_assoc_ipchi2) +
                    (trackB.ipChi2 < max_assoc_ipchi2);

    // Get PV-SV separation.
    const float dx = sv.x - pv.position.x;
    const float dy = sv.y - pv.position.y;
    const float dz = sv.z - pv.position.z;
    const float fd = sqrtf(dx * dx + dy * dy + dz * dz);

    // Get covariance and FD chi2.
    const float cov00 = sv.cov00 + pv.cov00;
    const float cov11 = sv.cov11 + pv.cov11;
    const float cov20 = sv.cov20 + pv.cov20;
    const float cov21 = sv.cov21 + pv.cov21;
    const float cov22 = sv.cov22 + pv.cov22;
    const float invdet = 1.f / (cov00 * cov11 * cov22 - cov00 * cov21 * cov21 - cov11 * cov20 * cov20);
    const float invcov00 = (cov11 * cov22 - cov21 * cov21) * invdet;
    const float invcov11 = (cov00 * cov22 - cov20 * cov20) * invdet;
    const float invcov20 = -cov11 * cov20 * invdet;
    const float invcov21 = cov00 * cov21 * invdet;
    const float invcov22 = cov00 * cov22 * invdet;
    sv.fdchi2 = invcov00 * dx * dx + invcov11 * dy * dy + invcov22 * dz * dz + 2.f * invcov20 * dx * dz +
                2.f * invcov21 * dy * dz;

    // PV-SV eta.
    sv.eta = atanhf(dz / fd);
    // SVz - PVz
    sv.dz = dz;

   if (sv.is_dimuon) {
     sv.vertex_ip = ip(pv.position.x, pv.position.y, pv.position.z, sv.x, sv.y, sv.z, sv.px/sv.pz, sv.py/sv.pz); 
     const float txA = trackA.state[2];
     const float tyA = trackA.state[3];
   
     const float txB = trackB.state[2];
     const float tyB = trackB.state[3];
     
     const float vx = tyA - tyB;
     const float vy = -txA + txB;
     const float vz = txA*tyB - txB*tyA;
     sv.vertex_clone_sin2 = (vx*vx + vy*vy + vz*vz) / ( (txA*txA + tyA*tyA + 1.f) * (txB*txB + tyB*tyB + 1.f)); 

   }
   else {
     sv.vertex_ip = -1.f;
     sv.vertex_clone_sin2 = -1.f;
  }

    // Corrected mass.
    const float px = trackA.px() + trackB.px();
    const float py = trackA.py() + trackB.py();
    const float pz = trackA.pz() + trackB.pz();
    const float mvis2 =
      2.f * mPi * mPi + 2.f * (sqrtf((trackA.p() * trackA.p() + mPi * mPi) * (trackB.p() * trackB.p() + mPi * mPi)) -
                               trackA.px() * trackB.px() - trackA.py() * trackB.py() - trackA.pz() * trackB.pz());
    const float pperp2 = ((py * dz - dy * pz) * (py * dz - dy * pz) + (pz * dx - dz * px) * (pz * dx - dz * px) +
                          (px * dy - dx * py) * (px * dy - dx * py)) /
                         fd / fd;
    sv.mcor = sqrtf(mvis2 + pperp2) + sqrtf(pperp2);

    // Minimum IP chi2 of constituent tracks.
    sv.minipchi2 = trackA.ipChi2 < trackB.ipChi2 ? trackA.ipChi2 : trackB.ipChi2;
  }

} // namespace VertexFit

__global__ void VertexFit::fit_secondary_vertices(VertexFit::Parameters parameters)
{
  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;
  const uint sv_offset = parameters.dev_sv_offsets[event_number];
  const uint n_svs = parameters.dev_sv_offsets[event_number + 1] - sv_offset;
  const uint idx_offset = 10 * VertexFit::max_svs * event_number;
  const uint* event_svs_trk1_idx = parameters.dev_svs_trk1_idx + idx_offset;
  const uint* event_svs_trk2_idx = parameters.dev_svs_trk2_idx + idx_offset;
  
  // Consolidated SciFi tracks.
  SciFi::Consolidated::ConstTracks scifi_tracks {parameters.dev_atomics_scifi,
                                                 parameters.dev_scifi_track_hit_number,
                                                 parameters.dev_scifi_qop,
                                                 parameters.dev_scifi_states,
                                                 parameters.dev_scifi_track_ut_indices,
                                                 event_number,
                                                 number_of_events};
  const uint event_tracks_offset = scifi_tracks.tracks_offset(event_number);

  // Track-PV association table.
  Associate::Consolidated::ConstTable kalman_pv_ipchi2 {parameters.dev_kalman_pv_ipchi2,
                                                        scifi_tracks.total_number_of_tracks()};
  const auto pv_table = kalman_pv_ipchi2.event_table(scifi_tracks, event_number);

  // Kalman fitted tracks.
  const ParKalmanFilter::FittedTrack* event_tracks = parameters.dev_kf_tracks + event_tracks_offset;

  // Primary vertices.
  const uint n_pvs_event = *(parameters.dev_number_of_multi_fit_vertices + event_number);
  cuda::span<PV::Vertex const> vertices {parameters.dev_multi_fit_vertices + event_number * PV::max_number_vertices, n_pvs_event};

  // Secondary vertices.
  VertexFit::TrackMVAVertex* event_secondary_vertices = parameters.dev_consolidated_svs + sv_offset;

  // Loop over svs.
  for (uint i_sv = threadIdx.x; i_sv < n_svs; i_sv += blockDim.x) {
    event_secondary_vertices[i_sv].chi2 = -1;
    event_secondary_vertices[i_sv].minipchi2 = 0;
    auto i_track = event_svs_trk1_idx[i_sv];
    auto j_track = event_svs_trk2_idx[i_sv];
    const ParKalmanFilter::FittedTrack trackA = event_tracks[i_track];
    const ParKalmanFilter::FittedTrack trackB = event_tracks[j_track];

    // Do the fit.
    doFit(trackA, trackB, event_secondary_vertices[i_sv]);
    event_secondary_vertices[i_sv].trk1 = i_track;
    event_secondary_vertices[i_sv].trk2 = j_track;

    // Fill extra info.
    fill_extra_info(event_secondary_vertices[i_sv], trackA, trackB);
    if (n_pvs_event > 0) {
      int ipv = pv_table.value(i_track) < pv_table.value(j_track) ? pv_table.pv(i_track) : pv_table.pv(j_track);
      auto pv = vertices[ipv];
      fill_extra_pv_info(event_secondary_vertices[i_sv], pv, trackA, trackB, parameters.max_assoc_ipchi2);
    }
    else {
      // Set the minimum IP chi2 to 0 by default so this doesn't pass any displacement cuts.
      event_secondary_vertices[i_sv].minipchi2 = 0;
    }
  }  
}
