/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <PrimaryVertexChecker.h>
#include <PVCheckerHistos.h>
#include <ROOTHeaders.h>

// Not very pretty, will be better once nvcc supports C++17
std::string const PVChecker::CPUTag::name = "CPU_PVChecker";
std::string const PVChecker::GPUTag::name = "GPU_PVChecker";

PVChecker::PVChecker(CheckerInvoker const* invoker, std::string const& root_file)
{
  m_histos = new PVCheckerHistos {invoker, root_file};
}

void PVChecker::accumulate(
  MCEvents const& mc_events,
  PV::Vertex* rec_vertex,
  int* number_of_vertex,
  const unsigned event_list_size,
  const unsigned* event_list)
{
  passed += event_list_size;

  std::vector<RecPVInfo> vec_all_rec;

  // vectors to collect the pulls and erros
  std::vector<double> vec_rec_x;
  std::vector<double> vec_rec_y;
  std::vector<double> vec_rec_z;
  std::vector<double> vec_diff_x;
  std::vector<double> vec_diff_y;
  std::vector<double> vec_diff_z;

  std::vector<double> vec_err_x;
  std::vector<double> vec_err_y;
  std::vector<double> vec_err_z;

  // vectors with the mcpv multiplicity
  std::vector<int> vec_n_trinmcpv;
  std::vector<int> vec_n_mcpv;

  // vectors for the efficiency and fake rate
  // notice that we have to duplicate some information
  // here because we are filling a different structure/histogram compared
  // to the above ntuples. Basically the resolution is always only
  // filled for reconstructed PVs, but here we need to fill several histograms
  // based on both the mc pv information (efficiency vs. mc pv multiplicity or z position)
  // and the reconstructed information (fakes vs. reconstructed pv multiplicitly or z position)
  std::vector<int> vec_mcpv_recd;
  std::vector<int> vec_recpv_fake;
  std::vector<int> vec_mcpv_mult;
  std::vector<int> vec_recpv_mult;
  std::vector<double> vec_mcpv_zpos;
  std::vector<double> vec_mc_x;
  std::vector<double> vec_mc_y;
  std::vector<double> vec_mc_z;

  // loop over selected events
  for (unsigned event_index = 0; event_index < event_list_size; ++event_index) {
    std::vector<PV::Vertex*> vecOfVertices;
    const auto event_number = event_list[event_index];

    // first fill vector with vertices
    for (int i = 0; i < number_of_vertex[event_number]; i++) {
      int index = event_number * PatPV::max_number_vertices + i;
      vecOfVertices.push_back(&(rec_vertex[index]));
    }
    // Fill reconstucted PV info
    std::vector<RecPVInfo> recpvvec;
    std::vector<PV::Vertex*>::iterator itRecV;
    for (itRecV = vecOfVertices.begin(); vecOfVertices.end() != itRecV; itRecV++) {
      PV::Vertex* pv;
      pv = *itRecV;
      RecPVInfo recinfo;
      recinfo.pRECPV = pv;
      recinfo.x = static_cast<double>(pv->position.x);
      recinfo.y = static_cast<double>(pv->position.y);
      recinfo.z = static_cast<double>(pv->position.z);

      double sigx = std::sqrt(static_cast<double>(pv->cov00));
      double sigy = std::sqrt(static_cast<double>(pv->cov11));
      double sigz = std::sqrt(static_cast<double>(pv->cov22));
      PatPV::XYZPoint a3d(sigx, sigy, sigz);
      recinfo.positionSigma = a3d;
      recinfo.nTracks = pv->nTracks;
      double minRD = 99999.;
      double maxRD = -99999.;
      double chi2 = static_cast<double>(pv->chi2);
      double nDoF = static_cast<double>(pv->ndof);

      int mother = 0;
      int velo = 0;
      int lg = 0;
      double d0 = 0;
      double mind0 = 99999.0;
      double maxd0 = -99999.0;
      double trackChi2 = 0.0;
      int tr = 0;

      recinfo.minTrackRD = minRD;
      recinfo.maxTrackRD = maxRD;
      recinfo.mother = mother;
      recinfo.chi2 = chi2;
      recinfo.nDoF = nDoF;
      recinfo.d0 = d0;
      recinfo.d0nTr = (double) d0 / (double) tr;
      recinfo.chi2nTr = (double) trackChi2 / (double) tr;
      recinfo.mind0 = mind0;
      recinfo.maxd0 = maxd0;
      recinfo.nVeloTracks = velo;
      recinfo.nLongTracks = lg;
      recinfo.indexMCPVInfo = -1;
      recpvvec.push_back(recinfo);
    }

    // Fill MC PV info

    // do checking of collision type and mother here or in dumping?

    // vector with MCPVinfo
    std::vector<MCPVInfo> mcpvvec;

    for (auto const& mc_vertex : mc_events[event_index].m_mcvs) {

      MCPVInfo mcprimvert;
      mcprimvert.pMCPV = &mc_vertex;
      // mcprimvert.nRecTracks = 0;
      mcprimvert.nRecTracks = mc_vertex.numberTracks;
      // mcprimvert.nRecTracks = 99;
      mcprimvert.nRecBackTracks = 0;
      mcprimvert.indexRecPVInfo = -1;
      mcprimvert.nCorrectTracks = 0;
      mcprimvert.multClosestMCPV = 0;
      mcprimvert.distToClosestMCPV = 999999.;
      mcprimvert.decayBeauty = 0;
      mcprimvert.decayCharm = 0;

      mcpvvec.push_back(mcprimvert);
    }

    std::vector<MCPVInfo> rblemcpv;
    std::vector<MCPVInfo> not_rble_but_visible;
    std::vector<MCPVInfo> not_rble;
    int nmrc = 0;

    // count not reconstructible MC PVs
    std::vector<MCPVInfo>::iterator itmc;
    for (itmc = mcpvvec.begin(); mcpvvec.end() != itmc; itmc++) {
      rblemcpv.push_back(*itmc);

      if (itmc->nRecTracks < nTracksToBeRecble) {
        nmrc++;
      }
      else {
        vec_mc_x.push_back(itmc->pMCPV->x);
        vec_mc_y.push_back(itmc->pMCPV->y);
        vec_mc_z.push_back(itmc->pMCPV->z);
      }
      if (itmc->nRecTracks < nTracksToBeRecble && itmc->nRecTracks > 1) {
        not_rble_but_visible.push_back(*itmc);
      }
      if (itmc->nRecTracks < nTracksToBeRecble && itmc->nRecTracks < 2) {
        not_rble.push_back(*itmc);
      }
    }

    // match by distance
    for (int ipv = 0; ipv < (int) recpvvec.size(); ipv++) {
      match_mc_vertex_by_distance(ipv, recpvvec, rblemcpv);
    };

    // find nr of false PV
    int nFalsePV = 0;
    int nFalsePV_real = 0;
    for (int ipv = 0; ipv < (int) recpvvec.size(); ipv++) {
      vec_all_rec.push_back(recpvvec[ipv]);

      // Counter for performance plots
      vec_recpv_mult.push_back(recpvvec[ipv].pRECPV->nTracks);

      if (recpvvec[ipv].indexMCPVInfo < 0) {
        // Counter for performance plots
        vec_recpv_fake.push_back(1);
        nFalsePV++;
        bool vis_found = false;
        for (unsigned int imc = 0; imc < not_rble_but_visible.size(); imc++) {
          if (not_rble_but_visible[imc].indexRecPVInfo > -1) continue;
          double dist = fabs(mcpvvec[imc].pMCPV->z - recpvvec[ipv].z);
          if (dist < 5.0 * static_cast<double>(recpvvec[ipv].positionSigma.z)) {
            vis_found = true;
            not_rble_but_visible[imc].indexRecPVInfo = 10;
            break;
          }
        } // imc
        if (!vis_found) nFalsePV_real++;
      }
      else {
        vec_recpv_fake.push_back(0);
      } // Counter for performance plots
    }

    // Fill distance to closest recble MC PV and its multiplicity
    std::vector<MCPVInfo>::iterator itmcl;
    for (itmcl = rblemcpv.begin(); rblemcpv.end() != itmcl; itmcl++) {
      std::vector<MCPVInfo>::iterator cmc = closestMCPV(rblemcpv, itmcl);
      double dist = 999999.;
      int mult = 0;
      if (cmc != rblemcpv.end()) {
        mult = cmc->nRecTracks;
        double diff_x = itmcl->pMCPV->x - cmc->pMCPV->x;
        double diff_y = itmcl->pMCPV->y - cmc->pMCPV->y;
        double diff_z = itmcl->pMCPV->z - cmc->pMCPV->z;
        dist = sqrt(diff_x * diff_x + diff_y * diff_y + diff_z * diff_z);
        itmcl->distToClosestMCPV = dist;
        itmcl->multClosestMCPV = mult;
      }
    }

    // count non.reconstructible close and isolated PVs
    int nmrc_isol = 0;
    int nmrc_close = 0;

    // Counters
    int nMCPV = rblemcpv.size() - nmrc;
    int nRecMCPV = 0;
    int nMCPV_isol = 0;
    int nRecMCPV_isol = 0;
    int nMCPV_close = 0;
    int nRecMCPV_close = 0;

    for (itmc = rblemcpv.begin(); rblemcpv.end() != itmc; itmc++) {
      // Counters for performance plots
      if (itmc->nRecTracks > nTracksToBeRecble) {
        vec_mcpv_mult.push_back(itmc->pMCPV->numberTracks);
        vec_mcpv_zpos.push_back(itmc->pMCPV->z);
        if (itmc->indexRecPVInfo > -1) {
          vec_mcpv_recd.push_back(1);
        }
        else {
          vec_mcpv_recd.push_back(0);
        }
      }
      if (itmc->distToClosestMCPV > dzIsolated) nMCPV_isol++;
      if (itmc->distToClosestMCPV > dzIsolated && itmc->nRecTracks < nTracksToBeRecble) nmrc_isol++;
      if (itmc->distToClosestMCPV < dzIsolated) nMCPV_close++;
      if (itmc->distToClosestMCPV < dzIsolated && itmc->nRecTracks < nTracksToBeRecble) nmrc_close++;
      if (itmc->indexRecPVInfo > -1) {
        nRecMCPV++;
        if (itmc->distToClosestMCPV > dzIsolated) nRecMCPV_isol++;
        if (itmc->distToClosestMCPV < dzIsolated) nRecMCPV_close++;
      }
    }

    nMCPV_isol = nMCPV_isol - nmrc_isol;
    nMCPV_close = nMCPV_close - nmrc_close;

    sum_nMCPV += nMCPV;
    sum_nRecMCPV += nRecMCPV;
    sum_nMCPV_isol += nMCPV_isol;
    sum_nRecMCPV_isol += nRecMCPV_isol;
    sum_nMCPV_close += nMCPV_close;
    sum_nRecMCPV_close += nRecMCPV_close;
    sum_nFalsePV += nFalsePV;
    sum_nFalsePV_real += nFalsePV_real;

    // loop over matched MC PVs and get pull and errors
    for (auto mc_vertex_info : rblemcpv) {
      int rec_index = mc_vertex_info.indexRecPVInfo;
      auto const* mc_vertex = mc_vertex_info.pMCPV;
      if (rec_index < 0) continue;

      sum_clones += mc_vertex_info.number_rec_vtx;
      sum_norm_clones++;
      vec_n_mcpv.push_back(nMCPV);
      vec_n_trinmcpv.push_back(mc_vertex->numberTracks);

      double diff_x = recpvvec[rec_index].x - mc_vertex->x;
      double diff_y = recpvvec[rec_index].y - mc_vertex->y;
      double diff_z = recpvvec[rec_index].z - mc_vertex->z;
      vec_diff_x.push_back(diff_x);
      vec_diff_y.push_back(diff_y);
      vec_diff_z.push_back(diff_z);
      vec_rec_x.push_back(recpvvec[rec_index].x);
      vec_rec_y.push_back(recpvvec[rec_index].y);
      vec_rec_z.push_back(recpvvec[rec_index].z);

      double err_x = static_cast<double>(recpvvec[rec_index].positionSigma.x);
      double err_y = static_cast<double>(recpvvec[rec_index].positionSigma.y);
      double err_z = static_cast<double>(recpvvec[rec_index].positionSigma.z);

      vec_err_x.push_back(err_x);
      vec_err_y.push_back(err_y);
      vec_err_z.push_back(err_z);
    }
  } // end loop over events

  m_histos->accumulate(
    vec_all_rec,
    vec_rec_x,
    vec_rec_y,
    vec_rec_z,
    vec_diff_x,
    vec_diff_y,
    vec_diff_z,
    vec_err_x,
    vec_err_y,
    vec_err_z,
    vec_n_trinmcpv,
    vec_n_mcpv,
    vec_mcpv_recd,
    vec_recpv_fake,
    vec_mcpv_mult,
    vec_recpv_mult,
    vec_mcpv_zpos,
    vec_mc_x,
    vec_mc_y,
    vec_mc_z);
}

PVChecker::~PVChecker() { delete m_histos; }

void PVChecker::report(size_t) const
{
  std::string ff = "by counting tracks";
  if (!matchByTracks) ff = "by dz distance";

  info_cout << "REC and MC vertices matched " << ff << std::endl;
  std::printf(
    "MC PV is reconstructible if at least %i tracks are reconstructed\n\
MC PV is isolated if dz to closest reconstructible MC PV > %2.2f mm\n\
REC and MC vertices matched %s\n\n",
    nTracksToBeRecble,
    dzIsolated,
    ff.c_str());

  printRat("All", sum_nRecMCPV, sum_nMCPV);
  printRat("Isolated", sum_nRecMCPV_isol, sum_nMCPV_isol);
  printRat("Close", sum_nRecMCPV_close, sum_nMCPV_close);
  printRat("False rate", sum_nFalsePV, sum_nRecMCPV + sum_nFalsePV);
  printRat("Real false rate", sum_nFalsePV_real, sum_nRecMCPV + sum_nFalsePV_real);
  printRat("Clones", 1.0f * sum_clones - sum_norm_clones, sum_norm_clones);
  info_cout << std::endl;

  m_histos->write();
}

void match_mc_vertex_by_distance(int ipv, std::vector<RecPVInfo>& rinfo, std::vector<MCPVInfo>& mcpvvec)
{

  double mindist = 999999.;
  int indexmc = -1;

  for (int imc = 0; imc < (int) mcpvvec.size(); imc++) {
    double dist = fabs(mcpvvec[imc].pMCPV->z - rinfo[ipv].z);
    if (dist < mindist) {
      mindist = dist;
      indexmc = imc;
    }
  }
  if (indexmc > -1) {
    if (mindist < 5.0 * static_cast<double>(rinfo[ipv].positionSigma.z)) {
      rinfo[ipv].indexMCPVInfo = indexmc;
      mcpvvec[indexmc].indexRecPVInfo = ipv;
      mcpvvec[indexmc].number_rec_vtx++;
    }
  }
}

void printRat(std::string mes, int a, int b)
{

  float rat = 0.f;
  if (b > 0) rat = 1.0f * a / b;

  // reformat message
  unsigned int len = 20;
  std::string pmes = mes;
  while (pmes.length() < len) {
    pmes += " ";
  }
  pmes += " : ";

  std::printf("%s %.3f (%6i/%6i)\n", pmes.c_str(), static_cast<double>(rat), a, b);
}

std::vector<MCPVInfo>::iterator closestMCPV(std::vector<MCPVInfo>& rblemcpv, std::vector<MCPVInfo>::iterator& itmc)
{

  std::vector<MCPVInfo>::iterator itret = rblemcpv.end();
  double mindist = 999999.;
  if (rblemcpv.size() < 2) return itret;
  std::vector<MCPVInfo>::iterator it;
  for (it = rblemcpv.begin(); it != rblemcpv.end(); it++) {
    if (it->pMCPV != itmc->pMCPV) {
      double diff_x = it->pMCPV->x - itmc->pMCPV->x;
      double diff_y = it->pMCPV->y - itmc->pMCPV->y;
      double diff_z = it->pMCPV->z - itmc->pMCPV->z;
      double dist = sqrt(diff_x * diff_x + diff_y * diff_y + diff_z * diff_z);

      if (dist < mindist) {
        mindist = dist;
        itret = it;
      }
    }
  }
  return itret;
}
