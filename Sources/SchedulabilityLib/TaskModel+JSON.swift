import Foundation

/// An error thrown when the JSON data used to initialize a TaskModel is invalid, incomplete, or
/// contains a circular dependency between tasks.
public enum SerializationError: Error, CustomStringConvertible, Equatable {

  case invalidConfiguration
  case missing(task: String, field: String)
  case invalid(task: String, field: String)
  case circularDependency(task1: String, task2: String)
  
  public var description: String {
    switch self {
    case .invalidConfiguration:
      return "Input configuration file does not follow a valid format"
    case .missing(let taskName, let fieldName):
      return "Task '\(taskName)' is missing field '\(fieldName)'"
    case .invalid(let taskName, let fieldName):
      return "Field '\(fieldName)' of task '\(taskName)' is invalid"
    case .circularDependency(let taskName1, let taskName2):
      return "Found circular dependency between '\(taskName1)' and '\(taskName2)'"
    }
  }

}

extension TaskModel {
  
  /// Initialize a task model from a JSON configuration file.
  ///
  /// - Parameter json: JSON data describing the configuration of the task model to initialize.
  public init(from json: Data) throws {
    // Read the configuration JSON as a dictionary.
    guard let jsonData = try JSONSerialization.jsonObject(with: json, options: [])
      as? [String: [String: Any]] else {
        throw SerializationError.invalidConfiguration
    }
    
    func buildTask(
      name: String,
      data: [String: Any],
      tasks: inout [String: Task],
      dependedOnBy: Set<String> = []
    ) throws {
      // Return if the current task has already been built previously (for example as a dependency
      // for another task).
      if tasks[name] != nil {
        return
      }
      
      // The 'id' field is compulsory for all tasks.
      guard let id = data["id"] as? Int else {
        throw SerializationError.missing(task: name, field: "id")
      }
      
      // So is 'wcet'.
      guard let wcet = data["wcet"] as? Int else {
        throw SerializationError.missing(task: name, field: "wcet")
      }
      
      let release = data["release"] as? Int ?? 0
      let deadline = data["deadline"] as? Int
      
      // Build all of the dependencies of the current task.
      let dependencyNames = data["dependencies"] as? [String] ?? []
      var dependencies: Set<Task> = []
      
      // The current task is added as a depending task for all of its dependencies.
      var newDependedOnBy = dependedOnBy
      newDependedOnBy.insert(name)
      
      for dependency in dependencyNames {
        // If one of the tasks the current task depends on is among its dependencies, we have a
        // circular dependency and throw an error.
        if dependedOnBy.contains(dependency) {
          throw SerializationError.circularDependency(task1: name, task2: dependency)
        }
        
        // Check that the dependencies of the current task are all defined in the configuration
        // file.
        if jsonData[dependency] == nil {
          throw SerializationError.invalid(task: name, field: "dependency \(dependency)")
        }
        
        try buildTask(
          name: dependency,
          data: jsonData[dependency]!,
          tasks: &tasks,
          dependedOnBy: newDependedOnBy
        )
        
        dependencies.insert(tasks[dependency]!)
      }
      
      // The current task is finally built once all of its dependencies have been too.
      tasks[name] = Task(id: id,
                         release: release,
                         deadline: deadline,
                         wcet: wcet,
                         dependencies: dependencies)
    }
        
    var tasks: [String: Task] = [:]
    for (taskName, data) in jsonData {
      try buildTask(name: taskName, data: data, tasks: &tasks)
    }
    
    self.init(tasks: Set<Task>(tasks.values))
  }
  
}
