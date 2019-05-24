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

sys.path.append('../')
from common.LHCbStyle import *
from common.Legend import *

from common.ConfigHistos import *
setLHCbStyle()

f = ROOT.TFile.Open("../../../output/GPU_PVChecker.root", "read")
hist_z = f.Get("eff_vs_z")
hist_mult = f.Get("eff_vs_mult")



hist_z.GetXaxis().SetTitle("z position of MC PV [mm]")
hist_z.GetYaxis().SetTitle("Reconstruction Eff (%/100)")

hist_mult.GetXaxis().SetTitle("track multiplicity of MC PV")
hist_mult.GetYaxis().SetTitle("Reconstruction Eff (%/100)")

canvas = ROOT.TCanvas("canvas", "canvas", 1000, 400)
canvas.Divide(2)

canvas.cd(1)
hist_z.SetLineColor(1)
hist_z.Draw()
canvas.cd(2)
hist_mult.SetLineColor(1)
hist_mult.Draw()


if not os.path.isdir("../../../plotsfornote"):
  os.mkdir("../../../plotsfornote")
canvas.SaveAs("../../../plotsfornote/PVEfficiencies.pdf")
