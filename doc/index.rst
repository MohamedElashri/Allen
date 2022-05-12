Welcome to Allen's documentation!
=================================

Allen is the LHCb high-level trigger 1 (HLT1) application on graphics processing units (GPUs).
It is responsible for filtering an input rate of 30 million collisions per second down to an output
rate of around 1-2 MHz. It does this by performing fast track reconstruction and selecting pp collision events based on one- and two-track objects entirely on GPUs.


This site documents various aspects of Allen.

.. toctree::
   :caption: User Guide
   :maxdepth: 3

   setup/build
   setup/input_files
   setup/run_allen
   setup/where_to_develop_for_GPUs
   setup/performance
   .. hlt1/reconstruction_algorithms
   develop/add_algorithm
   develop/configure_sequence
   develop/selections
   develop/tests
   develop/root_service
   develop/memory_layouts
   integration/producers_consumers
   monitoring/monitoring_allen
   ci/ci_configuration

Get in touch
^^^^^^^^^^^^^

Topics related to Allen are discussed in the following mattermost channels:

* |allen_developers_link|
* |allen_core_link|
* |allenpr_throughput_link|

.. |allen_developers_link| raw:: html

   <a href="https://mattermost.web.cern.ch/lhcb/channels/allen-developers" target="_blank">Channel for any Allen algorithm development discussion</a>

.. |allen_core_link| raw:: html

   <a href="https://mattermost.web.cern.ch/lhcb/channels/allen-core" target="_blank">Discussion of Allen core features</a>

.. |allenpr_throughput_link| raw:: html

   <a href="https://mattermost.web.cern.ch/lhcb/channels/allenpr-throughput" target="_blank">Throughput reports from nightlies and MRs</a>


.. toctree::
   :caption: API Reference
   :maxdepth: 3

   selection/hlt1


Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
