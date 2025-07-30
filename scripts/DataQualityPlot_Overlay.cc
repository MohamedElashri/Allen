/*****************************************************************************\
* (c) Copyright 2023-2024 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#if __has_include("LHCbStyle.C")
// If possible, include LHCbStyle to make the plots look nicer
// If the style file isn't available, use ROOT default style
#include "LHCbStyle.C"
#endif

struct Var {
  const TString varName;
  const float xmin;
  const float xmax;
  const float ymin;
  const float ymax;
  TString treeName; // Not const, sometimes forward/matching need to be switched
  TString cut = "";
  bool forward = false;
  bool logy = false;

  Var(
    const TString varName,
    const TString treeName,
    const float xmin,
    const float xmax,
    const float ymin = 0.f,
    const float ymax = 0.f) :
    varName {varName},
    treeName {treeName}, xmin {xmin}, xmax {xmax}, ymin {ymin}, ymax {ymax}
  {}
};

TH1* draw(
  TTree* tree,
  Var& var,
  TVirtualPad* pad,
  const TString& fileName,
  const bool first,
  const Int_t colourIndex,
  std::map<TVirtualPad*, TH1*>& originalHists);

void makeIPplot(
  TTree* tree,
  TString var,
  TVirtualPad* pad,
  const TString& fileName,
  const bool first,
  const Int_t colourIndex,
  std::map<TVirtualPad*, TH1*>& originalHists,
  const bool forward);

std::pair<TColor*, Int_t> GetColorAndLineStyle(Int_t index);

template<typename... FILENAMES>
void DataQualityPlot_Overlay(FILENAMES... files)
{
  std::vector<TString> fileList({files...});
  TString suffix = "";

  if (not fileList.back().EndsWith(".root")) {
    suffix = fileList.back();
    std::cout << "INFO : Using \"" << suffix << "\" as the output file suffix" << std::endl;
    std::cout << "     : To disable this behaviour, all input files should end in \".root\"" << std::endl;
    fileList.pop_back();
    if (not suffix.BeginsWith('_')) {
      suffix = "_" + suffix;
    }
  }

  std::cout << "Running over files : ";
  for (const TString& file : fileList) {
    std::cout << file << ", ";
  }
  std::cout << "\b\b" << std::endl;

#if __has_include("LHCbStyle.C")
  LHCbStyle();
#else
  std::cerr << "WARNING : LHCbStyle file not found, default plotting style will be used ..." << std::endl;
  std::cerr << "        : For best results put a copy of LHCbStyle.C in the Allen/scripts folder" << std::endl;
#endif
  gStyle->SetOptStat(0);

  std::map<TString, TCanvas*> canvases = {
    {"PVcanvas", new TCanvas("PVcanvas", "PVcanvas", 900, 600)},
    {"PVcovCanvas", new TCanvas("PVcovCanvas", "PVcovCanvas", 900, 900)},
    {"PVdistCanvas", new TCanvas("PVdistCanvas", "PVdistCanvas", 600, 600)},
    {"longMatchingCanvas", new TCanvas("longMatchingCanvas", "longMatchingCanvas", 900, 900)},
    {"longForwardCanvas", new TCanvas("longForwardCanvas", "longForwardCanvas", 900, 900)},
    {"kalmanCovCanvas", new TCanvas("kalmanCovCanvas", "kalmanCovCanvas", 1200, 1200)},
    {"veloCanvas", new TCanvas("veloCanvas", "veloCanvas", 900, 900)},
    {"occupancyCanvas", new TCanvas("occupancyCanvas", "occupancyCanvas", 600, 900)},
    {"PIDCanvas", new TCanvas("PIDCanvas", "PIDCanvas", 600, 600)},
    {"PIDkinCanvas", new TCanvas("PIDkinCanvas", "PIDkinCanvas", 1200, 600)},
    {"IPmatchingCanvas", new TCanvas("IPmatchingCanvas", "IPmatchingCanvas", 600, 600)},
    {"IPforwardCanvas", new TCanvas("IPforwardCanvas", "IPforwardCanvas", 600, 600)},
    {"IPresolutionCanvas", new TCanvas("IPresolutionCanvas", "IPresolutionCanvas", 600, 600)},
    {"fileCanvas", new TCanvas("fileCanvas", "fileCanvas", 600, 600)}};
  for (auto& [name, canvas] : canvases) {
    canvas->Divide(canvas->GetWindowWidth() / 300, canvas->GetWindowHeight() / 300);
  }
  std::map<TVirtualPad*, TH1*> originalHists;
  std::map<TString, TLegend*> legends;

  bool first = true;
  Int_t colourIndex = 0;

  for (const TString& fileName : fileList) {

    TCanvas* canvas = nullptr;
    TFile* file = TFile::Open(fileName);
    if (not file) {
      std::cerr << "WARNING : file " << fileName << " doesn't exist! skipping ...";
      continue;
    }

    std::cout << "Generating PV canvas ...";

    canvas = canvases["PVcanvas"];

    std::vector<Var> PVcanvasVars = {Var("n_pvs", "data_quality_validation_pv/PV_event", 0, 12),
                                     Var("pv_nTracks", "data_quality_validation_pv/PVs", 0, 20),
                                     Var("pv_y:pv_x", "data_quality_validation_pv/PVs", 0.8, 1.5, -0.1, 0.5),
                                     Var("pv_x", "data_quality_validation_pv/PVs", 0.8, 1.5),
                                     Var("pv_y", "data_quality_validation_pv/PVs", -0.1, 0.5),
                                     Var("pv_z", "data_quality_validation_pv/PVs", -100, 100)};

    for (size_t i = 0; i < PVcanvasVars.size(); ++i) {
      TVirtualPad* pad = canvas->cd(i + 1);
      Var var = PVcanvasVars[i];
      TTree* tree = dynamic_cast<TTree*>(file->Get(var.treeName));

      TH1* hist = draw(tree, var, pad, fileName, first, colourIndex, originalHists);

      if (i == 0) {
        if (first) {
          legends["mu"] = new TLegend(0.6, 0.7, 0.9, 0.9);
        }
        hist->ResetStats();
        // make a poisson shape, following
        // https://root-forum.cern.ch/t/fitting-a-poisson-distribution-to-a-histogram/12078/2
        TF1* f1 = new TF1(
          "f1",
          "[0]*TMath::Power(([1]/[2]),(x/[2]))*(TMath::Exp(-([1]/[2])))/TMath::Gamma((x/[2])+1.)",
          var.xmin,
          var.xmax);
        f1->SetParameters(1, 1, 1); // you MUST set non-zero initial values for parameters
        hist->Fit("f1", "RQ");      // "R" = fit between "xmin" and "xmax" of the "f1"
        Float_t mean = f1->GetParameter(1);
        legends["mu"]->AddEntry(hist, Form("#mu_{poisson} = %.2f", mean), "l");
        delete f1;

        if (fileName == fileList.back()) {
          legends["mu"]->Draw();
        }
      }
    }

    std::cout << " complete!" << std::endl;
    std::cout << "Generating PV covariance canvas ...";

    std::vector<Var> PVcovVars = {Var("cov00", "data_quality_validation_pv/PVs", 0., 0.004),
                                  Var("cov10", "data_quality_validation_pv/PVs", -0.0005, 0.0005),
                                  Var("cov11", "data_quality_validation_pv/PVs", 0., 0.0005),
                                  Var("cov20", "data_quality_validation_pv/PVs", -0.01, 0.01),
                                  Var("cov21", "data_quality_validation_pv/PVs", -0.01, 0.01),
                                  Var("cov22", "data_quality_validation_pv/PVs", 0., 0.3)};
    std::vector<Int_t> canvasOrder = {1, 4, 5, 7, 8, 9};

    canvas = canvases["PVcovCanvas"];

    for (size_t i = 0; i < PVcovVars.size(); ++i) {
      TVirtualPad* pad = canvas->cd(canvasOrder[i]);
      Var var = PVcovVars[i];
      TTree* tree = dynamic_cast<TTree*>(file->Get(var.treeName));

      draw(tree, var, pad, fileName, first, colourIndex, originalHists);
    }

    std::cout << " complete!" << std::endl;
    std::cout << "Generating PV distance canvas ...";

    canvas = canvases["PVdistCanvas"];

    std::vector<Var> PVdistCanvasVars = {Var("PVdistance_min", "data_quality_validation_pv/PV_event", 0, 200),
                                         Var("PVdistance_max", "data_quality_validation_pv/PV_event", 0, 300),
                                         Var("PVdistance_mean", "data_quality_validation_pv/PV_event", 0, 200),
                                         Var("PVdelta_z", "data_quality_validation_pv/PV_pairs", -6, 6)};

    for (size_t i = 0; i < PVdistCanvasVars.size(); ++i) {
      TVirtualPad* pad = canvas->cd(i + 1);
      Var var = PVdistCanvasVars[i];
      TTree* tree = dynamic_cast<TTree*>(file->Get(var.treeName));

      TH1* hist = draw(tree, var, pad, fileName, first, colourIndex, originalHists);

      if (i < 3) {
        if (first) {
          legends[var.varName] = new TLegend(0.5, 0.6, 0.9, 0.9);
        }
        hist->ResetStats();
        Float_t mean = hist->GetMean();
        Float_t lessThan2PVs = 1.f * tree->GetEntries(var.varName + "<0") / tree->GetEntries();
        legends[var.varName]->AddEntry(hist, Form("#mu = %.2f; <2 PV rate =  %.2f%%", mean, lessThan2PVs * 100), "l");

        if (fileName == fileList.back()) {
          legends[var.varName]->Draw();
        }
      }
    }

    std::cout << " complete!" << std::endl;
    std::cout << "Generating long tracks canvas (matching) ...";

    std::vector<Var> longVars = {
      Var("n_long_tracks", "data_quality_validation_matching/long_tracks_event", 1, 140),
      Var("qop", "data_quality_validation_matching/long_track_particles", -4e-4, 4e-4),
      Var("pt", "data_quality_validation_matching/long_track_particles", 0, 5000),
      Var("tx", "data_quality_validation_matching/long_track_particles", -0.12, 0.12),
      Var("ty", "data_quality_validation_matching/long_track_particles", -0.12, 0.12),
      Var("ty:tx", "data_quality_validation_matching/long_track_particles", -0.12, 0.12, -0.12, 0.12),
      Var("eta", "data_quality_validation_matching/long_track_particles", 1.5, 5.2),
      Var("phi", "data_quality_validation_matching/long_track_particles", -M_PI, M_PI),
      Var("eta:phi", "data_quality_validation_matching/long_track_particles", -M_PI, M_PI, 1.5, 5.2)};

    canvas = canvases["longMatchingCanvas"];

    for (size_t i = 0; i < longVars.size(); ++i) {
      TVirtualPad* pad = canvas->cd(i + 1);
      Var var = longVars[i];
      if (i == 0) {
        var.logy = true;
      }
      TTree* tree = dynamic_cast<TTree*>(file->Get(var.treeName));

      TH1* hist = draw(tree, var, pad, fileName, first, colourIndex, originalHists);
      if (i == 0) {
        if (first) {
          legends["nLongTracks_Matching"] = new TLegend(0.6, 0.7, 0.9, 0.9);
        }
        hist->ResetStats();
        Float_t mean = hist->GetMean();
        legends["nLongTracks_Matching"]->AddEntry(hist, Form("#mu = %.2f", mean), "l");

        if (fileName == fileList.back()) {
          legends["nLongTracks_Matching"]->Draw();
        }
      }
    }

    std::cout << " complete!" << std::endl;
    std::cout << "Generating long tracks canvas (forward) ...";

    canvas = canvases["longForwardCanvas"];

    for (size_t i = 0; i < longVars.size(); ++i) {
      TVirtualPad* pad = canvas->cd(i + 1);
      Var var = longVars[i];
      var.treeName.ReplaceAll("matching", "forward");
      if (i == 0) {
        var.logy = true;
      }
      var.forward = true;
      TTree* tree = dynamic_cast<TTree*>(file->Get(var.treeName));

      TH1* hist = draw(tree, var, pad, fileName, first, colourIndex, originalHists);
      if (i == 0) {
        if (first) {
          legends["nLongTracks_Forward"] = new TLegend(0.6, 0.7, 0.9, 0.9);
        }
        hist->ResetStats();
        Float_t mean = hist->GetMean();
        legends["nLongTracks_Forward"]->AddEntry(hist, Form("#mu = %.2f", mean), "l");

        if (fileName == fileList.back()) {
          legends["nLongTracks_Forward"]->Draw();
        }
      }
    }

    std::cout << " complete!" << std::endl;
    std::cout << "Generating Kalman covariance canvas ...";

    std::vector<Var> kalmanCovVars = {Var("cov00", "data_quality_validation_matching/long_track_particles", 0., 0.05),
                                      Var("cov11", "data_quality_validation_matching/long_track_particles", 0., 0.05),
                                      Var("cov20", "data_quality_validation_matching/long_track_particles", -1e-4, 0.),
                                      Var("cov22", "data_quality_validation_matching/long_track_particles", 0., 6e-7),
                                      Var("cov31", "data_quality_validation_matching/long_track_particles", -1e-4, 0.),
                                      Var("cov33", "data_quality_validation_matching/long_track_particles", 0., 6e-7)};

    canvas = canvases["kalmanCovCanvas"];
    canvasOrder = {1, 6, 9, 11, 14, 16};

    for (size_t i = 0; i < kalmanCovVars.size(); ++i) {
      TVirtualPad* pad = canvas->cd(canvasOrder[i]);
      Var var = kalmanCovVars[i];
      TTree* tree = dynamic_cast<TTree*>(file->Get(var.treeName));

      draw(tree, var, pad, fileName, first, colourIndex, originalHists);
    }

    std::cout << " complete!" << std::endl;
    std::cout << "Generating velo canvas ...";

    std::vector<Var> veloVars = {Var("n_velo_hits", "data_quality_validation_occupancy/occupancy", 0, 3000),
                                 Var("n_velo_tracks", "data_quality_validation_occupancy/occupancy", -0.5, 1000),
                                 Var("n_hits_per_track", "data_quality_validation_velo/velo_states", 0, 16),
                                 Var("tx", "data_quality_validation_velo/velo_states", -0.3, 0.3),
                                 Var("ty", "data_quality_validation_velo/velo_states", -0.3, 0.3),
                                 Var("ty:tx", "data_quality_validation_velo/velo_states", -0.3, 0.3, -0.3, 0.3),
                                 Var("eta", "data_quality_validation_velo/velo_states", 1.0, 5.2),
                                 Var("phi", "data_quality_validation_velo/velo_states", -M_PI, M_PI),
                                 Var("eta:phi", "data_quality_validation_velo/velo_states", -M_PI, M_PI, 1.0, 5.2)};

    canvas = canvases["veloCanvas"];

    for (size_t i = 0; i < veloVars.size(); ++i) {
      TVirtualPad* pad = canvas->cd(i + 1);
      Var var = veloVars[i];
      if (i < 2) {
        var.logy = true;
      }
      TTree* tree = dynamic_cast<TTree*>(file->Get(var.treeName));

      TH1* hist = draw(tree, var, pad, fileName, first, colourIndex, originalHists);

      if (i == 1 or i == 2) {
        if (first) {
          legends[var.varName] = new TLegend(0.6, 0.7, 0.9, 0.9);
        }
        hist->ResetStats();
        Float_t mean = hist->GetMean();
        legends[var.varName]->AddEntry(hist, Form("#mu = %.2f", mean), "l");

        if (fileName == fileList.back()) {
          legends[var.varName]->Draw();
        }
      }
    }

    std::cout << " complete!" << std::endl;
    std::cout << "Generating occupancy canvas ...";

    std::vector<Var> occupancyVars = {
      Var("n_velo_hits", "data_quality_validation_occupancy/occupancy", 1, 30000),
      Var("n_scifi_hits", "data_quality_validation_occupancy/occupancy", 1, 60000),
      Var("n_scifi_xz_seeds", "data_quality_validation_occupancy/occupancy", 1, 800),
      Var("n_ecal_clusters", "data_quality_validation_occupancy/occupancy", 1, 600),
      Var("n_muon_hits", "data_quality_validation_occupancy/occupancy", 1, 4000),
      Var("n_scifi_hits:n_velo_hits", "data_quality_validation_occupancy/occupancy", 1, 3000, 1, 6000),
    };

    canvas = canvases["occupancyCanvas"];

    for (size_t i = 0; i < occupancyVars.size(); ++i) {
      TVirtualPad* pad = canvas->cd(i + 1);
      Var var = occupancyVars[i];
      TTree* tree = dynamic_cast<TTree*>(file->Get(var.treeName));

      if (i != 5) {
        var.logy = true;
      }
      TH1* hist = draw(tree, var, pad, fileName, first, colourIndex, originalHists);

      if (i < 4) {
        if (first) {
          legends[var.varName] = new TLegend(0.6, 0.7, 0.9, 0.9);
        }
        hist->ResetStats();
        Float_t mean = hist->GetMean();
        legends[var.varName]->AddEntry(hist, Form("#mu = %.2f", mean), "l");

        if (fileName == fileList.back()) {
          legends[var.varName]->Draw();
        }
      }
    }

    std::cout << " complete!" << std::endl;
    std::cout << "Generating PID canvas ...";

    std::vector<Var> PIDVars = {
      Var("prop_muon", "data_quality_validation_matching/long_tracks_event", 0, 0.4),
      Var("prop_electron", "data_quality_validation_matching/long_tracks_event", 0, 0.4),
      Var("prop_muon", "data_quality_validation_matching/long_tracks_event", 0, 0.4),
      Var("prop_electron", "data_quality_validation_matching/long_tracks_event", 0, 0.4),
    };

    canvas = canvases["PIDCanvas"];

    for (size_t i = 0; i < PIDVars.size(); ++i) {
      TVirtualPad* pad = canvas->cd(i + 1);
      Var var = PIDVars[i];
      var.logy = true;
      TTree* tree = dynamic_cast<TTree*>(file->Get(var.treeName));
      TLegend* leg = nullptr;
      leg = new TLegend();
      if (i < 2) {
        leg->SetHeader("Matching", "C");
        var.treeName.ReplaceAll("forward", "matching");
      }
      else {
        leg->SetHeader("Forward", "C");
        var.treeName.ReplaceAll("matching", "forward");
        var.forward = true;
      }
      draw(tree, var, pad, fileName, first, colourIndex, originalHists);
      leg->SetTextColor(2);
      if (fileName == fileList.front()) {
        leg->Draw();
      }
    }

    std::cout << " complete!" << std::endl;
    std::cout << "Generating PID kinematic canvas ...";

    std::vector<Var> PIDkinVars = {Var("qop", "data_quality_validation_matching/long_track_particles", -4e-4, 4e-4),
                                   Var("pt", "data_quality_validation_matching/long_track_particles", 0, 2000),
                                   Var("qop", "data_quality_validation_matching/long_track_particles", -4e-4, 4e-4),
                                   Var("pt", "data_quality_validation_matching/long_track_particles", 0, 2000),
                                   Var("qop", "data_quality_validation_matching/long_track_particles", -4e-4, 4e-4),
                                   Var("pt", "data_quality_validation_matching/long_track_particles", 0, 2000),
                                   Var("qop", "data_quality_validation_matching/long_track_particles", -4e-4, 4e-4),
                                   Var("pt", "data_quality_validation_matching/long_track_particles", 0, 2000)};

    canvas = canvases["PIDkinCanvas"];

    for (size_t i = 0; i < PIDkinVars.size(); ++i) {
      TVirtualPad* pad = canvas->cd(i + 1);
      Var var = PIDkinVars[i];
      TLegend* leg = nullptr;
      leg = new TLegend();
      if (i < 4) {
        leg->SetHeader("Matching", "C");
        var.treeName.ReplaceAll("forward", "matching");
      }
      else {
        leg->SetHeader("Forward", "C");
        var.treeName.ReplaceAll("matching", "forward");
        var.forward = true;
      }
      if (i / 2 % 2 == 0) {
        var.cut = "is_muon==1";
      }
      else {
        var.cut = "is_electron==1";
      }
      TTree* tree = dynamic_cast<TTree*>(file->Get(var.treeName));
      draw(tree, var, pad, fileName, first, colourIndex, originalHists);
      leg->SetTextColor(2);
      if (fileName == fileList.front()) {
        leg->Draw();
      }
    }

    std::cout << " complete!" << std::endl;
    std::cout << "Generating IP canvas (matching)...";

    std::vector<Var> IPVars = {Var("ip_x", "data_quality_validation_matching/long_track_particles", -0.5, 0.5),
                               Var("ip_y", "data_quality_validation_matching/long_track_particles", -0.5, 0.5),
                               Var("ip_chi2", "data_quality_validation_matching/long_track_particles", -1, 1000),
                               Var("chi2", "data_quality_validation_matching/long_track_particles", 0, 100)};
    IPVars[2].logy = true;

    canvas = canvases["IPmatchingCanvas"];

    for (size_t i = 0; i < IPVars.size(); ++i) {
      TVirtualPad* pad = canvas->cd(i + 1);
      Var var = IPVars[i];
      TTree* tree = dynamic_cast<TTree*>(file->Get(var.treeName));

      TH1* hist = draw(tree, var, pad, fileName, first, colourIndex, originalHists);
      if (i < 2) {
        if (first) {
          legends[var.varName + "_matching"] = new TLegend(0.6, 0.7, 0.9, 0.9);
        }
        hist->ResetStats();
        Float_t width = hist->GetRMS();
        legends[var.varName + "_matching"]->AddEntry(hist, Form("#sigma = %.4f", width), "l");

        if (fileName == fileList.back()) {
          legends[var.varName + "_matching"]->Draw();
        }
      }
    }

    std::cout << " complete!" << std::endl;
    std::cout << "Generating IP canvas (forward)...";

    canvas = canvases["IPforwardCanvas"];

    for (size_t i = 0; i < IPVars.size(); ++i) {
      TVirtualPad* pad = canvas->cd(i + 1);
      Var var = IPVars[i];
      var.treeName.ReplaceAll("matching", "forward");
      TTree* tree = dynamic_cast<TTree*>(file->Get(var.treeName));
      var.forward = true;

      TH1* hist = draw(tree, var, pad, fileName, first, colourIndex, originalHists);
      if (i < 2) {
        if (first) {
          legends[var.varName + "_forward"] = new TLegend(0.6, 0.7, 0.9, 0.9);
        }
        hist->ResetStats();
        Float_t width = hist->GetRMS();
        legends[var.varName + "_forward"]->AddEntry(hist, Form("#sigma = %.4f", width), "l");

        if (fileName == fileList.back()) {
          legends[var.varName + "_forward"]->Draw();
        }
      }
    }

    std::cout << " complete!" << std::endl;
    std::cout << "Generating IP resolution canvas ...";

    std::vector<TString> IPresoVars = {"ip_x", "ip_x", "ip_y", "ip_y"};
    std::vector<TString> Trees = {"data_quality_validation_matching/long_track_particles",
                                  "data_quality_validation_forward/long_track_particles",
                                  "data_quality_validation_matching/long_track_particles",
                                  "data_quality_validation_forward/long_track_particles"};

    canvas = canvases["IPresolutionCanvas"];

    for (size_t i = 0; i < IPresoVars.size(); ++i) {
      TVirtualPad* pad = canvas->cd(i + 1);
      TString var = IPresoVars[i];
      TTree* tree = dynamic_cast<TTree*>(file->Get(Trees[i]));

      TLegend* leg = new TLegend();
      const bool forward = Trees[i].Contains("forward");
      if (forward) {
        leg->SetHeader("Forward", "C");
      }
      else {
        leg->SetHeader("Matching", "C");
      }

      makeIPplot(tree, var, pad, fileName, first, colourIndex, originalHists, forward);

      leg->SetTextColor(2);
      if (fileName == fileList.back()) {
        leg->Draw();
      }
    }

    std::cout << " complete!" << std::endl;

    // Add a canvas to show the filename/colour matchup
    if (first) {
      legends["files"] = new TLegend(0, 0, 1, 1);
    }
    canvases["fileCanvas"]->cd();
    TH1* temp = new TH1F(fileName.Data(), "", 1, 0., 1.);
    auto [colour, style] = GetColorAndLineStyle(colourIndex);
    temp->SetLineColor(colour->GetNumber());
    temp->SetLineStyle(style);
    legends["files"]->AddEntry(temp, fileName.Data(), "l");
    if (fileName == fileList.back()) {
      legends["files"]->Draw();
    }

    first = false;
    colourIndex++;
  }

  if (first == false) // if all filenames are invalid, do not print the canvases
  {
    std::cout << "Printing canvases..." << std::endl;
    for (auto& [name, canvas] : canvases) {
      canvas->SaveAs(Form("%s%s.pdf", canvas->GetName(), suffix.Data()));
    }
  }
  return;
}
/*-------------------------------------------------------------------------*/
TH1* draw(
  TTree* tree,
  Var& var,
  TVirtualPad* pad,
  const TString& fileName,
  const bool first,
  const Int_t colourIndex,
  std::map<TVirtualPad*, TH1*>& originalHists)
{
  TH1* hist = nullptr;
  TString name = "";
  if (not(var.ymin == 0 and var.ymax == 0)) {
    TString yVar = var.varName("^.+:");
    yVar.ReplaceAll(":", "");
    TString xVar = var.varName(":.+$");
    xVar.ReplaceAll(":", "");
    // create a unique name to avoid memory leaks
    name = Form(
      "%s_%s%s%s%s_%s",
      var.treeName.Data(),
      var.varName.Data(),
      var.forward ? "_forward" : "_matching",
      var.cut.Data(),
      fileName.Data(),
      pad->GetName());
    name.ReplaceAll("/", "_");

    static bool initColours = false;
    if (not initColours) {
      // Create 2D plot colour table
      // Taken from https://colorbrewer2.org/#type=sequential&scheme=BuPu&n=3 (using just the first 3 colours
      const UInt_t nColors = 3;
      Double_t red[nColors] = {224 / 255., 158 / 255., 136 / 255.};
      Double_t green[nColors] = {236 / 255., 188 / 255., 86 / 255.};
      Double_t blue[nColors] = {244 / 255., 218 / 255., 167 / 255.};
      Double_t length[nColors] = {0., 0.5, 1.};
      const Int_t nb = 10;
      TColor::CreateGradientColorTable(nColors, length, red, green, blue, nb);

      initColours = true;
    }

    hist = new TH2F(
      name.Data(),
      Form(
        "%s;%s%s;%s",
        var.varName.Data(),
        xVar.Data(),
        var.cut.Length() > 0 ? Form(" (%s)", var.cut.Data()) : "",
        yVar.Data()),
      100,
      var.xmin,
      var.xmax,
      100,
      var.ymin,
      var.ymax);
    hist->SetStats(kFALSE);

    tree->Draw(
      Form("%s >> %s", var.varName.Data(), name.Data()), var.cut.Data(), Form("NORM COLZ%s", first ? "" : " SAME"));
  }
  else {
    Int_t nBins = 100;
    if (var.varName.BeginsWith("n_") or var.varName == "nPVs") {
      nBins = var.xmax - var.xmin;
      if (nBins > 200) {
        nBins = 100;
      }
    }
    if (var.varName == "n_velo_tracks") {
      nBins = var.xmax - var.xmin;
    }
    // create a unique name to avoid memory leaks
    name = Form(
      "%s_%s%s%s%s_%s",
      var.treeName.Data(),
      var.varName.Data(),
      var.forward ? "_forward" : "_matching",
      var.cut.Data(),
      fileName.Data(),
      pad->GetName());
    name.ReplaceAll("/", "_");
    hist = new TH1F(
      name.Data(),
      Form(
        "%s;%s%s;Population",
        var.varName.Data(),
        var.varName.Data(),
        var.cut.Length() > 0 ? Form(" (%s)", var.cut.Data()) : ""),
      nBins,
      var.xmin,
      var.xmax);

    tree->Draw(
      Form("%s >> %s", var.varName.Data(), name.Data()), var.cut.Data(), Form("NORM HIST%s", first ? "" : " SAME"));
    // check if the Y axis needs rescaling...
    if (not first) {
      const Double_t yMax = hist->GetBinContent(hist->GetMaximumBin());
      const Double_t factor = var.logy ? 3. : 1.1;
      if (yMax * factor > originalHists[pad]->GetMaximum()) {
        originalHists[pad]->SetMaximum(yMax * factor);
      }
    }
  }
  auto [colour, style] = GetColorAndLineStyle(colourIndex);
  hist->SetLineColor(colour->GetNumber());
  hist->SetLineStyle(style);

  pad->SetLogy(var.logy);
  if (first) {
    originalHists[pad] = hist;
  }
  return hist;
}
/*-------------------------------------------------------------------------*/
void makeIPplot(
  TTree* tree,
  TString var,
  TVirtualPad* pad,
  const TString& fileName,
  const bool first,
  const Int_t colourIndex,
  std::map<TVirtualPad*, TH1*>& originalHists,
  const bool forward)
{
  // These bin edges match the TDR Fig.30
  std::vector<Float_t> pTbinEdges = {0.0f, 0.4f, 0.6f, 0.8f, 1.0f, 1.2f, 1.4f, 1.6f, 1.8f, 2.0f};
  if (forward) {
    pTbinEdges = {0.0f, 0.4f, 0.6f, 0.8f, 1.0f, 1.25f};
  }
  TString name =
    Form("%s_canvas_%s_%s_%s", var.Data(), tree->GetName(), fileName.Data(), forward ? "forward" : "matching");
  name.ReplaceAll("/", "_");
  name.ReplaceAll(".root", "");
  TH1F* IPplot = new TH1F(
    name.Data(),
    Form(";1/p_{T} [c/GeV];IP_{%s} resolution [#mum]", var == "ip_x" ? "x" : "y"),
    pTbinEdges.size() - 1,
    pTbinEdges.data());
  for (size_t i_ptBin = 0; i_ptBin < pTbinEdges.size() - 1; ++i_ptBin) {
    // find the IPs resolutions and fill the IPplot hist
    TH1F IPcalculationHist("IPcalculationHist", "", 60, -0.1, 0.1);

    TCut cut = Form("1000/pt > %f && 1000/pt <= %f", pTbinEdges[i_ptBin], pTbinEdges[i_ptBin + 1]);
    // cut.Print();
    tree->Draw(Form("%s >> IPcalculationHist", var.Data()), cut, "GOFF");
    if (IPcalculationHist.Integral(1, 60) > 0) {
      TFitResultPtr fit = IPcalculationHist.Fit("gaus", "SQ", "", -0.1, 0.1);
      IPplot->SetBinContent(i_ptBin + 1, fit->Value(2) * 1000);
      IPplot->SetBinError(i_ptBin + 1, fit->Error(2) * 1000);
    }
    else {
      IPplot->SetBinContent(i_ptBin + 1, 0.f);
      IPplot->SetBinError(i_ptBin + 1, 0.f);
    }
  }
  if (not first) {
    const Double_t yMax = IPplot->GetBinContent(IPplot->GetMaximumBin());
    const Double_t factor = 1.1;
    if (yMax * factor > originalHists[pad]->GetMaximum()) {
      originalHists[pad]->SetMaximum(yMax * factor);
    }
  }
  auto [colour, style] = GetColorAndLineStyle(colourIndex);
  IPplot->SetLineColor(colour->GetNumber());
  IPplot->SetLineStyle(style);

  if (first) {
    originalHists[pad] = IPplot;
  }
  TString drawOption = Form("%s", first ? "E1" : "SAME");
  IPplot->Draw(drawOption.Data());
  IPplot->SetMarkerStyle(0);
  return;
}
/*-------------------------------------------------------------------------*/
std::pair<TColor*, Int_t> GetColorAndLineStyle(Int_t index)
{
  static map<std::array<Int_t, 3>, TColor*> cache;
  // Generated from https://colorbrewer2.org/#type=qualitative&scheme=Paired&n=12 (with the yellow colour removed and
  // black added) If you have enough colours as to go off the end of the palette, it will loop with different line
  // styles
  const std::vector<std::array<Int_t, 3>> colourPalette = {{0, 0, 0},
                                                           {166, 206, 227},
                                                           {31, 120, 180},
                                                           {178, 223, 138},
                                                           {51, 160, 44},
                                                           {251, 154, 153},
                                                           {227, 26, 28},
                                                           {253, 191, 111},
                                                           {255, 127, 0},
                                                           {202, 178, 214},
                                                           {106, 61, 154},
                                                           {177, 89, 40}};

  const Int_t lineStyle = (index / colourPalette.size()) + 1;
  const Int_t trueIndex = index % colourPalette.size();
  TColor* colour;
  std::array<Int_t, 3> arrayColour = colourPalette[trueIndex];
  try {
    colour = cache.at(arrayColour);
  } catch (std::out_of_range&) {
    Int_t number = TColor::GetFreeColorIndex();
    colour = new TColor(number, arrayColour[0] / 255.f, arrayColour[1] / 255.f, arrayColour[2] / 255.f);
    cache[arrayColour] = colour;
  }
  return std::make_pair(colour, lineStyle);
}

/*-------------------------------------------------------------------------*/
void DataQualityPlot_Overlay()
{
  TString isPYtest = std::getenv("PYTEST_NAME");
  if (isPYtest.Contains("lhcb_ODQV_plot")) {
    DataQualityPlot_Overlay("allen_odqv_pytest.root");
  }
  else {
    std::cerr << "ERROR : Give me a set of files to run over!" << std::endl;
  }
  return;
}
