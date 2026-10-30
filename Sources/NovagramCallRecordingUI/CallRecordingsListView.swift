// SPDX-License-Identifier: GPL-2.0-or-later
import SwiftUI
import NovagramCallRecordingCore

/// The Call recordings screen: the summary line, day sections, the storage footer and the empty state, with a
/// menu to filter (All / Video / Voice), select (iOS; the Mac selects natively) and clear.
///
/// Put it in a navigation container; it sets its own title and toolbar. Rows play on tap (double-click on the Mac)
/// and offer Play, Share and Delete in a context menu (and swipe actions on iOS).
@available(macOS 14, iOS 15, *)
public struct CallRecordingsListView: View {
    @StateObject private var model: CallRecordingsListViewModel
    private let environment: CallRecordingUIEnvironment

    @State private var pendingDeletion: PendingDeletion?
    @State private var frames = CallRecordingFrameStore()
    @ScaledMetric(relativeTo: .body) private var scaledHundred: CGFloat = 100
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private struct PendingDeletion: Identifiable {
        let id = UUID()
        let urls: [URL]
        let text: String
    }

    /// Lists `storage`. The list loads when the view appears.
    public init(storage: CallRecordingStorage, environment: CallRecordingUIEnvironment) {
        self._model = StateObject(wrappedValue: CallRecordingsListViewModel(storage: storage))
        self.environment = environment
    }

    /// Uses the host's model, so the host can call ``CallRecordingsListViewModel/reload()`` after a new recording.
    public init(model: CallRecordingsListViewModel, environment: CallRecordingUIEnvironment) {
        self._model = StateObject(wrappedValue: model)
        self.environment = environment
    }

    #if os(iOS)
    // The grouped-settings row padding of the iOS app's lists; SwiftUI's default is about 15 pt above and below.
    private static let rowInsets = EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
    #endif

    private var theme: CallRecordingTheme {
        return self.environment.theme
    }

    private var strings: CallRecordingStrings {
        return self.environment.strings
    }

    private var fontScale: CGFloat {
        return self.theme.followsDynamicType ? self.scaledHundred / 100 : 1
    }

    private var isLargeText: Bool {
        return (self.theme.followsDynamicType && self.dynamicTypeSize.isAccessibilitySize) || self.theme.titleFontSize * self.fontScale >= 24
    }

    public var body: some View {
        Group {
            if self.model.isLoaded && self.model.recordings.isEmpty {
                self.emptyState
            } else {
                self.list
            }
        }
        .modifier(CallRecordingNavigationTitle(title: self.environment.showsToolbar ? self.strings.title : nil))
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarLeading) {
                if self.environment.showsToolbar && self.isSelecting {
                    Button(self.allVisibleSelected ? self.strings.deselectAll : self.strings.selectAll) {
                        self.toggleSelectAll()
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if !self.environment.showsToolbar {
                    EmptyView()
                } else if self.isSelecting {
                    Button(self.strings.done) {
                        self.setSelecting(false)
                    }
                    .font(.body.weight(.semibold))
                } else {
                    self.menu
                }
            }
            #else
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    self.share(self.selectedURLs, rect: self.frames.frame(for: self.selectedURLs))
                } label: {
                    Label(self.strings.share, systemImage: "square.and.arrow.up")
                }
                .disabled(self.selection.isEmpty)
                Button(role: .destructive) {
                    self.confirmDeleteSelected()
                } label: {
                    Label(self.strings.delete, systemImage: "trash")
                }
                .disabled(self.selection.isEmpty)
                self.menu
            }
            #endif
        }
        #if os(iOS)
        .navigationBarBackButtonHidden(self.environment.showsToolbar && self.isSelecting)
        .safeAreaInset(edge: .bottom) {
            if self.isSelecting {
                self.selectionBar
            }
        }
        #endif
        .alert(self.pendingDeletion?.text ?? "", isPresented: self.deletionIsPresented, presenting: self.pendingDeletion) { pending in
            Button(self.strings.delete, role: .destructive) {
                self.performDeletion(pending.urls)
            }
            Button(self.strings.cancel, role: .cancel) {
            }
        }
        .tint(self.theme.accent)
        .onReceive(self.model.clearAllRequests) { _ in
            self.confirmClearAll()
        }
        .task {
            await self.model.reload()
        }
    }

    // MARK: - List

    private var list: some View {
        let sections = self.model.sections()
        let summary = CallRecordingsListModel.summary(for: self.model.visibleRecordings, filter: self.model.filter, strings: self.strings, sizeString: self.environment.sizeString)
        return List(selection: self.$model.selection) {
            if sections.isEmpty {
                Section {
                } header: {
                    self.freeText(summary)
                } footer: {
                    self.freeText(self.strings.storageFooter)
                }
            }
            ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                Section {
                    ForEach(section.recordings) { recording in
                        self.row(recording)
                    }
                } header: {
                    if index == 0 {
                        VStack(alignment: .leading, spacing: 16) {
                            self.freeText(summary)
                            self.dayHeader(section.day)
                        }
                    } else {
                        self.dayHeader(section.day)
                    }
                } footer: {
                    if index == sections.count - 1 {
                        self.freeText(self.strings.storageFooter)
                    }
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        .environment(\.editMode, .constant(self.isSelecting ? .active : .inactive))
        #else
        .listStyle(.inset)
        .contextMenu(forSelectionType: URL.self) { urls in
            self.menuItems(for: Array(urls))
        } primaryAction: { urls in
            if let recording = self.model.recordings.first(where: { urls.contains($0.url) }) {
                self.environment.onPlay(recording)
            }
        }
        .onDeleteCommand {
            self.confirmDeleteSelected()
        }
        #endif
        .modifier(CallRecordingListBackground(color: self.theme.background))
    }

    @ViewBuilder
    private func row(_ recording: CallRecording) -> some View {
        let content = CallRecordingRow(recording: recording, environment: self.environment, fontScale: self.fontScale, isLarge: self.isLargeText, frames: self.frames)
            .accessibilityAction(named: Text(self.strings.play)) {
                self.environment.onPlay(recording)
            }
            .accessibilityAction(named: Text(self.strings.share)) {
                self.share([recording.url], rect: self.frames.frame(for: [recording.url]))
            }
            .accessibilityAction(named: Text(self.strings.delete)) {
                self.confirm([recording.url], text: self.strings.deleteConfirm)
            }
        #if os(iOS)
        Group {
            if self.isSelecting {
                content
            } else {
                Button {
                    self.environment.onPlay(recording)
                } label: {
                    content
                }
            }
        }
        .listRowBackground(self.theme.card)
        .listRowInsets(CallRecordingsListView.rowInsets)
        .listRowSeparatorTint(self.theme.separator)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                self.confirm([recording.url], text: self.strings.deleteConfirm)
            } label: {
                Label(self.strings.delete, systemImage: "trash")
            }
            Button {
                self.share([recording.url], rect: self.frames.frame(for: [recording.url]))
            } label: {
                Label(self.strings.share, systemImage: "square.and.arrow.up")
            }
            .tint(self.theme.accent)
        }
        .contextMenu {
            self.menuItems(for: [recording.url])
        }
        #else
        content
            .listRowSeparatorTint(self.theme.separator)
        #endif
    }

    @ViewBuilder
    private func menuItems(for urls: [URL]) -> some View {
        if !urls.isEmpty {
            if urls.count == 1, let recording = self.model.recordings.first(where: { $0.url == urls[0] }) {
                Button {
                    self.environment.onPlay(recording)
                } label: {
                    Label(self.strings.play, systemImage: "play")
                }
            }
            Button {
                self.share(urls, rect: self.frames.frame(for: urls))
            } label: {
                Label(self.strings.share, systemImage: "square.and.arrow.up")
            }
            Button(role: .destructive) {
                self.confirm(urls, text: urls.count == 1 ? self.strings.deleteConfirm : self.strings.deleteSelectedConfirm(urls.count))
            } label: {
                Label(self.strings.delete, systemImage: "trash")
            }
        }
    }

    private func freeText(_ text: String) -> some View {
        return Text(text)
            .font(.system(size: self.theme.freeTextFontSize * self.fontScale))
            .foregroundColor(self.theme.freeText)
            .textCase(nil)
    }

    private func dayHeader(_ day: Date) -> some View {
        return Text(self.environment.dayHeader(day))
            .font(.system(size: self.theme.freeTextFontSize * self.fontScale))
            .foregroundColor(self.theme.freeText)
            .textCase(.uppercase)
            .accessibilityAddTraits(.isHeader)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.circle")
                .font(.system(size: 56 * self.fontScale))
                .foregroundColor(self.theme.secondaryText)
                .accessibilityHidden(true)
            Text(self.strings.emptyTitle)
                .font(.system(size: self.theme.titleFontSize * self.fontScale, weight: .semibold))
                .foregroundColor(self.theme.primaryText)
            Text(self.environment.isRecordingEnabled ? self.strings.emptyTextEnabled : self.strings.emptyText)
                .font(.system(size: self.theme.subtitleFontSize * self.fontScale))
                .foregroundColor(self.theme.freeText)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(self.theme.background.ignoresSafeArea())
        .accessibilityElement(children: .combine)
    }

    // MARK: - Menu and selection

    private var menu: some View {
        Menu {
            Picker(selection: self.filterBinding) {
                ForEach(CallRecordingFilter.allCases, id: \.self) { filter in
                    Text(filter.title(self.strings)).tag(filter)
                }
            } label: {
                Text(self.strings.options)
            }
            .pickerStyle(.inline)
            if !self.model.visibleRecordings.isEmpty {
                #if os(iOS)
                Button {
                    self.setSelecting(true)
                } label: {
                    Label(self.strings.select, systemImage: "checkmark.circle")
                }
                #endif
                Button(role: .destructive) {
                    self.confirmClearAll()
                } label: {
                    Label(self.strings.clearAll, systemImage: "trash")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .accessibilityLabel(Text(self.strings.options))
        }
    }

    #if os(iOS)
    private var selectionBar: some View {
        HStack {
            Button {
                self.share(self.selectedURLs, rect: self.frames.shareButtonFrame)
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .accessibilityLabel(Text(self.strings.share))
            }
            .disabled(self.selection.isEmpty)
            .background(GeometryReader { proxy in
                let _ = self.frames.shareButtonFrame = proxy.frame(in: .global)
                Color.clear
            })
            Spacer()
            Button(role: .destructive) {
                self.confirmDeleteSelected()
            } label: {
                Text(self.strings.deleteSelectedButton(self.selection.count))
            }
            .foregroundColor(self.selection.isEmpty ? self.theme.secondaryText : self.theme.destructive)
            .disabled(self.selection.isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.bar)
    }
    #endif

    private var filterBinding: Binding<CallRecordingFilter> {
        return Binding(get: {
            self.model.filter
        }, set: { filter in
            self.model.filter = filter
        })
    }

    private var isSelecting: Bool {
        return self.model.isSelecting
    }

    private var selection: Set<URL> {
        return self.model.selection
    }

    private var deletionIsPresented: Binding<Bool> {
        return Binding(get: {
            self.pendingDeletion != nil
        }, set: { isPresented in
            if !isPresented {
                self.pendingDeletion = nil
            }
        })
    }

    private var selectedURLs: [URL] {
        return self.model.selectedURLs
    }

    private var allVisibleSelected: Bool {
        return self.model.allVisibleSelected
    }

    private func toggleSelectAll() {
        self.model.toggleSelectAll()
    }

    private func setSelecting(_ isSelecting: Bool) {
        self.model.setSelecting(isSelecting)
    }

    // MARK: - Actions

    private func share(_ urls: [URL], rect: CGRect) {
        guard !urls.isEmpty else {
            return
        }
        self.environment.onShare(urls, rect)
    }

    private func confirmDeleteSelected() {
        let urls = self.selectedURLs
        guard !urls.isEmpty else {
            return
        }
        self.confirm(urls, text: self.strings.deleteSelectedConfirm(urls.count))
    }

    private func confirmClearAll() {
        let visible = self.model.visibleRecordings
        guard !visible.isEmpty else {
            return
        }
        let text = CallRecordingsListModel.clearConfirmation(for: visible, filter: self.model.filter, strings: self.strings, sizeString: self.environment.sizeString)
        self.confirm(visible.map(\.url), text: text)
    }

    private func confirm(_ urls: [URL], text: String) {
        self.pendingDeletion = PendingDeletion(urls: urls, text: text)
    }

    private func performDeletion(_ urls: [URL]) {
        let deleted = self.model.delete(urls)
        self.frames.forget(deleted)
        self.model.selection.subtract(deleted)
        if self.model.visibleRecordings.isEmpty {
            self.model.setSelecting(false)
        }
    }
}

// The navigation title, or none when the host draws its own navigation bar.
@available(macOS 14, iOS 15, *)
private struct CallRecordingNavigationTitle: ViewModifier {
    let title: String?

    func body(content: Content) -> some View {
        if let title = self.title {
            content.navigationTitle(title)
        } else {
            content
        }
    }
}

// Shows the theme's background behind the list where the system allows it (iOS 16+; always on macOS 14).
@available(macOS 14, iOS 15, *)
private struct CallRecordingListBackground: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .scrollContentBackground(.hidden)
                .background(self.color.ignoresSafeArea())
        } else {
            content
        }
    }
}
