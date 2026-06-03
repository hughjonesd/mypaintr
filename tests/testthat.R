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

  crash_commands <- tempfile("mypaintr-lldb-crash-")
  writeLines(c("thread backtrace all", "process kill", "quit"), crash_commands)

  Sys.setenv(MYPAINTR_UNDER_LLDB = "true")
  status <- system2(
    "lldb",
    c(
      "--batch",
      "--one-line", "run",
      "--source-on-crash", crash_commands,
      "--",
      file.path(R.home("bin"), "exec", "R"),
      "--vanilla",
      "-f", script
    ),
    timeout = 180
  )
  quit(save = "no", status = status, runLast = FALSE)
}

library(testthat)
library(mypaintr)

test_check("mypaintr")
