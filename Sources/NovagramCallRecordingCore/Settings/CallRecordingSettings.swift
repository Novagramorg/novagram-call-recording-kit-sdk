// SPDX-License-Identifier: GPL-2.0-or-later
import Foundation

/// The call recording switches, shared by both apps: same keys, in the `pro_messager` suite, all default off.
///
/// Each switch is the feature itself: there is no second gate. Where an app shows the switches (a Developer section
/// while the feature is unapproved, its normal section once approved) is the app's business.
public struct CallRecordingSettings {
    /// The `UserDefaults` suite both apps use for Novagram settings.
    public static let suiteName = "pro_messager"
    /// The "Call recording" switch.
    public static let enabledKey = "novagram_call_recording"
    /// The "Record every call automatically" switch.
    public static let autoKey = "novagram_call_recording_auto"
    /// Set once the first-recording consent alert was accepted.
    public static let warnedKey = "novagram_call_recording_warned"

    /// Posted by an app when a call changes a switch or saves a recording, so open settings screens refresh.
    public static let changedNotification = Notification.Name("NovagramCallRecordingChanged")

    public let defaults: UserDefaults

    /// Reads and writes `defaults`; tests inject their own suite.
    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    /// The `pro_messager` suite (the standard defaults if the suite cannot be opened).
    public init() {
        self.init(defaults: UserDefaults(suiteName: CallRecordingSettings.suiteName) ?? .standard)
    }

    /// "Call recording": calls show the Record control. Missing key = off.
    public var isEnabled: Bool {
        get {
            return self.defaults.bool(forKey: CallRecordingSettings.enabledKey)
        }
        nonmutating set {
            self.defaults.set(newValue, forKey: CallRecordingSettings.enabledKey)
        }
    }

    /// "Record every call automatically". Only takes effect while ``isEnabled``. Missing key = off.
    public var isAutoEnabled: Bool {
        get {
            return self.defaults.bool(forKey: CallRecordingSettings.autoKey)
        }
        nonmutating set {
            self.defaults.set(newValue, forKey: CallRecordingSettings.autoKey)
        }
    }

    /// The consent alert was accepted once.
    public var wasWarned: Bool {
        get {
            return self.defaults.bool(forKey: CallRecordingSettings.warnedKey)
        }
        nonmutating set {
            self.defaults.set(newValue, forKey: CallRecordingSettings.warnedKey)
        }
    }
}
