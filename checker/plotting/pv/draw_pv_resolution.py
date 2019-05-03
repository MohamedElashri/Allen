#!/usr/bin/python

# Draw PV resolution as a function of number of tracks in PV
# author: Vladimir Gligorov (vladimir.gligorov@cern.ch)
# date:   02/2019
#

import os, sys
import argparse
import ROOT
from ROOT import gStyle
from ROOT import gROOT
from ROOT import TStyle
from ROOT import gPad

sys.path.append('../../')
from plotting.LHCbStyle import *
from plotting.Legend import *

from ConfigHistos import *

f = ROOT.TFile.Open("../../../output/GPU_PVChecker.root", "read")
t = f.Get("PV_tree")

setLHCbStyle()

ranges = {"x": 100., "y": 100., "z": 1000.}
pvcanv = {}

reshist = {}
for coord in ["x", "y", "z"]:
    reshist[coord] = ROOT.TH2F("reshist" + coord, "reshist" + coord, 15, 0,
                               150, 20, -1. * ranges[coord], ranges[coord])

for entry in range(t.GetEntries()):
    t.GetEntry(entry)
    for coord in ["x", "y", "z"]:
        reshist[coord].Fill(t.ntrinmcpv,
                            1000. * t.__getattr__("diff_" + coord))

if not os.path.isdir("../../../plotsfornote"):
  os.mkdir("../../../plotsfornote")

arr = ROOT.TObjArray()
for coord in ["x", "y", "z"]:
    pvcanv[coord] = ROOT.TCanvas("pvcanv" + coord, "pvcanv" + coord, 900, 800)
    pvcanv[coord].cd(1)
    reshist[coord].FitSlicesY(
        ROOT.TF1("gausx", "gaus(0)", -1. * ranges[coord], ranges[coord]), 0,
        -1, 0, "QNR", arr)
    arr[2].GetXaxis().SetTitle("Number of tracks in MC PV")
    arr[2].GetYaxis().SetTitle("Resolution (#mum)")
    arr[2].GetYaxis().SetTitleOffset(0.95)
    arr[2].DrawCopy()
    pvcanv[coord].SaveAs("../../../plotsfornote/PVRes_" + coord + "_VsNTr.pdf")
