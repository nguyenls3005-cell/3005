import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue
    @AppStorage(FeatureVisibility.developerModeStorageKey) private var developerModeEnabled = false
    @AppStorage("dialer_data_fetched") private var dialerFetched = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        AppLogo()
                        VStack(alignment: .leading, spacing: 3) {
                            Text("3105").font(.headline)
                            Text(language.text("common.version", appVersion)).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }.padding(.vertical, 4)
                }

                Section(language.text("settings.language")) {
                    Picker(language.text("settings.language"), selection: $languageCode) {
                        ForEach(AppLanguage.allCases) { option in Text(option.displayName).tag(option.rawValue) }
                    }.pickerStyle(.segmented).labelsHidden()
                }

                Section {
                    Toggle(isOn: $developerModeEnabled) {
                        Label(language.text("settings.developer_mode"), systemImage: "hammer.fill")
                    }
                } header: {
                    Text(language.text("dashboard.features"))
                } footer: {
                    Text(language.text("settings.developer_mode_footer"))
                }

                Section {
                    HStack {
                        Label("Lấy dữ liệu Dialer", systemImage: "phone.fill")
                        Spacer()
                        Image(systemName: dialerFetched ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundStyle(dialerFetched ? .green : .secondary)
                        Text(dialerFetched ? "Đã lấy" : "Chưa lấy").foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { dialerFetched.toggle() }
                } header: {
                    Text("Dialer")
                } footer: {
                    Text("Mở Điện thoại > Bàn phím và bấm một phím trước khi lấy dữ liệu. 3105 chỉ nhận diện phím và chế độ sáng/tối; tệp thường hoặc Chữ đậm sẽ được xử lý tự động.")
                }

                Section(language.text("common.device")) {
                    LabeledContent(language.text("dashboard.hardware_model"), value: AppInfo.displayMachineName)
                    LabeledContent(language.text("settings.ios_version"), value: "\(AppInfo.osVersion) (\(AppInfo.osBuild))")
                }

                Section {
                    HStack {
                        Text(language.text("settings.current_version"))
                        Spacer()
                        Text(language.text(appState.isSupported ? "settings.supported" : "settings.unsupported"))
                            .foregroundStyle(appState.isSupported ? Color.green : Color.red)
                    }
                    LabeledContent("iOS 17", value: ExploitSupportPolicy.verifiedIOS17Range)
                    LabeledContent("iOS 18", value: ExploitSupportPolicy.verifiedIOS18Range)
                    LabeledContent("iOS 26", value: ExploitSupportPolicy.verifiedIOS26Range)
                } header: {
                    Text(language.text("settings.verified_versions"))
                } footer: {
                    Text(language.text("settings.supported_versions_footer"))
                }

                Section(language.text("settings.social_media")) {
                    creditsRow(name: "GitHub", role: language.text("social.github_role"), url: "https://github.com/YangJiiii/3105")
                    creditsRow(name: "Cộng Đồng IOSVN", role: language.text("social.iosvn_role"), url: "https://t.me/ioscrackvn")
                }
            }
            .tint(AppTheme.accent)
            .navigationTitle(language.text("settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(language.text("common.done")) { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "AppReleaseDisplayVersion") as? String ?? "2.0"
    }

    @ViewBuilder
    private func creditsRow(name: String, role: String, url: String) -> some View {
        if let destination = URL(string: url) {
            Link(destination: destination) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(name).font(.headline).foregroundStyle(.primary)
                        Text(role).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.system(size: 14, weight: .medium)).foregroundStyle(AppTheme.accent).frame(width: 28, height: 28)
                }.contentShape(Rectangle())
            }
        }
    }
}
