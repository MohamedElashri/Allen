###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
import os, sys
import ROOT
import numpy as np
from array import array

sys.path.append('../')
from common.LHCbStyle import *
setLHCbStyle()

edges = np.array([0.0, 0.4, 0.6, 0.8, 1.0, 1.2, 1.4, 1.6, 1.8, 2.0])
bins = zip(edges[:-1], edges[1:])
centers = array('d', 0.5 * (edges[:-1] + edges[1:]))
# Dumb hack to not draw x "errors".
widths = array('d', 0. * (edges[1:] - edges[:-1]))


def ipRes3D(tree, var, ptBin):
    th1 = ROOT.TH1F('h', 'h', 100, 0, 0.1)
    tree.Draw(
        var + '>>h',
        'ghost==0 && 1000./best_pt>={} && 1000./best_pt<{}'.format(
            ptBin[0], ptBin[1]), 'goff')
    return th1.GetMean(), th1.GetStdDev() / np.sqrt(th1.Integral())


def ipResFit(tree, var, ptBin):
    th1 = ROOT.TH1F('h', 'h', 100, -0.1, 0.1)
    tree.Draw(
        var + '>>h',
        'ghost==0 && 1000./best_pt>={} && 1000./best_pt<{}'.format(
            ptBin[0], ptBin[1]), 'goff')
    f = ROOT.TF1('f', 'gaus', -0.1, 0.1)
    th1.Fit(f, 'R')
    return th1.GetFunction('f').GetParameter(2), th1.GetFunction(
        'f').GetParError(2)


def makeGraph(tree, var, resFunc):
    res = np.array([resFunc(tree, var, ptBin) for ptBin in bins])
    g = ROOT.TGraphErrors(
        len(centers), centers, array('d', 1000. * res[:, 0]), widths,
        array('d', 1000. * res[:, 1]))
    g.SetName(var + '_resolution')
    return g


if __name__ == '__main__':
    fNameSimple = sys.argv[1]
    fNameFull = sys.argv[2]
    if len(sys.argv) < 3:
        print "Need a simple kalman file and a full kalman file!"
    inFileSimple = ROOT.TFile(fNameSimple)
    inFileFull = ROOT.TFile(fNameFull)
    simpleTree = inFileSimple.Get('kalman_ip_tree')
    fullTree = inFileFull.Get('kalman_ip_tree')
    plotInfo = [('ipx', 'kalman_ipx', 'velo_ipx', ipResFit, 'IP_{#it{x}}'),
                ('ipy', 'kalman_ipy', 'velo_ipy', ipResFit, 'IP_{#it{y}}'),
                ('ip3d', 'kalman_ip', 'velo_ip', ipRes3D, 'IP_{3D}')]
    c1 = ROOT.TCanvas('c1', 'c1')
    latex = ROOT.TLatex()
    for info in plotInfo:
        gSimple = makeGraph(simpleTree, info[1], info[3])
        gFull = makeGraph(fullTree, info[1], info[3])
        gFull.SetLineColor(ROOT.kBlack)
        gFull.SetMarkerColor(ROOT.kBlack)
        gSimple.SetLineColor(ROOT.kBlue + 1)
        gSimple.SetMarkerColor(ROOT.kBlue + 1)
        mg = ROOT.TMultiGraph()
        mg.Add(gFull)
        mg.Add(gSimple)
        mg.Draw('ap')
        mg.GetHistogram().GetXaxis().SetTitle('1/#it{p}_{T} [#it{c}/GeV]')
        mg.GetHistogram().GetYaxis().SetTitle(info[4] + ' resolution [#mum]')
        mg.GetHistogram().GetXaxis().SetRangeUser(edges[0], edges[-1])
        mg.GetHistogram().GetYaxis().SetRangeUser(0, 50)
        legend = ROOT.TLegend(0.55, 0.37, 0.95, 0.17)
        legend.AddEntry(gFull, 'Full Kalman', 'lp')
        legend.AddEntry(gSimple, 'Simple Kalman', 'lp')
        legend.SetFillStyle(0)
        legend.Draw('same')
        c1.SaveAs('../../../plotsfornote/' + info[0] +
                  '_resolution_simple.pdf')
