import Foundation

public extension PendingTaskError {
    func describe() -> String {
        let errorIdString: String = (errorId != nil) ? String(describing: errorId!) : "none"
        let errorMessageString: String = (errorMessage != nil) ? String(describing: errorMessage!) : "none"

        return "errorId: \(errorIdString) errorMessage: \(errorMessageString) pendingTask: \(pendingTask.describe())"
    }

    func resolveError() throws {
        Wendy.shared.resolveError(taskId: pendingTask.taskId!)
    }
}
