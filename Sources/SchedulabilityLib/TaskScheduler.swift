import DDKit

final class TaskScheduler: Morphism {

  typealias DD = ScheduleSet

  /// The the task to schedule.
  let task: Task

  /// The ID of the core on which the task should be scheduled.
  let coreID: Int

  /// The system's gobal deadline.
  let globalDeadline: Int

  /// The factory that creates the nodes handled by this morphism.
  unowned let factory: ScheduleSet.Factory

  /// The morphism's cache.
  private var cache: [ScheduleSet.Pointer: ScheduleSet.Pointer] = [:]

  init(task: Task, coreID: Int, globalDeadline: Int, factory: ScheduleSet.Factory) {
    self.task = task
    self.coreID = coreID
    self.globalDeadline = globalDeadline
    self.factory = factory
  }

  func apply(on pointer: ScheduleSet.Pointer) -> ScheduleSet.Pointer {
    // Check for trivial cases.
    guard pointer != factory.zero.pointer
      else { return factory.zero.pointer }

    // This morphism must be applied on the part of the DD that encodes the state of each core.
    // Hence we can assert that it can't be the one terminal. Furthermore, since the cores are
    // always part of the encoding, we can assert that the skip branch is the zero terminal.
    assert(pointer != factory.one.pointer, "bad encoding")
    assert(pointer.pointee.key < .task(id: 0) && pointer.pointee.skip == factory.zero.pointer)

    // Query the cache.
    if let result = cache[pointer] {
      return result
    }
    let result: ScheduleSet.Pointer

    // Read the current clocks of the core on which the task should be scheduled.
    if pointer.pointee.key < .core(id: coreID) {
      // Just move down to the next node.
      result = factory.node(
        key: pointer.pointee.key,
        take: pointer.pointee.take.mapValues(apply(on:)),
        skip: factory.zero.pointer)
    } else if pointer.pointee.key == .core(id: coreID) {
      // Schedule the task on each path.
      var take: [ScheduleValue: ScheduleSet.Pointer] = [:]

      let release = task.dependencies.isEmpty
        ? task.release
        : max(task.release, task.dependencies.map({ dep in dep.release + dep.wcet }).max()!)
      let deadline = task.deadline == nil
        ? globalDeadline
        : min(task.deadline!, globalDeadline)

      for (arc, child) in pointer.pointee.take {
        // Compute the minimal ETS and ETA of the task.
        let ets = max(release, arc.clock)
        let eta = ets + task.wcet
        guard eta <= deadline
          else { continue }

        // Schedule the task for all possible time slots that satisfy both its deadline (if any)
        // and the global deadline.
        for offset in 0 ... (deadline - eta) {
          // Build a core/clock pair that identifies the core associated with this morphism and the
          // earliest time at which the task can be scheduled on it.
          let assignments = [
            ScheduleKey.task(id: task.id): ScheduleValue(coreID: arc.coreID, clock: ets + offset)
          ]

          // Insert the computed task assignment into the decision diagram.
          let insert = factory.morphisms.insert(assignments: assignments)
          let arcKey = ScheduleValue(coreID: coreID, clock: eta + offset)
          if let node = take[arcKey] {
            take[arcKey] = factory.union(node, insert.apply(on: child))
          } else {
            take[arcKey] = insert.apply(on: child)
          }
        }
      }

      result = factory.node(key: .core(id: coreID), take: take, skip: factory.zero.pointer)
    } else {
      // This shouldn't be reachable, as the representing the core associated with this morphism
      // should have been visited higher in the call stack.
      fatalError("unreachable")
    }

    cache[pointer] = result
    return result
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(task)
    hasher.combine(coreID)
    hasher.combine(globalDeadline)
  }

  static func == (lhs: TaskScheduler, rhs: TaskScheduler) -> Bool {
    return (lhs.task == rhs.task)
        && (lhs.coreID == rhs.coreID)
        && (lhs.globalDeadline == rhs.globalDeadline)
  }

}
