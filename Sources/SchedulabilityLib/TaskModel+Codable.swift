import Foundation

/// A decoding context, used by the decoders to track references.
public final class TaskDecodingContext {

  /// The tasks that have been decoded so far.
  var decodedTasks: [Int: Task]

  /// Initializes a task decoding context.
  public init() {
    self.decodedTasks = [:]
  }

}

/// An error that occured during the decoding of task model.
public enum TaskDecodingError: Error {

  /// This error occurs when the decoder that is used to decode isn't associated with a context
  /// a task decoding context.
  ///
  /// The task decoding context is used to keep track of all the tasks that have been decoded so
  /// far, so that dependencies can be properly linked together. It should be set on a decoder's
  /// user info dictionary *before* attempting to decode any task model.
  ///
  ///     let decloder = JSONDecoder()
  ///     decoder.userInfo[.decodingContext] = TaskDecodingContext()
  ///
  /// See also [TaskModel.decodingContext](x-source-tag://TaskModel.decodingContext).
  case missingOrInvalidDecodingContext

  /// This error occurs when the decoder attempts to retrieve a dependency that does not exists or
  /// hasn't been decoded yet.
  ///
  /// Tasks should appear *after* their dependencies in a serialized task model.
  case undefinedDependency

}

extension TaskModel {

  /// Initializes a task model from JSON data.
  public init(fromJSON data: Data) throws {
    let decoder = JSONDecoder()
    decoder.userInfo[TaskModel.decodingContext] = TaskDecodingContext()

    self = try decoder.decode(TaskModel.self, from: data)
  }

  /// The user info key that identifies decoding contexts.
  ///
  /// - Tag: TaskModel.decodingContext
  public static let decodingContext = CodingUserInfoKey(rawValue: "TaskDecodingContext")!

}
