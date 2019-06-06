import os, sys
import ROOT

sys.path.append('../')
from common.LHCbStyle import *
setLHCbStyle()

if __name__ == '__main__':
    c1 = ROOT.TCanvas('c1', 'c1')
    fNameSimple = sys.argv[1]
    fNameFull = sys.argv[2]
    if len(sys.argv < 3):
        print "Need a simple kalman file and a full kalman file!"
    simpleFile = ROOT.TFile(fNameSimple)
    fullFile = ROOT.TFile(fNameFull)
    simpleTree = simpleFile.Get('kalman_ip_tree')
    fullTree = fullFile.Get('kalman_ip_tree')
    velo = ROOT.TH1F('velo','velo',25,0,25)
    full = ROOT.TH1F('full','full',25,0,25)
    simple = ROOT.TH1F('simple','simple',25,0,25)
    fullTree.Draw('kalman_ip_chi2>>full','ghost==0','goff')
    fullTree.Draw('velo_ip_chi2>>velo','ghost==0','goff')
    simpleTree.Draw('kalman_ip_chi2>>simple','ghost==0','goff')
    velo.SetLineColor(ROOT.kBlack)
    velo.SetMarkerColor(ROOT.kBlack)
    full.SetLineColor(ROOT.kCyan+2)
    full.SetMarkerColor(ROOT.kCyan+2)
    simple.SetLineColor(ROOT.kOrange+2)
    simple.SetMarkerColor(ROOT.kOrange+2)
    velo.Draw('E')
    full.Draw('E same')
    simple.Draw('E same')
    legend = ROOT.TLegend(0.55, 0.92, 0.95, 0.72)
    legend.AddEntry(velo, 'VELO only', 'lp')
    legend.AddEntry(full, 'Full Kalman', 'lp')
    legend.AddEntry(simple, 'Simple Kalman', 'lp')
    legend.SetFillStyle(0)
    legend.Draw('same')
    velo.GetXaxis().SetTitle('IP #chi^{2}')
    c1.SetLogy(True)
    c1.SaveAs('../../../plotsfornote/kalman_ip_chi2_simple.pdf')
