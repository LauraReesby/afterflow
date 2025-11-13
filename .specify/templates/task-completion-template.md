# Task Completion Tracking Template

Use this template to track task completion for any feature implementation.

## Task Completion Protocol

Tasks can ONLY be marked as complete (✅) after ALL of the following criteria are met:

### 1. ✅ Code Implementation Complete
- [ ] All code changes implemented as specified
- [ ] Code follows project coding standards
- [ ] No compilation errors or warnings
- [ ] Code review completed (if applicable)

### 2. ✅ Tests Pass
- [ ] All existing tests continue to pass
- [ ] New unit tests written and passing
- [ ] New UI tests written and passing (for user-facing features)
- [ ] Integration tests updated and passing
- [ ] No test failures or flaky tests

### 3. ✅ Coverage Verification
- [ ] Code coverage measured and reported
- [ ] Minimum 80% coverage achieved for new code
- [ ] Overall project coverage maintained or improved
- [ ] Coverage report generated and reviewed

### 4. ✅ Functionality Verified
- [ ] Feature works as specified in acceptance criteria
- [ ] Manual testing completed for critical paths
- [ ] Error handling tested and working
- [ ] Performance requirements met
- [ ] Accessibility requirements verified (VoiceOver, Dynamic Type)

### 5. ✅ Documentation Updated
- [ ] Code comments added where necessary
- [ ] README updated if needed
- [ ] Spec files updated if implementation differs
- [ ] Change log updated

## Example Task Completion Checklist

```markdown
### T025 [P] [US1] Create SwiftUI previews for SessionFormView with sample data

#### Implementation Status:
- [x] Code Implementation Complete
- [x] Tests Pass  
- [x] Coverage Verification (Current: 85%)
- [x] Functionality Verified
- [x] Documentation Updated

#### Coverage Details:
- **Before**: 78%
- **After**: 85%
- **Target**: 80% ✅

#### Verification Notes:
- SwiftUI previews render correctly with sample data
- All test cases pass in both light and dark mode
- Accessibility labels work with VoiceOver
- Performance acceptable on target devices

**Status**: ✅ COMPLETE
```

## Marking Tasks Complete

### ❌ DO NOT mark complete if:
- Code compiles but tests are failing
- Coverage is below 80%
- Feature doesn't work as specified
- Manual testing reveals bugs
- Accessibility requirements not met

### ✅ DO mark complete when:
- All 5 criteria above are satisfied
- Feature is ready for production use
- No known issues or technical debt
- Documentation is up to date

## Coverage Reporting Commands

```bash
# Generate coverage report
xcodebuild test -scheme Afterflow \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -enableCodeCoverage YES

# View coverage details
xcrun xccov view Afterflow.xcresult --report --json

# Coverage threshold check
xcrun xccov view Afterflow.xcresult --report | grep "Total coverage"
```

## Task Status Indicators

- **[ ]** - Not started
- **[⏳]** - In progress (implementation phase)
- **[🧪]** - Testing phase
- **[📊]** - Coverage verification phase
- **[✅]** - Complete (all criteria met)
- **[❌]** - Blocked or failed

## Quality Gates

Before marking any task complete, ensure:

1. **Constitutional Compliance**: Feature aligns with all 6 core principles
2. **Privacy Protection**: No data leakage or privacy violations
3. **Therapeutic Value**: Feature supports healing and reflection
4. **Test Quality**: Comprehensive test coverage with meaningful assertions
5. **Performance**: Meets speed and memory requirements
6. **Accessibility**: Works with assistive technologies

## Commit Message Format for Completed Tasks

```
feat(session): implement mood rating slider component ✅

- Add MoodRatingView with 1-10 scale slider
- Include emoji mapping for visual feedback  
- Tests: 95% coverage achieved
- Accessibility: VoiceOver support verified
- Performance: <16ms render time

Closes: T043 [US3]
Coverage: 85% (+7% from baseline)
```

Remember: Task completion is not just about code - it's about delivering verified, tested, production-ready functionality that serves our therapeutic mission.