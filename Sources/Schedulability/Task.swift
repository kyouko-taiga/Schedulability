/// The description of a task to be scheduled.
class Task {

  /// The task's ID.
  let id: Int

  /// The task's worst-case execution time.
  ///
  /// The wors-case execution time (WCET) is the maximum lenght of time the task could take to
  /// execute on the system.
  let wcet: Int

  /// The task's dependencies.
  ///
  /// Task dependencies are other tasks that must be completed before this task can start.
  ///
  /// - Note: This property is declared `let` so as to avoid cyclic dependencies.
  let dependencies: Set<Task>

  init(id: Int, wcet: Int, dependencies: Set<Task> = []) {
    precondition(wcet > 0, "The task's WCET must be greater than 0.")
    precondition(dependencies.allSatisfy({ $0.id > id }), "Dependencies must have greater IDs.")

    self.id = id
    self.wcet = wcet
    self.dependencies = dependencies
  }

}

extension Task: Hashable {

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  static func == (lhs: Task, rhs: Task) -> Bool {
    return lhs === rhs
  }

}
