Writing Producers and Consumers
=====

All headers and source files are relative to directory `integration/non_event_data`.


Identifiers
-----------

Producers and Consumers are identified by a simple struct in the
header `include/Dumpers/Identifiers.h`:

```c++
namespace Allen {
namespace NonEventData {
  struct Identifier{};

  struct VeloGeometry : Identifier {
    inline static std::string const id = "VeloGeometry";
  };

}}
```

If an identifier for your pair of producers or consumers does not
exist, add one with a reasonable name.

For Allen to function, a `Producer` needs to be registered with the
`Updater` for every `Consumer`. When running standalone, a standalone
`Updater` is used, which registeres all required `Producer` to itself
on construction (`src/Updater.cpp`). When running with the LHCb stack,
a `Service` component takes that role, and all individual producers
are also a `Service` that register themselves.

Producer
--------

A `Producer` produces information derived from the detector geometry
as a `vector<char>`; it is typically a functor or a lambda. There are
always 2 implementation of a `Producer` for a given `Indentifier`, one
for standalone running and one for running with the LHCb stack. The
standalone `Producer` that reads the magnetic field polarity from a
file looks like this:

For example:
```c++
GeometryReader reader{};
std::string polarity_file = "polarity.bin";
auto produce_polarity = [&reader, polarity_file] () -> optional<vector<char>> {
   return reader.read_geometry(polarity_file);
};
```

Have a look at `Updater::Updater` in `src/Updater.cpp` to see how the
registration is done.

Consumer
--------

A `Consumer` is usually a functor that takes a `vector<char>` as
an argument and fills a device array or variable (or multiple of
those) with information needed by a kernel. It is constructed with
references to devices variables or arrays it needs to fill. If it is
simple, it can be declared in `include/Consumers.h`. For example:
```c++
namespace Consumers {
  struct MagneticField final : public Allen::NonEventData::Consumer {
  public:

    MagneticField(float*&);

    void consume(std::vector<char> const& data) override;

  private:

    std::reference_wrapper<float*> m_dev_magnet_polarity;
    const size_t m_size = sizeof(float);

  };
}
```

The implementation of this consumer looks like this:
```c++
Consumers::MagneticField::MagneticField(float*& dev_magnet_polarity)
  : m_dev_magnet_polarity{dev_magnet_polarity} {
}

void Consumers::MagneticField::consume(std::vector<char> const& data) {
  if (data.size() != m_size) {
    throw StrException{string{"sizes don't match: "} + to_string(m_size) + " " + to_string(data.size())};
  }
  if (!m_dev_magnet_polarity.get()) {
    // Allocate space
    Allen::malloc((void**) &m_dev_magnet_polarity.get(), data.size());
  }
  Allen::memcpy(m_dev_magnet_polarity, data.data(), data.size(), Allen::memcpyHostToDevice);
}
```
Device variables are allocated on first call and never reallocated,
instead it is checked that the size data matches if the consumer is
called again.

Consumers are registered to the `Updater` in `register_consumers` that
is defined in `main/src/Allen.cpp`.
