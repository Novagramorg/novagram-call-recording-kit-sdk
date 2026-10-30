// SPDX-License-Identifier: GPL-2.0-or-later
import XCTest
@testable import NovagramCallRecordingCore

@available(macOS 14, iOS 15, *)
final class CallRecordingNoticePolicyTests: XCTestCase {
    func testSentOncePerCallSession() {
        var policy = CallRecordingNoticePolicy()
        let callId = UUID()
        XCTAssertTrue(policy.beginSending(callSessionId: callId, isOneToOneUser: true, recorderDidStart: true))
        // Stop, then Record again while the notice is still on its way.
        XCTAssertFalse(policy.beginSending(callSessionId: callId, isOneToOneUser: true, recorderDidStart: true))
        policy.markDelivered(callSessionId: callId)
        // Stop, then Record again after it was delivered.
        XCTAssertFalse(policy.beginSending(callSessionId: callId, isOneToOneUser: true, recorderDidStart: true))
        XCTAssertEqual(policy.status(callSessionId: callId), .delivered)
    }

    func testEachCallGetsItsOwnNotice() {
        var policy = CallRecordingNoticePolicy()
        let first = UUID()
        let second = UUID()
        XCTAssertTrue(policy.beginSending(callSessionId: first, isOneToOneUser: true, recorderDidStart: true))
        XCTAssertTrue(policy.beginSending(callSessionId: second, isOneToOneUser: true, recorderDidStart: true))
        XCTAssertFalse(policy.beginSending(callSessionId: first, isOneToOneUser: true, recorderDidStart: true))
    }

    func testFailedNoticeIsSentAgainOnTheNextRecord() {
        var policy = CallRecordingNoticePolicy()
        let callId = UUID()
        XCTAssertTrue(policy.beginSending(callSessionId: callId, isOneToOneUser: true, recorderDidStart: true))
        policy.markFailed(callSessionId: callId)
        XCTAssertEqual(policy.status(callSessionId: callId), .failed)
        XCTAssertTrue(policy.beginSending(callSessionId: callId, isOneToOneUser: true, recorderDidStart: true))
        XCTAssertEqual(policy.status(callSessionId: callId), .sending)
    }

    func testForgetClearsTheCall() {
        var policy = CallRecordingNoticePolicy()
        let callId = UUID()
        XCTAssertTrue(policy.beginSending(callSessionId: callId, isOneToOneUser: true, recorderDidStart: true))
        policy.forget(callSessionId: callId)
        XCTAssertNil(policy.status(callSessionId: callId))
    }

    func testOnlyOneToOneUsersAfterTheRecorderStarted() {
        var policy = CallRecordingNoticePolicy()
        let callId = UUID()
        XCTAssertFalse(policy.beginSending(callSessionId: callId, isOneToOneUser: false, recorderDidStart: true), "group calls and bots get no notice")
        XCTAssertFalse(policy.beginSending(callSessionId: callId, isOneToOneUser: true, recorderDidStart: false), "a start that failed sends nothing")
        XCTAssertNil(policy.status(callSessionId: callId), "a refused start leaves no trace")
        XCTAssertTrue(policy.beginSending(callSessionId: callId, isOneToOneUser: true, recorderDidStart: true))
    }

    func testNoticeFollowsTheAppLanguage() {
        XCTAssertEqual(CallRecordingNoticePolicy.message(languageCode: "en"), "🔴 I'm recording this call (Novagram)")
        XCTAssertEqual(CallRecordingNoticePolicy.message(languageCode: "uz"), "🔴 Men bu qo'ng'iroqni yozib olyapman (Novagram)")
        XCTAssertEqual(CallRecordingNoticePolicy.message(languageCode: "ru"), "🔴 Я записываю этот звонок (Novagram)")
        XCTAssertEqual(CallRecordingNoticePolicy.message(languageCode: "zh-hans-raw"), "🔴 我正在录制这次通话（Novagram）")
        // Any other language gets the English text.
        XCTAssertEqual(CallRecordingNoticePolicy.message(languageCode: "de"), "🔴 I'm recording this call (Novagram)")
    }

    func testFailureToastFollowsTheAppLanguage() {
        XCTAssertEqual(CallRecordingNoticePolicy.failureMessage(languageCode: "en"), "Couldn't notify the other person, so the call is not being recorded.")
        XCTAssertEqual(CallRecordingNoticePolicy.failureMessage(languageCode: "uz"), "Suhbatdoshga xabar berib bo'lmadi, shuning uchun qo'ng'iroq yozilmayapti.")
        XCTAssertEqual(CallRecordingNoticePolicy.failureMessage(languageCode: "ru"), "Не удалось уведомить собеседника, поэтому звонок не записывается.")
        XCTAssertEqual(CallRecordingNoticePolicy.failureMessage(languageCode: "zh"), "无法通知对方，因此本次通话未被录制。")
        XCTAssertEqual(CallRecordingNoticePolicy.failureMessage(languageCode: "fr"), CallRecordingNoticePolicy.failureMessage(languageCode: "en"))
    }

    func testLanguageCodes() {
        XCTAssertEqual(CallRecordingLanguage(code: "uz-Latn"), .uzbek)
        XCTAssertEqual(CallRecordingLanguage(code: "ru_RU"), .russian)
        XCTAssertEqual(CallRecordingLanguage(code: "ZH-Hant"), .chinese)
        XCTAssertEqual(CallRecordingLanguage(code: ""), .english)
    }
}

@available(macOS 14, iOS 15, *)
final class CallRecordingSettingsTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        self.suiteName = "call-recording-settings-\(UUID().uuidString)"
        self.defaults = UserDefaults(suiteName: self.suiteName)
    }

    override func tearDown() {
        self.defaults.removePersistentDomain(forName: self.suiteName)
        super.tearDown()
    }

    // Both apps read these exact keys; renaming one wipes the users' switches.
    func testKeysAreTheSharedOnes() {
        XCTAssertEqual(CallRecordingSettings.suiteName, "pro_messager")
        XCTAssertEqual(CallRecordingSettings.enabledKey, "novagram_call_recording")
        XCTAssertEqual(CallRecordingSettings.autoKey, "novagram_call_recording_auto")
        XCTAssertEqual(CallRecordingSettings.warnedKey, "novagram_call_recording_warned")
    }

    func testEverythingIsOffByDefault() {
        let settings = CallRecordingSettings(defaults: self.defaults)
        XCTAssertFalse(settings.isEnabled)
        XCTAssertFalse(settings.isAutoEnabled)
        XCTAssertFalse(settings.wasWarned)
    }

    // One switch per feature: the stored key is what calls read, with no second gate.
    func testSwitchesAreTheStoredKeys() {
        let settings = CallRecordingSettings(defaults: self.defaults)
        settings.isEnabled = true
        XCTAssertTrue(settings.isEnabled)
        XCTAssertFalse(settings.isAutoEnabled)
        XCTAssertTrue(self.defaults.bool(forKey: "novagram_call_recording"))
        settings.isAutoEnabled = true
        XCTAssertTrue(settings.isAutoEnabled)
        XCTAssertTrue(self.defaults.bool(forKey: "novagram_call_recording_auto"))
        settings.isEnabled = false
        XCTAssertFalse(settings.isEnabled)
        settings.wasWarned = true
        XCTAssertTrue(self.defaults.bool(forKey: "novagram_call_recording_warned"))
    }
}
