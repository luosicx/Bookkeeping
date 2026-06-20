import SwiftUI

struct AppLockView: View {
    @AppStorage("isAppLockEnabled") private var isAppLockEnabled = false
    @AppStorage("requireOnLaunch") private var requireOnLaunch = true
    @State private var isAuthenticated = false
    @State private var showAuthError = false
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "lock.shield")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text(L.appLocked)
                .font(.title)
                .fontWeight(.bold)
            
            Text(L.authToContinue)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Button(action: authenticate) {
                HStack {
                    Image(systemName: BiometricAuth.shared.isBiometricAvailable() ? "faceid" : "lock")
                    Text(L.unlock)
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            if requireOnLaunch {
                authenticate()
            }
        }
        .alert(L.authFailed, isPresented: $showAuthError) {
            Button(L.retry, action: authenticate)
            Button(L.cancel, role: .cancel) { }
        } message: {
            Text(L.authFailedMessage)
        }
    }
    
    private func authenticate() {
        BiometricAuth.shared.authenticate { success, error in
            if success {
                withAnimation {
                    isAuthenticated = true
                }
            } else {
                showAuthError = true
            }
        }
    }
}

struct AppLockSettingsView: View {
    @AppStorage("isAppLockEnabled") private var isAppLockEnabled = false
    @AppStorage("requireOnLaunch") private var requireOnLaunch = true
    @AppStorage("lockTimeout") private var lockTimeout = 0
    
    var body: some View {
        Form {
            Section(header: Text(L.appLock)) {
                Toggle(L.enableAppLock, isOn: $isAppLockEnabled)
                
                if isAppLockEnabled {
                    HStack {
                        Text(L.biometricType)
                        Spacer()
                        Text(BiometricAuth.shared.getBiometricType())
                            .foregroundColor(.gray)
                    }
                }
            }
            
            if isAppLockEnabled {
                Section(header: Text(L.lockSettings)) {
                    Toggle(L.requireOnLaunch, isOn: $requireOnLaunch)
                    
                    Picker(L.autoLock, selection: $lockTimeout) {
                        Text(L.immediately).tag(0)
                        Text(L.after1Minute).tag(60)
                        Text(L.after5Minutes).tag(300)
                        Text(L.after15Minutes).tag(900)
                    }
                }
            }
        }
        .navigationTitle(L.appLockSettings)
    }
}

#Preview {
    AppLockView()
}
