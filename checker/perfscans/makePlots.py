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
        scans[thisscan][var].append(entry.lstrip(thisscan+'-'+var+'-').rstrip('-'+physperfsuffix))
    scans[thisscan][var].sort()

# What are we actually going to plot?
scanstoplot = ["VELO"]

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
    tpthistos[thisscan][var].SetMarkerStyle(24)
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
                   "VELO"       : { "start" : "Checking GPU Velo tracks",
                                    "end"   : "Checking GPU beamline PVs",
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
                   "PV"         : {
                                  },
                   "CompassUT"  : {
                                  },
                   "SciFi"      : {
                                  }
                 }
