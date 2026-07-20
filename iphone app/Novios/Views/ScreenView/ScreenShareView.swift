import SwiftUI

public struct ScreenShareView: View {
    @State private var selectedTab = 0

    public var body: some View {
        ZStack {
            Color(red: 0.035, green: 0.035, blue: 0.043).ignoresSafeArea()
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text("Compartir Pantalla").tag(0)
                    Text("Ver Pantalla").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle()).padding(.horizontal, 16).padding(.top, 8)
                .tint(Color(red: 1.0, green: 0.36, blue: 0.54))

                if selectedTab == 0 {
                    SenderView()
                } else {
                    ReceiverView()
                }
            }
        }
        .navigationTitle("Pantalla en Vivo")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SenderView: View {
    @State private var isSharing = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            if let err = errorMessage {
                Text(err).font(.system(size: 13)).foregroundColor(.red).padding(12)
                    .frame(maxWidth: .infinity).background(.red.opacity(0.15)).cornerRadius(12)
            }

            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 16).fill(Color(red: 0.11, green: 0.11, blue: 0.12))
                VStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up").font(.system(size: 64)).foregroundColor(.white.opacity(0.2))
                    Text(isSharing ? "Compartiendo pantalla..." : "Presiona \"Iniciar\" para compartir tu pantalla")
                        .font(.system(size: 14)).foregroundColor(.white.opacity(0.4)).multilineTextAlignment(.center)
                }
            }
            .frame(maxHeight: .infinity)

            Button {
                if isSharing {
                    isSharing = false; errorMessage = nil
                } else {
                    isLoading = true; errorMessage = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isSharing = true; isLoading = false
                    }
                }
            } label: {
                HStack {
                    if isLoading { ProgressView().tint(.white) }
                    else { Image(systemName: isSharing ? "stop.fill" : "square.and.arrow.up") }
                    Text(isSharing ? "Detener Transmisión" : "Iniciar Transmisión de Pantalla")
                }
                .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(isSharing ? Color.red : Color(red: 1.0, green: 0.36, blue: 0.54)).cornerRadius(16)
            }
            .disabled(isLoading)
            Spacer().frame(height: 20)
        }
        .padding(20)
    }
}

private struct ReceiverView: View {
    @State private var isConnected = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            if let err = errorMessage {
                Text(err).font(.system(size: 13)).foregroundColor(.red).padding(12)
                    .frame(maxWidth: .infinity).background(.red.opacity(0.15)).cornerRadius(12)
            }

            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 16).fill(Color(red: 0.11, green: 0.11, blue: 0.12))
                VStack(spacing: 12) {
                    Image(systemName: "tv").font(.system(size: 64)).foregroundColor(.white.opacity(0.2))
                    Text(isConnected ? "Esperando transmisión..." : "Presiona \"Conectar\" para ver la pantalla de tu pareja")
                        .font(.system(size: 14)).foregroundColor(.white.opacity(0.4)).multilineTextAlignment(.center)
                }
            }
            .frame(maxHeight: .infinity)

            Button {
                if isConnected {
                    isConnected = false; errorMessage = nil
                } else {
                    isLoading = true; errorMessage = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isConnected = true; isLoading = false
                    }
                }
            } label: {
                HStack {
                    if isLoading { ProgressView().tint(.white) }
                    else { Image(systemName: isConnected ? "stop.fill" : "play.fill") }
                    Text(isConnected ? "Desconectar" : "Conectar y Ver Pantalla")
                }
                .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(isConnected ? Color.red : Color(red: 1.0, green: 0.36, blue: 0.54)).cornerRadius(16)
            }
            .disabled(isLoading)
            Spacer().frame(height: 20)
        }
        .padding(20)
    }
}
