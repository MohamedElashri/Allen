#!/usr/bin/python
###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################

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
# hist_z_iso = f.Get("eff_vs_z_iso")
# hist_z_close = f.Get("eff_vs_z_close")
hist_mult = f.Get("eff_vs_mult")



hist_z.GetXaxis().SetTitle("z position of MC PV [mm]")
hist_z.GetYaxis().SetTitle("Reconstruction Eff (%/100)")

# hist_z_iso.GetXaxis().SetTitle("z position of isolated MC PV [mm]")
# hist_z_iso.GetYaxis().SetTitle("Reconstruction Eff (%/100)")

# hist_z_close.GetXaxis().SetTitle("z position of close MC PV [mm]")
# hist_z_close.GetYaxis().SetTitle("Reconstruction Eff (%/100)")

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


# canvas.cd(1)
# hist_z_iso.SetLineColor(1)
# hist_z_iso.Draw()

# canvas.cd(2)
# hist_z_close.SetLineColor(1)
# hist_z_close.Draw()
# canvas.SaveAs("../../../plotsfornote/PVEfficiencies_isoclose.pdf")


# hist_norm = f.Get("eff_norm")
# hist_norm_iso = f.Get("eff_norm_iso")
# hist_norm_close = f.Get("eff_norm_close")

# hist_norm_iso.Divide(hist_norm)
# hist_norm_close.Divide(hist_norm)

# canvas.cd(1)
# hist_norm_iso.SetLineColor(1)
# hist_norm_iso.GetXaxis().SetTitle("z position [mm]")
# hist_norm_iso.GetYaxis().SetTitle("Fraction of isolated MC PVs")
# hist_norm_iso.Draw()
# canvas.cd(2)
# hist_norm_close.SetLineColor(1)
# hist_norm_close.GetXaxis().SetTitle("z position [mm]")
# hist_norm_close.GetYaxis().SetTitle("Fraction of close MC PVs")
# hist_norm_close.Draw()
# canvas.SaveAs("../../../plotsfornote/PVEfficiencies_fraction.pdf")
