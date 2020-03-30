import SchedulabilityLib

func print(scheduling: [ScheduleKey : ScheduleValue]) {
  let tasks = scheduling.keys.filter({ $0.isTaskID })

  // Print the current clock of each core.
  for coreKey in scheduling.keys.filter({ $0.isCoreID }).sorted() {
    print("\(coreKey) @ \(scheduling[coreKey]!.clock): ", terminator: "")

    // Identify the tasks that are scheduled on the current core and order them according to the
    // scheduled execution order.
    let coreTasks = tasks.filter({ scheduling[$0]?.coreID == coreKey.coreID })
      .sorted(by: { a, b in
        scheduling[a]!.clock < scheduling[b]!.clock
      })

    print(coreTasks.map({ "t\($0.taskID):\(scheduling[$0]!.clock)" }).joined(separator: ", "))
  }
}

let factory = ScheduleSet.Factory()

let model = TaskModel {
  let t2 = Task(id: 2, release: 1, wcet: 1)
  let t1 = Task(id: 1, wcet: 3)
  let t0 = Task(id: 0, deadline: 4, wcet: 2, dependencies: [t2])

  return [t0, t1, t2]
}

let schedulings = model.schedulings(coreCount: 2, with: factory)
print("Number of possible schedulings: \(schedulings.count)")
print("Number of nodes created: \(factory.createdCount)\n")

//print(schedulings.randomElement() as Any)
//if let scheduling = schedulings.randomElement() {
//  print(scheduling: scheduling)
//}
for scheduling in schedulings {
  print(scheduling: scheduling)
  print()
}
