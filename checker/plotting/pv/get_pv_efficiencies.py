###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
import os, sys
import argparse
import ROOT
from ROOT import gStyle
from ROOT import gROOT
from ROOT import TStyle
from ROOT import TLegend
from ROOT import gPad
from ROOT import TMultiGraph
from ROOT import THStack
from ROOT import TMath

from pv_histos import *

sys.path.append('../')
from common.Legend import *
from common.LHCbStyle import *

setLHCbStyle()
ROOT.gROOT.ForceStyle();

sample = "minbias"
# f = [#ROOT.TFile.Open("../../../output/KstEE/GPU_PVChecker-KstEE.root", "read"),
#     #ROOT.TFile.Open("../../../output/KstMuMu/GPU_PVChecker-KstMuMu.root", "read"),
#     #ROOT.TFile.Open("../../../output/Ds2KKPi/GPU_PVChecker-Ds2KKPi.root", "read"),
#     #ROOT.TFile.Open("../../../output/Bs2PhiPhi/GPU_PVChecker-Bs2PhiPhi.root", "read"),
#     #ROOT.TFile.Open("../../../output/Z2MuMu/GPU_PVChecker-Z2MuMu.root", "read"),
#     ROOT.TFile.Open("../../../output/minbias/GPU_PVChecker-minbias.root", "read"),
# ]
f = [ROOT.TFile.Open("../../../output/GPU_PVChecker.root", "read")]
outputfile = ROOT.TFile("../../../plotsfornote_root/pv_plots" + sample + ".root", "recreate")

efficiencyHistoDict = pvEfficiencyHistoDict()
efficiencyHistos = ["z", "mult"]

for histo in efficiencyHistos:
    title = "efficiency vs. " + histo
    name = "efficiency vs. " + histo
    canvas = ROOT.TCanvas(name, title)
    # get histos
    numeratorName = "eff_matched_" + histo
    denominatorName = "eff_norm_" + histo
    print(denominatorName)
    print(numeratorName)
    numerator = f[0].Get(numeratorName)
    for infile in f[1:]:
        numerator.Add(infile.Get(numeratorName))
    denominator = f[0].Get(denominatorName)
    for infile in f[1:]:
        denominator.Add(infile.Get(denominatorName))
    if numerator.GetEntries() == 0 or denominator.GetEntries() == 0:
        continue

    numerator.Sumw2()
    denominator.Sumw2()

    g_efficiency = ROOT.TGraphAsymmErrors()
    g_efficiency.Divide(numerator, denominator, "cl=0.683 b(1,1) mode")

    g_efficiency.GetYaxis().SetRangeUser(0,1.05)
    g_efficiency.GetYaxis().SetTitle("efficiency")
    g_efficiency.GetXaxis().SetTitle(efficiencyHistoDict[histo]["xTitle"])

    g_efficiency.Draw("ap")

    # Draw variable distribution in same canvas
    norm = 0.9 / denominator.GetMaximum()
    denominator.Scale(norm)
    denominator.SetTitle(efficiencyHistoDict[histo]["title"] + " distribution")
    denominator.SetLineColor(ROOT.kWhite)
    denominator.SetFillColorAlpha(ROOT.kBlack, 0.2)
    denominator.Draw("hist bar same")

    # Add legend
    place = find_place(canvas, 3)
    legend = TLegend(place[0], place[1], place[2], place[3])
    legend.AddEntry(g_efficiency, "efficiency", "ep")
    legend.AddEntry(denominator, efficiencyHistoDict[histo]["title"] + " distribution", "f")
    legend.SetFillColorAlpha(ROOT.kWhite, 0.)
    legend.SetTextSize(0.06)
    legend.Draw("same")

    # Draw second y axis
    low = 0
    high = 1.05
    axis = ROOT.TGaxis(gPad.GetUxmax(), gPad.GetUymin(),gPad.GetUxmax(),gPad.GetUymax(),low,high,510,"+L")
    axis.SetTitleFont(132)
    axis.SetTitleSize(0.06)
    axis.SetTitleOffset(0.55)
    axis.SetTitle("Number of events [a.u.]")
    axis.SetLabelSize(0)
    axis.Draw()
    
    # Save plots
    canvas.SaveAs("../../../plotsfornote/pv_reco_eff_" + histo + "_" + sample + ".pdf")
    canvas.Write()

outputfile.Write()
outputfile.Close()
for infile in f:
    infile.Close()
