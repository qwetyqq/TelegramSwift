//
//  DataAndStorageViewController.swift
//  Telegram
//
//  Created by keepcoder on 18/04/2017.
//  Copyright © 2017 Telegram. All rights reserved.
//

import Cocoa
import TGUIKit
import PostboxMac
import TelegramCoreMac
import SwiftSignalKitMac


public func autodownloadDataSizeString(_ size: Int64) -> String {
    if size >= 1024 * 1024 * 1024 {
        let remainder = (size % (1024 * 1024 * 1024)) / (1024 * 1024 * 102)
        if remainder != 0 {
            return "\(size / (1024 * 1024 * 1024)),\(remainder) GB"
        } else {
            return "\(size / (1024 * 1024 * 1024)) GB"
        }
    } else if size >= 1024 * 1024 {
        let remainder = (size % (1024 * 1024)) / (1024 * 102)
        if size < 10 * 1024 * 1024 {
            return "\(size / (1024 * 1024)),\(remainder) MB"
        } else {
            return "\(size / (1024 * 1024)) MB"
        }
    } else if size >= 1024 {
        return "\(size / 1024) KB"
    } else {
        return "\(size) B"
    }
}


private struct AutomaticDownloadPeers {
    let privateChats: Bool
    let groups: Bool
    let channels: Bool
    let size: Int32?
    
    init(category: AutomaticMediaDownloadCategoryPeers) {
        self.privateChats = category.privateChats
        self.groups = category.groupChats
        self.channels = category.channels
        self.size = category.fileSize
    }
}


private func stringForAutomaticDownloadPeers(peers: AutomaticDownloadPeers, category: AutomaticDownloadCategory) -> String {
    var size: String?
    if var peersSize = peers.size, category == .video || category == .file {
        if peersSize == Int32.max {
            peersSize = 1536 * 1024 * 1024
        }
        size = autodownloadDataSizeString(Int64(peersSize))
    }
    
    if peers.privateChats && peers.groups && peers.channels {
        if let size = size {
            return L10n.autoDownloadSettingsUpToForAll(size)
        } else {
            return L10n.autoDownloadSettingsOnForAll
        }
    } else {
        var types: [String] = []
        if peers.privateChats {
            types.append(L10n.autoDownloadSettingsTypePrivateChats)
        }
        if peers.groups {
            types.append(L10n.autoDownloadSettingsTypeGroupChats)
        }
        if peers.channels {
            types.append(L10n.autoDownloadSettingsTypeChannels)
        }
        
        if types.isEmpty {
            return L10n.autoDownloadSettingsOffForAll
        }
        
        var string: String = ""
        for i in 0 ..< types.count {
            if !string.isEmpty {
                if i == types.count - 1 {
                    string.append(L10n.autoDownloadSettingsLastDelimeter)
                } else {
                    string.append(L10n.autoDownloadSettingsDelimeter)
                }
            }
            string.append(types[i])
        }
        
        if let size = size {
            return L10n.autoDownloadSettingsUpToFor(size, string)
        } else {
            return L10n.autoDownloadSettingsOnFor(string)
        }
    }
}


enum AutomaticDownloadCategory {
    case photo
    case video
    case file
}

private enum AutomaticDownloadPeerType {
    case contact
    case otherPrivate
    case group
    case channel
}


private final class DataAndStorageControllerArguments {
    let openStorageUsage: () -> Void
    let openNetworkUsage: () -> Void
    let openCategorySettings: (AutomaticMediaDownloadCategoryPeers, String) -> Void
    let toggleAutomaticDownload:(Bool) -> Void
    let resetDownloadSettings:()->Void
    let selectDownloadFolder: ()->Void
    let toggleAutomaticCopyToDownload:(Bool)->Void
    let toggleAutoplayGifs:(Bool) -> Void
    let toggleAutoplayVideos:(Bool) -> Void
    let toggleAutoplaySoundOnHover:(Bool) -> Void

    init(openStorageUsage: @escaping () -> Void, openNetworkUsage: @escaping () -> Void, openCategorySettings: @escaping(AutomaticMediaDownloadCategoryPeers, String) -> Void, toggleAutomaticDownload:@escaping(Bool) -> Void, resetDownloadSettings:@escaping()->Void, selectDownloadFolder: @escaping() -> Void, toggleAutomaticCopyToDownload:@escaping(Bool)->Void, toggleAutoplayGifs: @escaping(Bool) -> Void, toggleAutoplayVideos:@escaping(Bool) -> Void, toggleAutoplaySoundOnHover:@escaping(Bool) -> Void) {
        self.openStorageUsage = openStorageUsage
        self.openNetworkUsage = openNetworkUsage
        self.openCategorySettings = openCategorySettings
        self.toggleAutomaticDownload = toggleAutomaticDownload
        self.resetDownloadSettings = resetDownloadSettings
        self.selectDownloadFolder = selectDownloadFolder
        self.toggleAutomaticCopyToDownload = toggleAutomaticCopyToDownload
        self.toggleAutoplayGifs = toggleAutoplayGifs
        self.toggleAutoplayVideos = toggleAutoplayVideos
        self.toggleAutoplaySoundOnHover = toggleAutoplaySoundOnHover
    }
}

private enum DataAndStorageSection: Int32 {
    case usage
    case automaticPhotoDownload
    case automaticVoiceDownload
    case automaticInstantVideoDownload
    case voiceCalls
    case other
}

private enum DataAndStorageEntry: TableItemListNodeEntry {

    case storageUsage(Int32, String)
    case networkUsage(Int32, String)
    case automaticMediaDownloadHeader(Int32, String)
    case automaticDownloadMedia(Int32, Bool)
    case photos(Int32, AutomaticMediaDownloadCategoryPeers, Bool)
    case videos(Int32, AutomaticMediaDownloadCategoryPeers, Bool, Int32?)
    case files(Int32, AutomaticMediaDownloadCategoryPeers, Bool, Int32?)
    case voice(Int32, AutomaticMediaDownloadCategoryPeers, Bool)
    case instantVideo(Int32, AutomaticMediaDownloadCategoryPeers, Bool)
    case gifs(Int32, AutomaticMediaDownloadCategoryPeers, Bool)
    
    case autoplayHeader(Int32)
    case autoplayGifs(Int32, Bool)
    case autoplayVideos(Int32, Bool)
    case soundOnHover(Int32, Bool)
    case soundOnHoverDesc(Int32)
    case resetDownloadSettings(Int32, Bool)
    case downloadFolder(Int32, String)
    case automaticCopyToDownload(Int32, Bool)
    case sectionId(Int32)
    
    var stableId: Int32 {
        switch self {
        case .storageUsage:
            return 0
        case .networkUsage:
            return 1
        case .automaticMediaDownloadHeader:
            return 2
        case .automaticDownloadMedia:
            return 3
        case .photos:
            return 4
        case .videos:
            return 5
        case .files:
            return 6
        case .voice:
            return 7
        case .instantVideo:
            return 8
        case .gifs:
            return 9
        case .resetDownloadSettings:
            return 10
        case .autoplayHeader:
            return 11
        case .autoplayGifs:
            return 12
        case .autoplayVideos:
            return 13
        case .soundOnHover:
            return 14
        case .soundOnHoverDesc:
            return 15
        case .downloadFolder:
            return 16
        case .automaticCopyToDownload:
            return 17
        case let .sectionId(sectionId):
            return (sectionId + 1) * 1000 - sectionId
        }
    }
    
    var index:Int32 {
        switch self {
        case .storageUsage(let sectionId, _):
            return (sectionId * 1000) + stableId
        case .networkUsage(let sectionId, _):
            return (sectionId * 1000) + stableId
        case .automaticMediaDownloadHeader(let sectionId, _):
            return (sectionId * 1000) + stableId
        case .automaticDownloadMedia(let sectionId, _):
            return (sectionId * 1000) + stableId
        case let .photos(sectionId, _, _):
            return (sectionId * 1000) + stableId
        case let .videos(sectionId, _, _, _):
            return (sectionId * 1000) + stableId
        case let .files(sectionId, _, _, _):
            return (sectionId * 1000) + stableId
        case let .voice(sectionId, _, _):
            return (sectionId * 1000) + stableId
        case let .instantVideo(sectionId, _, _):
            return (sectionId * 1000) + stableId
        case let .gifs(sectionId, _, _):
            return (sectionId * 1000) + stableId
        case let .resetDownloadSettings(sectionId, _):
            return (sectionId * 1000) + stableId
        case let .autoplayHeader(sectionId):
            return (sectionId * 1000) + stableId
        case let .autoplayGifs(sectionId, _):
            return (sectionId * 1000) + stableId
        case let .autoplayVideos(sectionId, _):
            return (sectionId * 1000) + stableId
        case let .soundOnHover(sectionId, _):
            return (sectionId * 1000) + stableId
        case let .soundOnHoverDesc(sectionId):
            return (sectionId * 1000) + stableId
        case let .downloadFolder(sectionId, _):
            return (sectionId * 1000) + stableId
        case let .automaticCopyToDownload(sectionId, _):
            return (sectionId * 1000) + stableId
        case let .sectionId(sectionId):
            return (sectionId + 1) * 1000 - sectionId
        }
    }
    
    static func <(lhs: DataAndStorageEntry, rhs: DataAndStorageEntry) -> Bool {
        return lhs.index < rhs.index
    }
    
    func item(_ arguments: DataAndStorageControllerArguments, initialSize: NSSize) -> TableRowItem {
        switch self {
        case let .storageUsage(_, text):
            return GeneralInteractedRowItem(initialSize, stableId: stableId, name: text, type: .next, action: {
                arguments.openStorageUsage()
            })
        case let .networkUsage(_, text):
            return GeneralInteractedRowItem(initialSize, stableId: stableId, name: text, type: .next, action: {
                arguments.openNetworkUsage()
            })
        case let .automaticMediaDownloadHeader(_, text):
            return GeneralTextRowItem(initialSize, stableId: stableId, text: text, drawCustomSeparator: true, inset: NSEdgeInsets(left: 30.0, right: 30.0, top:2, bottom:6))
        case let .automaticDownloadMedia(_ , value):
            return GeneralInteractedRowItem(initialSize, stableId: stableId, name: L10n.dataAndStorageAutomaticDownload, type: .switchable(value), action: {
                arguments.toggleAutomaticDownload(!value)
            })
        case let .photos(_, category, enabled):
            return GeneralInteractedRowItem(initialSize, stableId: stableId, name: L10n.dataAndStorageAutomaticDownloadPhoto, description: stringForAutomaticDownloadPeers(peers: AutomaticDownloadPeers(category: category), category: .photo), type: .next, action: {
               arguments.openCategorySettings(category, L10n.dataAndStorageAutomaticDownloadPhoto)
            }, enabled: enabled)
        case let .videos(_, category, enabled, _):
            
            return GeneralInteractedRowItem(initialSize, stableId: stableId, name: L10n.dataAndStorageAutomaticDownloadVideo, description: stringForAutomaticDownloadPeers(peers: AutomaticDownloadPeers(category: category), category: .video), type: .next, action: {
                arguments.openCategorySettings(category, L10n.dataAndStorageAutomaticDownloadVideo)
            }, enabled: enabled)
        case let .files(_, category, enabled, _):
            return GeneralInteractedRowItem(initialSize, stableId: stableId, name: L10n.dataAndStorageAutomaticDownloadFiles, description: stringForAutomaticDownloadPeers(peers: AutomaticDownloadPeers(category: category), category: .file), type: .next, action: {
                arguments.openCategorySettings(category, L10n.dataAndStorageAutomaticDownloadFiles)
            }, enabled: enabled)
        case let .voice(_, category, enabled):
            return GeneralInteractedRowItem(initialSize, stableId: stableId, name: L10n.dataAndStorageAutomaticDownloadVoice, type: .next, action: {
                arguments.openCategorySettings(category, L10n.dataAndStorageAutomaticDownloadVoice)
            }, enabled: enabled)
        case let .instantVideo(_, category, enabled):
            return GeneralInteractedRowItem(initialSize, stableId: stableId, name: L10n.dataAndStorageAutomaticDownloadInstantVideo, type: .next, action: {
                arguments.openCategorySettings(category, L10n.dataAndStorageAutomaticDownloadInstantVideo)
            }, enabled: enabled)
        case let .gifs(_, category, enabled):
            return GeneralInteractedRowItem(initialSize, stableId: stableId, name: L10n.dataAndStorageAutomaticDownloadGIFs, type: .next, action: {
                arguments.openCategorySettings(category, L10n.dataAndStorageAutomaticDownloadGIFs)
            }, enabled: enabled)
        case let .resetDownloadSettings(_, enabled):
            return GeneralInteractedRowItem(initialSize, stableId: stableId, name: L10n.dataAndStorageAutomaticDownloadReset, nameStyle: ControlStyle(font: .normal(.title), foregroundColor: theme.colors.blueUI), type: .none, action: {
                arguments.resetDownloadSettings()
            }, enabled: enabled)
        case let .downloadFolder(_, path):
            return GeneralInteractedRowItem(initialSize, stableId: stableId, name: L10n.dataAndStorageDownloadFolder, type: .context(path), action: {
                arguments.selectDownloadFolder()
            })
        case let .automaticCopyToDownload(_, value):
            return GeneralInteractedRowItem(initialSize, stableId: stableId, name: "L10n.dataAndStorageAutomaticDownloadToDownloadFolder", type: .switchable(value), action: {
                arguments.toggleAutomaticDownload(!value)
            })
        case .autoplayHeader:
            return GeneralTextRowItem(initialSize, stableId: stableId, text: L10n.dataAndStorageAutoplayHeader, drawCustomSeparator: true, inset: NSEdgeInsets(left: 30.0, right: 30.0, top:2, bottom:6))
        case let .autoplayGifs(_, value):
            return GeneralInteractedRowItem(initialSize, stableId: stableId, name: L10n.dataAndStorageAutoplayGIFs, type: .switchable(value), action: {
                arguments.toggleAutoplayGifs(!value)
            })
        case let .autoplayVideos(_, value):
            return GeneralInteractedRowItem(initialSize, stableId: stableId, name: L10n.dataAndStorageAutoplayVideos, type: .switchable(value), action: {
                arguments.toggleAutoplayVideos(!value)
            })
        case let .soundOnHover(_, value):
            return GeneralInteractedRowItem(initialSize, stableId: stableId, name: L10n.dataAndStorageAutoplaySoundOnHover, type: .switchable(value), action: {
                arguments.toggleAutoplaySoundOnHover(!value)
            })
        case .soundOnHoverDesc:
            return GeneralTextRowItem(initialSize, stableId: stableId, text: L10n.dataAndStorageAutoplaySoundOnHoverDesc)
            
        default:
            return GeneralRowItem(initialSize, height: 20, stableId: stableId)
        }
    }
}

private struct DataAndStorageControllerState: Equatable {
    static func ==(lhs: DataAndStorageControllerState, rhs: DataAndStorageControllerState) -> Bool {
        return true
    }
}

private struct DataAndStorageData: Equatable {
    let automaticMediaDownloadSettings: AutomaticMediaDownloadSettings
    let generatedMediaStoreSettings: GeneratedMediaStoreSettings
    let voiceCallSettings: VoiceCallSettings
    
    init(automaticMediaDownloadSettings: AutomaticMediaDownloadSettings, generatedMediaStoreSettings: GeneratedMediaStoreSettings, voiceCallSettings: VoiceCallSettings) {
        self.automaticMediaDownloadSettings = automaticMediaDownloadSettings
        self.generatedMediaStoreSettings = generatedMediaStoreSettings
        self.voiceCallSettings = voiceCallSettings
    }
    
    static func ==(lhs: DataAndStorageData, rhs: DataAndStorageData) -> Bool {
        return lhs.automaticMediaDownloadSettings == rhs.automaticMediaDownloadSettings && lhs.generatedMediaStoreSettings == rhs.generatedMediaStoreSettings && lhs.voiceCallSettings == rhs.voiceCallSettings
    }
}


private func dataAndStorageControllerEntries(state: DataAndStorageControllerState, data: DataAndStorageData, autoplayMedia: AutoplayMediaPreferences) -> [DataAndStorageEntry] {
    var entries: [DataAndStorageEntry] = []
    
    var sectionId:Int32 = 1
    entries.append(.sectionId(sectionId))
    sectionId += 1
    
    entries.append(.storageUsage(sectionId, L10n.dataAndStorageStorageUsage))
    entries.append(.networkUsage(sectionId, L10n.dataAndStorageNetworkUsage))
    
    entries.append(.sectionId(sectionId))
    sectionId += 1


    entries.append(.automaticMediaDownloadHeader(sectionId, L10n.dataAndStorageAutomaticDownloadHeader))
    entries.append(.automaticDownloadMedia(sectionId, data.automaticMediaDownloadSettings.automaticDownload))
    entries.append(.photos(sectionId, data.automaticMediaDownloadSettings.categories.photo, data.automaticMediaDownloadSettings.automaticDownload))
    entries.append(.videos(sectionId, data.automaticMediaDownloadSettings.categories.video, data.automaticMediaDownloadSettings.automaticDownload, data.automaticMediaDownloadSettings.categories.video.fileSize))
    entries.append(.files(sectionId, data.automaticMediaDownloadSettings.categories.files, data.automaticMediaDownloadSettings.automaticDownload, data.automaticMediaDownloadSettings.categories.files.fileSize))
//    entries.append(.voice(sectionId, data.automaticMediaDownloadSettings.categories.voice, data.automaticMediaDownloadSettings.automaticDownload))
//    entries.append(.instantVideo(sectionId, data.automaticMediaDownloadSettings.categories.instantVideo, data.automaticMediaDownloadSettings.automaticDownload))
//    entries.append(.gifs(sectionId, data.automaticMediaDownloadSettings.categories.gif, data.automaticMediaDownloadSettings.automaticDownload))
    entries.append(.resetDownloadSettings(sectionId, data.automaticMediaDownloadSettings != AutomaticMediaDownloadSettings.defaultSettings))
    
    entries.append(.sectionId(sectionId))
    sectionId += 1
    
    
    entries.append(.autoplayHeader(sectionId))
    entries.append(.autoplayGifs(sectionId, autoplayMedia.gifs))
    entries.append(.autoplayVideos(sectionId, autoplayMedia.videos))
    entries.append(.soundOnHover(sectionId, autoplayMedia.soundOnHover))
    entries.append(.soundOnHoverDesc(sectionId))
    
    entries.append(.sectionId(sectionId))
    sectionId += 1
    
    entries.append(.downloadFolder(sectionId, data.automaticMediaDownloadSettings.downloadFolder))
    //entries.append(.automaticCopyToDownload(sectionId, data.automaticMediaDownloadSettings.automaticSaveDownloadedFiles))

    
    
    
    return entries
}


private func prepareTransition(left:[AppearanceWrapperEntry<DataAndStorageEntry>], right: [AppearanceWrapperEntry<DataAndStorageEntry>], initialSize: NSSize, arguments: DataAndStorageControllerArguments) -> TableUpdateTransition {
    let (removed, inserted, updated) = proccessEntriesWithoutReverse(left, right: right) { entry -> TableRowItem in
        return entry.entry.item(arguments, initialSize: initialSize)
    }
    return TableUpdateTransition(deleted: removed, inserted: inserted, updated: updated, animated: true)
}

class DataAndStorageViewController: TableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let context = self.context
        let initialState = DataAndStorageControllerState()
        let initialSize = self.atomicSize
        let statePromise = ValuePromise(initialState, ignoreRepeated: true)
        let stateValue = Atomic(value: initialState)
        let updateState: ((DataAndStorageControllerState) -> DataAndStorageControllerState) -> Void = { f in
            statePromise.set(stateValue.modify { f($0) })
        }
        
        let pushControllerImpl:(ViewController)->Void = { [weak self] controller in
            self?.navigationController?.push(controller)
        }
        
        let previous:Atomic<[AppearanceWrapperEntry<DataAndStorageEntry>]> = Atomic(value: [])
        let actionsDisposable = DisposableSet()
        
        let dataAndStorageDataPromise = Promise<DataAndStorageData>()
        dataAndStorageDataPromise.set(combineLatest(context.account.postbox.preferencesView(keys: [ApplicationSpecificPreferencesKeys.automaticMediaDownloadSettings, ApplicationSpecificPreferencesKeys.generatedMediaStoreSettings]), voiceCallSettings(context.sharedContext.accountManager))
            |> map { view, voiceCallSettings  -> DataAndStorageData in
                let automaticMediaDownloadSettings: AutomaticMediaDownloadSettings = view.values[ApplicationSpecificPreferencesKeys.automaticMediaDownloadSettings] as? AutomaticMediaDownloadSettings ?? AutomaticMediaDownloadSettings.defaultSettings

                
                let generatedMediaStoreSettings: GeneratedMediaStoreSettings = view.values[ApplicationSpecificPreferencesKeys.generatedMediaStoreSettings] as? GeneratedMediaStoreSettings ?? GeneratedMediaStoreSettings.defaultSettings
                
                
                return DataAndStorageData(automaticMediaDownloadSettings: automaticMediaDownloadSettings, generatedMediaStoreSettings: generatedMediaStoreSettings, voiceCallSettings: voiceCallSettings)
            })
        
        let arguments = DataAndStorageControllerArguments(openStorageUsage: {
            pushControllerImpl(StorageUsageController(context))
        }, openNetworkUsage: {
            networkUsageStatsController(context: context, f: pushControllerImpl)
        }, openCategorySettings: { category, title in
            pushControllerImpl(DownloadSettingsViewController(context, category, title, updateCategory: { category in
                _ = updateMediaDownloadSettingsInteractively(postbox: context.account.postbox, { current -> AutomaticMediaDownloadSettings in
                    switch title {
                    case L10n.dataAndStorageAutomaticDownloadPhoto:
                        return current.withUpdatedCategories(current.categories.withUpdatedPhoto(category))
                    case L10n.dataAndStorageAutomaticDownloadVideo:
                        return current.withUpdatedCategories(current.categories.withUpdatedVideo(category))
                    case L10n.dataAndStorageAutomaticDownloadFiles:
                        return current.withUpdatedCategories(current.categories.withUpdatedFiles(category))
                    case L10n.dataAndStorageAutomaticDownloadVoice:
                        return current.withUpdatedCategories(current.categories.withUpdatedVoice(category))
                    case L10n.dataAndStorageAutomaticDownloadInstantVideo:
                        return current.withUpdatedCategories(current.categories.withUpdatedInstantVideo(category))
                    case L10n.dataAndStorageAutomaticDownloadGIFs:
                        return current.withUpdatedCategories(current.categories.withUpdatedGif(category))
                    default:
                        return current
                    }
                }).start()
            }))
        }, toggleAutomaticDownload: { enabled in
            _ = updateMediaDownloadSettingsInteractively(postbox: context.account.postbox, { current -> AutomaticMediaDownloadSettings in
                return current.withUpdatedAutomaticDownload(enabled)
            }).start()
        }, resetDownloadSettings: {
            _ = (confirmSignal(for: mainWindow, header: appName, information: L10n.dataAndStorageConfirmResetSettings, okTitle: L10n.modalOK, cancelTitle: L10n.modalCancel) |> filter {$0} |> mapToSignal { _ -> Signal<Void, NoError> in
                return updateMediaDownloadSettingsInteractively(postbox: context.account.postbox, { _ -> AutomaticMediaDownloadSettings in
                    return AutomaticMediaDownloadSettings.defaultSettings
                })
            }).start()
        }, selectDownloadFolder: {
            selectFolder(for: mainWindow, completion: { newPath in
                _ = updateMediaDownloadSettingsInteractively(postbox: context.account.postbox, { current -> AutomaticMediaDownloadSettings in
                    return current.withUpdatedDownloadFolder(newPath)
                }).start()
            })
            
        }, toggleAutomaticCopyToDownload: { value in
            _ = updateMediaDownloadSettingsInteractively(postbox: context.account.postbox, { current -> AutomaticMediaDownloadSettings in
                return current.withUpdatedAutomaticSaveDownloadedFiles(value)
            }).start()
        }, toggleAutoplayGifs: { enable in
            _ = updateAutoplayMediaSettingsInteractively(postbox: context.account.postbox, {
                return $0.withUpdatedAutoplayGifs(enable)
            }).start()
        }, toggleAutoplayVideos: { enable in
            _ = updateAutoplayMediaSettingsInteractively(postbox: context.account.postbox, {
                return $0.withUpdatedAutoplayVideos(enable)
            }).start()
        }, toggleAutoplaySoundOnHover: { enable in
            _ = updateAutoplayMediaSettingsInteractively(postbox: context.account.postbox, {
                return $0.withUpdatedAutoplaySoundOnHover(enable)
            }).start()
        })
        
        self.genericView.merge(with: combineLatest(queue: .mainQueue(), statePromise.get(), dataAndStorageDataPromise.get(), appearanceSignal, autoplayMediaSettings(postbox: context.account.postbox))
            |> map { state, dataAndStorageData, appearance, autoplayMediaSettings -> TableUpdateTransition in
                
                let entries = dataAndStorageControllerEntries(state: state, data: dataAndStorageData, autoplayMedia: autoplayMediaSettings).map {AppearanceWrapperEntry(entry: $0, appearance: appearance)}
                return prepareTransition(left: previous.swap(entries), right: entries, initialSize: initialSize.modify({$0}), arguments: arguments)

        } |> beforeNext { [weak self] _ in
            self?.readyOnce()
        } |> afterDisposed {
                actionsDisposable.dispose()
        })
        
    }
    
    override func getRightBarViewOnce() -> BarView {
        return BarView(20, controller: self)
    }

}
