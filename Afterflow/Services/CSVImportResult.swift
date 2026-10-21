/// A data row that was left out of an import. `reason` is always a fixed string and never echoes cell contents.
struct CSVImportSkippedRow: Equatable {
    /// 1-based row position in the file; the header row is line 1. A record that spans several physical lines
    /// (a quoted cell containing a line break) counts once, matching the row numbers a spreadsheet shows.
    let line: Int
    let reason: String
}

/// Everything a CSV import produced: the parsed sessions plus what had to be skipped, defaulted or reworded
/// so the UI can tell the user.
struct CSVImportResult {
    var sessions: [TherapeuticSession] = []
    var skippedRows: [CSVImportSkippedRow] = []
    /// Rows whose Mood Before was blank (or whose column was missing) and received the default mood.
    var defaultedMoodBeforeCount = 0
    /// Rows imported as `.other` with the original text appended to their reflections.
    var unrecognisedTreatmentCount = 0
    /// Rows imported as `.other` with the original text appended to their reflections.
    var unrecognisedAdministrationCount = 0
}

/// Outcome of inserting imported sessions into the store.
struct CSVImportSummary: Equatable {
    let insertedCount: Int
    let skippedDuplicateCount: Int
}
