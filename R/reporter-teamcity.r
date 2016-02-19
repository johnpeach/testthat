#' @include reporter.r
NULL

#' Test reporter: Teamcity format.
#'
#' This reporter will output results in the Teamcity message format.
#' For more information about Teamcity messages, see
#' http://confluence.jetbrains.com/display/TCD7/Build+Script+Interaction+with+TeamCity
#'
#' @export
#' @export TeamcityReporter
#' @aliases TeamcityReporter
#' @keywords debugging
#' @param ... Arguments used to initialise class
TeamcityReporter <- setRefClass("TeamcityReporter", contains = "Reporter",
  fields = list(
    "currentContext" = "character",
    "currentTest" = "character",
    "i" = "integer"
  ),

  methods = list(

    start_context = function(desc) {
  		currentContext <<- desc
      teamcity("testSuiteStarted", currentContext)
    },
    end_context = function() {
      teamcity("testSuiteFinished", currentContext)
      cat("\n\n")
    },

    start_test = function(desc) {
      currentTest <<- desc
      i <<- 0
      teamcity("testSuiteStarted", currentTest)
    },
    end_test = function() {
      teamcity("testSuiteFinished", currentTest)
      cat("\n")
    },


    start_reporter = function() {
		  currentContext <<- ""
    },

    add_result = function(result) {
      callSuper(result)
      testName <- paste0("expectation ", i)

      if (expectation_skip(skipped)) {
        teamcity("testIgnored", testName, message = result$message)
        return()
      }

      teamcity("testStarted", testName)

      if (!expectation_success(result)) {
        lines <- strsplit(result$message, "\n")[[1]]

        teamcity("testFailed", testName, message = lines[1],
          details = paste(lines[-1], collapse = "\n")
        )
      }
      teamcity("testFinished", testName)
    }

  )
)

teamcity <- function(event, name, ...) {
  values <- list(name = name, ...)
  values <- vapply(values, teamcity_escape, character(1))
  if (length(values) == 0) {
    value_string <- ""
  } else {
    value_string <- paste0(names(values), "='", values, "'", collapse = " ")
  }

  cat("##teamcity[", event, " ", value_string, "]\n", sep = "")
}

# teamcity escape character is |
teamcity_escape <- function(s) {
  s <- gsub("(['|]|\\[|\\])", "|\\1", s)
  gsub("\n", "|n", s)
}
