if (identical(Sys.getenv("MYPAINTR_LLDB_TESTTHAT"), "true") &&
    !identical(Sys.getenv("MYPAINTR_UNDER_LLDB"), "true") &&
    identical(Sys.info()[["sysname"]], "Darwin")) {
  args <- commandArgs(FALSE)
  script <- character()
  file_arg <- args[startsWith(args, "--file=")]
  if (length(file_arg)) {
    script <- sub("^--file=", "", file_arg[[1]])
  } else {
    file_idx <- match("-f", args, nomatch = 0L)
    if (file_idx && length(args) > file_idx) {
      script <- args[[file_idx + 1L]]
    }
  }
  if (!length(script) && file.exists("testthat.R")) {
    script <- "testthat.R"
  }
  script <- normalizePath(script, mustWork = TRUE)

  status <- system2(
    "lldb",
    c(
      "--batch",
      "-o", "run",
      "-k", "thread backtrace all",
      "--",
      file.path(R.home("bin"), "exec", "R"),
      "--vanilla",
      "-f", script
    ),
    env = "MYPAINTR_UNDER_LLDB=true"
  )
  quit(save = "no", status = status, runLast = FALSE)
}

library(testthat)
library(mypaintr)

test_check("mypaintr")
