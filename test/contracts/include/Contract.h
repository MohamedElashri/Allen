#pragma once

namespace Allen {
  // Contract classes
  namespace contract {
    struct ContractException : public std::exception {
    private:
      std::string m_exception_message;

    public:
      ContractException(
        const std::string& location,
        const std::string& contract_name,
        const std::string& contract_message,
        const std::string& contract_type) :
        m_exception_message(
          "Contract exception in algorithm " + location + ", " + contract_type + " " + contract_name + ": " + contract_message)
      {}

      const char* what() const noexcept override { return m_exception_message.c_str(); }
    };

    struct Location {
      std::string m_location;
      std::string m_contract_name;

      void set_location(const std::string& location, const std::string& contract_name) {
        m_location = location;
        m_contract_name = contract_name;
      }

      virtual void require(const bool condition, const std::string& contract_message) const = 0;

      virtual ~Location() {}

    protected:
      void require(const bool condition, const std::string& contract_message, const std::string& contract_type) const
      {
        if (!condition) {
          throw ContractException {m_location, m_contract_name, contract_message, contract_type};
        }
      }
    };

    struct Precondition : public Location {
      virtual ~Precondition() {}
      void require(const bool condition, const std::string& contract_message) const override
      {
        Location::require(condition, contract_message, "precondition");
      }
    };

    struct Postcondition : public Location {
      virtual ~Postcondition() {}
      void require(const bool condition, const std::string& contract_message) const override
      {
        Location::require(condition, contract_message, "postcondition");
      }
    };
  } // namespace contract
} // namespace Allen
