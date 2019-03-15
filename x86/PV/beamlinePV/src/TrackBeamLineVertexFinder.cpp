/*****************************************************************************\
* (c) Copyright 2018 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the GNU General Public      *
* Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#include "TrackBeamLineVertexFinder.cuh"
#include "BeamlinePVConstants.cuh"
#include "SeedZWithIteratorPair.h"
#include "FloatOperations.cuh"

#ifdef WITH_ROOT
#include "TH1D.h"
#include "TFile.h"
#include "TTree.h"
#endif

/** @class TrackBeamLineVertexFinder TrackBeamLineVertexFinder.cpp
 *
 * PV finding strategy:
 * step 1: select tracks with velo info and cache some information useful for PV finding
 * step 2: fill a histogram with the z of the poca to the beamline
 * step 3: do a peak search in that histogram ('vertex seeds')
 * step 4: assign tracks to the closest seed ('partitioning')
 * step 5: fit the vertices with an adapative vertex fit
 *
 *  @author Wouter Hulsbergen (Nikhef, 2018)
 **/

//=============================================================================
// ::execute()
//=============================================================================

namespace {

  namespace GaussApprox {
    constexpr int N = 2;
    const float a = std::sqrt(double(2 * N + 3));
    float integral(float x)
    {
        const float a = std::sqrt(float(2 * order_polynomial + 3));
  const float xi = x / a;
  const float eta = 1.f - xi * xi;
  constexpr float p[] = {0.5f, 0.25f, 0.1875f, 0.15625f};
  // be careful: if you choose here one order more, you also need to choose 'a' differently (a(N)=sqrt(2N+3))
  return 0.5f + xi * (p[0] + eta * (p[1] + eta * p[2]));
    }
  } // namespace GaussApprox

  // This naively implements the adapative multi-vertex fit.
  void multifitAdaptive(
    const PVTrack* tracks,
    uint number_of_tracks,
    const float* zseeds,
    uint number_of_seeds,
    PV::Vertex* vertices,
    int* total_number_of_vertices)
  {
#ifdef WITH_ROOT
    TFile* weightfile = new TFile("weights.root", "RECREATE");
    TTree* weight_tree = new TTree("weights", "weights");
    int i_event, i_iteration, i_track;
    double b_weight;
    weight_tree->Branch("weight", &b_weight);
    weight_tree->Branch("event", &i_event);
    weight_tree->Branch("iteration", &i_iteration);
    weight_tree->Branch("nr_track", &i_track);
#endif

    PV::Vertex vertex;
    int number_of_vertices = 0;
    // loop over all seeds, on GPU do this in parallel
    for (int i_thisseed = 0; i_thisseed < number_of_seeds; i_thisseed++) {
      bool converged = false;
      float vtxcov[6];
      vtxcov[0] = 0.f;
      vtxcov[1] = 0.f;
      vtxcov[2] = 0.f;
      vtxcov[3] = 0.f;
      vtxcov[4] = 0.f;
      vtxcov[5] = 0.f;
      float2 vtxpos_xy {beamline.x, beamline.y};
      auto vtxpos_z = zseeds[i_thisseed];

      float chi2tot = 0;
      unsigned short nselectedtracks = 0;
      unsigned short iter = 0;
      debug_cout << "next vertex " << std::endl;
      for (; iter < maxFitIter && !converged; ++iter) {
        float halfD2Chi2DX2_00 = 0.f;
        float halfD2Chi2DX2_10 = 0.f;
        float halfD2Chi2DX2_11 = 0.f;
        float halfD2Chi2DX2_20 = 0.f;
        float halfD2Chi2DX2_21 = 0.f;
        float halfD2Chi2DX2_22 = 0.f;
        float3 halfDChi2DX {0.f, 0.f, 0.f};
        chi2tot = 0.f;
        nselectedtracks = 0;
        debug_cout << "next track" << std::endl;
        for (int i = 0; i < number_of_tracks; i++) {
          // compute the (chance in) z of the poca to the beam axis
          PVTrackInVertex trk = tracks[i];
          // extrapolate state to seed position
          const float dz = vtxpos_z - trk.z;

          // compute the chi2
          float2 res {0.f, 0.f};
          res = vtxpos_xy - (trk.x + trk.tx * dz);
          double chi2 = res.x * res.x * trk.W_00 + res.y * res.y * trk.W_11;
        //  debug_cout << "chi2 = " << chi2 << ", max = " << chi2max << std::endl;
          // compute the weight.
          trk.weight = 0;
          if (chi2 < maxChi2) {
            ++nselectedtracks;
            // Tukey's weight
            // double T = 1. + maxNumIter / (iter+1) * 0.05;
            double T = 1.f;
            trk.weight = exp(-chi2 / 2. / T);
            double denom = exp(-chi2Cut / 2. / T) + trk.weight;
            //try out different weight calucaltion
            double my_nom = 0;
            for (int i_otherseed = 0; i_otherseed < number_of_seeds; i_otherseed++) {
              float2 res_otherseed {0.f, 0.f};
              const auto dz = zseeds[i_otherseed] - trk.z;
              res_otherseed = res_otherseed - (trk.x + trk.tx * dz);
              // at the moment this term reuses W matrix at z of point of closest approach -> use seed positions instead?
              const auto chi2_otherseed =
                res_otherseed.x * res_otherseed.x * trk.W_00 + res_otherseed.y * res_otherseed.y * trk.W_11;
              denom += exp(-chi2_otherseed * 0.5f);
              if(i_thisseed == i_otherseed) my_nom = exp(-chi2_otherseed * 0.5f);
            }

            trk.weight = my_nom / denom;
#ifdef WITH_ROOT
            i_event = i_thisseed;
            b_weight = trk.weight;
            i_iteration = iter;
            i_track = i;
            weight_tree->Fill();
#endif

            if (trk.weight < maxWeight) continue;

            float3 HWr;
            HWr.x = res.x * trk.W_00;
            HWr.y = res.y * trk.W_11;
            HWr.z = -trk.tx.x * res.x * trk.W_00 - trk.tx.y * res.y * trk.W_11;

            halfDChi2DX = halfDChi2DX + HWr * trk.weight;

            halfD2Chi2DX2_00 += trk.weight * trk.HWH_00;
            halfD2Chi2DX2_11 += trk.weight * trk.HWH_11;
            halfD2Chi2DX2_20 += trk.weight * trk.HWH_20;
            halfD2Chi2DX2_21 += trk.weight * trk.HWH_21;
            halfD2Chi2DX2_22 += trk.weight * trk.HWH_22;

            chi2tot += trk.weight * chi2;
          }
        }
        if (nselectedtracks >= 2) {
          // compute the new vertex covariance using analytical inversion
          const auto a00 = halfD2Chi2DX2_00;
          const auto a11 = halfD2Chi2DX2_11;
          const auto a20 = halfD2Chi2DX2_20;
          const auto a21 = halfD2Chi2DX2_21;
          const auto a22 = halfD2Chi2DX2_22;

          const auto det = a00 * (a22 * a11 - a21 * a21) + a20 * (-a11 * a20);
          const auto inv_det = 1.f / det;

          // maybe we should catch the case when det = 0
          // if (det == 0) return false;

          vtxcov[0] = (a22 * a11 - a21 * a21) * inv_det;
          vtxcov[1] = -(-a20 * a21) * inv_det;
          vtxcov[2] = (a22 * a00 - a20 * a20) * inv_det;
          vtxcov[3] = (-a20 * a11) * inv_det;
          vtxcov[4] = -(a21 * a00) * inv_det;
          vtxcov[5] = (a11 * a00) * inv_det;

          const float2 delta_xy {
          -1.f * (vtxcov[0] * halfDChi2DX.x + vtxcov[1] * halfDChi2DX.y + vtxcov[3] * halfDChi2DX.z),
          -1.f * (vtxcov[1] * halfDChi2DX.x + vtxcov[2] * halfDChi2DX.y + vtxcov[4] * halfDChi2DX.z)};

          const auto delta_z = -1.f * (vtxcov[3] * halfDChi2DX.x + vtxcov[4] * halfDChi2DX.y + vtxcov[5] * halfDChi2DX.z);
          chi2tot += delta_xy.x * halfDChi2DX.x + delta_xy.y * halfDChi2DX.y + delta_z * halfDChi2DX.z;

          // update the position
          vtxpos_xy = vtxpos_xy + delta_xy;
          vtxpos_z = vtxpos_z + delta_z;
          converged = std::abs(delta_z) < maxDeltaZConverged;
        }
         else {
          float3 fakepos {-99999.f, -99999.f, -99999.f};
          vertex.setPosition(fakepos);
          break;
        }
      } // end iteration loop
      // std::cout << "Number of iterations: " << iter << " " << nselectedtracks << std::endl ;
      PV::Vertex vertex;
      vertex.chi2 = chi2tot;
      vertex.setPosition(vtxpos_xy, vtxpos_z);
      // vtxcov[5] = 100.;
      vertex.setCovMatrix(vtxcov);
      for (int i = 0; i < number_of_tracks; i++) {
        PVTrackInVertex trk = tracks[i];
        if (trk.weight > 0) vertex.n_tracks++;
      }
      const float2 beamline {0.f, 0.f};
      const auto beamlinedx = vertex.position.x - beamline.x;
      const auto beamlinedy = vertex.position.y - beamline.y;
      const auto beamlinerho2 = beamlinedx * beamlinedx + beamlinedy * beamlinedy;
      if (vertex.n_tracks >= minNumTracksPerVertex && beamlinerho2 < maxVertexRho2) {
        vertices[number_of_vertices] = vertex;
        number_of_vertices++;
      }
    }
    *total_number_of_vertices = number_of_vertices;
#ifdef WITH_ROOT
    weight_tree->Write();
    weightfile->Close();
#endif
  }

/*
  // This implements the adapative vertex fit with Tukey's weights.
  PV::Vertex fitAdaptive(
    const PVTrack* tracks,
    uint number_of_tracks,
    const float3& seedposition,
    unsigned short maxNumIter = 5,
    float chi2max = 9.f)
  {
    // make vector of TrackInVertex objects
    bool converged = false;

    float3 vtxpos = seedposition;

    PV::Vertex vertex;
    float vtxcov[6];
    vtxcov[0] = 0.f;
    vtxcov[1] = 0.f;
    vtxcov[2] = 0.f;
    vtxcov[3] = 0.f;
    vtxcov[4] = 0.f;
    vtxcov[5] = 0.f;

    const float maxDeltaZConverged {0.001f};
    float chi2tot = 0.f;
    unsigned short nselectedtracks = 0;
    unsigned short iter = 0;
    debug_cout << "next vertex " << std::endl;
    for (; iter < maxNumIter && !converged; ++iter) {
      float halfD2Chi2DX2_00 = 0.f;
      float halfD2Chi2DX2_10 = 0.f;
      float halfD2Chi2DX2_11 = 0.f;
      float halfD2Chi2DX2_20 = 0.f;
      float halfD2Chi2DX2_21 = 0.f;
      float halfD2Chi2DX2_22 = 0.f;
      float3 halfDChi2DX {0.f, 0.f, 0.f};
      chi2tot = 0.f;
      nselectedtracks = 0;
      float2 vtxposvec {vtxpos.x, vtxpos.y};
      debug_cout << "next track" << std::endl;
      for (int i = 0; i < number_of_tracks; i++) {
        // compute the chi2
        PVTrackInVertex trk = tracks[i];
        const float dz = vtxpos.z - trk.z;
        float2 res {0.f, 0.f};
        res = vtxposvec - (trk.x + trk.tx * dz);

        float chi2 = res.x * res.x * trk.W_00 + res.y * res.y * trk.W_11;
        debug_cout << "chi2 = " << chi2 << ", max = " << chi2max << std::endl;
        // compute the weight.
        trk.weight = 0;
        if (chi2 < chi2max) { // to branch or not, that is the question!
          ++nselectedtracks;
          // Tukey's weight
          trk.weight = 1.f - chi2 / chi2max;
          trk.weight = trk.weight * trk.weight;
          // += operator does not work for mixed FP types
          // halfD2Chi2DX2 += trk.weight * trk.HWH ;
          // halfDChi2DX   += trk.weight * trk.HW * res ;
          // if I use expressions, it crashes!
          // const Gaudi::SymMatrix3x3F thisHalfD2Chi2DX2 = weight * ROOT::Math::Similarity(H, trk.W ) ;
          float3 HWr;
          HWr.x = res.x * trk.W_00;
          HWr.y = res.y * trk.W_11;
          HWr.z = -trk.tx.x * res.x * trk.W_00 - trk.tx.y * res.y * trk.W_11;

          halfDChi2DX = halfDChi2DX + HWr * trk.weight;

          halfD2Chi2DX2_00 += trk.weight * trk.HWH_00;
          halfD2Chi2DX2_10 += 0.f;
          halfD2Chi2DX2_11 += trk.weight * trk.HWH_11;
          halfD2Chi2DX2_20 += trk.weight * trk.HWH_20;
          halfD2Chi2DX2_21 += trk.weight * trk.HWH_21;
          halfD2Chi2DX2_22 += trk.weight * trk.HWH_22;

          chi2tot += trk.weight * chi2;
        }
      }
      if (nselectedtracks >= 2) {
        // compute the new vertex covariance using analytical inversion
        float a00 = halfD2Chi2DX2_00;
        float a10 = halfD2Chi2DX2_10;
        float a11 = halfD2Chi2DX2_11;
        float a20 = halfD2Chi2DX2_20;
        float a21 = halfD2Chi2DX2_21;
        float a22 = halfD2Chi2DX2_22;

        float det = a00 * (a22 * a11 - a21 * a21) - a10 * (a22 * a10 - a21 * a20) + a20 * (a21 * a10 - a11 * a20);
        // if (det == 0) return false;

        vtxcov[0] = (a22 * a11 - a21 * a21) / det;
        vtxcov[1] = -(a22 * a10 - a20 * a21) / det;
        vtxcov[2] = (a22 * a00 - a20 * a20) / det;
        vtxcov[3] = (a21 * a10 - a20 * a11) / det;
        vtxcov[4] = -(a21 * a00 - a20 * a10) / det;
        vtxcov[5] = (a11 * a00 - a10 * a10) / det;

        // compute the delta w.r.t. the reference
        float3 delta {0.f, 0.f, 0.f};
        // CHECK this
        delta.x = -1.f * (vtxcov[0] * halfDChi2DX.x + vtxcov[1] * halfDChi2DX.y + vtxcov[3] * halfDChi2DX.z);
        delta.y = -1.f * (vtxcov[1] * halfDChi2DX.x + vtxcov[2] * halfDChi2DX.y + vtxcov[4] * halfDChi2DX.z);
        delta.z = -1.f * (vtxcov[3] * halfDChi2DX.x + vtxcov[4] * halfDChi2DX.y + vtxcov[5] * halfDChi2DX.z);

        // note: this is only correct if chi2 was chi2 of reference!
        chi2tot += delta.x * halfDChi2DX.x + delta.y * halfDChi2DX.y + delta.z * halfDChi2DX.z;

        // update the position
        vtxpos = vtxpos + delta;
        converged = std::abs(delta.z) < maxDeltaZConverged;
      }
      else {
        break;
      }
    } // end iteration loop
    // std::cout << "Number of iterations: " << iter << " " << nselectedtracks << std::endl ;
    vertex.chi2 = chi2tot;
    vertex.setPosition(vtxpos);
    vertex.setCovMatrix(vtxcov);
    for (int i = 0; i < number_of_tracks; i++) {
      PVTrackInVertex trk = tracks[i];
      if (trk.weight > 0) vertex.n_tracks++;
    }
    return vertex;
  }*/

} // namespace

void findPVs2(
  char* kalmanvelo_states,
  int* velo_atomics,
  uint* velo_track_hit_number,
  PV::Vertex* reconstructed_pvs,
  int* number_of_pvs,
  const uint number_of_events)
{

#ifdef WITH_ROOT
  // Histograms only for checking and debugging
  TFile* f = new TFile("../output/PVs.root", "RECREATE");
  // TTree *t_velo_states = new TTree("velo_states", "velo_states");
  TTree* t_velo_states = new TTree("velo_states", "velo_states");
  double cov_x, cov_y, cov_z;
  float tx, ty, x, y, z;
  t_velo_states->Branch("cov_x", &cov_x);
  t_velo_states->Branch("cov_y", &cov_y);
  t_velo_states->Branch("cov_z", &cov_z);
  t_velo_states->Branch("x", &x);
  t_velo_states->Branch("y", &y);
  t_velo_states->Branch("z", &z);
  t_velo_states->Branch("tx", &tx);
  t_velo_states->Branch("ty", &ty);
  TH1F* h_z0[number_of_events];
  TH1F* h_vx[number_of_events];
  TH1F* h_vy[number_of_events];
  TH1F* h_vz[number_of_events];
  for (int i = 0; i < number_of_events; ++i) {
    std::string name = "z0_" + std::to_string(i);
    h_z0[i] = new TH1F(name.c_str(), "", Nbins, 0, Nbins - 1);
    name = "vx_" + std::to_string(i);
    h_vx[i] = new TH1F(name.c_str(), "", 100, -1, 1);
    name = "vy_" + std::to_string(i);
    h_vy[i] = new TH1F(name.c_str(), "", 100, -1, 1);
    name = "vz_" + std::to_string(i);
    h_vz[i] = new TH1F(name.c_str(), "", 100, -300, 300);
  }
  // t_z0->Branch("z0", &z0, "z0[number_of_events]/F");
#endif

  for (uint event_number = 0; event_number < number_of_events; event_number++) {
    debug_cout << "AT EVENT " << event_number << std::endl;
    int& n_pvs = number_of_pvs[event_number];
    n_pvs = 0;

    // get consolidated states
    const Velo::Consolidated::Tracks velo_tracks {
      (uint*) velo_atomics, velo_track_hit_number, event_number, number_of_events};
    const Velo::Consolidated::States velo_states =
      Velo::Consolidated::States(kalmanvelo_states, velo_tracks.total_number_of_tracks);
    const uint number_of_tracks_event = velo_tracks.number_of_tracks(event_number);
    const uint event_tracks_offset = velo_tracks.tracks_offset(event_number);

    // Step 1: select tracks with velo info, compute the poca to the
    // beamline. cache the covariance matrix at this position. I'd
    // rather us a combination of copy_if and transform, but don't know
    // how to do that efficiently.
    const auto Ntrk = number_of_tracks_event; // tracks.size() ;
    debug_cout << "# of input velo states: " << Ntrk << std::endl;
    PVTrack pvtracks[Ntrk];
    // only use tracks within a certain z-range


    {

      for (short unsigned int index = 0; index < Ntrk; ++index) {
        VeloState s = velo_states.get(event_tracks_offset + index);
      
      const auto tx = s.tx;
      const auto ty = s.ty;
      const float dz = (tx * (beamline.x - s.x) + ty * (beamline.y - s.y)) / (tx * tx + ty * ty);
      PVTrack pvtrack = PVTrack {s, dz};

          pvtracks[index] = pvtrack;


        
      }
    }

    //debug_cout << "Selected " << (float) (number_of_tracks_in_zrange) / Ntrk << " states for PV seeds " << std::endl;

    // Step 2: fill a histogram with the z position of the poca. Use the
    // projected vertex error on that position as the width of a
    // gauss. Divide the gauss properly over the bins. This is quite
    // slow: some simplification may help here.

    // we need to define what a bin is: integral between
    //   zmin + ibin*dz and zmin + (ibin+1)*dz
    // we'll have lot's of '0.5' in the code below. at some point we may
    // just want to shift the bins.

    // this can be changed into an std::accumulate

    // std::vector<float> zhisto(Nbins,0.0f) ;
    float zhisto[Nbins] = {0.f};
    {
      for (int i = 0; i < Ntrk; i++) {
        PVTrack trk = pvtracks[i];
#ifdef WITH_ROOT
        cov_x = trk.W_00;
        cov_y = trk.W_11;
        cov_z = 1.;
        x = trk.x.x;
        y = trk.x.y;
        z = trk.z;
        tx = trk.tx.x;
        ty = trk.tx.y;
        t_velo_states->Fill();
#endif  
        if (zmin > trk.z || trk.z > zmax) continue;
        // bin in which z0 is, in floating point
        const float zbin = (trk.z - zmin) / dz;

        // to compute the size of the window, we use the track
        // errors. eventually we can just parametrize this as function of
        // track slope.
        const float zweight = trk.tx.x * trk.tx.x * trk.W_00 + trk.tx.y * trk.tx.y * trk.W_11;
        const float zerr = 1 / std::sqrt(zweight);
        // get rid of useless tracks. must be a bit carefull with this.
        if (zerr < maxTrackZ0Err) { // m_nsigma < 10*m_dz ) {
          const float a = std::sqrt(float(2 * order_polynomial + 3));
          const float halfwindow = a * zerr / dz;
          // this looks a bit funny, but we need the first and last bin of the histogram to remain empty.
          const int minbin = std::max(int(zbin - halfwindow), 1);
          const int maxbin = std::min(int(zbin + halfwindow), Nbins - 2);
          // we can get rid of this if statement if we make a selection of seeds earlier
          if (maxbin >= minbin) {
            float integral = 0.f;
            for (auto i = minbin; i < maxbin; ++i) {
              const float relz = (zmin + (i + 1) * dz - trk.z) / zerr;
              const float thisintegral = GaussApprox::integral(relz);
              zhisto[i] += thisintegral - integral;
              integral = thisintegral;
            }
            // deal with the last bin
            zhisto[maxbin] += 1.f - integral;
          }
        }
      }
    }
#ifdef WITH_ROOT
    for (int i = 0; i < Nbins; ++i) {
      h_z0[event_number]->SetBinContent(i, zhisto[i]);
    }
#endif

    // Step 3: perform a peak search in the histogram. This used to be
    // very simple but the logic needed to find 'significant dips' made
    // it a bit more complicated. In the end it doesn't matter so much
    // because it takes relatively little time.

    // FIXME: the logic is a bit too complicated here. need to see if we
    // simplify something without loosing efficiency.
    // std::vector<Cluster> clusters ;
    //&&( zhisto[i] > zhisto[i-2] || zhisto[i] > zhisto[i+2])
    Cluster clusters[PV::max_number_of_clusters];
    uint number_of_clusters = 0;
    /*
        //try to find a simpler peak finding, the numbers here could be optimized
        for(uint i = 2; i < Nbins-2; i++) {
          if(zhisto[i] > zhisto[i -1] && zhisto[i] > zhisto[i+1] && (zhisto[i] + zhisto[i-1] + zhisto[i+1]+ zhisto[i-2]
       + zhisto[i+2] > 2.5 ) && zhisto[i] > 1.5 ) { clusters[number_of_clusters] = Cluster(i-1, i,i+1); std::cout <<
       "cluster " << i *m_dz + m_zmin << " " << zhisto[i-1] << " " << zhisto[i] << " " << zhisto[i+1] << std::endl;
            number_of_clusters++;
          }
        }
    */
    {
      // step A: make 'ProtoClusters'
      // Step B: for each such ProtoClusters
      //    - find the significant extrema (an odd number, start with a minimum. you can always achieve this by adding a
      //    zero bin at the beginning)
      //      an extremum is a bin-index, plus the integral till that point, plus the content of the bin
      //    - find the highest extremum and
      //       - try and partition at the lowest minimum besides it
      //       - if that doesn't work, try the other extremum
      //       - if that doesn't work, accept as cluster

      // Step A: make 'proto-clusters': these are subsequent bins with non-zero content and an integral above the
      // threshold.

      using BinIndex = unsigned short;
      BinIndex clusteredges[PV::max_number_clusteredges];
      uint number_of_clusteredges = 0;
      {
        const float threshold = dz / (10.f * maxTrackZ0Err); // need something sensible that depends on binsize
        bool prevempty = true;
        float integral = zhisto[0];
        for (BinIndex i = 1; i < Nbins; ++i) {
          integral += zhisto[i];
          bool empty = zhisto[i] < threshold;
          if (empty != prevempty) {
            if (prevempty || integral > minTracksInSeed) {
              clusteredges[number_of_clusteredges] = i;
              number_of_clusteredges++;
            }
            else
              number_of_clusteredges--;
            prevempty = empty;
            integral = 0;
          }
        }
      }
      debug_cout << "Found " << number_of_clusteredges / 2 << " proto clusters" << std::endl;

      // Step B: turn these into clusters. There can be more than one cluster per proto-cluster.
      const size_t Nproto = number_of_clusteredges / 2;
      for (unsigned short i = 0; i < Nproto; ++i) {
        const BinIndex ibegin = clusteredges[i * 2];
        const BinIndex iend = clusteredges[i * 2 + 1];
        // std::cout << "Trying cluster: " << ibegin << " " << iend << std::endl ;

        // find the extrema
        const float mindip = minDipDensity * dz; // need to invent something
        const float minpeak = minDensity * dz;

        // std::vector<Extremum> extrema ;
        Extremum extrema[PV::max_number_vertices];
        uint number_of_extrema = 0;
        {
          bool rising = true;
          float integral = zhisto[ibegin];
          extrema[number_of_extrema] = Extremum(ibegin, zhisto[ibegin], integral);
          number_of_extrema++;
          for (unsigned short i = ibegin; i < iend; ++i) {
            const auto value = zhisto[i];
            bool stillrising = zhisto[i + 1] > value;
            if (rising && !stillrising && value >= minpeak) {
              const auto n = number_of_extrema;
              if (n >= 2) {
                // check that the previous mimimum was significant. we
                // can still simplify this logic a bit.
                const auto dv1 = extrema[n - 2].value - extrema[n - 1].value;
                // const auto di1 = extrema[n-1].index - extrema[n-2].index ;
                const auto dv2 = value - extrema[n - 1].value;
                if (dv1 > mindip && dv2 > mindip) {
                  extrema[number_of_extrema] = Extremum(i, value, integral + 0.5f * value);
                  number_of_extrema++;
                }
                else if (dv1 > dv2) {
                  number_of_extrema--;
                  if (number_of_extrema < 0) number_of_extrema = 0;
                }
                else {
                  number_of_extrema--;
                  number_of_extrema--;
                  if (number_of_extrema < 0) number_of_extrema = 0;
                  extrema[number_of_extrema] = Extremum(i, value, integral + 0.5f * value);
                  number_of_extrema++;
                }
              }
              else {
                extrema[number_of_extrema] = Extremum(i, value, integral + 0.5f * value);
                number_of_extrema++;
              }
            }
            else if (rising != stillrising) {
              extrema[number_of_extrema] = Extremum(i, value, integral + 0.5f * value);
              number_of_extrema++;
            }
            rising = stillrising;
            integral += value;
          }
          assert(rising == false);
          extrema[number_of_extrema] = Extremum(iend, zhisto[iend], integral);
          number_of_extrema++;
        }

        // now partition on  extrema
        const auto N = number_of_extrema;
        // std::vector<Cluster> subclusters ;
        Cluster subclusters[PV::max_number_subclusters];
        uint number_of_subclusters = 0;
        if (N > 3) {
          for (unsigned int i = 1; i < N / 2 + 1; ++i) {
            if (extrema[2 * i].integral - extrema[2 * i - 2].integral > minTracksInSeed) {
              subclusters[number_of_subclusters] =
                Cluster(extrema[2 * i - 2].index, extrema[2 * i].index, extrema[2 * i - 1].index);
              number_of_subclusters++;
            }
          }
        }
        if (number_of_subclusters == 0) {
          // FIXME: still need to get the largest maximum!
          if (extrema[1].value >= minpeak) {
            clusters[number_of_clusters] =
              Cluster(extrema[0].index, extrema[number_of_extrema - 1].index, extrema[1].index);
            number_of_clusters++;
          }
        }
        else {
          // adjust the limit of the first and last to extend to the entire protocluster
          subclusters[0].izfirst = ibegin;
          subclusters[number_of_subclusters].izlast = iend;
          for (int i = 0; i < number_of_subclusters; i++) {
            Cluster subcluster = subclusters[i];
            clusters[number_of_clusters] = subcluster;
            number_of_clusters++;
          }
        }
      }
    }

    debug_cout << "Found " << number_of_clusters << " clusters" << std::endl;

    // Step 4: partition the set of tracks by vertex seed: just
    // choose the closest one. The easiest is to loop over tracks and
    // assign to closest vertex by looping over all vertices. However,
    // that becomes very slow as time is proportional to both tracks and
    // vertices. A better method is to rely on the fact that vertices
    // are sorted in z, and then use std::partition, to partition the
    // track list on the midpoint between two vertices. The logic is
    // slightly complicated to deal with partitions that have too few
    // tracks. I checked it by comparing to the 'slow' method.

    // I found that this funny weighted 'maximum' is better than most other inexpensive solutions.
    auto zClusterMean = [&zhisto](auto izmax) -> float {
      const float* b = zhisto + izmax;
      float d1 = *b - *(b - 1);
      float d2 = *b - *(b + 1);
      float idz = d1 + d2 > 0 ? 0.5f * (d1 - d2) / (d1 + d2) : 0.0f;
      return zmin + dz * (izmax + idz + 0.5f);
    };



   

    float zpeaks[PV::max_number_vertices];
    int number_of_peaks = 0;
    for (int i = 0; i < number_of_clusters; ++i) {
      zpeaks[number_of_peaks] = zClusterMean(clusters[i].izmax);
      number_of_peaks++;
    }

    // Step 5: perform the adaptive vertex fit for each seed.
    // PV::Vertex preselected_vertices[PV::max_number_vertices];
    int number_preselected_vertices = 0;

    PV::Vertex preselected_vertices[PV::max_number_vertices];

    multifitAdaptive(
      pvtracks,
      Ntrk,
      zpeaks,
      number_of_peaks,
      preselected_vertices,
      &number_preselected_vertices);

  //  number_preselected_vertices = number_of_seedsZWIP;
    /*
       for ( int i = 0; i < number_of_seedsZWIP; i++ ) {
         SeedZWithIteratorPair seed = seedsZWithIteratorPair[i];
         PV::Vertex vertex = fitAdaptive(seed.get_array(),seed.get_size(),
                                         float3{beamline.x,beamline.y,seed.z},
                                         m_maxFitIter,m_maxDeltaChi2) ;
         preselected_vertices[number_preselected_vertices] = vertex;
         number_preselected_vertices++;
       }

       debug_cout << "Vertices remaining after fitter: " << number_preselected_vertices << std::endl;

       for ( int i = 0; i < number_preselected_vertices; i++ ) {
         PV::Vertex vertex = preselected_vertices[i];
         debug_cout << "   vertex has " << vertex.n_tracks << " tracks, x = " << vertex.position.x << ", y = " <<
       vertex.position.y << ", z = " << vertex.position.z << std::endl;
       }
   */
    // Steps that we could still take:
    // * remove vertices with too little tracks
    // * assign unused tracks to other vertices
    // * merge vertices that are close

    // create the output container
    for (int i = 0; i < number_preselected_vertices; i++) {
      PV::Vertex vertex = preselected_vertices[i];


#ifdef WITH_ROOT
      h_vx[event_number]->Fill(vertex.position.x);
      h_vy[event_number]->Fill(vertex.position.y);
      h_vz[event_number]->Fill(vertex.position.z);
#endif

      if (vertex.cov22 < 0.000000001f) continue;

      bool unique = true;
      for(int j_pv = 0; j_pv < n_pvs; j_pv++) {
        PV::Vertex vertex2 = reconstructed_pvs[j_pv];
        float z1 = vertex.position.z;
        float z2 = vertex2.position.z;
        float variance1 = vertex.cov22;
        float variance2 = vertex2.cov22;
        float chi2_dist = (z1-z2)*(z1-z2);
        chi2_dist = chi2_dist/(variance1+variance2);
        if(chi2_dist < minChi2Dist) unique = false;

      }
      if(unique) {
        reconstructed_pvs[PV::max_number_vertices * event_number + n_pvs] = vertex;
        n_pvs++;
      }
    }
  } // event loop

#ifdef WITH_ROOT
  f->Write();
  f->Close();
#endif
}


void pv_beamline_extrapolate(
  char* dev_velo_kalman_beamline_states,
  int* dev_atomics_storage,
  uint* dev_velo_track_hit_number,
  PVTrack* dev_pvtracks,
  const uint event_number,
  const uint number_of_events)
{

  const uint number_threads = 32;
  for(uint threadIdx = 0; threadIdx < number_threads; threadIdx++) {

    const Velo::Consolidated::Tracks velo_tracks {
      (uint*) dev_atomics_storage, dev_velo_track_hit_number, event_number, number_of_events};
    const Velo::Consolidated::States velo_states =
      Velo::Consolidated::States(dev_velo_kalman_beamline_states, velo_tracks.total_number_of_tracks);
    const uint number_of_tracks_event = velo_tracks.number_of_tracks(event_number);
    const uint event_tracks_offset = velo_tracks.tracks_offset(event_number);

    for (int i = 0; i < number_of_tracks_event / number_threads + 1; i++) {
      int index = number_threads * i + threadIdx;
      if (index < number_of_tracks_event) {
        VeloState s = velo_states.get(event_tracks_offset + index);
        const auto tx = s.tx;
        const auto ty = s.ty;
        const float dz = (tx * (beamline.x - s.x) + ty * (beamline.y - s.y)) / (tx * tx + ty * ty);
        PVTrack pvtrack = PVTrack {s, dz};
        dev_pvtracks[event_tracks_offset + index] = pvtrack;
      }
    }
  }
}


float mygauss_integral(float x)
{
  const float a = std::sqrt(float(2 * order_polynomial + 3));
  const float xi = x / a;
  const float eta = 1.f - xi * xi;
  constexpr float p[] = {0.5f, 0.25f, 0.1875f, 0.15625f};
  // be careful: if you choose here one order more, you also need to choose 'a' differently (a(N)=sqrt(2N+3))
  return 0.5f + xi * (p[0] + eta * (p[1] + eta * p[2]));
}


void pv_beamline_histo(int* dev_atomics_storage, uint* dev_velo_track_hit_number, PVTrack* dev_pvtracks, float* dev_zhisto, const uint event_number, const uint number_of_events )
{

  const uint number_threads = 32;
  const Velo::Consolidated::Tracks velo_tracks {
    (uint*) dev_atomics_storage, dev_velo_track_hit_number, event_number, number_of_events};

  const uint number_of_tracks_event = velo_tracks.number_of_tracks(event_number);
  const uint event_tracks_offset = velo_tracks.tracks_offset(event_number);

  float* histo_base_pointer = dev_zhisto + Nbins * event_number;

  // find better wy to intialize histogram bins to zero

  for (int i = 0; i < Nbins; i++) {
    *(histo_base_pointer + i) = 0.f;
  }

  for(uint threadIdx = 0; threadIdx < number_threads; threadIdx++) {

    for (int i = 0; i < number_of_tracks_event / number_threads + 1; i++) {
      int index = number_threads * i + threadIdx;
      if (index < number_of_tracks_event) {

        PVTrack trk = dev_pvtracks[event_tracks_offset + index];
        // apply the z cut here
        if (zmin < trk.z && trk.z < zmax) {

          // bin in which z0 is, in floating point
          const float zbin = (trk.z - zmin) / dz;

          // to compute the size of the window, we use the track
          // errors. eventually we can just parametrize this as function of
          // track slope.
          const float zweight = trk.tx.x * trk.tx.x * trk.W_00 + trk.tx.y * trk.tx.y * trk.W_11;
          const float zerr = 1.f / std::sqrt(zweight);
          // get rid of useless tracks. must be a bit carefull with this.
          if (zerr < maxTrackZ0Err) { // m_nsigma < 10*m_dz ) {
            // find better place to define this
            const float a = std::sqrt(float(2 * order_polynomial + 3));
            const float halfwindow = a * zerr / dz;
            // this looks a bit funny, but we need the first and last bin of the histogram to remain empty.
            const int minbin = std::max(int(zbin - halfwindow), 1);
            const int maxbin = std::min(int(zbin + halfwindow), Nbins - 2);
            // we can get rid of this if statement if we make a selection of seeds earlier
            if (maxbin >= minbin) {
              float integral = 0;
              for (auto i = minbin; i < maxbin; ++i) {
                const float relz = (zmin + (i + 1) * dz - trk.z) / zerr;
                const float thisintegral = mygauss_integral(relz);
                *(histo_base_pointer + i) += thisintegral - integral;
                integral = thisintegral;
              }
              // deal with the last bin
              *(histo_base_pointer + maxbin) += 1.f - integral;
            }
          }
        }
      }
    }
  }
}

void pv_beamline_peak(float* dev_zhisto, float* dev_zpeaks, uint* dev_number_of_zpeaks, uint number_of_events, uint event_number)
{


  if (event_number < number_of_events) {
    float* zhisto = dev_zhisto + Nbins * event_number;
    float* zpeaks = dev_zpeaks + PV::max_number_vertices * event_number;
    uint number_of_peaks = 0;

    Cluster clusters[PV::max_number_of_clusters];
    uint number_of_clusters = 0;
    using BinIndex = unsigned short;
    BinIndex clusteredges[PV::max_number_clusteredges];
    uint number_of_clusteredges = 0;
    {
      const float inv_maxTrackZ0Err = 1.f / (10.f * maxTrackZ0Err);
      const float threshold = dz * inv_maxTrackZ0Err; // need something sensible that depends on binsize
      bool prevempty = true;
      float integral = zhisto[0];
      for (BinIndex i = 1; i < Nbins; ++i) {
        integral += zhisto[i];
        bool empty = zhisto[i] < threshold;
        if (empty != prevempty) {
          if (prevempty || integral > minTracksInSeed) {
            clusteredges[number_of_clusteredges] = i;
            number_of_clusteredges++;
          }
          else
            number_of_clusteredges--;
          prevempty = empty;
          integral = 0;
        }
      }

      // Step B: turn these into clusters. There can be more than one cluster per proto-cluster.
      const size_t Nproto = number_of_clusteredges / 2;
      for (unsigned short i = 0; i < Nproto; ++i) {
        const BinIndex ibegin = clusteredges[i * 2];
        const BinIndex iend = clusteredges[i * 2 + 1];
        // find the extrema
        const float mindip = minDipDensity * dz; // need to invent something
        const float minpeak = minDensity * dz;

        Extremum extrema[PV::max_number_vertices];
        int number_of_extrema = 0;
        {
          bool rising = true;
          float integral = zhisto[ibegin];
          extrema[number_of_extrema] = Extremum(ibegin, zhisto[ibegin], integral);
          number_of_extrema++;
          for (unsigned short i = ibegin; i < iend; ++i) {
            const auto value = zhisto[i];
            bool stillrising = zhisto[i + 1] > value;
            if (rising && !stillrising && value >= minpeak) {
              const auto n = number_of_extrema;
              if (n >= 2) {
                // check that the previous mimimum was significant. we
                // can still simplify this logic a bit.
                const auto dv1 = extrema[n - 2].value - extrema[n - 1].value;
                // const auto di1 = extrema[n-1].index - extrema[n-2].index ;
                const auto dv2 = value - extrema[n - 1].value;
                if (dv1 > mindip && dv2 > mindip) {
                  extrema[number_of_extrema] = Extremum(i, value, integral + 0.5f * value);
                  number_of_extrema++;
                }
                else if (dv1 > dv2) {
                  number_of_extrema--;
                  if (number_of_extrema < 0) number_of_extrema = 0;
                }
                else {
                  number_of_extrema--;
                  number_of_extrema--;
                  if (number_of_extrema < 0) number_of_extrema = 0;
                  extrema[number_of_extrema] = Extremum(i, value, integral + 0.5f * value);
                  number_of_extrema++;
                }
              }
              else {
                extrema[number_of_extrema] = Extremum(i, value, integral + 0.5f * value);
                number_of_extrema++;
              }
            }
            else if (rising != stillrising) {
              extrema[number_of_extrema] = Extremum(i, value, integral + 0.5f * value);
              number_of_extrema++;
            }
            rising = stillrising;
            integral += value;
          }
          assert(rising == false);
          extrema[number_of_extrema] = Extremum(iend, zhisto[iend], integral);
          number_of_extrema++;
        }
        // now partition on  extrema
        const auto N = number_of_extrema;
        Cluster subclusters[PV::max_number_subclusters];
        uint number_of_subclusters = 0;
        if (N > 3) {
          for (unsigned int i = 1; i < N / 2 + 1; ++i) {
            if (extrema[2 * i].integral - extrema[2 * i - 2].integral > minTracksInSeed) {
              subclusters[number_of_subclusters] =
                Cluster(extrema[2 * i - 2].index, extrema[2 * i].index, extrema[2 * i - 1].index);
              number_of_subclusters++;
            }
          }
        }
        if (number_of_subclusters == 0) {
          // FIXME: still need to get the largest maximum!
          if (extrema[1].value >= minpeak) {
            clusters[number_of_clusters] =
              Cluster(extrema[0].index, extrema[number_of_extrema - 1].index, extrema[1].index);
            number_of_clusters++;
          }
        }
        else {
          // adjust the limit of the first and last to extend to the entire protocluster
          subclusters[0].izfirst = ibegin;
          subclusters[number_of_subclusters].izlast = iend;
          for (int i = 0; i < number_of_subclusters; i++) {
            Cluster subcluster = subclusters[i];
            clusters[number_of_clusters] = subcluster;
            number_of_clusters++;
          }
        }
      }
    }

    auto zClusterMean = [&zhisto](auto izmax) -> float {
      const float* b = zhisto + izmax;
      float d1 = *b - *(b - 1);
      float d2 = *b - *(b + 1);
      float idz = d1 + d2 > 0 ? 0.5f * (d1 - d2) / (d1 + d2) : 0.0f;
      return zmin + dz * (izmax + idz + 0.5f);
    };

    for (int i = 0; i < number_of_clusters; ++i) {
      zpeaks[number_of_peaks] = zClusterMean(clusters[i].izmax);
      number_of_peaks++;
    }

    dev_number_of_zpeaks[event_number] = number_of_peaks;
  }
}

void beamline_multi_fitter(
  int* dev_atomics_storage,
  uint* dev_velo_track_hit_number,
  PVTrack* dev_pvtracks,
  float* dev_zpeaks,
  uint* dev_number_of_zpeaks,
  PV::Vertex* dev_multi_fit_vertices,
  uint* dev_number_of_multi_fit_vertices,
  const uint event_number,
  const uint number_of_events)
{

  const uint number_threads = 32;
  for(uint threadIdx = 0; threadIdx < number_threads; threadIdx++) {
    uint* number_of_multi_fit_vertices = dev_number_of_multi_fit_vertices + event_number;

    const Velo::Consolidated::Tracks velo_tracks {
      (uint*) dev_atomics_storage, dev_velo_track_hit_number, event_number, number_of_events};

    const uint number_of_tracks = velo_tracks.number_of_tracks(event_number);
    const uint event_tracks_offset = velo_tracks.tracks_offset(event_number);

    const float* zseeds = dev_zpeaks + event_number * PV::max_number_vertices;
    const uint number_of_seeds = dev_number_of_zpeaks[event_number];

    const PVTrack* tracks = dev_pvtracks + event_tracks_offset;

    PV::Vertex* vertices = dev_multi_fit_vertices + event_number * PV::max_number_vertices;

    PV::Vertex vertex;

    // make sure that we have one thread per seed
    for (uint i_thisseed = threadIdx; i_thisseed < number_of_seeds; i_thisseed += number_threads) {
      bool converged = false;
      float vtxcov[6] = {0.f, 0.f, 0.f, 0.f, 0.f, 0.f};
      // initial vertex posisiton, use x,y of the beamline and z of the seed
      float2 vtxpos_xy {beamline.x, beamline.y};
      auto vtxpos_z = zseeds[i_thisseed];
      auto chi2tot = 0.f;
      unsigned short nselectedtracks = 0;
      unsigned short iter = 0;
      // debug_cout << "next vertex " << std::endl;
      for (; iter < maxFitIter && !converged; ++iter) {
        auto halfD2Chi2DX2_00 = 0.f;
        auto halfD2Chi2DX2_11 = 0.f;
        auto halfD2Chi2DX2_20 = 0.f;
        auto halfD2Chi2DX2_21 = 0.f;
        auto halfD2Chi2DX2_22 = 0.f;
        float3 halfDChi2DX {0.f, 0.f, 0.f};
        chi2tot = 0.f;
        nselectedtracks = 0;
        // debug_cout << "next track" << std::endl;
        for (int i = 0; i < number_of_tracks; i++) {
          // compute the chi2
          PVTrackInVertex trk = tracks[i];
          // skip tracks lying outside histogram range
        //  if (zmin > trk.z || trk.z > zmax) continue;
          const auto dz = vtxpos_z - trk.z;
          float2 res {0.f, 0.f};
          res = vtxpos_xy - (trk.x + trk.tx * dz);
          const auto chi2 = res.x * res.x * trk.W_00 + res.y * res.y * trk.W_11;
          // debug_cout << "chi2 = " << chi2 << ", max = " << chi2max << std::endl;
          // compute the weight.
          trk.weight = 0.f;
          if (chi2 < maxChi2) { // to branch or not, that is the question!
                                     // if (true) {
            ++nselectedtracks;
            // for more information on the weighted fitting, see e.g.
            // Adaptive Multi-vertex fitting, R. Frühwirth, W. Waltenberger
            // https://cds.cern.ch/record/803519/files/p280.pdf

            trk.weight = exp(-chi2 * 0.5f);
            auto denom = exp(-chi2Cut * 0.5f) + trk.weight;
            auto my_nom = 0.f;
            for (int i_otherseed = 0; i_otherseed < number_of_seeds; i_otherseed++) {
             // if(i_thisseed == i_otherseed) continue;
              float2 res_otherseed {0.f, 0.f};
              const auto dz = zseeds[i_otherseed] - trk.z;

              // we calculate the residual w.r.t to the other seed positions. Since we don't update them during the fit we
              // use the beamline (x,y)
              res_otherseed = res_otherseed - (trk.x + trk.tx * dz);
              // at the moment this term reuses W matrix at z of point of closest approach -> use seed positions instead?
              const auto chi2_otherseed =
                res_otherseed.x * res_otherseed.x * trk.W_00 + res_otherseed.y * res_otherseed.y * trk.W_11;
              denom += exp(-chi2_otherseed * 0.5f);
              if(i_thisseed == i_otherseed) my_nom = exp(-chi2_otherseed * 0.5f);
            }
            trk.weight = my_nom / denom;

            // unfortunately branchy, but reduces fake rate
            if (trk.weight < maxWeight) continue;
            float3 HWr;
            HWr.x = res.x * trk.W_00;
            HWr.y = res.y * trk.W_11;
            HWr.z = -trk.tx.x * res.x * trk.W_00 - trk.tx.y * res.y * trk.W_11;

            halfDChi2DX = halfDChi2DX + HWr * trk.weight;

            halfD2Chi2DX2_00 += trk.weight * trk.HWH_00;
            halfD2Chi2DX2_11 += trk.weight * trk.HWH_11;
            halfD2Chi2DX2_20 += trk.weight * trk.HWH_20;
            halfD2Chi2DX2_21 += trk.weight * trk.HWH_21;
            halfD2Chi2DX2_22 += trk.weight * trk.HWH_22;

            chi2tot += trk.weight * chi2;

          }
        }

        if (nselectedtracks >= 2) {
          // compute the new vertex covariance using analytical inversion
          const auto a00 = halfD2Chi2DX2_00;
          const auto a11 = halfD2Chi2DX2_11;
          const auto a20 = halfD2Chi2DX2_20;
          const auto a21 = halfD2Chi2DX2_21;
          const auto a22 = halfD2Chi2DX2_22;

          const auto det = a00 * (a22 * a11 - a21 * a21) + a20 * (-a11 * a20);
          const auto inv_det = 1.f / det;

          // maybe we should catch the case when det = 0
          // if (det == 0) return false;

          vtxcov[0] = (a22 * a11 - a21 * a21) * inv_det;
          vtxcov[1] = -(-a20 * a21) * inv_det;
          vtxcov[2] = (a22 * a00 - a20 * a20) * inv_det;
          vtxcov[3] = (-a20 * a11) * inv_det;
          vtxcov[4] = -(a21 * a00) * inv_det;
          vtxcov[5] = (a11 * a00) * inv_det;

          const float2 delta_xy {
            -1.f * (vtxcov[0] * halfDChi2DX.x + vtxcov[1] * halfDChi2DX.y + vtxcov[3] * halfDChi2DX.z),
            -1.f * (vtxcov[1] * halfDChi2DX.x + vtxcov[2] * halfDChi2DX.y + vtxcov[4] * halfDChi2DX.z)};

          const auto delta_z = -1.f * (vtxcov[3] * halfDChi2DX.x + vtxcov[4] * halfDChi2DX.y + vtxcov[5] * halfDChi2DX.z);
          chi2tot += delta_xy.x * halfDChi2DX.x + delta_xy.y * halfDChi2DX.y + delta_z * halfDChi2DX.z;

          // update the position
          vtxpos_xy = vtxpos_xy + delta_xy;
          vtxpos_z = vtxpos_z + delta_z;
          converged = std::abs(delta_z) < maxDeltaZConverged;
        }
        else {
          float3 fakepos {-99999.f, -99999.f, -99999.f};
          vertex.setPosition(fakepos);
          break;
        }
      } // end iteration loop
      // std::cout << "Number of iterations: " << iter << " " << nselectedtracks << std::endl ;
      vertex.chi2 = chi2tot;
      vertex.setPosition(vtxpos_xy, vtxpos_z);
      // vtxcov[5] = 100.;
      vertex.setCovMatrix(vtxcov);
      for (int i = 0; i < number_of_tracks; i++) {
        PVTrackInVertex trk = tracks[i];
        if (trk.weight > 0.f) vertex.n_tracks++;
      }

      // TODO integrate beamline position
      const float2 beamline {0.f, 0.f};
      const auto beamlinedx = vertex.position.x - beamline.x;
      const auto beamlinedy = vertex.position.y - beamline.y;
      const auto beamlinerho2 = beamlinedx * beamlinedx + beamlinedy * beamlinedy;
      if (vertex.n_tracks >= minNumTracksPerVertex && beamlinerho2 < maxVertexRho2) {
        
        vertices[*number_of_multi_fit_vertices] = vertex;
        (*number_of_multi_fit_vertices)++;
      }
    }
  }
}


void cleanup(PV::Vertex* dev_multi_fit_vertices,
  uint* dev_number_of_multi_fit_vertices,
  PV::Vertex* dev_multi_final_vertices,
  int* dev_number_of_multi_final_vertices,
  const uint event_number,
  const uint number_of_events) {
  
  PV::Vertex* vertices = dev_multi_fit_vertices + event_number * PV::max_number_vertices;
  PV::Vertex* final_vertices = dev_multi_final_vertices + event_number * PV::max_number_vertices;
  uint* number_of_multi_fit_vertices = dev_number_of_multi_fit_vertices + event_number;
    int tmp_number_vertices = 0;
  
  //loop over all rec PVs, check if another one is within certain sigma range, only fill if not
  for(int i_pv = 0; i_pv < number_of_multi_fit_vertices[0]; i_pv++ ) {

    bool unique = true;
    PV::Vertex vertex1 = vertices[i_pv];
    //PVs with such a small z uncertainty are very likely fakes 
    if (vertex1.cov22 > 100.f) continue;
    if (vertex1.cov22 < 0.000000001f) continue;
    for(int j_pv = 0; j_pv < tmp_number_vertices; j_pv++) {
      PV::Vertex vertex2 = final_vertices[j_pv];
      float z1 = vertex1.position.z;
      float z2 = vertex2.position.z;
      float variance1 = vertex1.cov22;
      float variance2 = vertex2.cov22;
      float chi2_dist = (z1-z2)*(z1-z2);
      chi2_dist = chi2_dist/(variance1+variance2);
      if(chi2_dist < minChi2Dist) unique = false;

    }
    if (unique) {
      final_vertices[tmp_number_vertices] = vertex1;
      tmp_number_vertices++;
    }
  }
  dev_number_of_multi_final_vertices[event_number] = tmp_number_vertices;
}


void findPVs(
  char* kalmanvelo_states,
  int* velo_atomics,
  uint* velo_track_hit_number,
  PV::Vertex* reconstructed_pvs,
  int* number_of_pvs,
  const uint number_of_events)

{
  PVTrack pvtracks[800*number_of_events];
  float zhisto[number_of_events * Nbins];
  float zpeaks[number_of_events * PV::max_number_vertices];
  uint number_of_zpeaks[number_of_events];

  PV::Vertex multi_fit_vertices[number_of_events * PV::max_number_vertices];
  uint number_of_multi_fit_vertices[number_of_events];
  PV::Vertex multi_final_vertices[number_of_events * PV::max_number_vertices];
  int number_of_multi_final_vertices[number_of_events];

  for(uint i_event = 0; i_event < number_of_events; i_event++) {
    pv_beamline_extrapolate(
      kalmanvelo_states,
      velo_atomics,
      velo_track_hit_number,
      pvtracks,
      i_event,
      number_of_events);
  }

  for(uint i_event = 0; i_event < number_of_events; i_event++) {
    pv_beamline_histo(velo_atomics,
      velo_track_hit_number,
      pvtracks,
      zhisto,
      i_event,
      number_of_events );
  }

  for(uint i_event = 0; i_event < number_of_events; i_event++) {
    pv_beamline_peak(zhisto, zpeaks, number_of_zpeaks, number_of_events, i_event);
  }
  for(uint i_event = 0; i_event < number_of_events; i_event++) {
    beamline_multi_fitter(
     velo_atomics,
     velo_track_hit_number,
     pvtracks,
     zpeaks,
     number_of_zpeaks,
     multi_fit_vertices,
     number_of_multi_fit_vertices,
     i_event,
     number_of_events);
  }
  for(uint i_event = 0; i_event < number_of_events; i_event++) {
    cleanup(multi_fit_vertices,
      number_of_multi_fit_vertices,
      reconstructed_pvs,
      number_of_pvs,
      i_event,
      number_of_events);
  }
}