# Compile and load the C++ code (requires Rcpp and a compiler)
Rcpp::sourceCpp("src/cpp/hello.cpp")
sum_cpp(c(1, 2, 3))
