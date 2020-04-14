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
    let schedules = model.schedules(coreCount: 2, globalDeadline: 10, with: factory)

    XCTAssertEqual(schedules.count, 325)
  }

}
