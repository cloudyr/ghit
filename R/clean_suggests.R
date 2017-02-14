clean_suggests <- function(description) {
    suggests <- strsplit(gsub("[[:space:]]+", "", description[1, "Suggests"]), ",")[[1L]]
    versioned <- grepl("\\(", suggests)
    if (any(versioned)) {
        message("Version requirements for 'Suggests' dependencies currently ignored.")
        suggests <- gsub("\\(.+\\)", "", suggests)
    }
    suggests
}
