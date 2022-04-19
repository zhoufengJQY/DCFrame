//
// Copyright (c) Bytedance Inc. and its affiliates.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//

import UIKit

/// CellModel Container class, abbreviated as ContainerModel
/// A `DCContainerModel` can include both `DCCellModel` and `DCContainerModel`
open class DCContainerModel: NSObject, DCModelable {

    /// Array for storing Model; Only getters and setters are allowed, no direct operations on this array
    public var modelArray: [DCModelable] {
        set {
            p_modelArray.write {
                $0 = newValue
            }
        }
        get {
            return p_modelArray.directValue
        }
    }
    private var p_modelArray = DCProtector<[DCModelable]>([DCModelable]())

    /// The parent of the current ContainerModel
    public weak var parentContainerModel: DCContainerModel?

    /// The union frame of the cells in the ContainerModel
    public var contentFrame: CGRect?

    /// Display status of the current ContainerModel. If set to true, reloadData() in DCCollectionView will not load this ContainerModel
    public var isHidden: Bool = false

    /// EDC of the current ContainerModel, will be reused by CellModels and Cells of this ContainerModel
    public private(set) lazy var eventDataController: DCEventDataController = {
        let eventDataController = DCEventDataController()
        eventDataController.tag = String(describing: Self.self)
        return eventDataController
    }()

    /// Perform operations on the CollectionView through this parameter, like updating data, scrolling to a specific position, etc
    public weak var dcHandler: DCBaseOperationable?

    /// Reference to `dcViewController` feature in `DCContainrCollectionView`
    public weak var dcViewController: UIViewController?

    /// Load the `DCCollectionView` of the current ContainerModel
    public weak var dcCollectionView: DCCollectionView?

    /// Boolean for whether the current ContainerModel is loaded
    public private(set) var isContainerModelLoaded: Bool = false

    #if DEBUG
    var assert_containerModelDidLoad = true
    #endif

    // MARK: - Functions for Adding Submodels

    /// Add a single Model
    /// - Parameter model: Model of type `DCCellModel` or `DCContainerModel`
    public func addSubmodel(_ model: DCModelable) {
        guard isValidModel(model) else {
            return
        }
        p_modelArray.write {
            $0.append(model)
        }
    }

    /// Add a set of Models
    /// - Parameter models: an array of Models of type DCCellModel or DCContainerModel
    public func addSubmodels(_ models: [DCModelable]) {
        for model in models {
            addSubmodel(model)
        }
    }

    /// Insert a Model as the first element of the ContainerModel
    /// - Parameter model: Model to be inserted
    public func insertSubmodelToFirst(_ model: DCModelable) {
        insertSubmodel(model, at: 0)
    }

    /// Insert a Model as the n-th element of the ContainerModel
    /// - Parameters:
    ///   - model: Model to be inserted
    ///   - index: position of the Model in the ContainerModel
    public func insertSubmodel(_ model: DCModelable, at index: Int) {
        guard isValidModel(model) else {
            return
        }
        p_modelArray.write {
            $0.insert(model, at: index)
        }
    }

    /// Insert a Model before a specific Model in the ContainerModel
    /// - Parameters:
    ///   - model: Model to be inserted
    ///   - before: the specified Model
    public func insertSubmodel(_ model: DCModelable, before: DCModelable) {
        guard isValidModel(model) && isValidModel(before) else {
            return
        }
        p_modelArray.write {
            var itemIndex = -1
            for (index, item) in $0.enumerated() where (item as? NSObject) === (before as? NSObject) {
                itemIndex = index
                break
            }
            if itemIndex != -1 {
                $0.insert(model, at: itemIndex)
            }
        }
    }

    /// Insert a Model after a specific Model in the ContainerModel
    /// - Parameters:
    ///   - model: Model to be inserted
    ///   - after: the specified Model
    public func insertSubmodel(_ model: DCModelable, after: DCModelable) {
        guard isValidModel(model) && isValidModel(after) else {
            return
        }
        p_modelArray.write {
            var itemIndex = -1
            for (index, item) in $0.enumerated() where (item as? NSObject) === (after as? NSObject) {
                itemIndex = index
                break
            }
            if itemIndex != -1 {
                if itemIndex < ($0.count - 1) {
                    $0.insert(model, at: itemIndex + 1)
                } else {
                    $0.append(model)
                }
            }
        }
    }

    /// Remove a specific Model
    /// - Parameter model: Model to be removed
    public func removeSubmodel(_ model: Any) {
        guard isValidModel(model) else {
            return
        }
        p_modelArray.write {
            var itemIndex = -1
            for (index, item) in $0.enumerated() where (item as? NSObject) === (model as? NSObject) {
                itemIndex = index
                break
            }
            if itemIndex != -1 {
                $0.remove(at: itemIndex)
            }
        }
    }

    /// Remove all Models in the ContainerModel
    public func removeAllSubmodels() {
        p_modelArray.write {
            $0.removeAll()
        }
    }

    private func isValidModel(_ model: Any) -> Bool {
        if (model as AnyObject) === self {
            assert(false, "Cannot add self as submodel")
            return false
        }
        if (model is DCContainerModel) || (model is DCCellModel) {
            return true
        }
        assert(false, "Model type error")
        return false
    }

    /// Will update the data of all cells in the ContainerModel
    public func needUpdateCellsData() {
        for item in modelArray {
            if let model = item as? DCContainerModel {
                model.needUpdateCellsData()
            } else if let model = item as? DCCellModel {
                model.needUpdateCellData()
            }
        }
    }

    /// Called only once during a lifecycle and is called when calling `loadContainerModel()` or `needUpdateLayout()` for the first time
    open func containerModelDidLoad() {
        isContainerModelLoaded = true
        #if DEBUG
        assert_containerModelDidLoad = false
        #endif
        // override
    }

    /// Called whenever `needReloadData()` is called
    open func collectionViewDataWillReload() {
        // override
    }

    // MARK: - Layout operations

    /// The margin or interval of the cell in the current ContainerModel
    public var layoutContext = DCContainerLayoutContext()

    /// The custom layout of current ContainerModel
    public var customLayout: DCContainerLayoutable?

    /// Dynamically calculate and return `layoutContext`
    /// - Returns: Layout context
    open func getLayoutContext() -> DCContainerLayoutContext? {
        return layoutContext
    }

    /// Dynamically calculate and return custom layout
    /// - Returns: Custom layout
    open func getCustomLayout() -> DCContainerLayoutable {
        return (customLayout ?? parentContainerModel?.getCustomLayout()) ?? DCContainerDefaultLayout()
    }
}

// MARK: - Handle Events and data

extension DCContainerModel {
    public func sharedData<T>(of sd: DCSharedDataID, default: T) -> T {
        return eventDataController.sharedData(of: sd, default: `default`)
    }

    public func sharedData(of sd: DCSharedDataID) -> Any? {
        return eventDataController.sharedData(of: sd)
    }

    public func shareData(_ data: Any?, to sd: DCSharedDataID) {
        eventDataController.shareData(data, to: sd)
    }

    public func shareData(_ data: Any?, to sd: DCSharedDataID, broadcast: Bool) {
        eventDataController.shareData(data, to: sd, broadcast: broadcast)
    }

    public func shareData(to sd: DCSharedDataID, closure: @escaping DCSharedDataCallbackBlock) {
        eventDataController.shareData(to: sd, broadcast: true, closure: closure)
    }

    public func shareData(to sd: DCSharedDataID, broadcast: Bool, closure: @escaping DCSharedDataCallbackBlock) {
        eventDataController.shareData(to: sd, broadcast: broadcast, closure: closure)
    }

    public func sendEvent(_ event: DCEventID) {
        sendEvent(event, data: nil)
    }

    public func sendEvent(_ event: DCEventID, data: Any?) {
        eventDataController.sendEvent(event, data: data)
    }

    @discardableResult
    public func subscribeEvent(_ event: DCEventID, completion: @escaping (Any?) -> Void) -> DCSubscribeEventAndable {
        return eventDataController.subscribeEvent(event, target: self, completion: completion)
    }

    @discardableResult
    public func subscribeEvent<T>(_ event: DCEventID, completion: @escaping (T) -> Void) -> DCSubscribeEventAndable {
        return eventDataController.subscribeEvent(event, target: self, completion: completion)
    }

    @discardableResult
    public func subscribeEvents(_ events: [DCEventID], completion: @escaping (DCEventID) -> Void) -> DCSubscribeEventAndable {
        return eventDataController.subscribeEvents(events, target: self, completion: completion)
    }

    @discardableResult
    public func subscribeEvents(_ events: [DCEventID], completion: @escaping (DCEventID, Any?) -> Void) -> DCSubscribeEventAndable {
        return eventDataController.subscribeEvents(events, target: self, completion: completion)
    }

    @discardableResult
    public func subscribeEvents<T>(_ events: [DCEventID], completion: @escaping (DCEventID, T) -> Void) -> DCSubscribeEventAndable {
        return eventDataController.subscribeEvents(events, target: self, completion: completion)
    }

    @discardableResult
    public func subscribeData<T>(_ sd: DCSharedDataID, completion: @escaping (T) -> Void) -> EDCSubscribeDataAndable {
        return eventDataController.subscribeData(sd, target: self, completion: completion)
    }

    @discardableResult
    public func subscribeData<T>(_ sd: DCSharedDataID, completion: @escaping (T) -> Void, emptyCall: @escaping () -> Void) -> EDCSubscribeDataAndable {
        return eventDataController.subscribeData(sd, target: self, completion: completion, emptyCall: emptyCall)
    }
}
