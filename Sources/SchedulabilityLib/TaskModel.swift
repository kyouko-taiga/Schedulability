import DDKit

/// A task model.
public struct TaskModel: Codable {

  /// The tasks contained in this model.
  public let tasks: [Int: Task]

  public init(tasks: Set<Task>) {
    self.tasks = Dictionary(uniqueKeysWithValues: tasks.map({ task in
      (key: task.id, value: task)
    }))
  }

  public init(tasks: () throws -> Set<Task>) rethrows {
    self.init(tasks: try tasks())
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let tasks = try container.decode([Task].self)
    self.tasks = Dictionary(uniqueKeysWithValues: tasks.map({ task in
      (key: task.id, value: task)
    }))
  }

  public func encode(to encoder: Encoder) throws {
    try self.tasks.values
      .sorted(by: { a, b in a.id > b.id })
      .encode(to: encoder)
  }

  public func schedules(
    coreCount: Int,
    globalDeadline: Int,
    with factory: ScheduleSet.Factory
  ) -> ScheduleSet {
    // Start with a DD that maps each core to an empty set of task and an initial clock.
    let initialMapping = Dictionary<ScheduleKey, ScheduleValue>(
      uniqueKeysWithValues: (0 ..< coreCount).map({ coreID in
        (key: .core(id: coreID), value: ScheduleValue(coreID: coreID, clock: 0))
      }))
    var dd = factory.encode(family: [initialMapping])

    var morphisms: [AnyMorphism<ScheduleSet>] = []
    for (taskID, task) in tasks {
      // Create a filter that removes all schedules where the task has already been executed.
      let filterUnscheduled = factory.morphisms.saturate(
        factory.morphisms.filter(excludingKeys: [.task(id: taskID)]))

      // Create a morphism that schedule the task on each core.
      let schedule = factory.morphisms.union(
        of: (0 ..< coreCount).map({ (coreID: Int) -> TaskScheduler in
          let morphism = TaskScheduler(
            task: task,
            coreID: coreID,
            globalDeadline: globalDeadline,
            factory: factory)
          return factory.morphisms.uniquify(morphism)
        }))

      let phi = factory.morphisms.composition(of: schedule, with: filterUnscheduled)
      morphisms.append(AnyMorphism(phi))
    }

    // Compute the space of all possible task assignments.
    let identity = factory.morphisms.identity
    let generator = factory.morphisms
      .fixedPoint(of: factory.morphisms.union(of: morphisms + [AnyMorphism(identity)]))
    dd = generator.apply(on: dd)

    // Filter out solutions that do not satisfy task dependencies.
    let locator = TaskDependencyConstraintLocator(model: self, factory: factory)
    dd = locator.apply(on: dd)

    return dd
  }

}
