#!/usr/bin/python

# Script for accessing histograms of reconstructible and
# reconstructed muon ID
#
# The efficency is calculated usig TGraphAsymmErrors
# and Bayesian error bars
#
# author: Dorothea vom Bruch (dorothea.vom.bruch@cern.ch)
# date:   05/2019
#

import os, sys
import argparse
import ROOT
from ROOT import gStyle
from ROOT import gROOT
from ROOT import TStyle
from ROOT import TLegend
from ROOT import gPad
from ROOT import TMultiGraph

sys.path.append('../')
from common.LHCbStyle import *
from common.Legend import *

from common.ConfigHistos import *


def getEfficiencyHistoNames():
    return ["eta", "p", "pt", "phi", "nPV"]


def getMuonCategories():
    return ["matched_isMuon", "not_matched_isMuon"]


def getGhostHistoNames():
    return ["eta", "nPV"]  # currently no eta information available from track
    #return ["nPV"]


def muonCategoryDict():
    basedict = {"matched_isMuon": {}, "not_matched_isMuon": {}}

    basedict["matched_isMuon"]["numerator"] = "matched_isMuon_"
    basedict["matched_isMuon"]["denominator"] = "muon_"
    basedict["matched_isMuon"]["title"] = "Muon ID efficiency"

    basedict["not_matched_isMuon"]["numerator"] = "not_matched_isMuon_"
    basedict["not_matched_isMuon"]["denominator"] = "not_muon_"
    basedict["not_matched_isMuon"]["title"] = "Muon misID efficiency"

    return basedict


f = ROOT.TFile.Open("../../../output/PrCheckerPlots.root", "read")
outputfile = ROOT.TFile(
    "../../../plotsfornote_root/muon_id_efficiency_plots.root", "recreate")

setLHCbStyle()

efficiencyHistoDict = efficiencyHistoDict()
efficiencyHistos = getEfficiencyHistoNames()
ghostHistos = getGhostHistoNames()
ghostHistoDict = ghostHistoDict()
muonCategories = getMuonCategories()
muonCatDict = muonCategoryDict()

outputfile.cd()

for category in muonCategories:

    for histo in efficiencyHistos:
        title = muonCatDict[category]["title"] + " vs. " + histo
        canvas = ROOT.TCanvas(title, title)
        ROOT.gPad.SetTicks()
        numeratorName = "Forward/" + muonCatDict[category][
            "numerator"] + efficiencyHistoDict[histo][
                "variable"] + "_reconstructed"
        print("Opening " + numeratorName)
        numerator = f.Get(numeratorName)
        denominatorName = "Forward/" + muonCatDict[category][
            "denominator"] + efficiencyHistoDict[histo][
                "variable"] + "_reconstructible"
        denominator = f.Get(denominatorName)
        print(numerator.GetEntries())
        print(denominator.GetEntries())
        if numerator.GetEntries() == 0 or denominator.GetEntries() == 0:
            continue

        numerator.Sumw2()
        denominator.Sumw2()

        g_efficiency = ROOT.TGraphAsymmErrors()
        g_efficiency.Divide(numerator, denominator, "cl=0.683 b(1,1) mode")
        # draw them both
        g_efficiency.Draw("ap")
        xtitle = efficiencyHistoDict[histo]["xTitle"]
        g_efficiency.GetXaxis().SetTitle(xtitle)
        g_efficiency.GetYaxis().SetTitle(muonCatDict[category]["title"])
        g_efficiency.GetYaxis().SetRangeUser(0, 1)

        # draw variable distribution in same canvas
        norm = 0.9 / numerator.GetMaximum()
        numerator.Scale(norm)
        numerator.SetTitle( efficiencyHistoDict[histo]["title"]+ " distribution")
        numerator.SetFillColorAlpha(ROOT.kBlack, 0.2)
        numerator.SetLineColor(ROOT.kWhite)
        numerator.Draw("hist bar same")

        place = find_place(canvas, 0)
        legend = TLegend(place[0], place[1], place[2], place[3])
        legend.AddEntry(g_efficiency, muonCatDict[category]["title"], "ep")
        legend.AddEntry(numerator,  efficiencyHistoDict[histo]["title"]+ " distribution","f")
        legend.Draw("same")

        canvas.Write()
        cleantitle = muonCatDict[category]["title"].replace(
                " ", "").replace(",", "_").replace("<", "_")
        canvas.SaveAs("../../../plotsfornote/muonID_isMuon_" + histo + "_"+ cleantitle + ".pdf")

# ghost histos
for histo in ghostHistos:
    title = "muon ID in ghost tracks vs. " + histo
    canvas = ROOT.TCanvas(title, title)
    ROOT.gPad.SetTicks()
    numeratorName = "Forward/ghost_isMuon_" + efficiencyHistoDict[histo]["variable"] + "_reconstructed"
    denominatorName = "Forward/" + histo + "_Ghosts"
    print("Opening " + numeratorName)
    print("Opening " + denominatorName)

    numerator = f.Get(numeratorName)
    denominator = f.Get(denominatorName)
    numerator.Sumw2()
    denominator.Sumw2()

    g_efficiency = ROOT.TGraphAsymmErrors()
    g_efficiency.Divide(numerator, denominator, "cl=0.683 b(1,1) mode")

    xtitle = ghostHistoDict[histo]["xTitle"]
    g_efficiency.GetXaxis().SetTitle(xtitle)
    g_efficiency.GetYaxis().SetTitle("muon ID in ghost tracks")
    g_efficiency.Draw("ap")
    g_efficiency.GetYaxis().SetRangeUser(0, 1)

    # draw variable distribution in same canvas
    norm = 0.9 / numerator.GetMaximum()
    numerator.Scale(norm)
    numerator.SetTitle( efficiencyHistoDict[histo]["title"]+ " distribution")
    numerator.SetFillColorAlpha(ROOT.kBlack, 0.2)
    numerator.SetLineColor(ROOT.kWhite)
    numerator.Draw("hist bar same")

    place = find_place(canvas, 0)
    legend = TLegend(place[0], place[1], place[2], place[3])
    legend.AddEntry(g_efficiency, "muon ID in ghost tracks", "ep")
    legend.AddEntry(numerator,  efficiencyHistoDict[histo]["title"]+ " distribution","f")
    legend.Draw("same")

    canvas.Write()
    canvas.SaveAs("../../../plotsfornote/muonID_isMuon_ghosts_" + histo + ".pdf")

outputfile.Write()
outputfile.Close()
f.Close()
