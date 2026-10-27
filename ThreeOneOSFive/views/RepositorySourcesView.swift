import SwiftUI
import UIKit

struct RepositorySourcesView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var store: PackageRepositoryStore
    @State private var showAddSource = false
    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void

    var body: some View {
        NavigationStack {
            List {
                if store.sources.isEmpty {
                    Section { emptyState }
                } else {
                    Section {
                        NavigationLink { Local3105RepoView() } label: {
                            HStack(spacing: 12) {
                                Image("anthumuc3105")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 34, height: 34)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                Text("Tính năng 3105").font(.body.weight(.semibold)).foregroundStyle(.primary)
                            }.padding(.vertical, 4)
                        }
                        ForEach(store.sources) { source in
                            NavigationLink { RepositorySourceDetailView(sourceID: source.id) } label: { RepositorySourceRow(source: source) }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) { store.removeSource(source) } label: { Label(language.text("repository.remove_source"), systemImage: "trash") }
                            }
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
}

struct Local3105RepoView: View {
    var body: some View {
        List {
            Section {
                HStack(alignment: .top, spacing: 14) {
                    Image("anthumuc3105")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 42, height: 42)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
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
                NavigationLink { LocalFootnoteTweakView() } label: { TweakRow(title: "Chữ màn hình khóa", desc: "Thêm hoặc chỉnh sửa Footnote trên màn hình khóa iOS 27.", icon: "text.bubble.fill") }
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
                Text("3105 · Phiên bản 1.0.0").font(.caption2).foregroundStyle(.secondary)
            }
        }.padding(.vertical, 4)
    }
}

struct LocalCleanerTweakView: View {
    @AppStorage("isCleanerInstalled") var isInstalled = false
    var body: some View {
        List {
            Section {
                HStack(alignment: .center, spacing: 16) {
                    AppRowIcon(systemName: "sparkles", frameSize: 60)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Dọn dẹp").font(.title3.bold())
                        Text("Kiểm tra và xoá bộ nhớ đệm, tệp tạm của ứng dụng.").font(.subheadline).foregroundStyle(.secondary)
                        Text("3105 · Phiên bản 1.0.0").font(.caption).foregroundStyle(.secondary)
                    }
                }.padding(.vertical, 8)
                
                Button { withAnimation { isInstalled = true } } label: {
                    Text(isInstalled ? "Đã cài" : "Cài đặt").font(.headline).foregroundStyle(isInstalled ? Color.secondary : Color.white).frame(maxWidth: .infinity).padding(.vertical, 14).background(isInstalled ? Color.gray.opacity(0.2) : AppTheme.accent).clipShape(Capsule())
                }.buttonStyle(.plain).disabled(isInstalled)
            }
            
            Section(header: Text("Thông tin gói").font(.headline)) {
                HStack { Text("Phiên bản"); Spacer(); Text("1.0.0").foregroundStyle(.secondary) }
                HStack { Text("Nguồn"); Spacer(); Text("Tính năng 3105").foregroundStyle(.secondary) }
                HStack { Text("Tác giả"); Spacer(); Text("3105").foregroundStyle(.secondary) }
                HStack { Text("Danh mục"); Spacer(); Text("Tính năng hệ thống").foregroundStyle(.secondary) }
                HStack { Text("iOS hỗ trợ"); Spacer(); Text("iOS 27").foregroundStyle(.secondary) }
            }
        }.navigationTitle("Dọn dẹp").navigationBarTitleDisplayMode(.inline)
    }
}

struct LocalSupervisedTweakView: View {
    @AppStorage("isSupervisedInstalled") var isInstalled = false
    var body: some View {
        List {
            Section {
                HStack(alignment: .center, spacing: 16) {
                    AppRowIcon(systemName: "checkmark.shield.fill", frameSize: 60)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Chế độ giám sát").font(.title3.bold())
                        Text("Bật hoặc tắt IsSupervised trên thiết bị iOS 27.").font(.subheadline).foregroundStyle(.secondary)
                        Text("3105 · Tính năng 3105").font(.caption).foregroundStyle(.secondary)
                    }
                }.padding(.vertical, 8)
                
                Button { withAnimation { isInstalled = true } } label: {
                    Text(isInstalled ? "Đã cài" : "Cài đặt").font(.headline).foregroundStyle(isInstalled ? Color.secondary : Color.white).frame(maxWidth: .infinity).padding(.vertical, 14).background(isInstalled ? Color.gray.opacity(0.2) : AppTheme.accent).clipShape(Capsule())
                }.buttonStyle(.plain).disabled(isInstalled)
            }
            
            Section(header: Text("Mô tả").font(.headline)) {
                Text("Giữ nguyên dữ liệu cấu hình hiện có và thay đổi giá trị Boolean IsSupervised.").font(.subheadline)
            }
            
            Section(header: Text("Thông tin gói").font(.headline)) {
                HStack { Text("Phiên bản"); Spacer(); Text("1.0.0").foregroundStyle(.secondary) }
                HStack { Text("Nguồn"); Spacer(); Text("Tính năng 3105").foregroundStyle(.secondary) }
                HStack { Text("Tác giả"); Spacer(); Text("3105").foregroundStyle(.secondary) }
                HStack { Text("Danh mục"); Spacer(); Text("Tính năng hệ thống").foregroundStyle(.secondary) }
                HStack { Text("iOS hỗ trợ"); Spacer(); Text("iOS 27").foregroundStyle(.secondary) }
            }
        }.navigationTitle("Chế độ giám sát").navigationBarTitleDisplayMode(.inline)
    }
}

struct LocalFootnoteTweakView: View {
    @AppStorage("isFootnoteInstalled") var isInstalled = false
    var body: some View {
        List {
            Section {
                HStack(alignment: .center, spacing: 16) {
                    AppRowIcon(systemName: "text.bubble.fill", frameSize: 60)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Chữ màn hình khóa").font(.title3.bold())
                        Text("Thêm hoặc chỉnh sửa Footnote trên màn hình khóa iOS 27.").font(.subheadline).foregroundStyle(.secondary)
                        Text("3105 · Tính năng 3105").font(.caption).foregroundStyle(.secondary)
                    }
                }.padding(.vertical, 8)
                
                Button { withAnimation { isInstalled = true } } label: {
                    Text(isInstalled ? "Đã cài" : "Cài đặt").font(.headline).foregroundStyle(isInstalled ? Color.secondary : Color.white).frame(maxWidth: .infinity).padding(.vertical, 14).background(isInstalled ? Color.gray.opacity(0.2) : AppTheme.accent).clipShape(Capsule())
                }.buttonStyle(.plain).disabled(isInstalled)
            }
            
            Section(header: Text("Mô tả").font(.headline)) {
                Text("Giữ nguyên dữ liệu cấu hình hiện có và thay đổi giá trị Boolean IsSupervised.").font(.subheadline)
            }
            
            Section(header: Text("Thông tin gói").font(.headline)) {
                HStack { Text("Phiên bản"); Spacer(); Text("1.0.0").foregroundStyle(.secondary) }
                HStack { Text("Nguồn"); Spacer(); Text("Tính năng 3105").foregroundStyle(.secondary) }
                HStack { Text("Tác giả"); Spacer(); Text("3105").foregroundStyle(.secondary) }
                HStack { Text("Danh mục"); Spacer(); Text("Tính năng hệ thống").foregroundStyle(.secondary) }
                HStack { Text("iOS hỗ trợ"); Spacer(); Text("iOS 27").foregroundStyle(.secondary) }
            }
        }.navigationTitle("Chữ màn hình khóa").navigationBarTitleDisplayMode(.inline)
    }
}

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
                } header: { Text(language.text("repository.source_tags")).font(.footnote.weight(.semibold)).foregroundStyle(.secondary).textCase(nil) }
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