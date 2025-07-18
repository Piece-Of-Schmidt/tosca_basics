% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/02_text_functions.R
\name{get_context}
\alias{get_context}
\title{Extract keyword-in-context (KWIC) windows}
\usage{
get_context(
  texts,
  pattern,
  windowsize = 30,
  seperator = NULL,
  ignore.case = F,
  perl = F,
  offset = T
)
}
\arguments{
\item{texts}{A character vector of input texts.}

\item{pattern}{A regular expression to search for.}

\item{windowsize}{Number of characters to include before and after the pattern.}

\item{seperator}{Optional separator string to mark the pattern (e.g., \verb{**} for markdown highlighting).}

\item{ignore.case}{Logical. Should pattern matching be case-insensitive? (default: \code{FALSE})}

\item{perl}{Logical. Should Perl-compatible regex be used? (default: \code{FALSE})}

\item{offset}{Logical. Should matches be horizontally aligned? (default: \code{TRUE})}
}
\value{
A character vector with the extracted and optionally highlighted context windows.
}
\description{
Extracts the textual context around a pattern in a set of character strings,
similar to \code{quanteda::kwic()}. Optionally highlights the pattern and aligns results.
}
\examples{
get_context("this is a test string", "test", windowsize = 10)
}
