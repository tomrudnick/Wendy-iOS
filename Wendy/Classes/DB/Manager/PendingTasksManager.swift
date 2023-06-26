import CoreData
import Foundation
import UIKit

internal class PendingTasksManager {
    internal static let shared: PendingTasksManager = PendingTasksManager()

    private init() {}

    internal func insertPendingTask(_ task: PendingTask) -> PendingTask {
        if task.tag.isEmpty { Fatal.customPreconditionFailure("You need to set a unique tag for \(String(describing: PendingTask.self)) instances.") }

        let persistedPendingTask: PersistedPendingTask = PersistedPendingTask(pendingTask: task)
        CoreDataManager.shared.saveContext()

        let pendingTaskForPersistedPendingTask = persistedPendingTask.pendingTask
        LogUtil.d("Successfully added task to Wendy. Task: \(pendingTaskForPersistedPendingTask.describe())")

        return pendingTaskForPersistedPendingTask
    }

    /**
     * fatal error if task by taskId does not exist.
     * fatal error if task by taskId does not belong to any groups.
     */
    internal func isTaskFirstTaskOfGroup(_ taskId: Double) -> Bool {
        guard let persistedPendingTask: PersistedPendingTask = getTaskByTaskId(taskId) else {
            fatalError("Task with id: \(taskId) does not exist.")
        }
        
        if persistedPendingTask.groupId == nil {
            Fatal.customPreconditionFailure("Task: \(persistedPendingTask.pendingTask.describe()) does not belong to a group.")
        }

        let context = CoreDataManager.shared.viewContext

        let pendingTaskFetchRequest: NSFetchRequest<PersistedPendingTask> = PersistedPendingTask.fetchRequest()
        pendingTaskFetchRequest.predicate = NSPredicate(format: "groupId == %@", persistedPendingTask.groupId!)
        pendingTaskFetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(PersistedPendingTask.createdAt), ascending: true)]

        var pendingTask: PersistedPendingTask? = nil
        
        context.performAndWait {
            do {
                let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
                pendingTask = pendingTasks.first
            } catch let error as NSError {
                Fatal.error("Error in Wendy while fetching data from database.", error: error)
            }
        }
       
        guard let pendingTask else { return false }
        return pendingTask.id == taskId
        
    }

    internal func getRandomTaskForTag(_ tag: String) -> PendingTask? {
        let context = CoreDataManager.shared.viewContext

        let pendingTaskFetchRequest: NSFetchRequest<PersistedPendingTask> = PersistedPendingTask.fetchRequest()
        pendingTaskFetchRequest.predicate = NSPredicate(format: "(tag == %@)", tag)

        
        var pendingTask: PendingTask? = nil
        
        context.performAndWait {
            do {
                let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
                pendingTask = pendingTasks.first?.pendingTask
            } catch let error as NSError {
                Fatal.error("Error in Wendy while fetching data from database.", error: error)
            }
        }
        
        return pendingTask
    }

    internal func getAllTasks() -> [PendingTask] {
        let context = CoreDataManager.shared.viewContext
        let _ = Wendy.shared.pendingTasksFactory

        var tasks: [PendingTask] = []
        
        context.performAndWait {
            do {
                let persistedPendingTasks: [PersistedPendingTask] = try context.fetch(PersistedPendingTask.fetchRequest()) as [PersistedPendingTask]

                var pendingTasks: [PendingTask] = []
                persistedPendingTasks.forEach { persistedPendingTask in
                    pendingTasks.append(persistedPendingTask.pendingTask)
                }

                tasks = pendingTasks
            } catch let error as NSError {
                Fatal.error("Error in Wendy while fetching data from database.", error: error)
            }
        }
        
        return tasks
    }

    internal func getExistingTasks(_ task: PendingTask) -> [PersistedPendingTask]? {
        let context = CoreDataManager.shared.viewContext

        let pendingTaskFetchRequest: NSFetchRequest<PersistedPendingTask> = PersistedPendingTask.fetchRequest()

        var keyValues = ["tag = %@": task.tag as NSObject]
        if let groupId = task.groupId {
            keyValues["groupId = %@"] = groupId as NSObject
        }
        if let dataId = task.dataId {
            keyValues["dataId = %@"] = dataId as NSObject
        }

        let predicates = keyValues.map { NSPredicate(format: $0.key, $0.value) }
        pendingTaskFetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        pendingTaskFetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(PersistedPendingTask.createdAt), ascending: true)]

        var tasks: [PersistedPendingTask]? = nil
        
        context.performAndWait {
            do {
                let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
                tasks = (pendingTasks.isEmpty) ? nil : pendingTasks
            } catch let error as NSError {
                Fatal.error("Error in Wendy while fetching data from database.", error: error)
            }
        }
        
        return tasks
       
    }

    @discardableResult
    internal func insertPendingTaskError(taskId: Double, humanReadableErrorMessage: String?, errorId: String?) -> PendingTaskError? {
        guard let persistedPendingTask: PersistedPendingTask = self.getTaskByTaskId(taskId) else {
            return nil
        }

        let persistedPendingTaskError: PersistedPendingTaskError = PersistedPendingTaskError(errorMessage: humanReadableErrorMessage, errorId: errorId, persistedPendingTask: persistedPendingTask)
        CoreDataManager.shared.saveContext()

        let pendingTaskError = PendingTaskError(from: persistedPendingTaskError, pendingTask: persistedPendingTask.pendingTask)
        LogUtil.d("Successfully recorded error to Wendy. Error: \(pendingTaskError.describe())")

        return pendingTaskError
    }

    internal func getLatestError(pendingTaskId: Double) -> PendingTaskError? {
        guard let persistedPendingTask: PersistedPendingTask = self.getTaskByTaskId(pendingTaskId) else {
            return nil
        }

        let context = CoreDataManager.shared.viewContext

        let pendingTaskErrorFetchRequest: NSFetchRequest<PersistedPendingTaskError> = PersistedPendingTaskError.fetchRequest()
        pendingTaskErrorFetchRequest.predicate = NSPredicate(format: "pendingTask == %@", persistedPendingTask)

        var pendingTaskError: PendingTaskError? = nil
        
        context.performAndWait {
            do {
                let pendingTaskErrors: [PersistedPendingTaskError] = try context.fetch(pendingTaskErrorFetchRequest)

                guard let persistedPendingTaskError: PersistedPendingTaskError = pendingTaskErrors.first else {
                    return
                }

                pendingTaskError = PendingTaskError(from: persistedPendingTaskError, pendingTask: persistedPendingTask.pendingTask)
            } catch let error as NSError {
                Fatal.error("Error in Wendy while fetching data from database.", error: error)
                return
            }
        }
        
        return pendingTaskError
    }

    internal func getAllErrors() -> [PendingTaskError] {
        let context = CoreDataManager.shared.viewContext

        
        var pendingTaskErrors: [PendingTaskError] = []
        
        context.performAndWait {
            do {
                let persistedPendingTaskErrors: [PersistedPendingTaskError] = try context.fetch(PersistedPendingTaskError.fetchRequest()) as [PersistedPendingTaskError]

                persistedPendingTaskErrors.forEach { taskError in
                    pendingTaskErrors.append(PendingTaskError(from: taskError, pendingTask: taskError.pendingTask!.pendingTask))
                }
                
            } catch let error as NSError {
                Fatal.error("Error in Wendy while fetching data from database.", error: error)
            }
        }
        
        return pendingTaskErrors
    }

    internal func getTaskByTaskId(_ taskId: Double) -> PersistedPendingTask? {
        let context = CoreDataManager.shared.viewContext

        let pendingTaskFetchRequest: NSFetchRequest<PersistedPendingTask> = PersistedPendingTask.fetchRequest()
        pendingTaskFetchRequest.predicate = NSPredicate(format: "id == %f", taskId)

        var pendingTask: PersistedPendingTask? = nil
        
        context.performAndWait {
            do {
                let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
                pendingTask = pendingTasks.first
            } catch let error as NSError {
                Fatal.error("Error in Wendy while fetching data from database.", error: error)
            }
        }
        return pendingTask
    }

    internal func getPendingTaskTaskById(_ taskId: Double) -> PendingTask? {
        guard let persistedPendingTask = getTaskByTaskId(taskId) else {
            return nil
        }

        return persistedPendingTask.pendingTask
    }

    // Note: Make sure to keep the query at "delete this table item by ID _____".
    // Because of this scenario: The runner is running a task with ID 1. While the task is running a user decides to update that data. This results in having to run that PendingTask a 2nd time (if the running task is successful) to sync the newest changes. To assert this 2nd change, we take advantage of SQLite's unique constraint. On unique constraint collision we replace (update) the data in the database which results in all the PendingTask data being the same except for the ID being incremented. So, after the runner runs the task successfully and wants to delete the task here, it will not delete the task because the ID no longer exists. It has been incremented so the newest changes can be run.
    internal func deleteTask(_ taskId: Double) {
        let context = CoreDataManager.shared.viewContext
        if let persistedPendingTask = getTaskByTaskId(taskId) {
            context.delete(persistedPendingTask)
            CoreDataManager.shared.saveContext()
        }
    }

    internal func updatePlaceInLine(_ taskId: Double, createdAt: Date) {
        guard let persistedPendingTask = getTaskByTaskId(taskId) else {
            return
        }

        let _ = CoreDataManager.shared.viewContext
        persistedPendingTask.setValue(createdAt, forKey: "createdAt")
        CoreDataManager.shared.saveContext()
    }

    internal func deletePendingTaskError(_ taskId: Double) -> Bool {
        let context = CoreDataManager.shared.viewContext
        if let persistedPendingTaskError = getTaskByTaskId(taskId)?.error {
            context.delete(persistedPendingTaskError)
            CoreDataManager.shared.saveContext()
            return true
        }
        return false
    }

    internal func getTotalNumberOfTasksForRunnerToRun(filter: RunAllTasksFilter?) -> Int {
        let context = CoreDataManager.shared.viewContext

        let pendingTaskFetchRequest: NSFetchRequest<PersistedPendingTask> = PersistedPendingTask.fetchRequest()

        var keyValues = ["manuallyRun = %@": NSNumber(value: false) as NSObject]
        if let filter = filter {
            keyValues = applyFilterPredicates(filter, to: keyValues)
        }

        let predicates = keyValues.map { NSPredicate(format: $0.key, $0.value) }
        pendingTaskFetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        var count: Int = 0
        
        context.performAndWait {
            do {
                let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
                count = pendingTasks.count
            } catch let error as NSError {
                Fatal.error("Error in Wendy while fetching data from database.", error: error)
            }
        }
        
        return count
    }

    internal func getLastPendingTaskInGroup(_ groupId: String) -> PersistedPendingTask? {
        let context = CoreDataManager.shared.viewContext

        let pendingTaskFetchRequest: NSFetchRequest<PersistedPendingTask> = PersistedPendingTask.fetchRequest()
        pendingTaskFetchRequest.predicate = NSPredicate(format: "groupId == %@", groupId)
        pendingTaskFetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(PersistedPendingTask.createdAt), ascending: false)]

        
        var lastPendingTask: PersistedPendingTask? = nil
        
        context.performAndWait {
            do {
                let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
                lastPendingTask = pendingTasks.first
            } catch let error as NSError {
                Fatal.error("Error in Wendy while fetching data from database.", error: error)
            }
        }
       
        return lastPendingTask
    }

    internal func getNextTaskToRun(_ lastSuccessfulOrFailedTaskId: Double, filter: RunAllTasksFilter?) -> PendingTask? {
        let context = CoreDataManager.shared.viewContext

        let pendingTaskFetchRequest: NSFetchRequest<PersistedPendingTask> = PersistedPendingTask.fetchRequest()

        var keyValues = ["id > %@": lastSuccessfulOrFailedTaskId as NSObject, "manuallyRun = %@": NSNumber(value: false) as NSObject]
        if let filter = filter {
            keyValues = applyFilterPredicates(filter, to: keyValues)
        }

        let predicates = keyValues.map { NSPredicate(format: $0.key, $0.value) }
        pendingTaskFetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        pendingTaskFetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(PersistedPendingTask.createdAt), ascending: true)]
        
        var pendingTask: PendingTask? = nil
        
        context.performAndWait {
            do {
                let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
                if pendingTasks.isEmpty { return }
                let persistedPendingTask: PersistedPendingTask = pendingTasks[0]

                pendingTask = persistedPendingTask.pendingTask
            } catch let error as NSError {
                Fatal.error("Error in Wendy while fetching data from database.", error: error)
            }
        }

        return pendingTask
    }

    private func applyFilterPredicates(_ filter: RunAllTasksFilter, to keyValues: [String: NSObject]) -> [String: NSObject] {
        var keyValues = keyValues
        let collections = WendyConfig.collections

        switch filter {
        case .group(let groupId):
            keyValues["groupId = %@"] = groupId as NSObject
        case .collection(let collectionId):
            let collection = collections.getCollection(id: collectionId)

            // Pending tasks where the tag of the pending task is in the collection
            keyValues["tag IN %@"] = collection as NSObject
        }

        return keyValues
    }
}
