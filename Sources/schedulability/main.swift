import Foundation
import ArgumentParser
import SchedulabilityLib

/// Pretty print a scheduling.
private func pprint(schedule: [ScheduleKey : ScheduleValue]) {
  let tasks = schedule.keys.filter({ $0.isTaskID })

  // Print the current clock of each core.
  for coreKey in schedule.keys.filter({ $0.isCoreID }).sorted() {
    print("\(coreKey) @ \(schedule[coreKey]!.clock): ", terminator: "")

    // Identify the tasks that are scheduled on the current core and order them according to the
    // scheduled execution order.
    let coreTasks = tasks.filter({ schedule[$0]?.coreID == coreKey.coreID })
      .sorted(by: { a, b in
        schedule[a]!.clock < schedule[b]!.clock
      })

    print(coreTasks.map({ "t\($0.taskID):\(schedule[$0]!.clock)" }).joined(separator: ", "))
  }
}

struct SchedulabilityCommand: ParsableCommand {

  /// Command that computes the schedule set of a given task model.
  struct Compute: ParsableCommand {

    @Option(default: 2, help: "The number of available cores")
    var coreCount: Int

    @Option(default: 1024, help: "The factory's bucket capacity")
    var bucketCapacity: Int

    @Flag(help: "Pretty-prints all found schedules")
    var show: Bool

    @Argument(default: nil, help: "The path to a task model")
    var taskModel: String

    func run() throws {
      // Try to read the input task model.
      guard let input = try? Data(contentsOf: URL(fileURLWithPath: taskModel))
        else { fatalError("Couldn't read from '\(taskModel)'!") }

      let decoder = JSONDecoder()
      decoder.userInfo[TaskModel.decodingContext] = TaskDecodingContext()
      let model = try decoder.decode(TaskModel.self, from: input)

      let globalDeadline = model.tasks.values
        .map({ task in task.deadline ?? task.release + task.wcet })
        .max() ?? 0

      let factory = ScheduleSet.Factory(bucketCapacity: bucketCapacity)
      var schedules: ScheduleSet = factory.zero
      let elapsed = measure {
        schedules = model.schedules(
          coreCount: coreCount,
          globalDeadline: globalDeadline,
          with: factory)
      }

      // Filter out the schedules that aren't feasibly (note that we can assume all schedulings
      // were consistent by construction).
      let keys = model.tasks.values.map({ task in ScheduleKey.task(id: task.id) })
      let filter = factory.morphisms.filter(containingKeys: keys)
      schedules = filter.apply(on: schedules)

      print(
        "Possible schedules: \(schedules.count) " +
        "(\(factory.createdCount) nodes created in \(elapsed.humanFormat))")

      if show {
        for schedule in schedules {
          pprint(schedule: schedule)
          print()
        }
      }
    }

  }

  /// Command that generates a random task model.
  struct Generate: ParsableCommand {

    @Argument(default: nil, help: "The number of tasks in the model")
    var taskCount: Int

    @Option(default: 4, help: "Maximum number of dependencies")
    var maxDepCount: Int

    @Option(default: 0.1, help: "Probability of a task being a dependency to another")
    var depProb: Float

    @Argument(default: nil, help: "The path to the output file")
    var output: String

    func run() throws {
      var tasks: [Task] = []
      for i in (0 ..< taskCount).reversed() {
        let dependencies = tasks
          .shuffled()
          .prefix(maxDepCount)
          .filter({ _ in Float.random(in: 0.0 ..< 1.0) < depProb })

        let release = Int.random(in: 0 ..< taskCount * 10)
        let wcet = Int.random(in: 1 ..< 5)
        let deadline = release + wcet + Int.random(in: 0 ..< 5)
        tasks.append(Task(
          id: i,
          release: release,
          deadline: deadline,
          wcet: wcet,
          dependencies: Set(dependencies)))
      }

      let model = TaskModel(tasks: Set(tasks))
      let encoder = JSONEncoder()
      let data = try encoder.encode(model)
      try data.write(to: URL(fileURLWithPath: self.output))
    }

  }

  static let configuration = CommandConfiguration(
    abstract: "Task schedulability utilities.",
    subcommands: [Compute.self, Generate.self])

}

SchedulabilityCommand.main()
