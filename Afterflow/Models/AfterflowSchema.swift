import SwiftData

/// The shape of the store as shipped before versioning was introduced. It points at the
/// top-level `TherapeuticSession` class (never a nested copy) so its hash matches existing
/// unversioned stores and current installs open without a migration.
/// Never edit this shape in place — see `AfterflowMigrationPlan`.
nonisolated enum AfterflowSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [TherapeuticSession.self]
    }
}

/// Ordered history of every schema the app has shipped.
///
/// Rule for future changes: any stored-property change to a model (add, remove, rename, retype,
/// or an attribute option that affects storage) requires a new `AfterflowSchemaV2` that captures
/// the new shape, appended to `schemas`, plus a `MigrationStage` (lightweight or custom) from V1
/// to V2 appended to `stages`. Never modify an existing version's models in place: the store on
/// a user's device is only recognisable by the exact shape its version recorded. V1 currently
/// aliases the live `TherapeuticSession`; before changing that class, freeze its present shape
/// into a nested snapshot model inside V1 so the old and new versions can coexist.
nonisolated enum AfterflowMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [AfterflowSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
