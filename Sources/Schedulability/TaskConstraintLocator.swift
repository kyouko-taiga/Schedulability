import DDKit

final class TaskDependencyConstraintLocator: Morphism {

  typealias DD = ScheduleSet

  /// The task model.
  public let model: TaskModel

  /// The factory that creates the nodes handled by this morphism.
  public unowned let factory: ScheduleSet.Factory

  /// The morphism's cache.
  private var cache: [ScheduleSet.Pointer: ScheduleSet.Pointer] = [:]

  init(model: TaskModel, factory: ScheduleSet.Factory) {
    self.model = model
    self.factory = factory
  }

  func apply(on pointer: ScheduleSet.Pointer) -> ScheduleSet.Pointer {
    // Check for trivial cases.
    guard !factory.isTerminal(pointer)
      else { return pointer }

    // Query the cache.
    if let result = cache[pointer] {
      return result
    }
    let result: ScheduleSet.Pointer

    if pointer.pointee.key.isCoreID {
      // Just move down to the next node.
      assert(pointer.pointee.skip == factory.zero.pointer)
      result = factory.node(
        key: pointer.pointee.key,
        take: pointer.pointee.take.mapValues(apply(on:)),
        skip: factory.zero.pointer)
    } else if let task = model.tasks[pointer.pointee.key.taskID] {
      if task.dependencies.isEmpty {
        // The current task has no dependencies, so we can just move on to the next.
        result = factory.node(
          key: pointer.pointee.key,
          take: pointer.pointee.take.mapValues(apply(on:)),
          skip: apply(on: pointer.pointee.skip))
      } else {
        // The current task has dependencies that should be checked. Therefore we need to compute
        // on each take branch the intersection of the DD returned by the recursive application of
        // this morphism (which will check dependencies for the remaining tasks) with the DD
        // obtained after filtering out paths that do not satisfy this task's dependencies.
        var take = pointer.pointee.take.mapValues(apply(on:))
        for (arc, child) in take {
          let filter = factory.morphisms.saturate(
            factory.morphisms.uniquify
              TaskDependencyFilter(
                dependencies: task.dependencies.map({ $0.id }),
                deadline: arc.clock,
                model: model,
                factory: factory)))
          take[arc] = filter.apply(on: child)
        }

        result = factory.node(
          key: pointer.pointee.key,
          take: take,
          skip: apply(on: pointer.pointee.skip))
      }
    } else {
      // This should be unreachable, as there can't be a task in the DD that wasn't in the model.
      fatalError("unreachable")
    }

    cache[pointer] = result
    return result
  }

  public func hash(into hasher: inout Hasher) {
  }

  static func == (
    lhs: TaskDependencyConstraintLocator,
    rhs: TaskDependencyConstraintLocator
  ) -> Bool {
    return lhs === rhs
  }

}
