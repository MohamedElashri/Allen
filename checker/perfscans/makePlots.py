import os,sys,fnmatch
import ROOT
from ROOT import *

scans = { "VELO"      : {
                         "max_scatter_seeding" : [],
                         "max_scatter_forwarding" : [],
                         "phi_extrapolation_base" : [],
                         "phi_extrapolation_coef" : []
                        },
          "PV"        : {
                         "zmin" : [],
                         "zmax" : [],
                         "maxChi2" : [],
                         "minTracksInSeed" : []
                        },
          "CompassUT" : {
                         "max_considered_before_found" : [],
                         "minPT" : [],
                         "minPTFinal" : [],
                         "minMomentum" : [],
                         "minMomentumFinal" : [],
                         "yTol" : []
                        },
          "SciFi"     : {
                         "maximum_number_of_candidates_per_ut_track" : [],
                         "maximum_number_of_candidates_per_ut_track_after_x_filter" : [],
                         "track_min_quality" : []
                        }
        }

physperfsuffix = "scan.stdout"
throughputsuffix = "tptscan.stdout"

resultsdir = "../../output/perfscans/"

# Get what parameter values we scaned over without having to hardcode it
files = os.listdir(resultsdir)
for thisscan in scans :
  for var in scans[thisscan] : 
    pattern = thisscan+'-'+var+'-*-'+physperfsuffix
    for entry in files:  
      if fnmatch.fnmatch(entry, pattern):
        scans[thisscan][var].append(entry.lstrip(thisscan).lstrip('-').lstrip(var)[1:].rstrip('-'+physperfsuffix))
    scans[thisscan][var].sort()

# What are we actually going to plot?
scanstoplot = ["VELO","PV","CompassUT","SciFi"]

tpthistos = {}
# Throughput plots are one number so do them first
canvtoploton = TCanvas("tptcanv","tptcanv",1000,800)
for thisscan in scanstoplot :
  tpthistos[thisscan] = {}
  for var in scans[thisscan] :
    tpthistos[thisscan][var] = TH1F(thisscan+var+"tphist",
                                    thisscan+var+"tphist",
                                    100,
                                    float(scans[thisscan][var][0])/1.1,
                                    float(scans[thisscan][var][-1])*1.1)
    tpthistos[thisscan][var].SetMarkerStyle(20)
    tpthistos[thisscan][var].SetMarkerSize(1.6)
    tpthistos[thisscan][var].GetYaxis().SetTitle("Throughput on V100 (kHz)")
    tpthistos[thisscan][var].GetYaxis().SetTitleOffset(0.9)
    tpthistos[thisscan][var].GetXaxis().SetTitle(var)
    tpthistos[thisscan][var].GetXaxis().SetTitleSize(0.05)
    tpthistos[thisscan][var].GetXaxis().SetTitleOffset(1.1)
    for scanpoint in scans[thisscan][var] :
      thistpfile = open(resultsdir+thisscan+'-'+var+'-'+scanpoint+'-'+throughputsuffix)
      for line in thistpfile :
        if line.find('events/s') > -1 :
          tpthistos[thisscan][var].Fill(float(scanpoint),float(line.split()[0])) 

    for thisbin in range(100):
      tpthistos[thisscan][var].SetBinError(thisbin,0)
    canvtoploton.cd()
    tpthistos[thisscan][var].Draw("P")
    tpthistos[thisscan][var].GetYaxis().SetRangeUser(0,100000)
    canvtoploton.SaveAs(resultsdir+thisscan+'-'+var+'-tptscan.pdf')

physperfhistos = {}
# The physics performance histos are a bit more complex to define
physperftoplot = { 
                   "VELO"       : { "end"   : "Checking GPU beamline PVs",
                                    "cats"  : ["ghosts",
                                               "Not electron long eta25 p<5GeV",
                                               "Not electron long eta25 p>5GeV",
                                               "Not electron long strange eta25 p<5GeV",
                                               "Not electron long strange eta25 p>5GeV",
                                               "Electrons long eta25 p<5GeV",
                                               "Electrons long eta25 p>5GeV",
                                               "Electrons long strange eta25 p<5GeV",
                                               "Electrons long strange eta25 p>5GeV"]
                                  },
                   "PV"         : { "end"   : "Checking Velo+UT tracks",
                                    "cats"  : ["All","Isolated","Close","False"]
                                  },
                   "CompassUT"  : { "end"   : "Checking SciFi tracks",
                                    "cats"  : ["ghosts",
                                               "Velo+UT, not long, p > 5 GeV",
                                               "Long, p > 5 GeV",
                                               "Long from B, p > 5 GeV", 
                                               "Long from B electrons, p > 5 GeV",
                                               "Long from B, p > 3 GeV, pt > 0.5 GeV"]
                                  },
                   "SciFi"      : { "end"   : "Producing Kalman plots",
                                    "cats"  : ["ghosts",
                                               "Long, p > 5 GeV",
                                               "Long strange, p > 5 GeV",
                                               "Long from B, p > 5 GeV", 
                                               "Long electrons from B, p > 5 GeV",
                                               "Long from B, p > 3 GeV, pt > 0.5 GeV"]

                                  }
                 }
ordertoread = ["VELO","PV","CompassUT","SciFi"]
# First a loop to set up all the histos
for thisscan in scanstoplot :
  physperfhistos[thisscan] = {}
  for var in scans[thisscan] : 
    physperfhistos[thisscan][var] = {}
    for ppgroup in ordertoread :
      for ppcat in physperftoplot[ppgroup]["cats"] :
        physperfhistos[thisscan][var][ppgroup+ppcat] = TH1F(thisscan+var+ppgroup+ppcat+"pphist",
                                                            thisscan+var+ppgroup+ppcat+"pphist",
                                                            100,
                                                            float(scans[thisscan][var][0])/1.05,
                                                            float(scans[thisscan][var][-1])*1.05)
        physperfhistos[thisscan][var][ppgroup+ppcat].SetMarkerStyle(24)
        physperfhistos[thisscan][var][ppgroup+ppcat].SetMarkerSize(1.6)
        physperfhistos[thisscan][var][ppgroup+ppcat].GetYaxis().SetTitle("Efficiency (%)")
        physperfhistos[thisscan][var][ppgroup+ppcat].GetYaxis().SetTitleOffset(0.9)
        physperfhistos[thisscan][var][ppgroup+ppcat].GetXaxis().SetTitle(var)
        physperfhistos[thisscan][var][ppgroup+ppcat].GetXaxis().SetTitleSize(0.05)
        physperfhistos[thisscan][var][ppgroup+ppcat].GetXaxis().SetTitleOffset(1.1)
 
#Now a loop to fill them
for thisscan in scanstoplot :  
  for var in scans[thisscan] : 
    for scanpoint in scans[thisscan][var] :
      thisppfile = open(resultsdir+thisscan+'-'+var+'-'+scanpoint+'-'+physperfsuffix)
      for ppgroup in ordertoread :
        for line in thisppfile :
          if line.find(physperftoplot[ppgroup]['end']) > -1 : 
            break
          for ppcat in physperftoplot[ppgroup]["cats"] :
            effval = 0.
            if line.find(ppcat) > -1 :
              if ppcat == "ghosts" :
                if line.find('TrackChecker output') == -1 :
                  continue
              if ppgroup == "PV" :
                effval = 100.*float(line.split(":")[1].split('(')[0])
              else :
                if ppcat == "ghosts" :
                  effval = float(line.split(':')[1].split()[2].rstrip('%'))
                else :
                  effval = float(line.split(':')[1].split('(')[0].split()[2].rstrip('%'))
              physperfhistos[thisscan][var][ppgroup+ppcat].Fill(float(scanpoint),effval) 

# Set errors to 0
for thisscan in scanstoplot :  
  for var in scans[thisscan] : 
    for ppgroup in ordertoread :
      for ppcat in physperftoplot[ppgroup]["cats"] :
        for thisbin in range(100):
          physperfhistos[thisscan][var][ppgroup+ppcat].SetBinError(thisbin,0)

# Now plot them
canvtoploton = TCanvas("ppcanv","ppcanv",1000,800)
legcanv = TCanvas("legcanv","legcanv",1000,800)
legend = TLegend(0.1,0.1,0.9,0.9)
legend.SetMargin(0.1)
legendpv = TLegend(0.35,0.25,0.65,0.75)
legendpv.SetMargin(0.2)
for thisscan in scanstoplot :  
  for var in scans[thisscan] : 
    for ppgroup in ordertoread :   
      legend.Clear()
      firstcat = True
      canvtoploton.cd()
      for col,ppcat in enumerate(physperftoplot[ppgroup]["cats"]) : 
        physperfhistos[thisscan][var][ppgroup+ppcat].SetLineColor(col+1)
        physperfhistos[thisscan][var][ppgroup+ppcat].SetMarkerColor(col+1)   
        physperfhistos[thisscan][var][ppgroup+ppcat].SetMarkerStyle(26-col)     
        if firstcat :
          physperfhistos[thisscan][var][ppgroup+ppcat].Draw("P") 
          physperfhistos[thisscan][var][ppgroup+ppcat].GetYaxis().SetRangeUser(0,100)
          firstcat = False
        else :
          physperfhistos[thisscan][var][ppgroup+ppcat].Draw("PSAME")
        if ppgroup == "PV" :         
          legendpv.AddEntry(physperfhistos[thisscan][var][ppgroup+ppcat],ppcat,"p")
        else :
          legend.AddEntry(physperfhistos[thisscan][var][ppgroup+ppcat],ppcat,"p")
      canvtoploton.SaveAs(resultsdir+thisscan+'-'+var+'-'+ppgroup+'-ppscan.pdf')
      legcanv.cd()
      if ppgroup == "PV" :
        legendpv.Draw()
      else :
        legend.Draw()
      legcanv.SaveAs(resultsdir+thisscan+'-'+var+'-'+ppgroup+'-legend.pdf')
