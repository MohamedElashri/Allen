.. _Allen_memory_layouts:

Memory layout of raw data in Allen
====================================

Algorithms that process raw detector data must support input of that
data in two different layouts: Allen layout and MEP layout. Both layouts store the raw data for many events one after each other, i.e. in Structure of Array (SoA) formats.
The main difference between Allen and MEP layout is the definition of the SoAs. In MEP layout one array contains the raw data for all events coming from one TELL40. In Allen layout one array contains the raw data for all TELL40s of one sub-detector for all events. MDF input files are converted to Allen layout. 

Raw data consists of for pieces of information: the data itself -
usually referred to as the fragment, the size of the fragment in
bytes, the type of the fragment and the source ID of the
fragment. The meaning of the fragment type and source ID are defined
in `this EDMS document <https://edms.cern.ch/document/2100937>`_.

The raw data is provided as four arrays:

* The fragment data - an array of `char const`,
* Fragment offsets - an array of `unsigned const` - indexed by event number and/or and bank number,
* Bank size offsets - an array of `unsigned const` - indexed by event number and and bank number,
* Bank type offsets - an array of `unsigned const` - indexed by event number and and bank number.

In both layouts all offsets are prepared per subdetector.

Allen layout
^^^^^^^^^^^^

In Allen layout the fragments for a given event are contiguous
in memory. The fragment offsets are indexed by event number and
a given offset is used to obtain a block of data from the fragment
data. This block contains the following information:
* `4` bytes: the number of fragments (`n_frag`),
* `(n_frag + 1) * 4` bytes: the relative offset to each fragment
* the fragments

For the size and types offsets arrays the sizes and types themselves
are also stored in the array, but this is hidden behind the
interface. The size or type of a fragment can be obtained by calling
``Allen::bank_size`` and ``Allen::bank_type``, respectively.

MEP layout
^^^^^^^^^^

In MEP layout the fragments originating from a given Tell40 for all
events in the batch are contiguous. To get the fragment payload for a
given event and fragment number, the offsets array needs to be passed
to the ``MEP::raw_bank`` function. The number of fragments per event
and the source IDs are also stored as part of the fragment
offsets. These can be obtained by calling ``MEP::number_of_banks`` and
``MEP::source_id``, respectively.

In the current implementation of the ``MEPProvider``, the sizes and
types are themselves stored in the sizes and types offsets
arrays. They can be obtained by calling ``Allen::bank_size`` and
``Allen::bank_type``, respectively.

For a given batch of events and a specific subdetector, only the
relevant parts of the MEP are currently copied to the device.
Fragment sizes and types are copied separately and stored in the
respective offsets arrays.

In the future, the full MEP, including all the sizes and types, will
be copied to the device, and all offsets will be adjusted accordingly
behind the scenes.
