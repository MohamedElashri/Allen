Writing Binary Dumpers for non-event data in Allen
==================================================

Dumpers import the geometry and condition information from the conditions database required for Allen processing. These dumper follow the DD4HEP formalism and are based on Gaudi algorithms.
These dumpers should be distinguished from event data
All headers and source files are relative to the directory `Dumpers/BinaryDumpers <https://gitlab.cern.ch/lhcb/Allen/-/tree/master/Dumpers/BinaryDumpers/src>`_.

In Allen, there is a base class named Dumper and defined in  `Allen/Dumpers/BinaryDumpers/src/Dumper.h <https://gitlab.cern.ch/lhcb/Allen/-/tree/master/Dumpers/BinaryDumpers/src/Dumper.h>`_.

The base class instantiate GAudi algorithms to get data from the conditions database.

As a best paratice, all dumpers should be derived from the base class Dumper.


A basic code for dumping non-event data into Allen follows the following structure :
  1. A C++ structure definition for data input
  2. Dumper Class definition by derivation from the base class
  3. Declaring the class in Gaudi (DECLARE_COMPONENT(dumper))
  4. Initiliazing the dumper.



Dumper struct definition for data
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Producers and Consumers are identified by a simple struct in the header `include/Dumpers/Identifiers.h`:

.. code-block:: c++

  namespace Allen {
  namespace NonEventData {
    struct Identifier{};

    struct VeloGeometry : Identifier {
      inline static std::string const id = "VeloGeometry";
    };
  }}

For every geometry or conditions data that should be converted from the conditions Database, a simple struct should be defined as a derived condition

The following elments are mandatory for the definition if each struct:

  * A first default constructor
  * A second constructor that takes an ::`std::vector<char>&data`:: as the first argument, followed by const references to the input detector elements or conditions.
  * At the end of the second constructor, the binary container produced by calling `write` as often as needed and assigned to `data`.


A simple dumper for detector geometry:

.. code-block:: c++

  struct Geometry {
    Geometry() = default;
    Geometry(std::vector<char>& data, const DeUTDetector& det)
    {
      DumpUtils::Writer output {};
      output.write(...);
      data = output.buffer();
    }
  };


A more complex dumper using two derived conditions and a regular condition as input :

.. code-block:: c++

  struct Boards {
    Boards() = default;
    Boards(
      std::vector<char>& data,
      IUTReadoutTool const& readout,
      IUTReadoutTool::ReadoutInfo const* roInfo,
      nlohmann::json const& readoutMap)
    {
      DumpUtils::Writer output {};
      output.write(...);
      data = output.buffer();
    }
  };


Derivation from Dumper base class
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

A specific dumper is defined buy inheriting from Dumper (header Dumper.h), with a function signature that is `void(derived_cond1, derived_cond2, ...)`.

Each derived condition should be tagged with `LHCb::Algorithm::Traits::usesConditions` for example:

.. code-block:: c++

  Allen::Dumpers::Dumper<void(VPGeometry const&), LHCb::Algorithm::Traits::usesConditions<VPGeometry>>


The signature of `operator()` matches `void operator()(const VPGeometry& VPGeo) const override`


Add an `std::vector<char>` data member for each derived condition.

An initilization function has to be defined in the class such as `StatusCode initialize() override`, this is done buy adding a block that does three things (`andThen` can be used):

  * call register_producer with as arguments: the Allen ID, the filename of the dumped binary file and the respective `std::vector<char>` data member.

  * call addConditionDerivation with as arguments: an `std::array<std::string>` containing the locations of all input detector elements or (derived) conditions; the storage location of the derived condition being created; and a lambda that takes const references to the required detector elements and (derived) conditions as arguments.

  * Inside the lambda, create an instance of the derived condition then call `dump()` and finally return the instance of the derived condition just created.



Initialiazing the dumper
^^^^^^^^^^^^^^^^^^^^^^^^
The dumper is initialised buy the `initialize()` function and buy registering the producer.

.. code-block:: c++

	StatusCode DumpUTGeometry::initialize()
    register_producer(Allen::NonEventData::UTGeometry::id, "ut_geometry", m_geomData);
    addConditionDerivation({DeUTDetLocation::location()}, inputLocation<Geometry>(), [&](DeUTDetector const& det) {
      Geometry geometry {m_geomData, det};
      dump();
      return geometry;
    });

Remarks :

    * If a tool is needed, a `ToolHandle` must be used to access it.
    * All the Gaudi expetion must be handeled at the dumper initilaization step (and not in the class definition step)

A `KeyValue` is added for each derived condition that is being created when calling the constructor of the `Dumper` base class:

.. code-block:: c++

  DumpUTGeometry::DumpUTGeometry(const std::string& name, ISvcLocator* svcLoc) :
    Dumper(name, svcLoc,
    {KeyValue {"UTGeomLocation", "AlgorithmSpecific-" + name + "-geometry"},
    KeyValue {"UTBoardsLocation", "AlgorithmSpecific-" + name + "-boards"}})
  {}
