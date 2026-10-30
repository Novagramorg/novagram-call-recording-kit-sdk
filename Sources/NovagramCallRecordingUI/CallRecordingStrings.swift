// SPDX-License-Identifier: GPL-2.0-or-later
import Foundation
import NovagramCallRecordingCore

/// Every text of the recordings screen. English, Uzbek, Russian and Chinese are built in; the host passes its
/// language code and may override any value (for example with Telegram's own "Cancel" and "Delete").
@available(macOS 14, iOS 15, *)
public struct CallRecordingStrings {
    public let language: CallRecordingLanguage

    public var title: String
    public var emptyTitle: String
    /// The empty state while the "Call recording" switch is off.
    public var emptyText: String
    /// The empty state while the "Call recording" switch is on.
    public var emptyTextEnabled: String
    public var videoCall: String
    public var voiceCall: String
    public var play: String
    public var share: String
    public var delete: String
    public var cancel: String
    public var select: String
    public var selectAll: String
    public var deselectAll: String
    public var done: String
    /// The accessibility label of the toolbar menu.
    public var options: String
    public var filterAll: String
    public var filterVideo: String
    public var filterVoice: String
    public var clearAll: String
    public var today: String
    public var yesterday: String
    /// Under the list.
    public var storageFooter: String
    /// One recording, from a swipe or a context menu.
    public var deleteConfirm: String
    /// The chat message sent when a recording starts (see `CallRecordingNoticePolicy`).
    public var noticeMessage: String
    /// The toast when that message could not be sent.
    public var noticeFailed: String

    /// "4 recordings · 24,6 MB": count and formatted size.
    public var summary: (Int, String) -> String
    /// The list when the filter hides every recording; the argument is "the Video filter is on".
    public var filterEmpty: (Bool) -> String
    /// "Delete 3 recordings?"
    public var deleteSelectedConfirm: (Int) -> String
    /// The delete button while selecting: "Delete (3)".
    public var deleteSelectedButton: (Int) -> String
    /// Clear All with no filter: count and formatted size.
    public var clearAllConfirm: (Int, String) -> String
    /// Clear All with the Video or Voice filter: count, formatted size, "the Video filter is on".
    public var clearFilteredConfirm: (Int, String, Bool) -> String

    public init(languageCode: String) {
        let language = CallRecordingLanguage(code: languageCode)
        self.language = language
        let pick = language.pick
        self.title = pick("Call recordings", "Qo'ng'iroq yozuvlari", "Записи звонков", "通话录音文件")
        self.emptyTitle = pick("No recordings yet", "Hali yozuvlar yo'q", "Записей пока нет", "还没有录音")
        // "Tap" on a touch screen, "Click" on the Mac. Only English differs: uz "bosing", ru "нажмите" and zh "点按"
        // (Apple's own word for a Mac click) fit both.
        #if os(macOS)
        let tapWord = "click"
        #else
        let tapWord = "tap"
        #endif
        self.emptyText = pick(
            "Turn on Call recording and \(tapWord) Record during a call.",
            "«Qo'ng'iroqni yozib olish»ni yoqing va qo'ng'iroq paytida «Yozish»ni bosing.",
            "Включите «Запись звонков» и нажмите «Запись» во время звонка.",
            "打开“通话录音”，并在通话中点按“录制”。"
        )
        self.emptyTextEnabled = pick(
            "\(tapWord.capitalized) Record during a call to save it here.",
            "Qo'ng'iroq paytida «Yozish»ni bosing, yozuv shu yerda saqlanadi.",
            "Нажмите «Запись» во время звонка, и запись появится здесь.",
            "在通话中点按“录制”，录音会保存在这里。"
        )
        self.videoCall = pick("Video call", "Video qo'ng'iroq", "Видеозвонок", "视频通话")
        self.voiceCall = pick("Voice call", "Ovozli qo'ng'iroq", "Аудиозвонок", "语音通话")
        self.play = pick("Play", "Ijro etish", "Воспроизвести", "播放")
        self.share = pick("Share", "Ulashish", "Поделиться", "分享")
        self.delete = pick("Delete", "O'chirish", "Удалить", "删除")
        self.cancel = pick("Cancel", "Bekor qilish", "Отмена", "取消")
        self.select = pick("Select", "Tanlash", "Выбрать", "选择")
        self.selectAll = pick("Select All", "Hammasini tanlash", "Выбрать все", "全选")
        self.deselectAll = pick("Deselect All", "Tanlovni bekor qilish", "Снять выбор", "取消全选")
        self.done = pick("Done", "Tayyor", "Готово", "完成")
        self.options = pick("Options", "Amallar", "Действия", "选项")
        self.filterAll = pick("All Recordings", "Barcha yozuvlar", "Все записи", "全部录音")
        self.filterVideo = pick("Video Calls", "Video qo'ng'iroqlar", "Видеозвонки", "视频通话")
        self.filterVoice = pick("Voice Calls", "Ovozli qo'ng'iroqlar", "Аудиозвонки", "语音通话")
        self.clearAll = pick("Clear All", "Hammasini o'chirish", "Удалить все", "全部清除")
        self.today = pick("Today", "Bugun", "Сегодня", "今天")
        self.yesterday = pick("Yesterday", "Kecha", "Вчера", "昨天")
        #if os(macOS)
        self.storageFooter = pick(
            "Recordings are stored only on this Mac and are never uploaded.",
            "Yozuvlar faqat shu Mac'da saqlanadi va hech qayerga yuklanmaydi.",
            "Записи хранятся только на этом Mac и никуда не загружаются.",
            "录音只保存在这台 Mac 上，绝不会上传。"
        )
        #else
        self.storageFooter = pick(
            "Recordings are stored only on this iPhone and are never uploaded.",
            "Yozuvlar faqat shu iPhone'da saqlanadi va hech qayerga yuklanmaydi.",
            "Записи хранятся только на этом iPhone и никуда не загружаются.",
            "录音只保存在这台 iPhone 上，绝不会上传。"
        )
        #endif
        self.deleteConfirm = pick("Delete this recording?", "Bu yozuv o'chirilsinmi?", "Удалить эту запись?", "删除这条录音？")
        self.noticeMessage = CallRecordingNoticePolicy.message(languageCode: languageCode)
        self.noticeFailed = CallRecordingNoticePolicy.failureMessage(languageCode: languageCode)

        let delete = self.delete
        self.summary = { count, size in
            switch language {
            case .uzbek:
                return "\(count) ta yozuv · \(size)"
            case .russian:
                return "\(count) \(CallRecordingStrings.russianRecordings(count)) · \(size)"
            case .chinese:
                return "\(count) 条录音 · \(size)"
            case .english:
                return "\(count) \(CallRecordingStrings.englishRecordings(count)) · \(size)"
            }
        }
        self.filterEmpty = { isVideo in
            if isVideo {
                return language.pick(en: "No video call recordings", uz: "Video qo'ng'iroq yozuvlari yo'q", ru: "Нет записей видеозвонков", zh: "没有视频通话录音")
            }
            return language.pick(en: "No voice call recordings", uz: "Ovozli qo'ng'iroq yozuvlari yo'q", ru: "Нет записей аудиозвонков", zh: "没有语音通话录音")
        }
        self.deleteSelectedConfirm = { count in
            switch language {
            case .uzbek:
                return "\(count) ta yozuv o'chirilsinmi?"
            case .russian:
                return "Удалить \(count) \(CallRecordingStrings.russianRecordings(count))?"
            case .chinese:
                return "删除 \(count) 条录音？"
            case .english:
                return "Delete \(count) \(CallRecordingStrings.englishRecordings(count))?"
            }
        }
        self.deleteSelectedButton = { count in
            return "\(delete) (\(count))"
        }
        self.clearAllConfirm = { count, size in
            let isOne = count == 1
            switch language {
            case .uzbek:
                return "\(isOne ? "" : "Barcha ")\(count) ta yozuv (\(size)) o'chirilsinmi? Buni qaytarib bo'lmaydi."
            case .russian:
                return "Удалить \(isOne ? "" : "все ")\(count) \(CallRecordingStrings.russianRecordings(count)) (\(size))? Это действие нельзя отменить."
            case .chinese:
                return "删除\(isOne ? "" : "全部 ")\(count) 条录音（\(size)）？此操作无法撤销。"
            case .english:
                return "Delete \(isOne ? "" : "all ")\(count) \(CallRecordingStrings.englishRecordings(count)) (\(size))? This cannot be undone."
            }
        }
        self.clearFilteredConfirm = { count, size, isVideo in
            switch language {
            case .uzbek:
                let kind = isVideo ? "video qo'ng'iroq" : "ovozli qo'ng'iroq"
                return "\(count) ta \(kind) yozuvi (\(size)) o'chirilsinmi? Filtr yashirgan yozuvlar qoladi."
            case .russian:
                let kind = isVideo ? "видеозвонков" : "аудиозвонков"
                return "Удалить \(count) \(CallRecordingStrings.russianRecordings(count)) \(kind) (\(size))? Записи, скрытые фильтром, останутся."
            case .chinese:
                let kind = isVideo ? "视频通话" : "语音通话"
                return "删除 \(count) 条\(kind)录音（\(size)）？被筛选隐藏的录音会保留。"
            case .english:
                let kind = isVideo ? "video call" : "voice call"
                return "Delete \(count) \(kind) \(CallRecordingStrings.englishRecordings(count)) (\(size))? Recordings hidden by the filter are kept."
            }
        }
    }

    static func englishRecordings(_ count: Int) -> String {
        return count == 1 ? "recording" : "recordings"
    }

    static func russianRecordings(_ count: Int) -> String {
        let mod10 = count % 10
        let mod100 = count % 100
        if mod10 == 1 && mod100 != 11 {
            return "запись"
        }
        if (2 ... 4).contains(mod10) && !(12 ... 14).contains(mod100) {
            return "записи"
        }
        return "записей"
    }
}
