import DDKit

final class TaskDependencyFilter: Morphism, MFDDSaturable {

  typealias DD = ScheduleSet

  /// The IDs of each dependency that has to be checked.
  public let dependencies: [Int]

  /// The time before which the dependency should have been executed.
  public let deadline: Int

  /// The task model.
  public let model: TaskModel

  /// The next morphism to apply once the first assignment has been processed.
  private var next: ScheduleSet.SaturatedMorphism<TaskDependencyFilter>?

  /// The factory that creates the nodes handled by this morphism.
  public unowned let factory: ScheduleSet.Factory

  /// The morphism's cache.
  private var cache: [ScheduleSet.Pointer: ScheduleSet.Pointer] = [:]

  public var lowestRelevantKey: ScheduleKey { .task(id: dependencies.min()!) }

  init(dependencies: [Int], deadline: Int, model: TaskModel, factory: ScheduleSet.Factory) {
    assert(dependencies.count > 0)
    self.dependencies = dependencies.sorted()
    self.next = dependencies.count > 1
      ? factory.morphisms.saturate(
        factory.morphisms.uniquify(TaskDependencyFilter(
          dependencies: Array(self.dependencies.dropFirst()),
          deadline: deadline,
          model: model,
          factory: factory)))
      : nil

    self.deadline = deadline
    self.model = model
    self.factory = factory
  }

  func apply(on pointer: ScheduleSet.Pointer) -> ScheduleSet.Pointer {
    // Check for trivial cases.
    guard !factory.isTerminal(pointer)
      else { return factory.zero.pointer }

    // Query the cache.
    if let result = cache[pointer] {
      return result
    }
    let result: ScheduleSet.Pointer

    // Check that the given dependencies are satisfied.
    if pointer.pointee.key < .task(id: dependencies[0]) {
      // Just move down to the next node.
      result = factory.node(
        key: pointer.pointee.key,
        take: pointer.pointee.take.mapValues(apply(on:)),
        skip: apply(on: pointer.pointee.skip))
    } else if pointer.pointee.key == .task(id: dependencies[0]) {
      // Retrieve the task's description from the model.
      let task = model.tasks[pointer.pointee.key.taskID]!

      // Only keep take branches for which the time at which the task will be completed is lower or
      // equal to this morphism's deadline.
      var take: [ScheduleValue: ScheduleSet.Pointer] = [:]
      for (arc, child) in pointer.pointee.take where arc.clock + task.wcet <= deadline {
        take[arc] = next?.apply(on: child) ?? child
      }

      result = factory.node(
        key: pointer.pointee.key,
        take: take,
        skip: factory.zero.pointer)
    } else {
      result = factory.zero.pointer
    }

    cache[pointer] = result
    return result
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(dependencies)
    hasher.combine(deadline)
  }

  static func == (lhs: TaskDependencyFilter, rhs: TaskDependencyFilter) -> Bool {
    return (lhs.dependencies == rhs.dependencies)
        && (lhs.deadline == rhs.deadline)
  }

}
