Measure performance
=====================
Both the throughput and the physics performance are monitored over time automatically with the two following tools:

* |throughput_link|
* |dashboard_link|

.. |throughput_link| raw:: html

   <a href="https://lbgrafana.cern.ch/d/Qvm54N3Mz/allen-performance?orgId=1" target="_blank">Allen throughput evolution over time in grafana</a>

.. |dashboard_link| raw:: html

   <a href="https://lblhcbpr.cern.ch/dashboards/allen" target="_blank">Allen dashboard with physics performance over time</a>

Processing throughput
^^^^^^^^^^^^^^^^^^^^^^^^^

Every merge request in Allen will automatically be tested in the CI system. As part of the tests, the throughput is measured on a number of different GPUs and a CPU.
The results of the tests are published in this |mattermost_channel_throughput|.

.. |mattermost_channel_throughput| raw:: html

   <a href="https://mattermost.web.cern.ch/lhcb/channels/allenpr-throughput" target="_blank">mattermost channel</a>

For local throughput measurements, we recommend the following settings in Allen standalone mode::

  ./Allen --sequence hlt1_pp_default --mdf /scratch/allen_data/mdf_input/upgrade_mc_minbias_scifi_v5_retinacluster_000_v1.mdf -n 500 -m 500 -r 1000 -t 16

For other input files, please see the section on :ref:`input_files`.


Physics performance
^^^^^^^^^^^^^^^^^^^^^^

Physics quantities, such as track and vertex reconstruction efficiencies and the momentum resolution, can be determined both within Allen compiled in standalone mode and when calling Allen from Moore.

Allen also provides a :ref:`root_service`, with which physics quantities used in HLT1 lines can be stored in ROOT files for performance studies.

Scripts for standalone Allen
--------------------------------
Create the directory Allen/output, then the ROOT file PrCheckerPlots.root will be saved there when running a validation sequence.

* Efficiency plots: Histograms of reconstructible and reconstructed tracks are saved in `Allen/output/PrCheckerPlots.root`.
  Plots of efficiencies versus various kinematic variables can be created by running `efficiency_plots.py <../../checker/plotting/tracking/efficiency_plots.py>` in the directory
  `checker/plotting/tracking`. The resulting ROOT file `efficiency_plots.root` with graphs of efficiencies is saved in the directory `plotsfornote_root`.
* Momentum resolution plots: A 2D histogram of momentum resolution versus momentum is also stored in `Allen/output/PrCheckerPlots.root` for Upstream and Forward tracks.
  Velo tracks are straight lines, so no momentum resolution is calculated. Running the script `momentum_resolution.py <../../checker/plotting/tracking/momentum_resolution.py>` in the directory `checker/plotting/tracking`
  will produce a plot of momentum resolution versus momentum in the ROOT file `momentum_resolution.root` in the directory `plotsfornote_root`.
  In this script, the 2D histogram of momentum resolution versus momentum is projected onto the momentum resolution axis in slices of the momentum.
  The resulting 1D histograms are fitted with a Gaussian function if they have more than 100 entries. The Gaussian fit is constrained to the region [-0.05,0.05] in
  the case of Forward tracks and to [-0.5, 0.5] for Upstream tracks respectively to avoid the non-Gaussian tails.
  The mean and sigma of the Gaussian are used as value and uncertainty in the momentum resolution versus momentum plot.
  The plot is only generated if at least one momentum slice histogram has more than 100 entries.

.. _moore_performance_scripts:

Scripts in Moore
-------------------
Call the executable from within the stack directory as in the following example: ::

  ./Moore/run gaudirun.py Moore/Hlt/RecoConf/tests/qmtest/allen_gaudi_forward_with_mcchecking.qmt

This will call the configured Allen algorithms, convert reconstructed tracks to Rec objects and run the MC checkers for track reconstruction efficiencies.

HltEfficiencyChecker in MooreAnalysis
----------------------------------------
The |moore_analysis| repository contains the `HltEfficiencyChecker` tool for giving rates and
efficiencies. To get `MooreAnalysis`, you can use the nightlies or do `make MooreAnalysis` from the top-level directory of the stack.

.. |moore_analysis| raw:: html

   <a href="https://gitlab.cern.ch/lhcb/MooreAnalysis" target="_blank">MooreAnalysis</a>

To get the efficiencies of all the Allen lines, from the top-level directory do::

  ./MooreAnalysis/run MooreAnalysis/HltEfficiencyChecker/scripts/hlt_eff_checker.py MooreAnalysis/HltEfficiencyChecker/options/hlt1_eff_default_retinacluster.yaml

and to get the rates::

  MooreAnalysis/run MooreAnalysis/HltEfficiencyChecker/scripts/hlt_eff_checker.py MooreAnalysis/HltEfficiencyChecker/options/hlt1_rate_example_retinacluster.yaml

Full documentation for the `HltEfficiencyChecker` tool, including a walk-through example for HLT1 efficiencies with Allen, is given |hltefficiencychecker_tutorial|.

.. |hltefficiencychecker_tutorial| raw:: html

   <a href="https://lhcbdoc.web.cern.ch/lhcbdoc/moore/master/tutorials/hltefficiencychecker.html" target="_blank">in this tutorial</a>
