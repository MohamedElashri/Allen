Monitoring in Allen
=================================

Overview
^^^^^^^^^^^^^
Monitoring in Allen is performed by dedicated monitoring threads (by default there is a single thread).
After a slice of data is processed, the `HostBuffers` corresponding to that slice are sent to the monitoring
thread concurrent with being sent to the I/O thread for output. The flow of `HostBuffers` is shown below:

.. mermaid::

  graph LR
  A((HostBuffer<br>Manager))-->B[GPU thread]
  B-->C[I/O thread]
  B-->|if free|D[Monitoring thread]
  C-->A
  D-->A

To avoid excessive load on the CPU, monitoring threads will not queue `HostBuffers`, i.e, if the
monitoring thread is already busy then new `HostBuffers` will be immediately marked as monitored.
Functionality exists within `MonitorManager` to reactively reduce the amount of monitoring performed
(n.b. this corresponds to an **increase** in the `monitoring_level`) in response to a large number of skipped
slices. This is not currently used but would allow monitoring to favour running *some* types of monitors
for *all* slices over running *all* types of monitors for *some* slices. Additionally, less important monitors
could be run on a random sub-sample of slices. The `MetaMonitor` provides monitoring histograms that track
the numbers of successfully monitored and skipped slices as well as the monitoring level.

Monitor classes
^^^^^^^^^^^^^^^^^^^
Currently, monitoring is performed of the rate for each HLT line (`RateMonitor`) and for the momentum,
pT and chi^2(IP) of each track produced by the Kalman filter (`TrackMonitor`). Further monitoring histograms
can be either added to one of these classes or to a new monitoring class, as appropriate.

Additional monitors that produce histograms based on information in the `HostBuffers` should be added to
`integration/monitoring` and inherit from the `BufferMonitor` class. The `RateMonitor` class provides an
example of this. Furthermore, each histogram that is added must be given a unique key in MonitorBase::MonHistType.

Once a new monitoring class has been written, this may be added to the monitoring thread(s) by including an instance
of the class in the vectors created in `MonitorManager::init`, e.g.

.. code-block:: c++

  m_monitors.back().push_back(new RateMonitor(buffers_manager, time_step, offset));

To monitor a feature, either that feature or others from which it can be calculated must be present in the
`HostBuffers`. For example, the features recorded by `TrackMonitor` depend on the buffers `host_kf_tracks`
(for the track objects) and `host_atomics_scifi` (for the number of tracks in each event and the offset to the
start of each event). It is important that any buffers used by the monitoring are copied from the device to
the host memory and that they do not depend on `runtime_options.do_check` being set. Additionally, to avoid
a loss of performance, these buffers must be written to pinned memory, i.e. the memory must be allocated by
`cudaMallocHost` and not by `malloc` in `HostBuffers::reserve`.

Saving histograms
^^^^^^^^^^^^^^^^^^^^^^
All histograms may be saved by calling `MonitorManager::saveHistograms`. This is currently performed once after
Allen has finished executing. In principle, this could be performed on a regular basis within the main loop but
ideally would require monitoring threads to be paused for thread safety.

Histograms are currently written to `monitoringHists.root`.

Gaudi monitoring
^^^^^^^^^^^^^^^^^^^^^^
Add to a line
-------------
A good example is in the `KsToPiPiLine` which I will use to demonstrate the necessary changes here.

**Edit the header**

There are several necessary additions to the header that monitoring will use:

* Include the necessary header

.. code-block:: c++

  #include "AllenMonitoring.h"

* Add the `DeviceProperties` `struct` after the line `struct` declaration

.. code-block:: c++

  struct DeviceProperties {
    Allen::Monitoring::Histogram<>::DeviceType histogram_ks_mass;
    DeviceProperties(const kstopipi_line_t& algo, const Allen::Context& ctx) :
      histogram_ks_mass(algo.m_histogram_ks_mass.data(ctx))
    {}
  };

* The additional function needs to be declared in the `SelectionAlgorithm` struct, for example:

.. code-block:: c++

  __device__ static void monitor(
    const Parameters& parameters,
    const DeviceProperties& properties,
    std::tuple<const Allen::Views::Physics::CompositeParticle> input,
    unsigned index,
    bool sel);

* In the list of properties, add the histogram with the name, title, and a tuple of the number of bins, minimum,
and maximum. This one will appear in the root file as `ks_mass`, have a title of `m(ks)`, and 100 bins between 400
and 600.

.. code-block:: c++

  Allen::Monitoring::Histogram<> m_histogram_ks_mass {this, "ks_mass", "m(ks)", {100u, 400.f, 600.f}};

**Fill the histogram**

The `monitor` function is where the histogram will be filled. Using what conditions you want to fill the histogram
(typically that the event is selected by the line i.e. `sel`), increment the histogram. An example of this is

.. code-block:: c++

  __device__ void kstopipi_line::kstopipi_line_t::monitor(
    const Parameters& parameters,
    const DeviceProperties& properties,
    std::tuple<const Allen::Views::Physics::CompositeParticle> input,
    unsigned index,
    bool sel)
  {
    if (sel) {
      const auto ks = std::get<0>(input);
      properties.histogram_ks_mass.increment(ks.m12(Allen::mPi, Allen::mPi));
    }
  }

**Turn on the monitoring**

In the configuration of the line (a file called `hlt1_*_lines.py`, for `KsToPiPi` it is `hlt1_inclusive_hadron_lines.py`)
the `enable_monitoring` property (which is a default property of all lines) needs to be set. After this the `make_kstopipi_line` function now looks like

.. code-block:: python

  def make_kstopipi_line(long_tracks,
                        secondary_vertices,
                        pre_scaler_hash_string=None,
                        post_scaler_hash_string=None,
                        name='Hlt1KsToPiPi_{hash}',
                        enable_monitoring=True):
      number_of_events = initialize_number_of_events()

      return make_algorithm(
          kstopipi_line_t,
          name=name,
          enable_monitoring=is_allen_standalone() and enable_monitoring,
          host_number_of_events_t=number_of_events["host_number_of_events"],
          host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
          dev_particle_container_t=secondary_vertices[
              "dev_multi_event_composites"],
          pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
          post_scaler_hash_string=post_scaler_hash_string or name + "_post")

Note that it requires the `is_allen_standalone` flag to be true, which can be imported using

.. code-block:: python

  from AllenCore.configuration_options import is_allen_standalone

if it is not already in the configuration file. `enable_monitoring` is set to `True` by default here, and so every
version of the `KsToPiPiLine` will have monitoring unless explicitly set to `False`. To turn on monitoring for just
one version of a line, set `enable_monitoring` to `False` by default in the `hlt1_*_lines.py` file, and then set it
to `True` in `HLT1.py`, as done by the `DiMuonDrellYan` line for example:

.. code-block:: python

  make_di_muon_drell_yan_line(
    long_tracks,
    dileptons,
    muonid,
    name="Hlt1DiMuonDrellYan",
    pre_scaler_hash_string="di_muon_drell_yan_line_pre",
    post_scaler_hash_string="di_muon_drell_yan_line_post",
    minMass=5000.,
    minTrackP=12500,
    maxChi2Corr=2.4,
    enable_monitoring=True,
    enable_tupling=enable_tupling)


Add to an algorithm
-------------------
For this one I am using `VeloConsolidateTracks` as an example.

**Edit the header**

We will need similar edits to the header

* Include the monitoring header
.. code-block:: c++

  #include "AllenMonitoring.h"

* Change the algorithm declaration to include the monitoring inputs
.. code-block:: c++

  __global__ void velo_consolidate_tracks(
    Parameters,
    Allen::Monitoring::Histogram<>::DeviceType,
    Allen::Monitoring::AveragingCounter<>::DeviceType);

* Add it to the property list where the fields are the same as before (name, title, and a tuple of number of bins,
minimum, and maximim)
.. code-block:: c++

  Allen::Monitoring::Histogram<> m_histogram_n_velo_tracks {this,
                                                            "n_velo_tracks_event",
                                                            "n_velo_tracks_event",
                                                            {1001u, -0.5f, 1000.5f}};

**Pass it to the algorithm**

In the `Operator` function, there is a `global_function` call to the algorithm which should be edited to include the
histogram as an input. The histogram can be accesssed like so
.. code-block:: c++

  global_function(velo_consolidate_tracks)(size<dev_event_list_t>(arguments), property<block_dim_t>(), context)(
      arguments, m_histogram_n_velo_tracks.data(context), m_velo_tracks.data(context));

**Increment**

* The algorithm declaration will need to be updated to reflect the additional input
.. code-block:: c++

  __global__ void velo_consolidate_tracks::velo_consolidate_tracks(
    velo_consolidate_tracks::Parameters parameters,
    Allen::Monitoring::Histogram<>::DeviceType dev_number_of_tracks_histo,
    Allen::Monitoring::AveragingCounter<>::DeviceType dev_tracks_counter)

* Then the histogram can be filled from inside the algorithm with the generated values
.. code-block:: c++

  dev_number_of_tracks_histo.increment(event_total_number_of_tracks);

2D Histograms
---------------
Most everything is the same for a 2D histogram, but you will need to add the second axis to the declaration,

.. code-block:: c++

  Allen::Monitoring::Histogram2D<> m_histogram_test_2d {this, "2d", "2d title", {10u, 0.f, 100.f}, {10u, 0.f, 100.f}};

edit anywhere the type is specified to be

.. code-block:: c++

  Allen::Monitoring::Histogram2D<>::DeviceType

and increment using both values

.. code-block:: c++

  histo_test_2d.increment(test_val_1, test_val_2);

There is not currently support for 3D histograms.

Counters
--------
Similarly, counters follow the same pattern as histograms except for minor changes. The declaration is

.. code-block:: c++

  Allen::Monitoring::Counter<> m_invalid_chanid {this, "n_invalid_chanid"};

where only the name is chosen. The type is

.. code-block:: c++

  Allen::Monitoring::Counter<>::DeviceType invalid_chanid

and it can be incremented as

.. code-block:: c++

  invalid_chanid.increment();

Please note there is also the `AveragingCounter` type available which is incremented using a value like

.. code-block:: c++

  dev_n_pvs_counter.add(*tmp_number_vertices);

as an example. Then the number of entries, sum, and mean are saved whereas the standard counter only saves
the number of entries.

Testing offline
---------------
Please note that Gaudi monitoring is only avaliable when running with a Gaudi build from the |allen_event_loop|.
To test the histogram, set the flags `--register-monitoring-counters 1 monitoring-filename test` in your
command. Then after running, there will be a root file created with the given name plus `_gaudi` with the histograms.

.. |allen_event_loop| raw:: html

   <a href="https://allen-doc.docs.cern.ch/setup/run_allen.html#as-gaudi-project-event-loop-steered-by-allen-data-taking" target="_blank">Allen event loop</a>
