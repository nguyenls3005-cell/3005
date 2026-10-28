import SwiftUI
import UIKit

struct LegacyRepositoryExploreView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var repositoryStore: PackageRepositoryStore
    @AppStorage(FeatureVisibility.cleanerStorageKey) private var cleanerEnabled = true
    @State private var activeTool: BuiltInTool?

    let wallpapersSupported: Bool
    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void

    private var featuredPackages: [RepositoryPackageRecord] {
        repositoryStore.packages.filter(\.package.isFeatured)
    }

    private var regularPackages: [RepositoryPackageRecord] {
        let featuredIDs = Set(featuredPackages.map(\.id))
        return repositoryStore.packages.filter { !featuredIDs.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            List {
                builtInToolsSection
                if repositoryStore.packages.isEmpty {
                    marketplaceEmptySection
                } else {
                    if !featuredPackages.isEmpty {
                        packageSection(titleKey: "repository.featured", packages: featuredPackages)
                    }
                    if !regularPackages.isEmpty {
                        packageSection(titleKey: "repository.all_packages", packages: regularPackages)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(language.text("repository.explore"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                AppUtilityToolbar(language: language, onOpenSettings: onOpenSettings, onOpenLogs: onOpenLogs)
            }
            .refreshable { await repositoryStore.refreshAllAndWait() }
            .onAppear { repositoryStore.refreshAllIfNeeded() }
            .sheet(item: $activeTool) { tool in
                switch tool {
                case .cleaner: CleanerView()
                case .wallpaper: WallpaperLabView()
                }
            }
            .navigationDestination(for: RepositoryPackageRecord.self) { record in
                RepositoryPackageDetailView(record: record)
            }
        }
    }

    private var builtInToolsSection: some View {
        Section {
            if cleanerEnabled {
                builtInToolButton(.cleaner, titleKey: "tab.cleaner", subtitleKey: "repository.cleaner_subtitle", systemImage: "sparkles")
            }
            if wallpapersSupported {
                builtInToolButton(.wallpaper, titleKey: "tab.wallpapers", subtitleKey: "repository.wallpaper_subtitle", systemImage: wallpaperSymbol)
            }
        } header: {
            Text(language.text("repository.built_in_tools"))
        } footer: {
            Text(language.text("repository.tools_footer"))
        }
    }

    private func builtInToolButton(_ tool: BuiltInTool, titleKey: String, subtitleKey: String, systemImage: String) -> some View {
        Button { activeTool = tool } label: {
            HStack(spacing: 12) {
                AppRowIcon(systemName: systemImage)
                VStack(alignment: .leading, spacing: 3) {
                    Text(language.text(titleKey)).font(.body.weight(.semibold)).foregroundStyle(.primary)
                    Text(language.text(subtitleKey)).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
            }.contentShape(Rectangle())
        }.buttonStyle(.plain)
    }

    private var marketplaceEmptySection: some View {
        Section {
            VStack(spacing: 12) {
                Image(systemName: "square.stack.3d.up").font(.system(size: AppTheme.emptyIconSize, weight: .light)).foregroundStyle(AppTheme.accent)
                Text(language.text(repositoryStore.sources.isEmpty ? "repository.no_sources_title" : "repository.no_packages_title")).font(.headline)
            }.frame(maxWidth: .infinity).padding(.vertical, 32)
        }
    }

    private func packageSection(titleKey: String, packages: [RepositoryPackageRecord]) -> some View {
        Section(language.text(titleKey)) {
            ForEach(packages) { record in
                NavigationLink(value: record) { RepositoryPackageRow(record: record) }
            }
        }
    }

    private var wallpaperSymbol: String { if #available(iOS 18.0, *) { return "photo.on.rectangle.angled.fill" }; return "photo.fill.on.rectangle.fill" }
}

struct RepositoryPackageDetailView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var repositoryStore: PackageRepositoryStore
    @EnvironmentObject private var patchStore: PatchProjectStore
    @AppStorage("dialer_data_fetched") private var dialerFetched = false
    @State private var showInstallAlert = false
    @State private var showDialerError = false

    let record: RepositoryPackageRecord

    private var compatibility: PackageCompatibility {
        PackageCompatibilityEvaluator.evaluate(
            record.package.supportedOS, major: AppInfo.versionTuple.major, minor: AppInfo.versionTuple.minor, patch: AppInfo.versionTuple.patch, build: AppInfo.osBuild
        )
    }

    private var isInstalled: Bool {
        if record.package.kind == .wallpaper { return repositoryStore.isInstalled(record) }
        guard let packageID = repositoryStore.resolvedPackageID(for: record) else { return false }
        return patchStore.items.contains { $0.id == packageID }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 14) {
                        RepositoryPackageIcon(package: record.package, size: 64)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.package.name).font(.title2.bold())
                            Text(record.package.summary).font(.subheadline).foregroundStyle(.secondary).lineLimit(3)
                            Text("@\(record.package.author) · \(record.sourceName)").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    
                    Button {
                        if record.package.kind.rawValue == "dialer" && !dialerFetched {
                            showDialerError = true
                        } else {
                            repositoryStore.install(record, using: patchStore)
                            showInstallAlert = true
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if repositoryStore.isDownloading(record) {
                                ProgressView().tint(.white)
                            } else {
                                Text(isInstalled ? "Cập nhật" : "Cài đặt").font(.headline)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .background(compatibility == .compatible ? AppTheme.accent : Color.gray)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(compatibility != .compatible || repositoryStore.isDownloading(record) || patchStore.isBusy)
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("Mô tả").font(.headline)) {
                Text(record.package.details ?? record.package.summary).font(.subheadline)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(record.package.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Đã nhập xong", isPresented: $showInstallAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Gói đã được xác minh và thêm vào Đã cài. Hãy mở gói tại đó để xem và áp dụng.")
        }
        .alert("Lỗi Dialer", isPresented: $showDialerError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Vui lòng vào Cài đặt và chọn 'Lấy dữ liệu Dialer' trước khi cài đặt giao diện bàn phím.")
        }
    }
}

struct RepositoryPackageRow: View {
    @Environment(\.appLanguage) private var language
    let record: RepositoryPackageRecord
    var body: some View {
        HStack(spacing: 12) {
            RepositoryPackageIcon(package: record.package, size: 40)
            VStack(alignment: .leading, spacing: 3) {
                Text(record.package.name).font(.body.weight(.semibold)).foregroundStyle(.primary).lineLimit(2)
                Text(record.package.summary).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                Text(record.package.author).font(.caption2).foregroundStyle(.tertiary)
            }
        }.padding(.vertical, 4)
    }
}

struct RepositoryPackageIcon: View {
    @StateObject private var imageLoader = RepositoryImageLoader()
    let package: RepositoryPackage
    let size: CGFloat
    var body: some View {
        Group {
            if let image = imageLoader.image { Image(uiImage: image).resizable().scaledToFill() }
            else { placeholder }
        }
        .frame(width: size, height: size).background(Color(uiColor: .secondarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .task(id: package.iconURL) {
            guard let iconURL = package.iconURL else { return }
            await imageLoader.load(url: iconURL, maximumPixelSize: 240)
        }
    }
    private var placeholder: some View {
        Image(systemName: package.kind == .wallpaper ? "photo.fill" : "shippingbox.fill")
            .font(.system(size: size * 0.42, weight: .medium)).foregroundStyle(AppTheme.accent)
    }
}

struct RepositoryScreenshotPreview: View {
    @StateObject private var imageLoader = RepositoryImageLoader()
    let url: URL
    let accessibilityLabel: String
    var body: some View {
        ZStack {
            Color(uiColor: .secondarySystemFill)
            if let image = imageLoader.image {
                Image(uiImage: image).resizable().scaledToFit()
            } else if imageLoader.didFail {
                Image(systemName: "photo").font(.title2).foregroundStyle(.tertiary)
            } else {
                ProgressView()
            }
        }
        .frame(width: 200, height: 360)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .task(id: url) { await imageLoader.load(url: url, maximumPixelSize: 1_200) }
    }
}

struct AppUtilityToolbar: ToolbarContent {
    let language: AppLanguage
    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button(action: onOpenSettings) { Label(language.text("settings.title"), systemImage: "gearshape") }
                Button(action: onOpenLogs) { Label(language.text("accessibility.open_logs"), systemImage: "apple.terminal") }
            } label: { Image(systemName: "gearshape") }
        }
    }
}

private enum BuiltInTool: String, Identifiable { case cleaner, wallpaper; var id: String { rawValue } }
private enum StorePresentationAlert: Identifiable {
    case patch(PatchStoreAlert), repository(RepositoryStoreAlert)
    var id: String {
        switch self {
        case .patch(let alert): return "patch:" + alert.id.uuidString
        case .repository(let alert): return "repository:" + alert.id.uuidString
        }
    }
}
private struct RepositoryStorePresentationModifier: ViewModifier {
    @Environment(\.appLanguage) private var language
    @ObservedObject var store: PackageRepositoryStore
    @ObservedObject var patchStore: PatchProjectStore
    func body(content: Content) -> some View {
        content.alert(item: activeAlert) { activeAlert in
            switch activeAlert {
            case .patch(let alert): Alert(title: Text(language.text(alert.titleKey)), message: Text(alert.message(language: language)), dismissButton: .default(Text(language.text("common.ok"))))
            case .repository(let alert): Alert(title: Text(language.text(alert.titleKey)), message: Text(language.text(alert.messageKey)), dismissButton: .default(Text(language.text("common.ok"))))
            }
        }
    }
    private var activeAlert: Binding<StorePresentationAlert?> {
        Binding(
            get: {
                if let repositoryAlert = store.alert { return .repository(repositoryAlert) }
                if let patchAlert = patchStore.alert { return .patch(patchAlert) }
                return nil
            },
            set: { newValue in
                guard newValue == nil else { return }
                if store.alert != nil { store.alert = nil } else { patchStore.alert = nil }
            }
        )
    }
}
extension View {
    func repositoryStorePresentation(_ store: PackageRepositoryStore, patchStore: PatchProjectStore) -> some View {
        modifier(RepositoryStorePresentationModifier(store: store, patchStore: patchStore))
    }
}
