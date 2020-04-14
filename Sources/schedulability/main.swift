import SchedulabilityLib

func print(schedule: [ScheduleKey : ScheduleValue]) {
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

func main() {
  let factory = ScheduleSet.Factory(bucketCapacity: 1 << 15)

  let model = TaskModel {
    let t2 = Task(id: 2, release: 1, wcet: 1)
    let t1 = Task(id: 1, wcet: 3)
    let t0 = Task(id: 0, deadline: 4, wcet: 2, dependencies: [t2])

    return [t0, t1, t2]
  }

  var schedules: ScheduleSet = factory.zero
  let elapsed = measure {
    schedules = model.schedules(coreCount: 2, globalDeadline: 10, with: factory)
  }

  print(
    "Possible schedules: \(schedules.count) " +
    "(\(factory.createdCount) nodes created in \(elapsed.humanFormat))")

//  // Print one schedule at random.
//  if let schedule = schedules.randomElement() {
//    print(schedule: schedule)
//  }

//  // Print all schedules.
//  for schedule in schedules {
//    print(schedule: schedule)
//    print()
//  }

}

main()
