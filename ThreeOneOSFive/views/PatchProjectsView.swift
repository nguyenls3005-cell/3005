import SwiftUI
import UIKit
import UniformTypeIdentifiers

private enum PatchPackagePickerPolicy {
    static let packageType = UTType(filenameExtension: "3105") ?? .data
    static let allowedContentTypes: [UTType] = [packageType, .data]
    static let copiesSelectedDocument = true
}
private enum WallpaperPackagePickerPolicy {
    static let packageType = UTType(filenameExtension: "tendies") ?? .data
    static let allowedContentTypes: [UTType] = [packageType, .data]
}

struct PatchProjectsView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var draftCoordinator: PatchDraftCoordinator
    @EnvironmentObject private var store: PatchProjectStore
    
    @AppStorage("isCleanerInstalled") private var isCleanerInstalled = false
    @AppStorage("isSupervisedInstalled") private var isSupervisedInstalled = false
    @AppStorage("isFootnoteInstalled") private var isFootnoteInstalled = false
    
    @State private var showCreate = false
    @State private var showImporter = false
    @State private var showWallpaperImporter = false
    @State private var searchText = ""
    @State private var wallpaperPackages: [WallpaperStagedPackage] = []
    @State private var wallpaperImportFeedback: WallpaperImportFeedback?
    @State private var wallpaperPendingDeletion: WallpaperStagedPackage?
    @State private var isImportingWallpapers = false
    @State private var showSimulatedWallpaperDetail = false
    @State private var simulatedWallpaperDetailGate = OneShotPresentationGate()
    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void

    private var filteredItems: [PatchLibraryItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return store.items }
        return store.items.filter { item in
            if item.packageURL.lastPathComponent.localizedCaseInsensitiveContains(query) { return true }
            guard let project = item.project else { return false }
            if project.name.localizedCaseInsensitiveContains(query) || project.author.localizedCaseInsensitiveContains(query) { return true }
            guard item.canInspectContents else { return false }
            return project.allBundleIdentifiers.contains { $0.localizedCaseInsensitiveContains(query) }
                || project.directories.contains { $0.relativePath.localizedCaseInsensitiveContains(query) }
                || project.rules.contains { $0.relativePath.localizedCaseInsensitiveContains(query) || $0.replacementFilename.localizedCaseInsensitiveContains(query) }
        }
    }

    private var filteredWallpaperPackages: [WallpaperStagedPackage] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return wallpaperPackages }
        return wallpaperPackages.filter { $0.displayName.localizedCaseInsensitiveContains(query) }
    }

    private var hasLocalContent: Bool {
        !store.items.isEmpty || !wallpaperPackages.isEmpty || isCleanerInstalled || isSupervisedInstalled || isFootnoteInstalled
    }

    private var hasSearchResults: Bool {
        !filteredItems.isEmpty || !filteredWallpaperPackages.isEmpty || (searchText.isEmpty && (isCleanerInstalled || isSupervisedInstalled || isFootnoteInstalled))
    }

    init(onOpenSettings: @escaping () -> Void = {}, onOpenLogs: @escaping () -> Void = {}) {
        self.onOpenSettings = onOpenSettings
        self.onOpenLogs = onOpenLogs
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppSearchField(text: $searchText, prompt: language.text("installed.search"), clearLabel: language.text("common.clear"))
                Divider()
                List {
                    if !hasLocalContent && (store.isBusy || isImportingWallpapers) {
                        loadingState.listRowSeparator(.hidden)
                    } else if !hasLocalContent {
                        emptyState.listRowSeparator(.hidden)
                    } else if !hasSearchResults && !store.isBusy {
                        searchEmptyState.listRowSeparator(.hidden)
                    } else {
                        if isCleanerInstalled || isSupervisedInstalled || isFootnoteInstalled {
                            Section("Tính năng 3105") {
                                if isCleanerInstalled {
                                    NavigationLink { CleanerView() } label: { localTweakRow(title: "Dọn dẹp", icon: "sparkles") }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) { withAnimation { isCleanerInstalled = false } } label: { Label("Xóa", systemImage: "trash") }
                                        }
                                }
                                if isSupervisedInstalled {
                                    NavigationLink { InstalledSupervisedTweakView() } label: { localTweakRow(title: "Chế độ giám sát", icon: "checkmark.shield.fill") }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) { withAnimation { isSupervisedInstalled = false } } label: { Label("Xóa", systemImage: "trash") }
                                        }
                                }
                                if isFootnoteInstalled {
                                    NavigationLink { InstalledFootnoteTweakView() } label: { localTweakRow(title: "Chữ màn hình khóa", icon: "text.bubble.fill") }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) { withAnimation { isFootnoteInstalled = false } } label: { Label("Xóa", systemImage: "trash") }
                                        }
                                }
                            }
                        }

                        if !filteredItems.isEmpty {
                            Section(language.text("patch.title")) {
                                ForEach(filteredItems) { item in itemRow(item) }
                                    .onDelete { offsets in offsets.map { filteredItems[$0] }.forEach(store.delete) }
                            }
                        }
                        if !filteredWallpaperPackages.isEmpty {
                            Section(language.text("tab.wallpapers")) {
                                ForEach(filteredWallpaperPackages) { package in
                                    NavigationLink { InstalledWallpaperPackageDetailView(package: package, onApplied: reloadWallpaperPackages) } label: { wallpaperRow(package) }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) { wallpaperPendingDeletion = package } label: { Label(language.text("common.delete"), systemImage: "trash") }
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle(language.text("tab.installed"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button { showCreate = true } label: { Label(language.text("patch.new"), systemImage: "doc.badge.plus") }
                        Button { showImporter = true } label: { Label(language.text("patch.import"), systemImage: "square.and.arrow.down") }
                        Button { showWallpaperImporter = true } label: { Label(language.text("wallpaper.import"), systemImage: "photo.badge.plus") }
                    } label: {
                        if store.isBusy || isImportingWallpapers { ProgressView() } else { Image(systemName: "plus") }
                    }
                    .disabled(store.isBusy || isImportingWallpapers)
                }
                AppUtilityToolbar(language: language, onOpenSettings: onOpenSettings, onOpenLogs: onOpenLogs)
            }
            .sheet(isPresented: $showImporter) {
                FileDocumentPicker(allowedContentTypes: PatchPackagePickerPolicy.allowedContentTypes, copiesSelectedDocument: PatchPackagePickerPolicy.copiesSelectedDocument, allowsMultipleSelection: false, onSelection: { result in
                    showImporter = false
                    if case .success(let urls) = result, let url = urls.first { store.importPackage(at: url) }
                }, onCancel: { showImporter = false }).ignoresSafeArea()
            }
            .sheet(isPresented: $showCreate) {
                PatchProjectEditorView(existingProject: nil, passwordIsProtected: false) { project, password in store.create(project: project, password: password) }
            }
            .sheet(item: $draftCoordinator.request) { request in
                PatchProjectEditorView(existingProject: nil, passwordIsProtected: false, initialDraft: request.draft) { project, password in
                    store.create(project: project, password: password)
                    draftCoordinator.clear()
                }
            }
            .sheet(isPresented: $showWallpaperImporter) {
                FileDocumentPicker(allowedContentTypes: WallpaperPackagePickerPolicy.allowedContentTypes, copiesSelectedDocument: true, allowsMultipleSelection: true, onSelection: { result in
                    showWallpaperImporter = false
                    if case .success(let urls) = result, !urls.isEmpty { importWallpaperPackages(urls) }
                }, onCancel: { showWallpaperImporter = false }).ignoresSafeArea()
            }
            .alert(item: $wallpaperImportFeedback) { feedback in Alert(title: Text(language.text(feedback.titleKey)), message: Text(feedback.message), dismissButton: .default(Text(language.text("common.ok")))) }
            .alert(item: $wallpaperPendingDeletion) { package in
                Alert(title: Text(language.text("wallpaper.delete_title")), message: Text(language.text("wallpaper.delete_message", package.displayName)), primaryButton: .destructive(Text(language.text("common.delete"))) { deleteWallpaperPackage(package) }, secondaryButton: .cancel(Text(language.text("common.cancel"))))
            }
            .onAppear { reloadWallpaperPackages(); consumeExternalImport() }
            .onChange(of: draftCoordinator.importRequest?.id) { _ in consumeExternalImport() }
        }
    }

    private func localTweakRow(title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            AppRowIcon(systemName: icon, frameSize: 34)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.body.weight(.semibold)).foregroundStyle(.primary)
                HStack(spacing: 4) {
                    Image(systemName: "shippingbox.fill").font(.system(size: 10))
                    Text("Tính năng 3105").font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Color.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.orange.opacity(0.12), in: Capsule())
            }
        }.padding(.vertical, 4)
    }

    private func consumeExternalImport() {
        guard let request = draftCoordinator.importRequest else { return }
        draftCoordinator.clearImport()
        store.importPackage(from: request.source)
    }
    private func reloadWallpaperPackages() { wallpaperPackages = WallpaperPackageStore.packages() }
    private func deleteWallpaperPackage(_ package: WallpaperStagedPackage) {
        do { try WallpaperPackageStore.delete(package); reloadWallpaperPackages() }
        catch { wallpaperImportFeedback = WallpaperImportFeedback(titleKey: "wallpaper.operation_failed", message: wallpaperErrorMessage(error)) }
    }
    private func importWallpaperPackages(_ urls: [URL]) {
        guard !isImportingWallpapers else { return }
        isImportingWallpapers = true
        DispatchQueue.global(qos: .userInitiated).async {
            var imported = 0; var failures: [String] = []
            for url in urls {
                do { _ = try WallpaperPackageStore.importPackage(from: url); imported += 1; log("wallpaper: staged \(url.lastPathComponent)") }
                catch { failures.append("\(url.lastPathComponent): \(wallpaperErrorMessage(error))"); log("wallpaper: import rejected \(url.lastPathComponent)") }
            }
            DispatchQueue.main.async {
                isImportingWallpapers = false; reloadWallpaperPackages()
                wallpaperImportFeedback = WallpaperImportFeedback(titleKey: failures.isEmpty ? "wallpaper.import_done_title" : "wallpaper.import_result_title", message: failures.isEmpty ? language.text("wallpaper.import_done_message", Int64(imported)) : failures.joined(separator: "\n"))
            }
        }
    }
    private func wallpaperErrorMessage(_ error: Error) -> String {
        if let wallpaperError = error as? WallpaperLabError { return language.text(wallpaperError.localizationKey) }
        return language.text("wallpaper.error.unknown")
    }
    private func wallpaperRow(_ package: WallpaperStagedPackage) -> some View {
        HStack(spacing: 12) {
            AppRowIcon(systemName: wallpaperSymbol)
            VStack(alignment: .leading, spacing: 3) {
                Text(package.displayName).font(.body.weight(.semibold)).foregroundStyle(.primary).lineLimit(1)
                InstalledContentKindBadge(kind: .wallpaper, language: language)
                Text(language.text("wallpaper.package_summary", Int64(package.payload.descriptors.count), ByteCountFormatter.string(fromByteCount: package.payload.totalBytes, countStyle: .file))).font(.caption).foregroundStyle(.secondary)
            }
        }.padding(.vertical, 4)
    }
    private var wallpaperSymbol: String { if #available(iOS 18.0, *) { return "photo.on.rectangle.angled.fill" }; return "photo.fill.on.rectangle.fill" }
    @ViewBuilder private func itemRow(_ item: PatchLibraryItem) -> some View {
        if item.isLocked {
            Button { store.requestUnlock(for: item) } label: { PatchProjectRow(item: item, language: language) }.buttonStyle(.plain)
        } else {
            NavigationLink { PatchProjectDetailView(store: store, projectID: item.id) } label: { PatchProjectRow(item: item, language: language) }
        }
    }
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "shippingbox").font(.system(size: AppTheme.emptyIconSize, weight: .light)).foregroundStyle(AppTheme.accent)
            Text(language.text("installed.empty_title")).font(.headline)
            Text(language.text("installed.empty_message")).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button(language.text("patch.new")) { showCreate = true }.buttonStyle(.bordered).controlSize(.large)
        }.frame(maxWidth: .infinity).padding(.vertical, 64)
    }
    private var loadingState: some View {
        VStack(spacing: 12) { ProgressView(); Text(language.text("installed.loading")).font(.subheadline).foregroundStyle(.secondary) }.frame(maxWidth: .infinity).padding(.vertical, 64)
    }
    private var searchEmptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass").font(.system(size: AppTheme.emptyIconSize, weight: .light)).foregroundStyle(.secondary)
            Text(language.text("patch.search_empty")).font(.headline)
            Text(language.text("patch.search_empty_message")).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }.frame(maxWidth: .infinity).padding(.vertical, 64)
    }
}

struct InstalledSupervisedTweakView: View {
    @AppStorage("isSupervisedEnabled") var isEnabled = false
    var body: some View {
        List {
            Section {
                HStack(alignment: .top, spacing: 12) {
                    AppRowIcon(systemName: "checkmark.shield.fill", frameSize: 44)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Chế độ giám sát").font(.headline)
                        HStack(spacing: 6) {
                            if isEnabled { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green); Text("Đã bật").font(.subheadline).foregroundStyle(.green) }
                            else { Image(systemName: "circle.dashed").foregroundStyle(.secondary); Text("Chưa bật").font(.subheadline).foregroundStyle(.secondary) }
                        }
                    }
                }
            }
            Section { Toggle("Chế độ giám sát", isOn: $isEnabled) } footer: { Text("Thay đổi trực tiếp giá trị IsSupervised.") }
        }.navigationTitle("Chế độ giám sát").navigationBarTitleDisplayMode(.inline)
    }
}

struct InstalledFootnoteTweakView: View {
    @AppStorage("footnoteText") var savedText = ""
    @State private var inputText = ""
    var body: some View {
        List {
            Section {
                HStack(alignment: .top, spacing: 12) {
                    AppRowIcon(systemName: "text.bubble.fill", frameSize: 44)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Chữ màn hình khóa").font(.headline)
                        HStack(spacing: 6) {
                            if savedText.isEmpty { Image(systemName: "circle.dashed").foregroundStyle(.secondary); Text("Chưa có nội dung").font(.subheadline).foregroundStyle(.secondary) }
                            else { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green); Text("Đã thiết lập").font(.subheadline).foregroundStyle(.green) }
                        }
                    }
                }
            }
            Section {
                TextField("Nhập chữ hiển thị trên màn hình khóa", text: $inputText, axis: .vertical).lineLimit(3)
                Button { savedText = inputText } label: {
                    Text("Lưu Footnote").font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 12).background(AppTheme.accent).clipShape(Capsule())
                }.buttonStyle(.plain)
            } footer: { Text("Sau khi áp dụng, hãy khởi động lại thiết bị.") }
        }.navigationTitle("Chữ màn hình khóa").navigationBarTitleDisplayMode(.inline).onAppear { inputText = savedText }
    }
}

private struct WallpaperImportFeedback: Identifiable { let id = UUID(); let titleKey: String; let message: String }
private struct PatchProjectRow: View {
    let item: PatchLibraryItem
    let language: AppLanguage
    var body: some View {
        HStack(spacing: 12) {
            AppRowIcon(systemName: item.isLocked ? "lock.doc.fill" : "shippingbox.fill")
            VStack(alignment: .leading, spacing: 3) {
                Text(item.project?.name ?? language.text("patch.locked_project")).font(.body.weight(.semibold)).foregroundStyle(.primary).lineLimit(1)
                InstalledContentKindBadge(kind: .patch, language: language)
                if let author = item.project?.author, !author.isEmpty { Text(language.text("patch.by_author", author)).font(.caption).foregroundStyle(.secondary) }
            }
            Spacer()
        }.padding(.vertical, 4)
    }
}
private enum InstalledContentKind {
    case patch, wallpaper
    var localizationKey: String { switch self { case .patch: return "installed.kind.patch"; case .wallpaper: return "installed.kind.wallpaper" } }
    var systemImage: String { switch self { case .patch: return "shippingbox.fill"; case .wallpaper: return "photo.fill" } }
}
private struct InstalledContentKindBadge: View {
    let kind: InstalledContentKind
    let language: AppLanguage
    var body: some View {
        HStack(spacing: 4) { Image(systemName: kind.systemImage); Text(language.text(kind.localizationKey)) }
            .font(.caption2.weight(.semibold)).foregroundStyle(AppTheme.accent).padding(.horizontal, 8).frame(height: 24).background(AppTheme.accent.opacity(0.12), in: Capsule()).fixedSize()
    }
}
