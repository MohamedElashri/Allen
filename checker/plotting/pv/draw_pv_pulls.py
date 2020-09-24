#!/usr/bin/python
###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################



import os, sys
import argparse
import ROOT
from ROOT import gStyle
from ROOT import gROOT
from ROOT import TStyle
from ROOT import gPad
from ROOT import TPaveText


sys.path.append('../')
from common.LHCbStyle import *
from common.Legend import *
from common.ConfigHistos import *

f = ROOT.TFile.Open("../../../output/GPU_PVChecker.root", "read")
t = f.Get("PV_tree")

setLHCbStyle()

xrange = 5.
pvcanv = {}
pvtext = {}
func = {}

reshist = {}
for coord in ["x", "y", "z"]:
    reshist[coord] = ROOT.TH1F("pullhist" + coord, "pullhist" + coord, 50, -1. * xrange, xrange)

for entry in range(t.GetEntries()):
    t.GetEntry(entry)
    for coord in ["x", "y", "z"]:
        reshist[coord].Fill(t.__getattr__("diff_" + coord) / t.__getattr__("err_" + coord))

if not os.path.isdir("../../../plotsfornote"):
  os.mkdir("../../../plotsfornote")


for coord in ["x", "y", "z"]:
    pvcanv[coord] = ROOT.TCanvas("pvcanv" + coord, "pvcanv" + coord, 900, 800)
    pvcanv[coord].SetLeftMargin(0.2)
    pvcanv[coord].SetBottomMargin(0.2)
    pvcanv[coord].cd(1)
    func[coord] = ROOT.TF1("gausx", "gaus(0)", -1. * xrange, xrange)
    reshist[coord].Fit(func[coord])        
    reshist[coord].GetXaxis().SetTitle("#frac{#delta_{"+coord+"}}{#sigma_{"+coord+"}}" )
    reshist[coord].GetYaxis().SetTitle("Entries")
    reshist[coord].GetYaxis().SetTitleOffset(1.2)
    reshist[coord].GetXaxis().SetTitleOffset(1.)
    reshist[coord].Draw()
    func[coord].SetLineColor(ROOT.kRed)
    func[coord].Draw("SAME")
    pvtext[coord] = pavetext = TPaveText(0.75,0.8,0.85,0.9, "NDCNB") 
    pvtext[coord].SetTextSize(0.05)
    pvtext[coord].AddText("mean: " + '{:3.3f}'.format(func[coord].GetParameter(1)))
    pvtext[coord].AddText("sigma: " + '{:3.3f}'.format(func[coord].GetParameter(2)))
    pvtext[coord].SetFillColor(0)
    pvtext[coord].Draw("")
    pvcanv[coord].SaveAs("../../../plotsfornote/PVPull_" + coord + ".pdf")
