//
//  Preferences.swift
//  Backup Status
//
//  Created by Niels Mouthaan on 21/11/2023.
//

import Foundation
import OSLog
import WidgetKit

extension String {
    
    static let preferencesKey = "preferences"
    private static let statusKey = "status"
    static let widgetKind = "BackupStatusWidget"
}

struct Preferences: Codable {
    
    struct Destination: Codable {
        
        let id: String
        let isEncrypted: Bool
        let isNetwork: Bool
        let bytesAvailable: Int64
        let bytesUsed: Int64
        let volumeName: String
        let snapshots: [Date]
        
        fileprivate init(id: String, isEncrypted: Bool, isNetwork: Bool, bytesAvailable: Int64, bytesUsed: Int64, volumeName: String, snapshots: [Date]) {
            self.id = id
            self.isEncrypted = isEncrypted
            self.isNetwork = isNetwork
            self.bytesAvailable = bytesAvailable
            self.bytesUsed = bytesUsed
            self.volumeName = volumeName
            self.snapshots = snapshots
        }
        
        init(_ dictionary: [String: Any]) {
            self.id = dictionary["DestinationID"] as? String ?? ""
            self.isEncrypted = dictionary["LastKnownEncryptionState"] as? String == "Encrypted"
            self.isNetwork = dictionary["NetworkURL"] != nil
            self.bytesAvailable = dictionary["BytesAvailable"] as? Int64 ?? 0
            self.bytesUsed = dictionary["BytesUsed"] as? Int64 ?? 0
            self.volumeName = dictionary["LastKnownVolumeName"] as? String ?? ""
            self.snapshots = dictionary["SnapshotDates"] as? [Date] ?? []
        }
        
        var lastSnapshot: Date? {
            snapshots.max() ?? nil
        }
    }
    
    var destinations: [Destination]
    var lastDestination: Destination?
    
    fileprivate init(destinations: [Destination], lastDestination: Destination?) {
        self.destinations = destinations
        self.lastDestination = lastDestination
    }
    
    init?(url: URL) {
        if url.startAccessingSecurityScopedResource() {
            do {
                let data = try Data(contentsOf: url)
                guard let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
                    Logger.app.error("Failed serializing preferences file")
                    return nil
                }
                guard let destinationsData = plist["Destinations"] as? [[String: Any]] else {
                    Logger.app.error("Missing or invalid Destinations attribute in preferences file")
                    return nil
                }
                self.destinations = destinationsData.compactMap { Destination($0) }
                if let lastDestinationId = plist["LastDestinationID"] as? String {
                    self.lastDestination = self.destinations.filter { $0.id == lastDestinationId }.first
                }
            } catch {
                Logger.app.error("Failed reading content from preferences file: \(error)")
                return nil
            }
            url.stopAccessingSecurityScopedResource()
        } else {
            Logger.app.error("Failed accessing preferences file")
            return nil
        }
    }
    
    public func store() -> Bool {
        do {
            let data = try JSONEncoder().encode(self)
            UserDefaults.shared.set(data, forKey: .preferencesKey)
            WidgetCenter.shared.reloadTimelines(ofKind: .widgetKind)
            Logger.app.info("Preferences stored")
            return true
        } catch {
            Logger.app.error("Failed storing preferences: \(error)")
            return false
        }
    }
    
    static func load() -> Preferences? {
        if let data = UserDefaults.shared.data(forKey: .preferencesKey) {
            do {
                let preferences = try JSONDecoder().decode(Preferences.self, from: data)
                Logger.app.info("Preferences loaded")
                return preferences
            } catch {
                Logger.app.error("Failed loading preferences: \(error)")
            }
        } else {
            Logger.app.info("Preferences not available")
        }
        return nil
    }
    
    static func clear() {
        UserDefaults.shared.removeObject(forKey: .preferencesKey)
        WidgetCenter.shared.reloadTimelines(ofKind: .widgetKind)
    }
    
    static var demo: Preferences {
        let snapshots = [
            Date(timeIntervalSinceNow: (-130 * 60) + 31),
            Date(timeIntervalSinceNow: (-590 * 60) + 15),
            Date(timeIntervalSinceNow: (-150 * 60) + 18),
            Date(timeIntervalSinceNow: (-904 * 60) + 27),
            Date(timeIntervalSinceNow: (-200 * 60) + 45),
            Date(timeIntervalSinceNow: (-360 * 60) + 10),
            Date(timeIntervalSinceNow: (-480 * 60) + 55),
            Date(timeIntervalSinceNow: (-720 * 60) + 30),
            Date(timeIntervalSinceNow: (-210 * 60) + 20),
            Date(timeIntervalSinceNow: (-320 * 60) + 40),
            Date(timeIntervalSinceNow: (-430 * 60) + 50),
            Date(timeIntervalSinceNow: (-540 * 60) + 60),
            Date(timeIntervalSinceNow: (-650 * 60) + 35),
            Date(timeIntervalSinceNow: (-760 * 60) + 45),
            Date(timeIntervalSinceNow: (-870 * 60) + 55),
            Date(timeIntervalSinceNow: (-980 * 60) + 25),
            Date(timeIntervalSinceNow: (-1030 * 60) + 30),
            Date(timeIntervalSinceNow: (-1100 * 60) + 40),
            Date(timeIntervalSinceNow: (-1170 * 60) + 50),
            Date(timeIntervalSinceNow: (-1240 * 60) + 60),
            Date(timeIntervalSinceNow: (-1310 * 60) + 35),
            Date(timeIntervalSinceNow: (-1380 * 60) + 45),
            Date(timeIntervalSinceNow: (-1450 * 60) + 55),
            Date(timeIntervalSinceNow: (-1520 * 60) + 25),
            Date(timeIntervalSinceNow: (-1590 * 60) + 30)
        ]
        let destination = Destination(id: "0F051871-0C44-4856-83C6-4852661B2BF7", isEncrypted: true, isNetwork: false, bytesAvailable: 1311960657920, bytesUsed: 454036393984, volumeName: "Time Machine", snapshots: snapshots)
        return Preferences(destinations: [destination], lastDestination: destination)
    }
}
