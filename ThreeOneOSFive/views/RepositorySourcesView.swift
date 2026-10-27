import SwiftUI
import UIKit

struct RepositorySourcesView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var store: PackageRepositoryStore
    @State private var showAddSource = false
    @State private var showSimulatedSourceDetail = false
    @State private var simulatedSourceDetailGate = OneShotPresentationGate()

    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void

    var body: some View {
        NavigationStack {
            List {
                if store.sources.isEmpty {
                    Section {
                        emptyState
                    }
                } else {
                    Section {
                        NavigationLink { Local3105RepoView() } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8).fill(Color(red: 0.98, green: 0.92, blue: 0.92)).frame(width: 34, height: 34)
                                    Text("T").font(.system(size: 18, weight: .bold)).foregroundStyle(Color.orange)
                                }
                                Text("Tính năng 3105").font(.body.weight(.semibold)).foregroundStyle(.primary)
                            }.padding(.vertical, 4)
                        }
                        ForEach(store.sources) { source in
                            NavigationLink { RepositorySourceDetailView(sourceID: source.id) } label: { RepositorySourceRow(source: source) }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) { store.removeSource(source) } label: { Label(language.text("repository.remove_source"), systemImage: "trash") }
                            }
                            .contextMenu { sourceActions(source) }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(language.text("repository.sources"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button { showAddSource = true } label: { Image(systemName: "plus") } }
                AppUtilityToolbar(language: language, onOpenSettings: onOpenSettings, onOpenLogs: onOpenLogs)
            }
            .refreshable { await store.refreshAllAndWait() }
            .onAppear { store.refreshAllIfNeeded() }
            .sheet(isPresented: $showAddSource) { AddRepositorySourceView() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "shippingbox.and.arrow.backward").font(.system(size: AppTheme.emptyIconSize, weight: .light)).foregroundStyle(AppTheme.accent)
            Text(language.text("repository.no_sources_title")).font(.headline)
            Button(language.text("repository.add_source")) { showAddSource = true }.buttonStyle(.bordered)
        }.frame(maxWidth: .infinity).padding(.vertical, 48)
    }

    @ViewBuilder
    private func sourceActions(_ source: RepositorySource) -> some View {
        Button { store.refresh(source) } label: { Label(language.text("repository.refresh_source"), systemImage: "arrow.clockwise") }
        Button { UIPasteboard.general.string = source.manifestURL.absoluteString } label: { Label(language.text("repository.copy_link"), systemImage: "doc.on.doc") }
        Button(role: .destructive) { store.removeSource(source) } label: { Label(language.text("repository.remove_source"), systemImage: "trash") }
    }
}

// --- GIAO DIỆN REPO LOCAL ---
struct Local3105RepoView: View {
    var body: some View {
        List {
            Section {
                HStack(alignment: .top, spacing: 14) {
                    ZStack { RoundedRectangle(cornerRadius: 8).fill(Color(red: 0.98, green: 0.92, blue: 0.92)).frame(width: 42, height: 42); Text("T").font(.system(size: 22, weight: .bold)).foregroundStyle(Color.orange) }
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Tính năng 3105").font(.body.weight(.semibold))
                        Text("Các tính năng hệ thống được tích hợp sẵn trong 3105, không tải từ mạng.").font(.caption).foregroundStyle(.secondary).lineLimit(2)
                        Text("3 gói").font(.caption).foregroundStyle(.secondary)
                    }
                }.padding(.vertical, 3)
            }

            Section(header: Text("Tag").font(.footnote.weight(.semibold)).foregroundStyle(.secondary).textCase(nil)) {
                NavigationLink { LocalTweakListView(title: "Tất cả gói") } label: { LocalTagRow(name: "Tất cả gói", count: 3) }
                NavigationLink { LocalTweakListView(title: "Dọn dẹp") } label: { LocalTagRow(name: "Dọn dẹp", count: 1) }
                NavigationLink { LocalTweakListView(title: "iOS 27") } label: { LocalTagRow(name: "iOS 27", count: 2) }
                NavigationLink { LocalTweakListView(title: "Tính năng 3105") } label: { LocalTagRow(name: "Tính năng 3105", count: 3) }
            }
        }.listStyle(.insetGrouped).navigationTitle("Tính năng 3105").navigationBarTitleDisplayMode(.inline)
    }
}

struct LocalTagRow: View {
    let name: String; let count: Int
    var body: some View {
        HStack(spacing: 12) {
            AppRowIcon(systemName: "shippingbox.fill", frameSize: 34)
            VStack(alignment: .leading, spacing: 3) {
                Text(name).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                Text("\(count) gói").font(.caption).foregroundStyle(.secondary)
            }
        }.padding(.vertical, 2)
    }
}

struct LocalTweakListView: View {
    let title: String
    var body: some View {
        List {
            if title == "Tất cả gói" || title == "Dọn dẹp" || title == "Tính năng 3105" {
                NavigationLink { LocalCleanerTweakView() } label: { TweakRow(title: "Dọn dẹp", desc: "Kiểm tra và xoá bộ nhớ đệm, tệp tạm của ứng dụng.", icon: "sparkles") }
            }
            if title == "Tất cả gói" || title == "iOS 27" || title == "Tính năng 3105" {
                NavigationLink { LocalSupervisedTweakView() } label: { TweakRow(title: "Chế độ giám sát", desc: "Bật hoặc tắt IsSupervised trên thiết bị iOS 27.", icon: "checkmark.shield.fill") }
                NavigationLink { LocalFootnoteTweakView() } label: { TweakRow(title: "Chữ màn hình khóa", desc: "Thêm hoặc chỉnh sửa Footnote trên iOS 27.", icon: "text.bubble.fill") }
            }
        }.listStyle(.insetGrouped).navigationTitle(title).navigationBarTitleDisplayMode(.inline)
    }
}

struct TweakRow: View {
    let title: String; let desc: String; let icon: String
    var body: some View {
        HStack(spacing: 12) {
            AppRowIcon(systemName: icon, frameSize: 34)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                Text(desc).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                Text("3105 · Phiên bản 1.0.0").font(.caption2).foregroundStyle(.tertiary)
            }
        }.padding(.vertical, 4)
    }
}

// --- CHI TIẾT CÁC TWEAK ---
struct LocalCleanerTweakView: View {
    @AppStorage("isCleanerInstalled") var isInstalled = false
    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    AppRowIcon(systemName: "sparkles", frameSize: 44)
                    VStack(alignment: .leading) {
                        Text("Dọn dẹp").font(.headline)
                        Text("Kiểm tra và xoá bộ nhớ đệm, tệp tạm của ứng dụng.").font(.caption).foregroundStyle(.secondary)
                        Text("3105 · Phiên bản 1.0.0").font(.caption2).foregroundStyle(.tertiary)
                    }
                }
                Button { withAnimation { isInstalled = true } } label: {
                    Text(isInstalled ? "Đã cài" : "Cài đặt").frame(maxWidth: .infinity).padding(.vertical, 8)
                }.buttonStyle(.borderedProminent).tint(isInstalled ? .gray : AppTheme.accent).disabled(isInstalled)
            }
            if isInstalled {
                Section { NavigationLink { CleanerView() } label: { Label("Mở công cụ dọn dẹp", systemImage: "arrow.up.forward.app") } }
            }
            Section("Thông tin gói") { LabeledContent("Loại", value: "Tính năng 3105"); LabeledContent("Tác giả", value: "3105") }
        }.navigationTitle("Dọn dẹp").navigationBarTitleDisplayMode(.inline)
    }
}

struct LocalSupervisedTweakView: View {
    @AppStorage("isSupervisedInstalled") var isInstalled = false
    @AppStorage("isSupervisedEnabled") var isEnabled = false
    var body: some View {
        List {
            Section {
                HStack(alignment: .top, spacing: 12) {
                    AppRowIcon(systemName: "checkmark.shield.fill", frameSize: 44)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Chế độ giám sát").font(.headline)
                        Text("Bật hoặc tắt IsSupervised trên thiết bị iOS 27.").font(.caption).foregroundStyle(.secondary)
                        HStack { Text("Trạng thái"); Text(isEnabled ? "Đã bật" : "Chưa bật").fontWeight(.semibold).foregroundStyle(isEnabled ? .green : .secondary) }.font(.caption).padding(.top, 2)
                    }
                }
                Button { withAnimation { isInstalled = true } } label: {
                    Text(isInstalled ? "Đã cài" : "Cài đặt").frame(maxWidth: .infinity).padding(.vertical, 8)
                }.buttonStyle(.borderedProminent).tint(isInstalled ? .gray : AppTheme.accent).disabled(isInstalled)
            }
            if isInstalled {
                Section { Toggle("Chế độ giám sát", isOn: $isEnabled) } footer: { Text("Thay đổi trực tiếp giá trị IsSupervised. Sau khi áp dụng, hãy khởi động lại thiết bị.") }
            }
            Section("Thông tin gói") {
                LabeledContent("Loại", value: "Tính năng 3105")
                LabeledContent("iOS hỗ trợ", value: "iOS 27")
                LabeledContent("File đích", value: "CloudConfigurationDetails.plist")
            }
        }.navigationTitle("Chế độ giám sát").navigationBarTitleDisplayMode(.inline)
    }
}

struct LocalFootnoteTweakView: View {
    @AppStorage("isFootnoteInstalled") var isInstalled = false
    @AppStorage("footnoteText") var text = ""
    @State private var inputText = ""
    var body: some View {
        List {
            Section {
                HStack(alignment: .top, spacing: 12) {
                    AppRowIcon(systemName: "text.bubble.fill", frameSize: 44)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Chữ màn hình khóa").font(.headline)
                        Text("Thêm hoặc chỉnh sửa Footnote trên màn hình khóa iOS 27.").font(.caption).foregroundStyle(.secondary)
                        HStack { Text("Trạng thái"); Text(text.isEmpty ? "Chưa có nội dung" : text).fontWeight(.semibold).foregroundStyle(text.isEmpty ? .secondary : .primary) }.font(.caption).padding(.top, 2)
                    }
                }
                Button { withAnimation { isInstalled = true } } label: {
                    Text(isInstalled ? "Đã cài" : "Cài đặt").frame(maxWidth: .infinity).padding(.vertical, 8)
                }.buttonStyle(.borderedProminent).tint(isInstalled ? .gray : AppTheme.accent).disabled(isInstalled)
            }
            if isInstalled {
                Section(header: Text("Nội dung Footnote")) {
                    TextField("Nhập chữ hiển thị trên màn hình khóa", text: $inputText, axis: .vertical).lineLimit(3)
                    Button { text = inputText } label: { Label("Lưu Footnote", systemImage: "square.and.arrow.down").frame(maxWidth: .infinity) }.buttonStyle(.bordered)
                }
            }
            Section("Thông tin gói") {
                LabeledContent("Loại", value: "Tính năng 3105")
                LabeledContent("iOS hỗ trợ", value: "iOS 27")
                LabeledContent("File đích", value: "Footnote.plist")
            }
        }
        .navigationTitle("Chữ màn hình khóa").navigationBarTitleDisplayMode(.inline)
        .onAppear { inputText = text }
    }
}

// --- GIỮ NGUYÊN CÁC HÀM CŨ CỦA BẠN ---
private struct RepositorySourceRow: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var store: PackageRepositoryStore
    let source: RepositorySource
    var body: some View {
        HStack(spacing: 12) {
            RepositorySourceIcon(repository: store.repository(for: source.id), fallbackText: store.repository(for: source.id)?.name ?? source.manifestURL.host ?? "3105")
            Text(store.repository(for: source.id)?.name ?? source.manifestURL.host ?? language.text("repository.unknown_source")).font(.body.weight(.semibold)).foregroundStyle(.primary).lineLimit(2)
        }.padding(.vertical, 4)
    }
}

private struct RepositorySourceStatus: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var store: PackageRepositoryStore
    let source: RepositorySource
    @ViewBuilder var body: some View {
        switch store.state(for: source.id) {
        case .idle: Text(language.text("repository.not_refreshed")).foregroundStyle(.secondary)
        case .loading: Label(language.text("repository.refreshing"), systemImage: "arrow.triangle.2.circlepath").foregroundStyle(.secondary)
        case .loaded: Text(language.text("repository.package_count", Int64(store.repository(for: source.id)?.packages.count ?? 0))).foregroundStyle(.secondary)
        case .failed(let error): Label(language.text(error.localizationKey), systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red).lineLimit(2)
        }
    }
}

private struct RepositorySourceDetailView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var store: PackageRepositoryStore
    let sourceID: UUID
    private var source: RepositorySource? { store.sources.first { $0.id == sourceID } }
    private var repository: PackageRepository? { store.repository(for: sourceID) }
    private var records: [RepositoryPackageRecord] {
        guard let source, let repository else { return [] }
        return repository.packages.map { RepositoryPackageRecord(sourceID: source.id, sourceName: repository.name, sourceURL: repository.sourceURL, package: $0) }
    }
    private var tagGroups: [RepositoryTagGroup] { PackageRepositoryTagIndex.groups(for: repository?.packages ?? []) }
    var body: some View {
        List {
            Section {
                HStack(alignment: .top, spacing: 14) {
                    RepositorySourceIcon(repository: repository, fallbackText: repository?.name ?? source?.manifestURL.host ?? "3105")
                    VStack(alignment: .leading, spacing: 5) {
                        Text(repository?.name ?? source?.manifestURL.host ?? language.text("repository.unknown_source")).font(.body.weight(.semibold))
                        if let summary = repository?.summary { Text(summary).font(.caption).foregroundStyle(.secondary).lineLimit(2) }
                        if let source { RepositorySourceStatus(source: source).font(.caption) }
                    }
                }.padding(.vertical, 3)
            }
            if let source, store.state(for: source.id) == .loading {
                Section { HStack(spacing: 10) { ProgressView(); Text(language.text("repository.refreshing")) } }
            } else if records.isEmpty {
                Section { Text(language.text("repository.source_empty")).foregroundStyle(.secondary) }
            } else {
                Section {
                    NavigationLink { RepositoryTagPackagesView(title: language.text("repository.all_source_packages"), records: records) } label: { RepositoryTagRow(name: language.text("repository.all_source_packages"), count: records.count, package: records.first?.package) }
                    ForEach(tagGroups) { group in
                        NavigationLink { RepositoryTagPackagesView(title: group.name, records: records.filter { record in group.packages.contains { $0.identifier == record.package.identifier } }) } label: { RepositoryTagRow(name: group.name, count: group.packages.count, package: group.packages.first) }
                    }
                } header: {
                    Text(language.text("repository.source_tags")).font(.footnote.weight(.semibold)).foregroundStyle(.secondary).textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped).navigationTitle(repository?.name ?? source?.manifestURL.host ?? language.text("repository.unknown_source")).navigationBarTitleDisplayMode(.inline)
    }
}

private struct RepositoryTagRow: View {
    @Environment(\.appLanguage) private var language
    let name: String
    let count: Int
    let package: RepositoryPackage?
    var body: some View {
        HStack(spacing: 12) {
            if let package { RepositoryPackageIcon(package: package, size: 34) } else { AppRowIcon(systemName: "tag.fill", frameSize: 34) }
            VStack(alignment: .leading, spacing: 3) {
                Text(name).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                Text(language.text("repository.package_count", Int64(count))).font(.caption).foregroundStyle(.secondary)
            }
        }.padding(.vertical, 2)
    }
}

private struct RepositoryTagPackagesView: View {
    let title: String
    let records: [RepositoryPackageRecord]
    var body: some View {
        List(records) { record in
            NavigationLink { RepositoryPackageDetailView(record: record) } label: { RepositoryPackageRow(record: record).frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle()) }
        }.listStyle(.insetGrouped).navigationTitle(title).navigationBarTitleDisplayMode(.inline)
    }
}