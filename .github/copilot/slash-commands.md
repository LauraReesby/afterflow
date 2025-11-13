# Afterflow Development Slash Commands

Custom slash commands to streamline development of the therapeutic session logging app while maintaining constitutional compliance and quality standards.

## Core Development Commands

### `/plan [feature-name]`
**Purpose**: Generate implementation plan following READ → PLAN → DIFF → APPLY → TEST → VERIFY → COMMIT workflow

**Usage**: 
```
/plan mood-rating-slider
/plan spotify-playlist-integration
```

**Output**: Creates structured Change Plan with:
- Constitutional compliance check
- File modification list with reasoning
- Testing strategy (unit, UI, integration)
- Coverage targets and verification steps
- Risk assessment and rollback plan
- Task completion checklist

---

### `/coverage [component]`
**Purpose**: Check current code coverage and identify gaps for 80% requirement

**Usage**:
```
/coverage all
/coverage TherapeuticSession
/coverage SessionFormViewModel
```

**Output**: 
- Current coverage percentage
- Files below 80% threshold
- Specific lines needing test coverage
- Suggested test additions
- Coverage improvement plan

---

### `/test [component] [type]`
**Purpose**: Generate comprehensive tests following TDD approach

**Usage**:
```
/test TherapeuticSession unit
/test SessionFormView ui
/test session-creation integration
```

**Output**:
- Test file creation with proper naming
- Test cases covering edge cases
- Mock data setup for therapeutic context
- Accessibility test scenarios
- Performance benchmarks

---

### `/privacy [feature]`
**Purpose**: Analyze privacy implications and ensure constitutional compliance

**Usage**:
```
/privacy spotify-integration
/privacy session-data-export
/privacy mood-tracking
```

**Output**:
- Privacy impact assessment
- Data flow analysis
- User control verification
- External dependency review
- Constitutional compliance checklist

---

## Therapeutic-Focused Commands

### `/therapeutic [feature]`
**Purpose**: Evaluate feature for therapeutic value and healing support

**Usage**:
```
/therapeutic reflection-prompts
/therapeutic mood-visualization
```

**Output**:
- Therapeutic value assessment
- User experience during altered states
- Healing workflow integration
- Calm interface design verification
- Pattern recognition support

---

### `/accessible [component]`
**Purpose**: Ensure full accessibility compliance for inclusive healing

**Usage**:
```
/accessible MoodRatingView
/accessible SessionListView
```

**Output**:
- VoiceOver compatibility check
- Dynamic Type support verification
- High contrast mode testing
- Motor accessibility considerations
- Cognitive load assessment

---

## Quality Assurance Commands

### `/review [code|spec]`
**Purpose**: Constitutional compliance and quality review

**Usage**:
```
/review SessionDataService.swift
/review 001-core-session-logging
```

**Output**:
- Constitutional principle compliance
- Code quality assessment
- Security vulnerability scan
- Performance impact analysis
- Therapeutic value verification

---

### `/complete [task-id]`
**Purpose**: Verify task completion criteria and mark as done

**Usage**:
```
/complete T025
/complete US1-mood-rating
```

**Output**:
- Implementation verification checklist
- Test execution results
- Coverage confirmation (≥80%)
- Functionality validation
- Documentation completeness check
- Task marking as ✅ complete

---

### `/commit [task-id] [message]`
**Purpose**: Generate conventional commit with spec references

**Usage**:
```
/commit T025 "implement mood rating slider component"
/commit US1 "complete session creation workflow"
```

**Output**:
- Conventional commit message format
- Spec ID references
- Coverage metrics inclusion
- Constitutional compliance note
- Change summary with context

---

## Spotify Integration Commands

### `/spotify [action]`
**Purpose**: Spotify Web API integration assistance (PKCE only, no playback)

**Usage**:
```
/spotify oauth-setup
/spotify playlist-search
/spotify cache-metadata
```

**Output**:
- PKCE OAuth implementation
- Web API endpoint usage
- Offline caching strategy
- Privacy-compliant token management
- User control mechanisms

---

## Data & Export Commands

### `/export [format] [scope]`
**Purpose**: Generate data export functionality for therapeutic collaboration

**Usage**:
```
/export csv all-sessions
/export pdf therapist-summary
/export email session-range
```

**Output**:
- Export implementation plan
- Format-specific code generation
- Privacy field selection UI
- Therapist sharing workflow
- Data integrity verification

---

### `/migrate [from-version] [to-version]`
**Purpose**: SwiftData model migration for data preservation

**Usage**:
```
/migrate 1.0 1.1
/migrate current next
```

**Output**:
- SwiftData migration code
- Data preservation strategy
- Rollback mechanism
- Testing migration scenarios
- User communication plan

---

## Development Workflow Commands

### `/setup [environment]`
**Purpose**: Environment setup and configuration

**Usage**:
```
/setup dev
/setup testing
/setup ci
```

**Output**:
- Xcode project configuration
- SwiftData container setup
- Test target configuration
- CI/CD pipeline setup
- Code coverage reporting

---

### `/debug [issue]`
**Purpose**: Debugging assistance for therapeutic app context

**Usage**:
```
/debug swiftdata-persistence
/debug ui-state-management
/debug memory-usage
```

**Output**:
- Debugging strategy
- Logging implementation
- Performance profiling setup
- Memory leak detection
- User experience impact analysis

---

### `/docs [component]`
**Purpose**: Generate therapeutic-focused documentation

**Usage**:
```
/docs TherapeuticSession
/docs session-workflow
/docs privacy-features
```

**Output**:
- SwiftDocC documentation
- Therapeutic context explanations
- Privacy policy content
- User guide sections
- Developer onboarding

---

## Constitutional Enforcement Commands

### `/constitutional [check|update]`
**Purpose**: Verify and maintain constitutional compliance

**Usage**:
```
/constitutional check
/constitutional update-version
```

**Output**:
- Full constitutional compliance audit
- Principle violation detection
- Remediation recommendations
- Version control for constitution
- Team communication of changes

---

### `/focus [check]`
**Purpose**: Ensure simplicity and therapeutic focus

**Usage**:
```
/focus feature-creep-check
/focus therapeutic-value-audit
```

**Output**:
- Feature complexity analysis
- Therapeutic value assessment
- Simplicity score calculation
- Feature removal recommendations
- User journey optimization

---

## Implementation Priority

### Immediate (Phase 1):
1. `/plan` - Essential for structured development
2. `/coverage` - Critical for 80% requirement
3. `/test` - Mandatory for TDD approach
4. `/complete` - Task completion tracking

### Phase 2:
1. `/privacy` - Privacy-first compliance
2. `/therapeutic` - Healing value verification
3. `/review` - Quality assurance
4. `/commit` - Proper git workflow

### Phase 3:
1. `/spotify` - Integration assistance
2. `/export` - Data sharing features
3. `/accessible` - Inclusive design
4. `/debug` - Development efficiency

### Future Enhancements:
1. `/migrate` - Data model evolution
2. `/docs` - Documentation generation
3. `/constitutional` - Governance enforcement
4. `/focus` - Therapeutic mission alignment

These slash commands are designed specifically for therapeutic app development, ensuring every development action supports the healing mission while maintaining the highest standards of privacy, quality, and constitutional compliance.