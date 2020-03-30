import XCTest

import SchedulabilityLib

final class TaskModelTests: XCTestCase {

  /// Tests the generation of all possible schedulings given a task model.
  ///
  /// The task model in this test is composed of three tasks. The first one is released after 1
  /// time unit, so as to test the proper computation of the ETS for itself and its dependencies.
  /// The second one has no particular constraint, so it can be scheduled anywhere. The last one
  /// depends on the first, so as to test the dependency checker, and has a short deadline, so as
  /// to test the deadline satisfaction.
  func testSchedulings() {
    // Create the task model.
    let model = TaskModel {
      let t2 = Task(id: 2, release: 1, wcet: 1)
      let t1 = Task(id: 1, wcet: 3)
      let t0 = Task(id: 0, deadline: 4, wcet: 2, dependencies: [t2])

      return [t0, t1, t2]
    }

    // Compute all possible schedulings on a two-cores architectures.
    let factory = ScheduleSet.Factory()
    let schedulings = model.schedulings(coreCount: 2, with: factory)

    XCTAssertEqual(schedulings.count, 23)

    // core(0) @ 0: -
    // core(1) @ 0: -
    XCTAssert(schedulings.contains([
      .core(id: 0): .init(coreID: 0, clock: 0),
      .core(id: 1): .init(coreID: 1, clock: 0),
    ]))

    // core(0) @ 3: t1:0
    // core(1) @ 0: -
    XCTAssert(schedulings.contains([
      .core(id: 0): .init(coreID: 0, clock: 3),
      .core(id: 1): .init(coreID: 1, clock: 0),
      .task(id: 1): .init(coreID: 0, clock: 0),
    ]))

    // core(0) @ 0: -
    // core(1) @ 3: t1:0
    XCTAssert(schedulings.contains([
      .core(id: 0): .init(coreID: 0, clock: 0),
      .core(id: 1): .init(coreID: 1, clock: 3),
      .task(id: 1): .init(coreID: 1, clock: 0),
    ]))

    // core(0) @ 2: t2:1
    // core(1) @ 0: -
    XCTAssert(schedulings.contains([
      .core(id: 0): .init(coreID: 0, clock: 2),
      .core(id: 1): .init(coreID: 1, clock: 0),
      .task(id: 2): .init(coreID: 0, clock: 1),
    ]))

    // core(0) @ 0: -
    // core(1) @ 2: t2:1
    XCTAssert(schedulings.contains([
      .core(id: 0): .init(coreID: 0, clock: 0),
      .core(id: 1): .init(coreID: 1, clock: 2),
      .task(id: 2): .init(coreID: 1, clock: 1),
    ]))

    // core(0) @ 4: t1:0, t2:3
    // core(1) @ 0: -
    XCTAssert(schedulings.contains([
      .core(id: 0): .init(coreID: 0, clock: 4),
      .core(id: 1): .init(coreID: 1, clock: 0),
      .task(id: 1): .init(coreID: 0, clock: 0),
      .task(id: 2): .init(coreID: 0, clock: 3),
    ]))

    // core(0) @ 0: -
    // core(1) @ 4: t1:0, t2:3
    XCTAssert(schedulings.contains([
      .core(id: 0): .init(coreID: 0, clock: 0),
      .core(id: 1): .init(coreID: 1, clock: 4),
      .task(id: 1): .init(coreID: 1, clock: 0),
      .task(id: 2): .init(coreID: 1, clock: 3),
    ]))

    // core(0) @ 5: t2:1, t1:2
    // core(1) @ 0: -
    XCTAssert(schedulings.contains([
      .core(id: 0): .init(coreID: 0, clock: 5),
      .core(id: 1): .init(coreID: 1, clock: 0),
      .task(id: 1): .init(coreID: 0, clock: 2),
      .task(id: 2): .init(coreID: 0, clock: 1),
    ]))

    // core(0) @ 0: -
    // core(1) @ 5: t2:1, t1:2
    XCTAssert(schedulings.contains([
      .core(id: 0): .init(coreID: 0, clock: 0),
      .core(id: 1): .init(coreID: 1, clock: 5),
      .task(id: 1): .init(coreID: 1, clock: 2),
      .task(id: 2): .init(coreID: 1, clock: 1),
    ]))

    // core(0) @ 3: t1:0
    // core(1) @ 2: t2:1
    XCTAssert(schedulings.contains([
      .core(id: 0): .init(coreID: 0, clock: 3),
      .core(id: 1): .init(coreID: 1, clock: 2),
      .task(id: 1): .init(coreID: 0, clock: 0),
      .task(id: 2): .init(coreID: 1, clock: 1),
    ]))

    // core(0) @ 2: t2:1
    // core(1) @ 3: t1:0
    XCTAssert(schedulings.contains([
      .core(id: 0): .init(coreID: 0, clock: 2),
      .core(id: 1): .init(coreID: 1, clock: 3),
      .task(id: 1): .init(coreID: 1, clock: 0),
      .task(id: 2): .init(coreID: 0, clock: 1),
    ]))

    // core(0) @ 4: t2:1, t0:2
    // core(1) @ 0: -
    XCTAssert(schedulings.contains([
      .core(id: 0): .init(coreID: 0, clock: 4),
      .core(id: 1): .init(coreID: 1, clock: 0),
      .task(id: 0): .init(coreID: 0, clock: 2),
      .task(id: 2): .init(coreID: 0, clock: 1),
    ]))

    // core(0) @ 0: -
    // core(1) @ 4: t2:1, t0:2
    XCTAssert(schedulings.contains([
      .core(id: 0): .init(coreID: 0, clock: 0),
      .core(id: 1): .init(coreID: 1, clock: 4),
      .task(id: 0): .init(coreID: 1, clock: 2),
      .task(id: 2): .init(coreID: 1, clock: 1),
    ]))

    // core(0) @ 4: t0:2
    // core(1) @ 2: t2:1
    XCTAssert(schedulings.contains([
      .core(id: 0): .init(coreID: 0, clock: 4),
      .core(id: 1): .init(coreID: 1, clock: 2),
      .task(id: 0): .init(coreID: 0, clock: 2),
      .task(id: 2): .init(coreID: 1, clock: 1),
    ]))

    // core(0) @ 2: t2:1
    // core(1) @ 4: t0:2
    XCTAssert(schedulings.contains([
      .core(id: 0): .init(coreID: 0, clock: 2),
      .core(id: 1): .init(coreID: 1, clock: 4),
      .task(id: 0): .init(coreID: 1, clock: 2),
      .task(id: 2): .init(coreID: 0, clock: 1),
    ]))

    // core(0) @ 7: t2:1, t0:2, t1:4
    // core(1) @ 0: -
    XCTAssert(schedulings.contains([
      .core(id: 0): .init(coreID: 0, clock: 7),
      .core(id: 1): .init(coreID: 1, clock: 0),
      .task(id: 0): .init(coreID: 0, clock: 2),
      .task(id: 1): .init(coreID: 0, clock: 4),
      .task(id: 2): .init(coreID: 0, clock: 1),
    ]))

    // core(0) @ 0: -
    // core(1) @ 7: t2:1, t0:2, t1:4
    XCTAssert(schedulings.contains([
      .core(id: 0): .init(coreID: 0, clock: 0),
      .core(id: 1): .init(coreID: 1, clock: 7),
      .task(id: 0): .init(coreID: 1, clock: 2),
      .task(id: 1): .init(coreID: 1, clock: 4),
      .task(id: 2): .init(coreID: 1, clock: 1),
    ]))

    // core(0) @ 7: t0:2, t1:4
    // core(1) @ 2: t2:1
    XCTAssert(schedulings.contains([
      .core(id: 0): .init(coreID: 0, clock: 7),
      .core(id: 1): .init(coreID: 1, clock: 2),
      .task(id: 0): .init(coreID: 0, clock: 2),
      .task(id: 1): .init(coreID: 0, clock: 4),
      .task(id: 2): .init(coreID: 1, clock: 1),
    ]))

    // core(0) @ 2: t2:1
    // core(1) @ 7: t0:2, t1:4
    XCTAssert(schedulings.contains([
      .core(id: 0): .init(coreID: 0, clock: 2),
      .core(id: 1): .init(coreID: 1, clock: 7),
      .task(id: 0): .init(coreID: 1, clock: 2),
      .task(id: 1): .init(coreID: 1, clock: 4),
      .task(id: 2): .init(coreID: 0, clock: 1),
    ]))

    // core(0) @ 5: t2:1, t1:2
    // core(1) @ 4: t0:2
    XCTAssert(schedulings.contains([
      .core(id: 0): .init(coreID: 0, clock: 5),
      .core(id: 1): .init(coreID: 1, clock: 4),
      .task(id: 0): .init(coreID: 1, clock: 2),
      .task(id: 1): .init(coreID: 0, clock: 2),
      .task(id: 2): .init(coreID: 0, clock: 1),
    ]))

    // core(0) @ 4: t0:2
    // core(1) @ 5: t2:1, t1:2
    XCTAssert(schedulings.contains([
      .core(id: 0): .init(coreID: 0, clock: 4),
      .core(id: 1): .init(coreID: 1, clock: 5),
      .task(id: 0): .init(coreID: 0, clock: 2),
      .task(id: 1): .init(coreID: 1, clock: 2),
      .task(id: 2): .init(coreID: 1, clock: 1),
    ]))

    // core(0) @ 4: t2:1, t0:2
    // core(1) @ 3: t1:0
    XCTAssert(schedulings.contains([
      .core(id: 0): .init(coreID: 0, clock: 4),
      .core(id: 1): .init(coreID: 1, clock: 3),
      .task(id: 0): .init(coreID: 0, clock: 2),
      .task(id: 1): .init(coreID: 1, clock: 0),
      .task(id: 2): .init(coreID: 0, clock: 1),
    ]))

    // core(0) @ 3: t1:0
    // core(1) @ 4: t2:1, t0:2
    XCTAssert(schedulings.contains([
      .core(id: 0): .init(coreID: 0, clock: 3),
      .core(id: 1): .init(coreID: 1, clock: 4),
      .task(id: 0): .init(coreID: 1, clock: 2),
      .task(id: 1): .init(coreID: 0, clock: 0),
      .task(id: 2): .init(coreID: 1, clock: 1),
    ]))
  }

}
