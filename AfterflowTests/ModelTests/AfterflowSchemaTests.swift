@testable import Afterflow
import SwiftData
import Testing

struct AfterflowSchemaTests {
    @Test("V1 is version 1.0.0") func versionOneIdentifier() {
        #expect(AfterflowSchemaV1.versionIdentifier == Schema.Version(1, 0, 0))
    }

    @Test("V1 contains only the top-level TherapeuticSession model") func versionOneModels() {
        let models = AfterflowSchemaV1.models
        #expect(models.count == 1)
        let isSession = models.first == TherapeuticSession.self
        #expect(isSession)
    }

    @Test("The migration plan lists exactly V1 and no stages") func planListsOnlyVersionOne() {
        let schemas = AfterflowMigrationPlan.schemas
        #expect(schemas.count == 1)
        let isVersionOne = schemas.first == AfterflowSchemaV1.self
        #expect(isVersionOne)
        #expect(AfterflowMigrationPlan.stages.isEmpty)
    }
}
