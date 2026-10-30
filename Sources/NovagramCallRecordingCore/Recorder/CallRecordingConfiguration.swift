// SPDX-License-Identifier: GPL-2.0-or-later
import Foundation
import CoreGraphics

/// How recordings are encoded.
public struct CallRecordingConfiguration: Sendable, Equatable {
    /// The size of the recorded video in pixels; rounded down to even numbers (H.264 needs them), at least 2x2.
    /// The default is 720x1280, portrait, like the phone's call screen.
    public let videoSize: CGSize

    public init(videoSize: CGSize = CGSize(width: 720, height: 1280)) {
        let width = max(2, Int(videoSize.width) & ~1)
        let height = max(2, Int(videoSize.height) & ~1)
        self.videoSize = CGSize(width: width, height: height)
    }

    public static let standard = CallRecordingConfiguration()

    var canvas: CGRect {
        return CGRect(origin: .zero, size: self.videoSize)
    }
}

/// Why a recording failed.
public enum CallRecordingError: Error, Equatable, Sendable {
    /// AVAssetWriter failed; the text says at which stage and with which error.
    case writerFailed(String)
    /// The recording stopped before any audio arrived.
    case nothingRecorded
    /// ``CallRecordingCenter/stop(callId:completion:)`` for a call that is not being recorded.
    case cancelled
    /// ``CallRecordingCenter/start(callId:peerName:onDetach:)`` for a call that is already being recorded.
    case alreadyRecording
}
