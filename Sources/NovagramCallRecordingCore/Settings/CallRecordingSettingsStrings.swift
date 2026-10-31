// SPDX-License-Identifier: GPL-2.0-or-later
import Foundation

/// Every text of the "Call recording" settings page, so both apps explain each setting with the same words.
///
/// The apps draw the page with their own lists; the layout is the same, like the Camera page in the system
/// Settings, where every setting has its own block with an explanation under it:
///
/// - The app's settings list (a Developer section while the feature is unapproved) has one row, ``title`` with
///   ``on`` / ``off`` as its value, that opens the page.
/// - ``recordingHeader``: the ``recordTitle`` switch (``CallRecordingSettings/isEnabled``), ``recordFooter`` under it.
/// - While it is on: the ``autoTitle`` switch (``CallRecordingSettings/isAutoEnabled``), ``autoFooter`` under it.
/// - ``recordingsHeader``: the ``recordingsTitle`` row (the recording count as its value) that opens the list,
///   ``recordingsFooter`` under it. Always shown, so recordings stay reachable after the switch is turned off.
/// - ``privacyHeader``: the ``privacyText`` paragraph.
///
/// An app may add its own rows (the Mac's "Save to" folder) with its own texts. The texts name no device or
/// platform (App Review), so every platform shows the same words.
public struct CallRecordingSettingsStrings {
    public let language: CallRecordingLanguage

    /// The page title and the row that opens the page.
    public var title: String
    /// The value of that row while the "Call recording" switch is on.
    public var on: String
    /// The value of that row while the switch is off.
    public var off: String

    public var recordingHeader: String
    /// The "Call recording" switch.
    public var recordTitle: String
    public var recordFooter: String
    /// The "Record every call automatically" switch.
    public var autoTitle: String
    public var autoFooter: String

    public var recordingsHeader: String
    /// The row that opens the recordings list.
    public var recordingsTitle: String
    public var recordingsFooter: String

    public var privacyHeader: String
    /// Quotes the chat message ``CallRecordingNoticePolicy/message(languageCode:)`` word for word.
    public var privacyText: String

    public init(languageCode: String) {
        let language = CallRecordingLanguage(code: languageCode)
        self.language = language
        let pick = language.pick
        let notice = CallRecordingNoticePolicy.message(languageCode: languageCode)

        // One text for every platform: no device or platform names (App Review) and no "tap" / "click".
        self.title = pick("Call recording", "Qo'ng'iroqni yozib olish", "Запись звонков", "通话录音")
        self.on = pick("On", "Yoqilgan", "Вкл.", "打开")
        self.off = pick("Off", "O'chirilgan", "Выкл.", "关闭")

        self.recordingHeader = pick("RECORDING", "YOZIB OLISH", "ЗАПИСЬ", "录音")
        self.recordTitle = self.title
        self.recordFooter = pick(
            "Adds a Record button to voice and video calls to start and stop recording. The first time, Novagram asks you to confirm.",
            "Ovozli va video qo'ng'iroqlarga yozishni boshlash va to'xtatish uchun «Yozish» tugmasini qo'shadi. Birinchi marta Novagram tasdiqlashni so'raydi.",
            "Добавляет в аудио- и видеозвонки кнопку «Запись», чтобы начинать и останавливать запись. В первый раз Novagram попросит подтверждение.",
            "在语音和视频通话中添加“录制”按钮，用来开始和停止录音。第一次录音时，Novagram 会请你确认。"
        )
        self.autoTitle = pick("Record every call automatically", "Har bir qo'ng'iroqni avtomatik yozib olish", "Записывать каждый звонок автоматически", "自动录制每个通话")
        self.autoFooter = pick(
            "Recording starts by itself when your call starts ringing or when you answer. If you stop it, it does not start again in that call.",
            "Qo'ng'iroq jiringlay boshlaganda yoki javob berganingizda yozish o'zi boshlanadi. Uni to'xtatsangiz, shu qo'ng'iroqda qayta boshlanmaydi.",
            "Запись начинается сама, когда идёт вызов или когда вы отвечаете. Если вы её остановите, в этом звонке она больше не начнётся.",
            "当你的呼叫开始响铃或你接听时，录音会自动开始。如果你停止录音，本次通话中不会再次开始。"
        )

        self.recordingsHeader = pick("RECORDINGS", "YOZUVLAR", "ЗАПИСИ", "录音文件")
        self.recordingsTitle = pick("Call recordings", "Qo'ng'iroq yozuvlari", "Записи звонков", "通话录音文件")
        self.recordingsFooter = pick(
            "Recordings are kept only on this device and are never uploaded: video calls as video, voice calls as audio. Open the list to play, share or delete them.",
            "Yozuvlar faqat shu qurilmada saqlanadi va hech qayerga yuklanmaydi: video qo'ng'iroqlar video, ovozli qo'ng'iroqlar audio bo'lib. Ro'yxatni ochib, ularni tinglash, ulashish yoki o'chirish mumkin.",
            "Записи хранятся только на этом устройстве и никуда не загружаются: видеозвонки — как видео, аудиозвонки — как аудио. Откройте список, чтобы прослушать, отправить или удалить их.",
            "录音只保存在此设备上，绝不会上传：视频通话保存为视频，语音通话保存为音频。打开列表即可播放、分享或删除录音。"
        )

        self.privacyHeader = pick("PRIVACY", "MAXFIYLIK", "КОНФИДЕНЦИАЛЬНОСТЬ", "隐私")
        self.privacyText = pick(
            "When a recording starts, Novagram sends “\(notice)” to the chat, so the other person knows. The REC mark stays on screen while recording. If that message cannot be sent, the call is not recorded.",
            "Yozib olish boshlanganda Novagram chatga «\(notice)» xabarini yuboradi, shunda suhbatdoshingiz bundan xabardor bo'ladi. Yozib olish davomida REC belgisi ekranda turadi. Bu xabar yuborilmasa, qo'ng'iroq yozib olinmaydi.",
            "Когда начинается запись, Novagram отправляет в чат «\(notice)», чтобы собеседник знал об этом. Пока идёт запись, значок REC остаётся на экране. Если это сообщение не удаётся отправить, звонок не записывается.",
            "录音开始时，Novagram 会向聊天发送“\(notice)”，让对方知道。录音期间 REC 标记始终显示在屏幕上。如果这条消息无法发送，通话将不会被录制。"
        )
    }
}
