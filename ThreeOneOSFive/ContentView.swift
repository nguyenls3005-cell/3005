import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.appLanguage) private var language
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var patchDraftCoordinator: PatchDraftCoordinator
    @EnvironmentObject private var patchStore: PatchProjectStore
    @EnvironmentObject private var repositoryStore: PackageRepositoryStore
    @AppStorage(FeatureVisibility.developerModeStorageKey)
    private var developerModeEnabled = false
    @State private var tabNavigation: AppTabNavigationState
    @State private var showSettings = false
    @State private var showLogs = false

    init() {
        _tabNavigation = State(initialValue: AppTabNavigationState())
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                regularLayout
            } else {
                compactLayout
            }
        }
        .tint(AppTheme.accent)
        .imageScale(.small)
        .onChange(of: patchDraftCoordinator.request?.id) { requestID in
            if requestID != nil { tabNavigation.select(AppSection.installed.rawValue) }
        }
        .onChange(of: developerModeEnabled) { _ in
            tabNavigation.reconcileSelection(with: featureVisibility)
        }
        .onAppear {
            tabNavigation.reconcileSelection(with: featureVisibility)
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showLogs) { LogView() }
        .patchStorePresentation(patchStore)
        .repositoryStorePresentation(repositoryStore, patchStore: patchStore)
    }

    private var compactLayout: some View {
        TabView(selection: tabSelection) {
            ForEach(visibleSections) { section in
                sectionContent(section)
                    .tabItem {
                        CompactTabLabel(title: language.text(section.titleKey), systemImage: section.systemImage)
                    }
                    .tag(section.rawValue)
            }
        }
    }

    private var regularLayout: some View {
        NavigationSplitView {
            List {
                ForEach(visibleSections) { section in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) { tabNavigation.select(section.rawValue) }
                    } label: {
                        Label(language.text(section.titleKey), systemImage: section.systemImage)
                            .fontWeight(section.rawValue == tabNavigation.selectedTab ? .semibold : .regular)
                            .frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(section.rawValue == tabNavigation.selectedTab ? AppTheme.accent.opacity(0.14) : Color.clear)
                }
            }
            .navigationTitle("3005")
            .navigationSplitViewColumnWidth(min: 210, ideal: 240, max: 300)
        } detail: {
            sectionContent(selectedVisibleSection).id(selectedVisibleSection.rawValue)
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private func sectionContent(_ section: AppSection) -> some View {
        switch section {
        case .home: RepositoryHomeView(onOpenSettings: openSettings, onOpenLogs: openLogs)
        case .new: RepositoryNewView(onOpenSettings: openSettings, onOpenLogs: openLogs)
        case .sources: RepositorySourcesView(onOpenSettings: openSettings, onOpenLogs: openLogs)
        case .installed: PatchProjectsView(onOpenSettings: openSettings, onOpenLogs: openLogs)
        case .files: AppDataBrowserView(tabSession: filesTabSession, onOpenSettings: openSettings, onOpenLogs: openLogs)
        case .search: RepositorySearchView(onOpenSettings: openSettings, onOpenLogs: openLogs)
        }
    }

    // LOGIC ẨN/HIỆN TAB DỰA VÀO NPT
    private var visibleSections: [AppSection] {
        // Nếu bật NPT: Ẩn Tìm kiếm, hiện Tệp
        if developerModeEnabled {
            return [.home, .new, .sources, .installed, .files]
        } else {
            // Nếu tắt NPT: Ẩn Tệp, hiện Tìm kiếm
            return [.home, .new, .sources, .installed, .search]
        }
    }

    private var tabSelection: Binding<Int> {
        Binding(get: { tabNavigation.selectedTab }, set: { tabNavigation.select($0) })
    }

    private var filesTabSession: Binding<FilesTabSession> {
        Binding(get: { tabNavigation.filesTabs }, set: { tabNavigation.setFilesTabs($0) })
    }

    private var featureVisibility: FeatureVisibility {
        FeatureVisibility(developerModeEnabled: developerModeEnabled)
    }

    private var selectedVisibleSection: AppSection {
        let selected = AppSection(rawValue: tabNavigation.selectedTab)
        return selected.flatMap { visibleSections.contains($0) ? $0 : nil } ?? .home
    }

    private func openSettings() { showSettings = true }
    private func openLogs() { showLogs = true }
}

private struct CompactTabLabel: View {
    let title: String
    let systemImage: String
    @ViewBuilder var body: some View {
        if let image = UIImage(systemName: systemImage, withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .medium))?.withRenderingMode(.alwaysTemplate) {
            Image(uiImage: image)
        } else {
            Image(systemName: systemImage).font(.system(size: 17, weight: .medium))
        }
        Text(title)
    }
}

private extension AppSection {
    var titleKey: String {
        switch self {
        case .home: return "tab.home"
        case .new: return "tab.new"
        case .sources: return "tab.sources"
        case .installed: return "tab.installed"
        case .files: return "tab.files"
        case .search: return "tab.search"
        }
    }
    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .new: return "clock.arrow.circlepath"
        case .sources: return "shippingbox.fill"
        case .installed: return "tray.full.fill"
        case .files: return "folder.fill"
        case .search: return "magnifyingglass"
        }
    }
}