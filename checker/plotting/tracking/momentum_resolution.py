#!/usr/bin/python

# Script for obtaining the momentum resolution versus momentum
# from a 2D histogram of dp versus p
#
# author: Dorothea vom Bruch (dorothea.vom.bruch@cern.ch)
# date:   12/2018
#

import os, sys
import argparse
import ROOT
from ROOT import gStyle
from ROOT import gROOT
from ROOT import TStyle
from ROOT import gPad
from ROOT import TGraphErrors
from array import array
from ROOT import TMath
from ROOT import TLegend
from ROOT import TGraph
from ROOT import TMultiGraph


sys.path.append('../')
from common.LHCbStyle import *
from common.Legend import *

def getHistos():
    basedict = {
        "p": {},
        "qop": {},
    }

    basedict["p"]["name"] = "momentum_resolution_vs_p_gauss"
    basedict["p"]["title"] = "momentum resolution vs p, Gaussian fit"
    basedict["p"]["x_axis_title"] = "p [MeV/c]"
    basedict["p"]["y_axis_title"] = "#sigma_{p}/p [%]"
    basedict["p"]["graph_name"] = "p resolution"
    basedict["p"]["distro_name"] = "p distribution"

    basedict["qop"]["name"] = "qop_resolution_vs_qop_gauss"
    basedict["qop"]["title"] = "q/p resolution vs q/p, Gaussian fit"
    basedict["qop"]["x_axis_title"] = "q/p [c/MeV]"
    basedict["qop"]["y_axis_title"] = "#sigma_{q/p}/(q/p)"
    basedict["qop"]["graph_name"] = "q/p resolution"
    basedict["qop"]["distro_name"] = "q/p distribution"

    return basedict


def getTrackers():
    return ["Upstream", "Forward"]


def getResolutionInSlices(histo2D, var, var_dict):
    # fit slices
    n = 0
    xFit, yFit = array('d'), array('d')
    xFitErr, yFitErr = array('d'), array('d')
    rms, rmsErr = array('d'), array('d')
    nBinsX = histo2D.GetNbinsX()
    xAxis = histo2D.GetXaxis()
    for i in range(nBinsX+1):
        histo1D = histo2D.ProjectionY("_py", i, i, "")
        if histo1D.GetEntries() >= 100:
            # fit Gaussian
            if tracker == "Forward":
                g1 = ROOT.TF1("g1", "gaus", -0.05, 0.05)
            elif tracker == "Upstream":
                g1 = ROOT.TF1("g1", "gaus", -0.5, 0.5)
            #histo1D.GetYaxis().SetTitle("Entries")
            #histo1D.GetXaxis().SetTitle("Resolution (%/100)")
            histo1D.Fit(g1, "R")
            histo1D.Write()
            p = xAxis.GetBinCenter(i)
            lowEdge = xAxis.GetBinLowEdge(i)
            upEdge = xAxis.GetBinUpEdge(i)
            width = upEdge - lowEdge
            xFit.append(p)
            sigma_p = histo1D.GetFunction("g1").GetParameter(2)
            yFit.append(sigma_p*100)
            xFitErr.append(width/2)
            delta_sigma_p = histo1D.GetFunction("g1").GetParError(2)
            yFitErr.append(delta_sigma_p*100)

            # get RMS of histogram
            rms.append(histo1D.GetRMS())
            rmsErr.append(histo1D.GetRMSError())

            n += 1

    if n == 0:
        return

    name = var_dict[var]["name"]
    title = var_dict[var]["title"]
    canvas = ROOT.TCanvas(name, title)
    canvas.cd()
    print('{:s}: n = {:d}: '.format(tracker, n))
    gr = TGraphErrors(n, xFit, yFit, xFitErr, yFitErr)
    #gr.Draw("ap")

    name = tracker + name
    x_axis_title = var_dict[var]["x_axis_title"]
    y_axis_title = var_dict[var]["y_axis_title"]
    gr.GetXaxis().SetTitle(x_axis_title)
    gr.GetYaxis().SetTitle(y_axis_title)
    gr.SetTitle("")
    gr.SetName(name)

    #name = "dp_vs_p_rms"
    #title = "dp vs p, histogram RMS"
    #canvas = ROOT.TCanvas(name, title)
    #gr = TGraphErrors( n, xFit, rms, xFitErr, rmsErr )
    #gr.Draw("ap")

    # overall momentum resolution
    histo1D = histo2D.ProjectionX("_px")

    # plot distribution in same canvas
    max_y = TMath.MaxElement(gr.GetN(), gr.GetY())
    max_index = TMath.LocMax(gr.GetN(), gr.GetY())
    max_y_error = gr.GetErrorY(max_index)
    norm = max_y / histo1D.GetMaximum()
    histo1D.Scale(norm)
    histo1D.Write()
    n_bins = histo1D.GetXaxis().GetNbins()
    histo1D.SetFillColorAlpha(ROOT.kBlack, 0.2)
    histo1D.SetLineColor(ROOT.kWhite)
    histo1D.GetYaxis().SetRangeUser(0, max_y+2*max_y_error)
    histo1D.GetXaxis().SetTitle(x_axis_title)
    histo1D.GetYaxis().SetTitle(y_axis_title)
    histo1D.GetYaxis().SetTitleOffset(0.8)
    histo1D.Draw("hist bar")
    gr.Draw("p same")

    place = find_place(canvas, 4)
    legend = TLegend(place[0], place[1], place[2], place[3])
    legend.AddEntry(gr, var_dict[var]["graph_name"], "ep")
    legend.AddEntry(histo1D, var_dict[var]["distro_name"], "f")
    legend.SetFillColorAlpha(ROOT.kWhite, 0.)
    legend.SetTextSize(0.06)
    legend.Draw("same")

    # Draw second y axis
    low = 0
    high = 1.1 * histo1D.GetYaxis().GetXmax() #1.2*max_y
    axis = ROOT.TGaxis(gPad.GetUxmax(), gPad.GetUymin(),gPad.GetUxmax(),gPad.GetUymax(),low,high,510,"+L")
    axis.SetTitleFont(132)
    axis.SetTitleSize(0.06)
    axis.SetTitleOffset(0.55)
    axis.SetTitle("Number of events [a.u.]")
    axis.SetLabelSize(0)
    axis.SetNdivisions(1)
    axis.Draw()
    
    # Save plots
    canvas.Write()
    canvas.SaveAs("../../../plotsfornote/" + tracker + "MomResVs" + var +
                  ".pdf")

    histo1D.Fit("gaus")
    sigma_p = histo1D.GetFunction("gaus").GetParameter(2)
    delta_sigma_p = histo1D.GetFunction("gaus").GetParError(2)
    print('{:s}: sigma p = {:f} +/- {:f}'.format(tracker, sigma_p,
                                                 delta_sigma_p))



outputfile = ROOT.TFile("../../../plotsfornote_root/momentum_resolution.root",
                        "recreate")

# f = [ROOT.TFile.Open("../../../output/KstEE/PrCheckerPLots-KstEE.root", "read"),
#      ROOT.TFile.Open("../../../output/KstMuMu/PrCheckerPLots-KstMuMu.root", "read"),
#      ROOT.TFile.Open("../../../output/Ds2KKPi/PrCheckerPLots-Ds2KKPi.root", "read"),
#      #ROOT.TFile.Open("../../../output/minbias/PrCheckerPLots-minbias.root", "read"),
#      ROOT.TFile.Open("../../../output/Bs2PhiPhi/PrCheckerPLots-Bs2PhiPhi.root", "read"),
#      ROOT.TFile.Open("../../../output/Z2MuMu/PrCheckerPLots-Z2MuMu.root", "read"),
# ]
f = [ROOT.TFile.Open("../../../output/PrCheckerPlots.root", "read")]

setLHCbStyle()
ROOT.gROOT.ForceStyle();

trackers = getTrackers()
var_dict = getHistos()

for tracker in trackers:
    outputfile.cd()
    trackerDir = outputfile.mkdir(tracker)
    trackerDir.cd()

    # momentum resolution
    name = tracker + "/momentum_resolution"
    histo2D = f[0].Get(name)
    for infile in f[1:]:
        histo2D.Add(infile.Get(name))

    getResolutionInSlices(histo2D, "p", var_dict)

    # qop resolution
    name = tracker + "/qop_resolution"
    histo2D = f[0].Get(name)
    for infile in f[1:]:
        histo2D.Add(infile.Get(name))

    getResolutionInSlices(histo2D, "qop", var_dict)

outputfile.Write()
outputfile.Close()
f[0].Close()
for infile in f:
    infile.Close()
