# Wave 3 APK Fixture Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the third wave of real APK-driven regression coverage by introducing one four-transforms baseline fixture and one major-star-placement baseline fixture, then verify, commit, and push the work to GitHub.

**Architecture:** Keep the implementation centered in the test target and fixture layer. First capture two new real APK samples and freeze their evidence, then extend the fixture contract with the smallest possible optional fields for `siHuaInfo` and selected `majorStarNames`, and finally teach the regression suite to compare those fields against the existing stable `ZiWeiChartComparableSnapshot`.

**Tech Stack:** Swift 5.9, XCTest, XcodeGen, JSON fixtures, `xcodebuild`, Android emulator / `adb`, Git / GitHub

---

## Scope Guard

This plan only covers the third-wave regression expansion that is already approved in `docs/superpowers/specs/2026-03-28-wave3-apk-fixtures-design.md`:

- one new APK sample for `siHuaInfo`
- one new APK sample for selected major-star placements
- the minimum fixture-contract and test changes needed to compare them
- final verification, commit, and push

This plan does **not** include:

- changing `ZiWeiEngine` business logic
- expanding to all 12 palaces of major stars
- adding supporting stars, misc stars, brightness, transforms, or UI automation

## Baseline Discipline

Every new baseline added in this plan must satisfy all of these rules:

- `expected` values come from one real APK run with the same `apkRaw`
- `source` records enough context to trace how the APK values were read
- if a value is not clearly visible in APK evidence, leave it out rather than guessing
- never inspect iOS output and copy it back into fixture `expected`

## File Map

**Evidence-backed fixtures**

- Create: `ZiWeiDoushuDianLiangXingKongTests/Fixtures/APKBaselines/sihua-smoke.json` — one real APK sample containing only `expected.global.siHuaInfo`
- Create: `ZiWeiDoushuDianLiangXingKongTests/Fixtures/APKBaselines/star-placement-smoke.json` — one real APK sample containing only selected palace `majorStarNames`

**Fixture contract and docs**

- Modify: `ZiWeiDoushuDianLiangXingKongTests/Support/APKBaselineCase.swift` — add optional `siHuaInfo` and optional palace `majorStarNames`
- Modify: `ZiWeiDoushuDianLiangXingKongTests/Fixtures/APKBaselines/README.md` — document the new optional fields and the ordering rule for `siHuaInfo`

**Regression and loader tests**

- Modify: `ZiWeiDoushuDianLiangXingKongTests/APKBaselineLoaderTests.swift` — cover loading and decoding of the new fixtures
- Modify: `ZiWeiDoushuDianLiangXingKongTests/APKBaselineRegressionTests.swift` — compare `siHuaInfo` and selected palace `majorStarNames`
- Modify: `ZiWeiDoushuDianLiangXingKongTests/ZiWeiChartComparableSnapshotTests.swift` — add focused assertions that the snapshot still exposes stable `siHuaInfo` and `majorStars` data in the shape needed by regression tests

**Project wiring**

- Modify: `ZiWeiDoushuDianLiangXingKong.xcodeproj/project.pbxproj` — regenerated so the new JSON fixtures are bundled into the test target resources

## Task 1: Capture and Freeze Two New Real APK Samples

**Files:**
- Reference: `docs/apk-baselines/runtime-setup.md`
- Reference: `docs/apk-baselines/capture-workflow.md`

- [ ] **Step 1: Confirm emulator and APK runtime path are usable**

Run:

```bash
adb devices
adb -s <serial> shell getprop sys.boot_completed
adb -s <serial> shell am start -n com.example.ziweixingyu/com.ziweixingyu.ziweixingyu.MainActivity
```

Expected:
- one emulator is listed, and `<serial>` is replaced with that device ID in later steps
- `sys.boot_completed` returns `1`
- APK can be brought to the main activity

- [ ] **Step 2: Capture one new four-transforms candidate sample**

Do:
- manually navigate the APK to a chart whose four-transforms text is clearly visible
- save a screenshot with `adb -s <serial> exec-out screencap -p > /tmp/tiandiziwei-wave3-sihua.png`
- read the current `shared_prefs` input values from the same runtime session

Run:

```bash
adb -s <serial> shell "grep -R \"圻拆祗柝袛祇#\" /data/user/0/com.example.ziweixingyu/shared_prefs 2>/dev/null"
```

Expected:
- one screenshot exists for manual reading
- one exact `apkRaw` string can be frozen for the same chart

- [ ] **Step 3: Capture one new major-star-placement candidate sample**

Do:
- manually navigate to a chart where several palace major stars are clear enough to read
- save a screenshot with `adb -s <serial> exec-out screencap -p > /tmp/tiandiziwei-wave3-stars.png`
- freeze the same chart’s `apkRaw` from `shared_prefs`

Expected:
- one screenshot exists for manual reading
- at least 2-3 palaces have visually reliable major-star evidence

- [ ] **Step 4: Freeze the evidence in working notes before any JSON is written**

Write down for each sample:
- exact `apkRaw`
- optional `apkClockRaw`
- screenshot filename
- field-reading notes
- only the APK-confirmed values to be encoded later

Expected:
- both future fixtures can be written later without consulting iOS output

## Task 2: Add the New Fixture Schema, Resources, and Loader Coverage

**Files:**
- Modify: `ZiWeiDoushuDianLiangXingKongTests/Support/APKBaselineCase.swift`
- Modify: `ZiWeiDoushuDianLiangXingKongTests/Fixtures/APKBaselines/README.md`
- Modify: `ZiWeiDoushuDianLiangXingKongTests/APKBaselineLoaderTests.swift`
- Create: `ZiWeiDoushuDianLiangXingKongTests/Fixtures/APKBaselines/sihua-smoke.json`
- Create: `ZiWeiDoushuDianLiangXingKongTests/Fixtures/APKBaselines/star-placement-smoke.json`
- Modify: `ZiWeiDoushuDianLiangXingKong.xcodeproj/project.pbxproj`

- [ ] **Step 1: Add the minimum compile-only schema fields required for Swift tests to build**

Implement only the optional model fields, with no regression logic yet:

- `Expected.Global.siHuaInfo: [String]?`
- `PalaceExpectation.majorStarNames: [String]?`

Expected:
- the test target can compile references to the new optional fields

- [ ] **Step 2: Write the failing loader tests for new fields and fixture IDs**

Add tests shaped like:

```swift
func testLoadSiHuaSmokeFixture() throws {
    let fixture = try APKBaselineLoader.load(id: "sihua-smoke")
    XCTAssertEqual(fixture.id, "sihua-smoke")
    XCTAssertFalse(try XCTUnwrap(fixture.expected.global.siHuaInfo).isEmpty)
}

func testLoadStarPlacementSmokeFixture() throws {
    let fixture = try APKBaselineLoader.load(id: "star-placement-smoke")
    XCTAssertEqual(fixture.id, "star-placement-smoke")
    XCTAssertFalse(fixture.expected.palaces.isEmpty)
    XCTAssertNotNil(fixture.expected.palaces.first?.majorStarNames)
}
```

- [ ] **Step 3: Run loader tests to verify the new assertions fail**

Run:

```bash
xcodebuild test \
  -project ZiWeiDoushuDianLiangXingKong.xcodeproj \
  -scheme ZiWeiDoushuDianLiangXingKong \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4' \
  -only-testing:ZiWeiDoushuDianLiangXingKongTests/APKBaselineLoaderTests
```

Expected: FAIL because the new fixture JSON files do not yet exist in the test bundle, or because they are not yet registered in generated project resources.

- [ ] **Step 4: Write the two fixture JSON files from the frozen APK evidence**

Implement:
- `sihua-smoke.json` with only `expected.global.siHuaInfo`
- `star-placement-smoke.json` with only selected `expected.palaces[].position + majorStarNames`
- `source.notes` that explain how each value was read from APK screenshots

- [ ] **Step 5: Update fixture README and regenerate the Xcode project**

Implement:
- update fixture README with:
  - `siHuaInfo` ordering must match `snapshot.global.siHuaInfo`
  - `majorStarNames` means `majorStars` / 正曜 only
- run `bash ./scripts/regenerate-xcode-project.sh` so the new JSON files are added to test resources

- [ ] **Step 6: Run loader tests to verify they pass**

Run the same command from Step 3.

Expected: PASS and both fixtures decode cleanly from the bundle.

- [ ] **Step 7: Commit the schema and fixture-loading work**

```bash
git add \
  ZiWeiDoushuDianLiangXingKongTests/Support/APKBaselineCase.swift \
  ZiWeiDoushuDianLiangXingKongTests/Fixtures/APKBaselines/README.md \
  ZiWeiDoushuDianLiangXingKongTests/Fixtures/APKBaselines/sihua-smoke.json \
  ZiWeiDoushuDianLiangXingKongTests/Fixtures/APKBaselines/star-placement-smoke.json \
  ZiWeiDoushuDianLiangXingKongTests/APKBaselineLoaderTests.swift \
  ZiWeiDoushuDianLiangXingKong.xcodeproj/project.pbxproj
git commit -m "test: add wave3 apk fixture schema"
```

## Task 3: Add Regression Assertions for Four-Transforms and Major Stars

**Files:**
- Modify: `ZiWeiDoushuDianLiangXingKongTests/APKBaselineRegressionTests.swift`
- Modify: `ZiWeiDoushuDianLiangXingKongTests/ZiWeiChartComparableSnapshotTests.swift`

- [ ] **Step 1: Add the minimum array-assertion helper required for Swift tests to compile**

Implement only the compare helper signature(s) needed to reference `[String]?` expectations in tests, without completing the actual regression loop yet.

Expected:
- regression tests can compile references to `siHuaInfo` and `majorStarNames`

- [ ] **Step 2: Write the failing regression assertions**

Add failing expectations shaped like:

```swift
assertEqualIfPresent(
    snapshot.global.siHuaInfo,
    fixture.expected.global.siHuaInfo,
    fixtureID: fixture.id,
    field: "siHuaInfo"
)
```

and for palace expectations:

```swift
assertEqualIfPresent(
    palace.majorStars.map(\.name),
    palaceExpectation.majorStarNames,
    fixtureID: fixture.id,
    field: "palaces[\(palaceExpectation.position)].majorStarNames"
)
```

- [ ] **Step 3: Run regression tests to verify they fail for the expected reason**

Run:

```bash
xcodebuild test \
  -project ZiWeiDoushuDianLiangXingKong.xcodeproj \
  -scheme ZiWeiDoushuDianLiangXingKong \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4' \
  -only-testing:ZiWeiDoushuDianLiangXingKongTests/APKBaselineRegressionTests \
  -only-testing:ZiWeiDoushuDianLiangXingKongTests/ZiWeiChartComparableSnapshotTests
```

Expected: FAIL because the regression logic for `siHuaInfo` and/or `majorStarNames` comparison is still incomplete, not because the test target cannot compile.

- [ ] **Step 4: Implement the minimal regression support**

Implement:
- stable comparison of `snapshot.global.siHuaInfo`
- stable comparison of `palace.majorStars.map(\.name)` after normalizing to a stable order
- one focused snapshot test proving:
  - `siHuaInfo` remains deterministic
  - `majorStars` are exposed in the palace snapshot shape used by regression tests

- [ ] **Step 5: Run regression tests to verify they pass**

Run the same command from Step 3.

Expected: PASS for the new third-wave assertions.

- [ ] **Step 6: Commit the regression assertion work**

```bash
git add \
  ZiWeiDoushuDianLiangXingKongTests/APKBaselineRegressionTests.swift \
  ZiWeiDoushuDianLiangXingKongTests/ZiWeiChartComparableSnapshotTests.swift
git commit -m "test: add wave3 apk regression assertions"
```

## Task 4: Run Full Verification, Finalize, and Push

**Files:**
- Modify: tracked files from Tasks 1-3

- [ ] **Step 1: Run the baseline regression slice**

Run:

```bash
bash ./scripts/run-apk-baseline-tests.sh
```

Expected: PASS including the new `sihua-smoke` and `star-placement-smoke` fixtures.

- [ ] **Step 2: Run the full test suite**

Run:

```bash
xcodebuild test \
  -project ZiWeiDoushuDianLiangXingKong.xcodeproj \
  -scheme ZiWeiDoushuDianLiangXingKong \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4'
```

Expected: PASS with no unrelated regressions.

- [ ] **Step 3: Run lint checks on changed files**

Run:

```bash
# use ReadLints on all touched files
```

Expected: no newly introduced diagnostics.

- [ ] **Step 4: Verify the new fixtures are present in the generated project and test bundle path**

Check:
- `git diff` / `project.pbxproj` includes the two new JSON resources
- the latest successful test run copied both fixtures into the test bundle resources

Expected:
- no fixture is left only on disk without project/resource registration

- [ ] **Step 5: Push the branch to GitHub**

```bash
git push
```

Expected: remote branch updates successfully.

## Review Checklist

Before execution handoff, verify the plan still satisfies the approved spec:

- the work remains split into two APK-backed samples rather than one overloaded sample
- `siHuaInfo` ordering is defined by the current snapshot output, not by a hand-written alternative rule
- palace star assertions only cover `majorStars` / 正曜
- no production chart logic changes are required
- final workflow includes verification, commit, and push

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-03-28-wave3-apk-fixtures.md`. Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
