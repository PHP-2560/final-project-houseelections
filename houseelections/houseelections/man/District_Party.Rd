% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/District_Party.R
\name{District_Party}
\alias{District_Party}
\title{District broken down by party}
\usage{
District_Party(state, district_no = 1)
}
\arguments{
\item{state}{The name of the state with the district you are interested in.
It must also be properly capitalized.}

\item{district_no}{The number of the district in the state. This is inputted as
a numeric (no parantheses needed).}
}
\description{
Given a state and a district in that state, this function will return the number
of Republicans, Democrats, Independents that district sent to Congress. It also
gives the average margin of victory for the elections in that district.
}
\examples{
District_Results("Pennsylvania", 10)
District_Results("Wyoming")
}
