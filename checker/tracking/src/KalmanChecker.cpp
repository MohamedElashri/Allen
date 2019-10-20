#include <cstdio>

#include <KalmanChecker.h>
#include <ROOTHeaders.h>

std::string const KalmanChecker::KalmanTag::name = "KalmanChecker";

KalmanChecker::KalmanChecker(CheckerInvoker const* invoker, std::string const& root_file)
{
#ifdef WITH_ROOT
  // Setup the TTree.
  m_file = invoker->root_file(root_file);
  m_file->cd();

  // NOTE: This TTree will be cleaned up by ROOT when the file is
  // closed.
  m_tree = new TTree("kalman_ip_tree", "kalman_ip_tree");
  m_tree->Branch("z", &m_trk_z);
  m_tree->Branch("x", &m_trk_x);
  m_tree->Branch("y", &m_trk_y);
  m_tree->Branch("tx", &m_trk_tx);
  m_tree->Branch("ty", &m_trk_ty);
  m_tree->Branch("qop", &m_trk_qop);
  m_tree->Branch("first_qop", &m_trk_first_qop);
  m_tree->Branch("best_qop", &m_trk_best_qop);
  m_tree->Branch("best_pt", &m_trk_best_pt);
  m_tree->Branch("kalman_ip", &m_trk_kalman_ip);
  m_tree->Branch("kalman_ipx", &m_trk_kalman_ipx);
  m_tree->Branch("kalman_ipy", &m_trk_kalman_ipy);
  m_tree->Branch("kalman_ip_chi2", &m_trk_kalman_ip_chi2);
  m_tree->Branch("kalman_docaz", &m_trk_kalman_docaz);
  m_tree->Branch("velo_ip", &m_trk_velo_ip);
  m_tree->Branch("velo_ipx", &m_trk_velo_ipx);
  m_tree->Branch("velo_ipy", &m_trk_velo_ipy);
  m_tree->Branch("velo_ip_chi2", &m_trk_velo_ip_chi2);
  m_tree->Branch("velo_docaz", &m_trk_velo_docaz);
  m_tree->Branch("chi2", &m_trk_chi2);
  m_tree->Branch("chi2V", &m_trk_chi2V);
  m_tree->Branch("chi2T", &m_trk_chi2T);
  m_tree->Branch("ndof", &m_trk_ndof);
  m_tree->Branch("ndofV", &m_trk_ndofV);
  m_tree->Branch("ndofT", &m_trk_ndofT);
  m_tree->Branch("ghost", &m_trk_ghost);
  m_tree->Branch("mcp_p", &m_mcp_p);
#else
  _unused(invoker);
  _unused(root_file);
#endif
}

void KalmanChecker::accumulate(MCEvents const& mc_events, std::vector<Checker::Tracks> const& tracks)
{
  // Loop over events.
  for (size_t i_event = 0; i_event < tracks.size(); ++i_event) {
    const auto& mc_event = mc_events[i_event];
    const auto& mcps = mc_event.m_mcps;
    const auto& event_tracks = tracks[i_event];
    MCAssociator mcassoc {mcps};

    // Loop over tracks.
    for (auto track : event_tracks) {
      const auto& ids = track.ids();
      const auto assoc = mcassoc(ids.begin(), ids.end(), track.n_matched_total);
      if (!assoc)
        m_trk_ghost = 1.f;
      else {
        const auto weight = std::get<1>(assoc.front());
        if (weight < 0.7f)
          m_trk_ghost = 1.f;
        else {
          m_trk_ghost = 0.f;
          const auto mcp = std::get<0>(assoc.front());
          m_mcp_p = mcp.p;
        }
      }
      m_trk_z = track.z;
      m_trk_x = track.x;
      m_trk_y = track.y;
      m_trk_tx = track.tx;
      m_trk_ty = track.ty;
      m_trk_qop = track.qop;
      m_trk_first_qop = track.first_qop;
      m_trk_best_qop = track.best_qop;
      m_trk_kalman_ip = track.kalman_ip;
      m_trk_kalman_ipx = track.kalman_ipx;
      m_trk_kalman_ipy = track.kalman_ipy;
      m_trk_kalman_ip_chi2 = track.kalman_ip_chi2;
      m_trk_kalman_docaz = track.kalman_docaz;
      m_trk_velo_ip = track.velo_ip;
      m_trk_velo_ipx = track.velo_ipx;
      m_trk_velo_ipy = track.velo_ipy;
      m_trk_velo_ip_chi2 = track.velo_ip_chi2;
      m_trk_velo_docaz = track.velo_docaz;
      m_trk_chi2 = track.chi2;
      m_trk_chi2V = track.chi2V;
      m_trk_chi2T = track.chi2T;
      m_trk_ndof = (float) track.ndof;
      m_trk_ndofV = (float) track.ndofV;
      m_trk_ndofT = (float) track.ndofT;
      float sint =
        std::sqrt((m_trk_tx * m_trk_tx + m_trk_ty * m_trk_ty) / (1.f + m_trk_tx * m_trk_tx + m_trk_ty * m_trk_ty));
      m_trk_best_pt = sint / std::abs(track.best_qop);
#ifdef WITH_ROOT
      m_tree->Fill();
#endif
    }
  }
}

void KalmanChecker::report(size_t) const
{
#ifdef WITH_ROOT
  m_file->cd();
  m_file->WriteTObject(m_tree);
#endif
}
