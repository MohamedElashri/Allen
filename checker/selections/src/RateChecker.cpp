#include "RateChecker.h"

std::string const RateChecker::RateTag::name = "RateChecker";

double binomial_error(int n, int k) { return 1. / n * std::sqrt(1. * k * (1. - 1. * k / n)); }

void RateChecker::report(const size_t requested_events) const
{
  // Assume 30 MHz input rate.
  const double in_rate = 30000.0;
  size_t longest_string = 10;
  for (const auto& line_name : m_line_names) {
    if (line_name.length() > longest_string) {
      longest_string = line_name.length();
    }
  }

  for (unsigned i_line = 0; i_line < m_line_names.size(); i_line++) {
    std::printf("%s:", m_line_names[i_line].c_str());
    for (unsigned i = 0; i < longest_string - m_line_names[i_line].length(); ++i) {
      std::printf(" ");
    }

    std::printf(
      " %6i/%6lu, (%8.2f +/- %8.2f) kHz\n",
      m_counters[i_line],
      requested_events,
      1. * m_counters[i_line] / requested_events * in_rate,
      binomial_error(requested_events, m_counters[i_line]) * in_rate);
  }

  std::printf("Inclusive:");
  for (unsigned i = 0; i < longest_string - 9; ++i) {
    std::printf(" ");
  }

  std::printf(
    " %6i/%6lu, (%8.2f +/- %8.2f) kHz\n",
    m_tot,
    requested_events,
    1. * m_tot / requested_events * in_rate,
    binomial_error(requested_events, m_tot) * in_rate);
}