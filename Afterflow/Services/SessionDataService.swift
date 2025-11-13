//  Constitutional Compliance: Privacy-First, SwiftData Native, Offline-First

import Foundation
import SwiftData
import SwiftUI

/// Service responsible for managing TherapeuticSession persistence with auto-save capabilities
/// Following constitutional principles:
/// - Privacy-First: All data remains local, no cloud sync
/// - Offline-First: Works completely without network
/// - SwiftData Native: Uses Apple's native framework for data persistence
@Observable
class SessionDataService {
    
    // MARK: - Properties
    
    /// The SwiftData model context for persistence operations
    private let modelContext: ModelContext
    
    /// Timer for auto-save functionality
    private var autoSaveTimer: Timer?
    
    /// Tracks if there are unsaved changes
    private var hasUnsavedChanges = false
    
    /// Auto-save interval (5 seconds as per constitutional requirements)
    private let autoSaveInterval: TimeInterval = 5.0
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupAutoSave()
    }
    
    deinit {
        autoSaveTimer?.invalidate()
    }
    
    // MARK: - CRUD Operations
    
    /// Create a new therapy session
    /// - Parameter session: The TherapeuticSession to save
    /// - Throws: Any persistence-related errors
    func createSession(_ session: TherapeuticSession) throws {
        modelContext.insert(session)
        markUnsavedChanges()
        try saveContext()
    }
    
    /// Update an existing therapy session
    /// - Parameter session: The TherapeuticSession to update
    /// - Throws: Any persistence-related errors
    func updateSession(_ session: TherapeuticSession) throws {
        session.markAsUpdated()
        markUnsavedChanges()
        try saveContext()
    }
    
    /// Delete a therapy session
    /// - Parameter session: The TherapeuticSession to delete
    /// - Throws: Any persistence-related errors
    func deleteSession(_ session: TherapeuticSession) throws {
        modelContext.delete(session)
        markUnsavedChanges()
        try saveContext()
    }
    
    /// Fetch all therapy sessions, sorted by date (newest first)
    /// - Returns: Array of TherapeuticSession objects
    func fetchAllSessions() throws -> [TherapeuticSession] {
        let descriptor = FetchDescriptor<TherapeuticSession>(
            sortBy: [SortDescriptor(\.sessionDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Fetch sessions within a date range
    /// - Parameters:
    ///   - startDate: Start of date range
    ///   - endDate: End of date range
    /// - Returns: Array of TherapeuticSession objects within the date range
    func fetchSessions(from startDate: Date, to endDate: Date) throws -> [TherapeuticSession] {
        let descriptor = FetchDescriptor<TherapeuticSession>(
            predicate: #Predicate { session in
                session.sessionDate >= startDate && session.sessionDate <= endDate
            },
            sortBy: [SortDescriptor(\.sessionDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Fetch sessions by treatment type
    /// - Parameter treatmentType: The treatment type to filter by
    /// - Returns: Array of TherapeuticSession objects matching the treatment type
    func fetchSessions(treatmentType: PsychedelicTreatmentType) throws -> [TherapeuticSession] {
        let treatmentTypeString = treatmentType.rawValue
        let descriptor = FetchDescriptor<TherapeuticSession>(
            predicate: #Predicate { session in
                session.treatmentTypeRawValue == treatmentTypeString
            },
            sortBy: [SortDescriptor(\.sessionDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - Auto-Save Implementation
    
    /// Set up automatic saving to prevent data loss
    private func setupAutoSave() {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: autoSaveInterval, repeats: true) { [weak self] _ in
            self?.performAutoSave()
        }
    }
    
    /// Perform auto-save if there are unsaved changes
    private func performAutoSave() {
        guard hasUnsavedChanges else { return }
        
        do {
            try saveContext()
            hasUnsavedChanges = false
        } catch {
            // Log error but don't crash - auto-save should be resilient
            print("Auto-save failed: \(error.localizedDescription)")
        }
    }
    
    /// Force save immediately (for manual save operations)
    func forceSave() throws {
        try saveContext()
        hasUnsavedChanges = false
    }
    
    /// Mark that there are unsaved changes
    private func markUnsavedChanges() {
        hasUnsavedChanges = true
    }
    
    /// Save the model context
    /// - Throws: SwiftData persistence errors
    private func saveContext() throws {
        if modelContext.hasChanges {
            try modelContext.save()
        }
    }
    
    // MARK: - Draft Recovery
    
    /// Save a draft session for crash recovery
    /// - Parameter session: The draft session to save
    func saveDraft(_ session: TherapeuticSession) {
        // Add a special marker to identify drafts
        UserDefaults.standard.set(session.id.uuidString, forKey: "current_draft_id")
        UserDefaults.standard.set(Date(), forKey: "draft_save_time")
        
        do {
            try createSession(session)
        } catch {
            print("Failed to save draft: \(error.localizedDescription)")
        }
    }
    
    /// Recover any existing draft session
    /// - Returns: Draft TherapeuticSession if one exists, nil otherwise
    func recoverDraft() -> TherapeuticSession? {
        guard let draftIdString = UserDefaults.standard.string(forKey: "current_draft_id"),
              let draftId = UUID(uuidString: draftIdString),
              let draftSaveTime = UserDefaults.standard.object(forKey: "draft_save_time") as? Date else {
            return nil
        }
        
        // Only recover drafts that are less than 24 hours old
        let hoursSinceLastSave = Date().timeIntervalSince(draftSaveTime) / 3600
        guard hoursSinceLastSave < 24 else {
            clearDraft()
            return nil
        }
        
        do {
            let descriptor = FetchDescriptor<TherapeuticSession>(
                predicate: #Predicate { session in
                    session.id == draftId
                }
            )
            let sessions = try modelContext.fetch(descriptor)
            return sessions.first
        } catch {
            print("Failed to recover draft: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Clear the current draft
    func clearDraft() {
        UserDefaults.standard.removeObject(forKey: "current_draft_id")
        UserDefaults.standard.removeObject(forKey: "draft_save_time")
    }
    
    // MARK: - Validation
    
    /// Validate a session before saving
    /// - Parameter session: The session to validate
    /// - Returns: Array of validation error messages (empty if valid)
    func validateSession(_ session: TherapeuticSession) -> [String] {
        var errors: [String] = []
        
        // Treatment type validation is built into the enum, so we just need to validate other fields
        if session.intention.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Intention is required")
        }
        
        // Check for future date
        if session.sessionDate > Date() {
            errors.append("Session date cannot be in the future")
        }
        
        if session.moodBefore < 1 || session.moodBefore > 10 {
            errors.append("Pre-mood scale must be between 1 and 10")
        }
        
        if session.moodAfter < 1 || session.moodAfter > 10 {
            errors.append("Mood after must be between 1 and 10")
        }
        
        return errors
    }
}

// MARK: - Background Task Support

extension SessionDataService {
    
    /// Save data when app enters background
    func saveOnBackground() {
        do {
            try forceSave()
        } catch {
            print("Failed to save on background: \(error.localizedDescription)")
        }
    }
}