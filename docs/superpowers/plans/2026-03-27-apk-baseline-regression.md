# APK Baseline Regression Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an APK-baseline-driven workflow that can reliably capture APK chart outputs, normalize them into structured fixtures, and automatically compare iOS chart results against those fixtures.

**Architecture:** Keep the first iteration centered in the test target. Treat APK output capture as an ingestion step that produces structured baseline files, then map `ZiWeiChart` into a comparable snapshot shape and let XCTest compare the two. Avoid product-code changes unless the test target cannot derive a stable comparison model without duplicating business rules.

**Tech Stack:** Swift 5.9, XCTest, XcodeGen, JSON fixtures, `xcodebuild`, Android Studio / `adb`

---

## Scope Guard

This plan only covers the current first-priority work:

- APK result acquisition as a baseline source
- Structured baseline fixtures
- APK-driven automated regression for core chart results

This plan does **not** include the later UI / input-flow optimization track.

## Baseline Discipline

Every baseline fixture in `ZiWeiDoushuDianLiangXingKongTests/Fixtures/APKBaselines/` must satisfy these rules:

- `expected` values must come from one real APK run with the same input
- the fixture must record enough `source` metadata to trace that APK run later
- never copy current iOS output into `expected` just to make the suite pass
- if a field has not yet been verified from APK output, leave it out of the first-wave assertions rather than guessing

## File Map

**Environment and capture docs**

- Create: `docs/apk-baselines/runtime-setup.md` — machine architecture, emulator/runtime choice, APK install verification steps
- Create: `docs/apk-baselines/apk-source-log.md` — frozen APK path, source note, hash, capture date
- Create: `docs/apk-baselines/capture-workflow.md` — how to turn one APK run into one structured baseline fixture

**Test fixture contract**

- Create: `ZiWeiDoushuDianLiangXingKongTests/Fixtures/APKBaselines/README.md` — fixture schema, naming rules, field semantics
- Create: `ZiWeiDoushuDianLiangXingKongTests/Fixtures/APKBaselines/core-fields-smoke.json` — first baseline case
- Create: `ZiWeiDoushuDianLiangXingKongTests/Fixtures/APKBaselines/daxian-direction-smoke.json` — first direction / age-range case
- Create: `ZiWeiDoushuDianLiangXingKongTests/Fixtures/APKBaselines/sihua-smoke.json` — first four-transforms case
- Create: `ZiWeiDoushuDianLiangXingKongTests/Fixtures/APKBaselines/star-placement-smoke.json` — first major-star-placement case

**Test support code**

- Create: `ZiWeiDoushuDianLiangXingKongTests/Support/APKBaselineCase.swift` — `Codable` models for input, global fields, palaces, and baseline metadata
- Create: `ZiWeiDoushuDianLiangXingKongTests/Support/APKBaselineLoader.swift` — load one fixture or all fixtures from the test bundle
- Create: `ZiWeiDoushuDianLiangXingKongTests/Support/ZiWeiChartComparableSnapshot.swift` — stable comparable shape derived from `ZiWeiChart`

**Regression tests**

- Create: `ZiWeiDoushuDianLiangXingKongTests/APKBaselineLoaderTests.swift` — loader and resource-bundle coverage
- Create: `ZiWeiDoushuDianLiangXingKongTests/ZiWeiChartComparableSnapshotTests.swift` — snapshot-mapping coverage
- Create: `ZiWeiDoushuDianLiangXingKongTests/APKBaselineRegressionTests.swift` — end-to-end baseline vs iOS comparison

**Project and docs updates**

- Modify: `project.yml` — ensure fixture JSON files are bundled into the unit-test target
- Modify: `README.md` — document the new APK-baseline regression layer and exact test commands
- Create: `scripts/run-apk-baseline-tests.sh` — stable wrapper for running the regression suite locally

### Task 1: Freeze APK Runtime and Baseline Source

**Files:**
- Create: `docs/apk-baselines/runtime-setup.md`
- Create: `docs/apk-baselines/apk-source-log.md`

- [ ] **Step 1: Record machine architecture and APK hash**

Run:

```bash
uname -m
shasum -a 256 app.apk
```

Expected:
- machine architecture is recorded as `arm64` or `x86_64`
- one SHA256 line for `app.apk`

- [ ] **Step 2: Write runtime-setup doc with the minimum runnable path**

Document:
- chosen emulator / runtime path
- install command
- launch command
- how to reach the chart input screen

- [ ] **Step 3: Write apk-source-log doc**

Include:
- APK filename and relative path
- SHA256
- where the APK came from
- date frozen for baseline capture

- [ ] **Step 4: Verify the APK can be installed in the chosen runtime**

Run:

```bash
adb devices
adb install -r app.apk
```

Expected:
- one target device / emulator visible
- install output contains `Success`

- [ ] **Step 5: Record one end-to-end sample from APK UI**

Capture and write down at least one real sample case with:
- the exact input used
- where the values were read in APK
- at least these visible fields: `命宫` / `身宫` and one other core field

Expected:
- at least one future fixture already has a real APK provenance trail

- [ ] **Step 6: Commit**

```bash
git add docs/apk-baselines/runtime-setup.md docs/apk-baselines/apk-source-log.md
git commit -m "docs: freeze apk baseline runtime"
```

### Task 2: Define Fixture Contract and Bundle Loader

**Files:**
- Create: `ZiWeiDoushuDianLiangXingKongTests/Fixtures/APKBaselines/README.md`
- Create: `ZiWeiDoushuDianLiangXingKongTests/Fixtures/APKBaselines/core-fields-smoke.json`
- Create: `ZiWeiDoushuDianLiangXingKongTests/Support/APKBaselineCase.swift`
- Create: `ZiWeiDoushuDianLiangXingKongTests/Support/APKBaselineLoader.swift`
- Create: `ZiWeiDoushuDianLiangXingKongTests/APKBaselineLoaderTests.swift`
- Modify: `project.yml`

- [ ] **Step 1: Write the failing loader test**

```swift
func testLoadsCoreFieldsSmokeFixture() throws {
    let fixture = try APKBaselineLoader.load(named: "core-fields-smoke")
    XCTAssertEqual(fixture.id, "core-fields-smoke")
    XCTAssertEqual(fixture.expected.global.mingGong, "子")
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
xcodebuild test \
  -scheme ZiWeiDoushuDianLiangXingKong \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ZiWeiDoushuDianLiangXingKongTests/APKBaselineLoaderTests
```

Expected: FAIL because the loader / fixture / bundled resource does not exist yet.

- [ ] **Step 3: Add baseline models, fixture README, first JSON, and test-bundle resource config**

Implement:
- `Codable` baseline structs with explicit top-level fields and sections: `id`, `input`, `expected.global`, `expected.palaces`, `source`
- `project.yml` resource wiring for `ZiWeiDoushuDianLiangXingKongTests/Fixtures/APKBaselines`
- loader that can decode one named fixture from the test bundle
- add `func makeChart() -> ZiWeiChart` on the fixture input model so tests can call `fixture.input.makeChart()`
- fixture README rules that explicitly require APK-sourced `expected` values and `source` traceability

- [ ] **Step 4: Run the test to verify it passes**

Run:

```bash
xcodebuild test \
  -scheme ZiWeiDoushuDianLiangXingKong \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ZiWeiDoushuDianLiangXingKongTests/APKBaselineLoaderTests
```

Expected: PASS and fixture decodes cleanly from the test bundle.

- [ ] **Step 5: Commit**

```bash
git add project.yml \
  ZiWeiDoushuDianLiangXingKongTests/Fixtures/APKBaselines/README.md \
  ZiWeiDoushuDianLiangXingKongTests/Fixtures/APKBaselines/core-fields-smoke.json \
  ZiWeiDoushuDianLiangXingKongTests/Support/APKBaselineCase.swift \
  ZiWeiDoushuDianLiangXingKongTests/Support/APKBaselineLoader.swift \
  ZiWeiDoushuDianLiangXingKongTests/APKBaselineLoaderTests.swift
git commit -m "test: add apk baseline fixture loader"
```

### Task 3: Build a Comparable Snapshot for `ZiWeiChart`

**Files:**
- Create: `ZiWeiDoushuDianLiangXingKongTests/Support/ZiWeiChartComparableSnapshot.swift`
- Create: `ZiWeiDoushuDianLiangXingKongTests/ZiWeiChartComparableSnapshotTests.swift`

- [ ] **Step 1: Write the failing snapshot-mapping test**

```swift
func testSnapshotCapturesCoreRegressionFields() {
    let chart = ZiWeiEngine.generateChart(
        year: 1990, month: 1, day: 1, hour: 12, minute: 0,
        isMale: true, timeInputMode: .clockTime,
        isLeapMonth: false, useMonthAdjustment: false, longitude: 120.0
    )

    let snapshot = ZiWeiChartComparableSnapshot(chart: chart)
    XCTAssertEqual(snapshot.global.mingGong, chart.mingGong)
    XCTAssertEqual(snapshot.global.shenGong, chart.shenGong)
    XCTAssertEqual(snapshot.palaces.count, 12)
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
xcodebuild test \
  -scheme ZiWeiDoushuDianLiangXingKong \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ZiWeiDoushuDianLiangXingKongTests/ZiWeiChartComparableSnapshotTests
```

Expected: FAIL because the snapshot type does not exist yet.

- [ ] **Step 3: Implement a stable snapshot shape**

Implement:
- global fields for `mingGong`, `shenGong`, `siHuaInfo`, `isShun`, and comparable age-range fields
- palace-level comparable fields focused on position, key stars, transforms, and big-luck ranges
- deterministic ordering so repeated runs produce the same comparison output

- [ ] **Step 4: Run the test to verify it passes**

Run:

```bash
xcodebuild test \
  -scheme ZiWeiDoushuDianLiangXingKong \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ZiWeiDoushuDianLiangXingKongTests/ZiWeiChartComparableSnapshotTests
```

Expected: PASS and snapshot content is stable enough for fixture comparison.

- [ ] **Step 5: Commit**

```bash
git add \
  ZiWeiDoushuDianLiangXingKongTests/Support/ZiWeiChartComparableSnapshot.swift \
  ZiWeiDoushuDianLiangXingKongTests/ZiWeiChartComparableSnapshotTests.swift
git commit -m "test: add comparable ziwei chart snapshot"
```

### Task 4: Add APK-Driven Regression Tests for Core Fields

**Files:**
- Create: `ZiWeiDoushuDianLiangXingKongTests/APKBaselineRegressionTests.swift`
- Create: `ZiWeiDoushuDianLiangXingKongTests/Fixtures/APKBaselines/daxian-direction-smoke.json`
- Create: `ZiWeiDoushuDianLiangXingKongTests/Fixtures/APKBaselines/sihua-smoke.json`
- Create: `ZiWeiDoushuDianLiangXingKongTests/Fixtures/APKBaselines/star-placement-smoke.json`

- [ ] **Step 1: Write the failing regression test**

```swift
func testCoreBaselineFixturesMatchIOSOutput() throws {
    let fixtures = try APKBaselineLoader.loadAll()
    XCTAssertFalse(fixtures.isEmpty)

    for fixture in fixtures {
        let chart = fixture.input.makeChart()
        let snapshot = ZiWeiChartComparableSnapshot(chart: chart)
        XCTAssertEqual(snapshot.global.mingGong, fixture.expected.global.mingGong, fixture.id)
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
xcodebuild test \
  -scheme ZiWeiDoushuDianLiangXingKong \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ZiWeiDoushuDianLiangXingKongTests/APKBaselineRegressionTests
```

Expected: FAIL because the regression test and baseline comparison logic do not exist yet.

- [ ] **Step 3: Implement comparison helpers and fixture iteration**

Implement:
- implement `fixture.input.makeChart()` on the input model as the canonical way to turn one fixture input into one `ZiWeiChart`
- core-field assertions for all first-wave targets from the spec: `mingGong`, `shenGong`, `siHuaInfo`, `isShun` / big-luck direction, age-range fields, and selected major-star placements
- clear failure messages that name the fixture ID and the mismatched field

- [ ] **Step 4: Run the regression test to verify it passes**

Run:

```bash
xcodebuild test \
  -scheme ZiWeiDoushuDianLiangXingKong \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ZiWeiDoushuDianLiangXingKongTests/APKBaselineRegressionTests
```

Expected: PASS for the first batch of curated APK baselines.

- [ ] **Step 5: Commit**

```bash
git add \
  ZiWeiDoushuDianLiangXingKongTests/APKBaselineRegressionTests.swift \
  ZiWeiDoushuDianLiangXingKongTests/Fixtures/APKBaselines/daxian-direction-smoke.json \
  ZiWeiDoushuDianLiangXingKongTests/Fixtures/APKBaselines/sihua-smoke.json \
  ZiWeiDoushuDianLiangXingKongTests/Fixtures/APKBaselines/star-placement-smoke.json
git commit -m "test: add apk baseline regression suite"
```

### Task 5: Document the Capture Workflow and Stabilize the Run Command

**Files:**
- Create: `docs/apk-baselines/capture-workflow.md`
- Create: `scripts/run-apk-baseline-tests.sh`
- Modify: `README.md`

- [ ] **Step 1: Write a failing syntax-and-presence check for the wrapper command**

```bash
bash -n ./scripts/run-apk-baseline-tests.sh
```

Expected: FAIL because the script does not exist yet.

- [ ] **Step 2: Write the capture-workflow doc**

Document:
- how to launch the APK
- how to collect one chart's result fields
- how to map that result into one JSON fixture
- how to mark source and confidence

- [ ] **Step 3: Add the wrapper script and README instructions**

Implement:
- a shell wrapper that runs the regression suite with one stable command
- README section describing the APK-baseline layer and local command to run it

- [ ] **Step 4: Run the wrapper checks to verify they pass**

Run:

```bash
bash -n ./scripts/run-apk-baseline-tests.sh
./scripts/run-apk-baseline-tests.sh
```

Expected: PASS and it executes the same `xcodebuild` regression suite consistently.

- [ ] **Step 5: Commit**

```bash
git add \
  docs/apk-baselines/capture-workflow.md \
  scripts/run-apk-baseline-tests.sh \
  README.md
git commit -m "docs: add apk baseline capture workflow"
```

### Task 6: Run the Full Relevant Test Slice Before Handoff

**Files:**
- Test: `ZiWeiDoushuDianLiangXingKongTests/APKBaselineLoaderTests.swift`
- Test: `ZiWeiDoushuDianLiangXingKongTests/ZiWeiChartComparableSnapshotTests.swift`
- Test: `ZiWeiDoushuDianLiangXingKongTests/APKBaselineRegressionTests.swift`

- [ ] **Step 1: Run the new APK-baseline test slice**

Run:

```bash
xcodebuild test \
  -scheme ZiWeiDoushuDianLiangXingKong \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ZiWeiDoushuDianLiangXingKongTests/APKBaselineLoaderTests \
  -only-testing:ZiWeiDoushuDianLiangXingKongTests/ZiWeiChartComparableSnapshotTests \
  -only-testing:ZiWeiDoushuDianLiangXingKongTests/APKBaselineRegressionTests
```

Expected: PASS for the whole new regression slice.

- [ ] **Step 2: Run the existing parsing / helper tests as a regression safety check**

Run:

```bash
xcodebuild test \
  -scheme ZiWeiDoushuDianLiangXingKong \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ZiWeiDoushuDianLiangXingKongTests/ChartInputTests \
  -only-testing:ZiWeiDoushuDianLiangXingKongTests/LunarCalendarConverterTests \
  -only-testing:ZiWeiDoushuDianLiangXingKongTests/TrueSolarTimeTests \
  -only-testing:ZiWeiDoushuDianLiangXingKongTests/ZiWeiEnginePureHelpersTests
```

Expected: PASS and no unrelated regression introduced by the new test harness.

- [ ] **Step 3: Verify the planned files are clean after the final test slice**

```bash
git status
```

Expected: clean working tree for the files covered by this plan.

## Review Checklist

Before implementation handoff, verify the plan still satisfies the spec:

- APK output remains the only truth source
- baseline fixtures are externalized and reviewable
- the first test wave only covers the agreed core result fields
- the environment work stays in service of result capture, not as a standalone project
- UI optimization remains outside this plan

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-03-27-apk-baseline-regression.md`. Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
