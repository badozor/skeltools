// Project: {{name}} (created on {{date}})
// Compile from R: Rcpp::sourceCpp("src/cpp/hello.cpp")
#include <Rcpp.h>

// [[Rcpp::export]]
double sum_cpp(Rcpp::NumericVector x) {
  double total = 0;
  for (R_xlen_t i = 0; i < x.size(); ++i) total += x[i];
  return total;
}
