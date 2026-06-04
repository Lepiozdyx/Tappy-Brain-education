import SwiftUI

struct TappyBrainEducationApp: View {
    @StateObject private var store = AppStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        RootView()
            .environmentObject(store)
            .task {
                await store.load()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    Task {
                        await store.load()
                    }
                }
            }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if store.isLoading {
                LoadingView()
            } else if !hasCompletedOnboarding {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            } else {
                MainTabView()
            }
        }
        .alert("Storage Error", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.errorMessage ?? "")
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 18) {
            ProgressView()
                .tint(TappyColors.ink)
            Text("LOADING FLIGHT DATA")
                .font(.pixel(18, weight: .bold))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tappyBackground()
    }
}

enum AppRoute: Hashable {
    case academy(Course?)
    case notifications
    case settings
    case certificate(UUID)
}

struct MainTabView: View {
    @EnvironmentObject private var store: AppStore
    @State private var path: [AppRoute] = []
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottom) {
                Group {
                    switch selectedTab {
                    case 0:
                        HomeView(path: $path)
                    case 1:
                        FlightLogView()
                    default:
                        GraduateHallView(path: $path)
                    }
                }
                .padding(.bottom, 92)

                PixelTabBar(selectedTab: $selectedTab)
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .academy(let course):
                    AcademyView(editingCourse: course)
                        .navigationBarBackButtonHidden(true)
                case .notifications:
                    NotificationsView()
                        .navigationBarBackButtonHidden(true)
                case .settings:
                    SettingsView(path: $path)
                        .navigationBarBackButtonHidden(true)
                case .certificate(let courseID):
                    if let course = store.state.courses.first(where: { $0.id == courseID }) {
                        CertificateView(course: course)
                            .navigationBarBackButtonHidden(true)
                    } else {
                        MissingRouteView(title: "CERTIFICATE LOST", message: "This diploma is no longer available.")
                            .navigationBarBackButtonHidden(true)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct PixelTabBar: View {
    @Binding var selectedTab: Int

    private let tabs: [PixelTabItem] = [
        PixelTabItem(title: "Flight", assetName: "tab_flight_icon"),
        PixelTabItem(title: "Log", assetName: "tab_log_icon"),
        PixelTabItem(title: "Hall", assetName: "tab_hall_icon")
    ]

    var body: some View {
        HStack(spacing: 18) {
            ForEach(tabs.indices, id: \.self) { index in
                Button {
                    selectedTab = index
                } label: {
                    SafeAssetImage(name: tabs[index].assetName, mode: .contain)
                        .frame(width: 31, height: 31)
                        .padding(14)
                        .background(Color(uiColor: .systemBackground))
                        .overlay(
                            Rectangle()
                                .stroke(selectedTab == index ? TappyColors.yellow : TappyColors.ink, lineWidth: 4)
                        )
                        .background(TappyColors.ink.offset(x: 3, y: 4))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tabs[index].title)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 18)
        .padding(.bottom, 22)
        .background(TappyColors.grass)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(TappyColors.ink)
                .frame(height: 4)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

private struct PixelTabItem {
    let title: String
    let assetName: String
}

struct MissingRouteView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 20) {
            HeaderBar(title: title, showBack: true)
            PixelCard {
                Text(message)
                    .font(.pixel(16))
                    .foregroundStyle(TappyColors.muted)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            Spacer()
        }
        .tappyBackground()
    }
}
