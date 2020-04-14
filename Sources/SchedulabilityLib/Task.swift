/// The description of a task to be scheduled.
public final class Task: Codable {

  /// The task's ID.
  public let id: Int

  /// The task's release time (i.e. the earliest time it is available to process).
  public let release: Int

  /// The task's deadline (i.e. the latest time at which the task can be completed).
  public let deadline: Int?

  /// The task's worst-case execution time.
  ///
  /// The wors-case execution time (WCET) is the maximum lenght of time the task could take to
  /// execute on the system.
  public let wcet: Int

  /// The task's dependencies.
  ///
  /// Task dependencies are other tasks that must be completed before this task can start.
  ///
  /// - Note: This property is declared `let` so as to avoid cyclic dependencies.
  public let dependencies: Set<Task>

  public init(id: Int, release: Int = 0, deadline: Int? = nil, wcet: Int, dependencies: Set<Task> = []) {
    precondition(wcet > 0, "The task's WCET must be greater than 0.")
    precondition(dependencies.allSatisfy({ $0.id > id }), "Dependencies must have greater IDs.")

    self.id = id
    self.release = release
    self.deadline = deadline
    self.wcet = wcet
    self.dependencies = dependencies
  }

  public init(from decoder: Decoder) throws {
    guard let context = decoder.userInfo[TaskModel.decodingContext] as? TaskDecodingContext
      else { throw TaskDecodingError.missingOrInvalidDecodingContext }
    let container = try decoder.container(keyedBy: Task.CodingKeys.self)

    self.id = try container.decode(Int.self, forKey: .id)
    self.release = try container.decodeIfPresent(Int.self, forKey: .release) ?? 0
    self.deadline = try container.decodeIfPresent(Int.self, forKey: .deadline)
    self.wcet = try container.decode(Int.self, forKey: .wcet)

    // Handle dependencies, if present.
    if let dependencyIDs = try container.decodeIfPresent([Int].self, forKey: .dependencies) {
      self.dependencies = try Set(dependencyIDs.map({ (taskID: Int) -> Task in
        guard let task = context.decodedTasks[taskID]
          else { throw TaskDecodingError.undefinedDependency }
        return task
      }))
    } else {
      self.dependencies = []
    }

    // Add this task to the set of decoded tasks, so that it can be retrieved by ID.
    context.decodedTasks[self.id] = self
  }

}

extension Task: Hashable {

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  public static func == (lhs: Task, rhs: Task) -> Bool {
    return lhs === rhs
  }

}
