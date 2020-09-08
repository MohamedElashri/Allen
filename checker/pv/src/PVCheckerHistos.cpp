/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "PVCheckerHistos.h"

#ifdef WITH_ROOT
namespace {
  float binomial_error(float k, float N) { return sqrtf(k * (1 - k / N)) / N; }
} // namespace
#endif

PVCheckerHistos::PVCheckerHistos(CheckerInvoker const* invoker, std::string const& root_file)
{
#ifdef WITH_ROOT
  m_file = invoker->root_file(root_file);
  m_file->cd();

  eff_vs_z = std::make_unique<TH1F>("eff_vs_z", "eff_vs_z", m_bins_norm_z, -300, 300);
  eff_matched_vs_z = std::make_unique<TH1F>("eff_matched_z", "eff_matched_z", m_bins_norm_z, -300, 300);
  eff_vs_mult = std::make_unique<TH1F>("eff_vs_mult", "eff_vs_mult", m_bins_norm_mult, 0, 50);
  eff_matched_vs_mult = std::make_unique<TH1F>("eff_matched_mult", "eff_matched_mult", m_bins_norm_mult, 0, 50);
  eff_norm_z = std::make_unique<TH1F>("eff_norm_z", "eff_norm_z", m_bins_norm_z, -300, 300);
  eff_norm_mult = std::make_unique<TH1F>("eff_norm_mult", "eff_norm_mult", m_bins_norm_mult, 0, 50);
  fakes_vs_mult = std::make_unique<TH1F>("fakes_vs_mult", "fakes_vs_mult", m_bins_fake_mult, 0, 20);
  fakes_norm = std::make_unique<TH1F>("fakes_norm_mult", "fakes_norm_mult", m_bins_fake_mult, 0, 20);

  std::string tree_name = "PV_tree";

  m_tree = std::make_unique<TTree>(tree_name.c_str(), tree_name.c_str());
  m_tree->Branch("nmcpv", &m_nmcpv);
  m_tree->Branch("ntrinmcpv", &m_ntrinmcpv);

  m_tree->Branch("diff_x", &m_diff_x);
  m_tree->Branch("diff_y", &m_diff_y);
  m_tree->Branch("diff_z", &m_diff_z);
  m_tree->Branch("rec_x", &m_rec_x);
  m_tree->Branch("rec_y", &m_rec_y);
  m_tree->Branch("rec_z", &m_rec_z);

  m_tree->Branch("err_x", &m_err_x);
  m_tree->Branch("err_y", &m_err_y);
  m_tree->Branch("err_z", &m_err_z);

  m_mctree = std::make_unique<TTree>("MC_tree", "MC_tree");
  m_mctree->Branch("x", &m_mc_x);
  m_mctree->Branch("y", &m_mc_y);
  m_mctree->Branch("z", &m_mc_z);

  m_allPV = std::make_unique<TTree>("allPV", "allPV");
  m_allPV->Branch("x", &m_x);
  m_allPV->Branch("y", &m_y);
  m_allPV->Branch("z", &m_z);
  m_allPV->Branch("errx", &m_errx);
  m_allPV->Branch("erry", &m_erry);
  m_allPV->Branch("errz", &m_errz);
  m_allPV->Branch("isFake", &m_isFake);
#else
  _unused(invoker);
  _unused(root_file);
#endif
}

void PVCheckerHistos::accumulate(
  std::vector<RecPVInfo> const& vec_all_rec,
  std::vector<double> const& vec_rec_x,
  std::vector<double> const& vec_rec_y,
  std::vector<double> const& vec_rec_z,
  std::vector<double> const& vec_diff_x,
  std::vector<double> const& vec_diff_y,
  std::vector<double> const& vec_diff_z,
  std::vector<double> const& vec_err_x,
  std::vector<double> const& vec_err_y,
  std::vector<double> const& vec_err_z,
  std::vector<int> const& vec_n_trinmcpv,
  std::vector<int> const& vec_n_mcpv,
  std::vector<int> const& vec_mcpv_recd,
  std::vector<int> const& vec_recpv_fake,
  std::vector<int> const& vec_mcpv_mult,
  std::vector<int> const& vec_recpv_mult,
  std::vector<double> const& vec_mcpv_zpos,
  std::vector<double> const& vec_mc_x,
  std::vector<double> const& vec_mc_y,
  std::vector<double> const& vec_mc_z)
{
#ifdef WITH_ROOT
  // save information about matched reconstructed PVs for pulls distributions
  for (size_t i = 0; i < vec_diff_x.size(); i++) {
    m_nmcpv = vec_n_mcpv.at(i);
    m_ntrinmcpv = vec_n_trinmcpv.at(i);
    m_diff_x = vec_diff_x.at(i);
    m_diff_y = vec_diff_y.at(i);
    m_diff_z = vec_diff_z.at(i);
    m_rec_x = vec_rec_x.at(i);
    m_rec_y = vec_rec_y.at(i);
    m_rec_z = vec_rec_z.at(i);

    m_err_x = vec_err_x.at(i);
    m_err_y = vec_err_y.at(i);
    m_err_z = vec_err_z.at(i);

    m_tree->Fill();
  }

  for (size_t i = 0; i < vec_recpv_mult.size(); i++) {
    fakes_vs_mult->Fill(vec_recpv_mult.at(i), vec_recpv_fake.at(i));
    fakes_norm->Fill(vec_recpv_mult.at(i), 1);
  }

  for (size_t i = 0; i < vec_mcpv_mult.size(); i++) {
    eff_vs_z->Fill(vec_mcpv_zpos.at(i), vec_mcpv_recd.at(i));
    eff_vs_mult->Fill(vec_mcpv_mult.at(i), vec_mcpv_recd.at(i));
    if (vec_mcpv_recd.at(i)) {
      eff_matched_vs_z->Fill(vec_mcpv_zpos.at(i));
      eff_matched_vs_mult->Fill(vec_mcpv_mult.at(i));
    }
    eff_norm_z->Fill(vec_mcpv_zpos.at(i), 1);
    eff_norm_mult->Fill(vec_mcpv_mult.at(i), 1);
  }

  std::vector<float> binerrors_vs_z;
  std::vector<float> binerrors_vs_mult;

  // Proper uncertainties for efficiencies
  for (int i = 1; i <= m_bins_norm_z; i++) {
    float N = 1.f * static_cast<float>(eff_norm_z->GetBinContent(i));
    float k = 1.f * static_cast<float>(eff_vs_z->GetBinContent(i));
    if (k < N && N > 0) {
      binerrors_vs_z.push_back(binomial_error(k, N));
    }
    else
      binerrors_vs_z.push_back(0.);
  }
  for (int i = 1; i <= m_bins_norm_mult; i++) {
    float N = 1.f * static_cast<float>(eff_norm_mult->GetBinContent(i));
    float k = 1.f * static_cast<float>(eff_vs_mult->GetBinContent(i));
    if (k < N && N > 0) {
      binerrors_vs_mult.push_back(binomial_error(k, N));
    }
    else
      binerrors_vs_mult.push_back(0.);
  }

  eff_vs_z->Divide(eff_norm_z.get());
  for (int i = 1; i <= m_bins_norm_z; i++) {
    eff_vs_z->SetBinError(i, binerrors_vs_z.at(i - 1));
  }
  eff_vs_mult->Divide(eff_norm_mult.get());
  for (int i = 1; i <= m_bins_norm_mult; i++) {
    eff_vs_mult->SetBinError(i, binerrors_vs_mult.at(i - 1));
  }
  fakes_vs_mult->Divide(fakes_norm.get());

  for (size_t j = 0; j < vec_mc_x.size(); j++) {
    m_mc_x = vec_mc_x.at(j);
    m_mc_y = vec_mc_y.at(j);
    m_mc_z = vec_mc_z.at(j);
    m_mctree->Fill();
  }

  for (auto rec_pv : vec_all_rec) {
    m_x = rec_pv.x;
    m_y = rec_pv.y;
    m_z = rec_pv.z;
    m_errx = rec_pv.positionSigma.x;
    m_erry = rec_pv.positionSigma.y;
    m_errz = rec_pv.positionSigma.z;
    m_isFake = rec_pv.indexMCPVInfo < 0;
    m_allPV->Fill();
  }
#else
  _unused(vec_all_rec);
  _unused(vec_rec_x);
  _unused(vec_rec_y);
  _unused(vec_rec_z);
  _unused(vec_diff_x);
  _unused(vec_diff_y);
  _unused(vec_diff_z);
  _unused(vec_err_x);
  _unused(vec_err_y);
  _unused(vec_err_z);
  _unused(vec_n_trinmcpv);
  _unused(vec_n_mcpv);
  _unused(vec_mcpv_recd);
  _unused(vec_recpv_fake);
  _unused(vec_mcpv_mult);
  _unused(vec_recpv_mult);
  _unused(vec_mcpv_zpos);
  _unused(vec_mc_x);
  _unused(vec_mc_y);
  _unused(vec_mc_z);
#endif
}

void PVCheckerHistos::write()
{
#ifdef WITH_ROOT
  m_file->cd();
  std::tuple to_write {std::ref(m_tree),
                       std::ref(m_mctree),
                       std::ref(m_allPV),
                       std::ref(eff_vs_z),
                       std::ref(eff_vs_mult),
                       std::ref(eff_matched_vs_z),
                       std::ref(eff_matched_vs_mult),
                       std::ref(eff_norm_z),
                       std::ref(eff_norm_mult),
                       std::ref(fakes_vs_mult),
                       std::ref(fakes_norm)};
  for_each(to_write, [this](auto& o) {
    o.get()->SetDirectory(nullptr);
    m_file->WriteTObject(o.get().get());
  });
#endif
}
