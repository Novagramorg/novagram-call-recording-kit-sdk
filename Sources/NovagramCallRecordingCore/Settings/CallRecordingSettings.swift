// SPDX-License-Identifier: GPL-2.0-or-later
import Foundation

/// The call recording switches, shared by both apps: same keys, in the `pro_messager` suite, all default off.
///
/// The whole feature sits behind the hidden Developer switch "Call recording (beta)" (`novagram_dev_call_recording`,
/// missing key = off). With it off ``isEnabled`` and ``isAutoEnabled`` are false; the user's own switches keep their
/// values (``isUserEnabled``, ``isUserAutoEnabled``).
public struct CallRecordingSettings {
    /// The `UserDefaults` suite both apps use for Novagram settings.
    public static let suiteName = "pro_messager"
    /// The user's "Call recording" switch.
    public static let enabledKey = "novagram_call_recording"
    /// The user's "Record every call automatically" switch.
    public static let autoKey = "novagram_call_recording_auto"
    /// Set once the first-recording consent alert was accepted.
    public static let warnedKey = "novagram_call_recording_warned"
    /// The Developer switch "Call recording (beta)".
    public static let developerFlagKey = "novagram_dev_call_recording"

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

    /// The Developer switch. Missing key = off.
    public var isDeveloperEnabled: Bool {
        get {
            return self.defaults.object(forKey: CallRecordingSettings.developerFlagKey) as? Bool ?? false
        }
        nonmutating set {
            self.defaults.set(newValue, forKey: CallRecordingSettings.developerFlagKey)
        }
    }

    /// What calls read: the Developer switch and the user's "Call recording" switch are both on.
    public var isEnabled: Bool {
        return self.isDeveloperEnabled && self.isUserEnabled
    }

    /// "Record every call automatically", gated by the Developer switch. Only takes effect while ``isEnabled``.
    public var isAutoEnabled: Bool {
        return self.isDeveloperEnabled && self.isUserAutoEnabled
    }

    /// The user's "Call recording" switch as stored.
    public var isUserEnabled: Bool {
        get {
            return self.defaults.bool(forKey: CallRecordingSettings.enabledKey)
        }
        nonmutating set {
            self.defaults.set(newValue, forKey: CallRecordingSettings.enabledKey)
        }
    }

    /// The user's "Record every call automatically" switch as stored.
    public var isUserAutoEnabled: Bool {
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
