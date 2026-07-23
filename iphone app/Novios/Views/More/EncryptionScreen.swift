import SwiftUI
import CommonCrypto

public struct EncryptionScreen: View {
    @ObservedObject private var theme = ThemeManager.shared
    @State private var mode = 0
    @State private var input = ""
    @State private var secret = ""
    @State private var result = ""
    @State private var showCopied = false

    public init() {}

    public var body: some View {
        ZStack {
            LiquidBackgroundView()
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Modo", selection: $mode) {
                        Text("Cifrar").tag(0)
                        Text("Descifrar").tag(1)
                    }
                    .pickerStyle(.segmented).padding(.horizontal, 24)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(mode == 0 ? "Mensaje" : "Mensaje cifrado").appFont(size: 13, weight: .semibold).foregroundColor(theme.textSecondary)
                        TextEditor(text: $input).frame(minHeight: 100).padding(8)
                            .background(theme.surfaceBackground).cornerRadius(10)
                    }
                    .padding(.horizontal, 24)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Clave secreta").appFont(size: 13, weight: .semibold).foregroundColor(theme.textSecondary)
                        SecureField("Clave compartida", text: $secret)
                            .padding(12).background(theme.surfaceBackground).cornerRadius(10)
                    }
                    .padding(.horizontal, 24)

                    Button {
                        result = mode == 0 ? encrypt(input, secret) : decrypt(input, secret)
                    } label: {
                        Text(mode == 0 ? "Cifrar" : "Descifrar")
                            .appFont(size: 16, weight: .bold).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(theme.primaryGradient).cornerRadius(12)
                    }
                    .disabled(input.isEmpty || secret.isEmpty)
                    .padding(.horizontal, 24)

                    if !result.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(mode == 0 ? "Texto cifrado" : "Texto descifrado")
                                    .appFont(size: 13, weight: .semibold).foregroundColor(theme.textSecondary)
                                Spacer()
                                Button {
                                    UIPasteboard.general.string = result
                                    showCopied = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showCopied = false }
                                } label: {
                                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                                        .foregroundColor(theme.primary)
                                }
                            }
                            Text(result).appFont(size: 13).padding(12)
                                .background(theme.surfaceBackground).cornerRadius(10)
                                .textSelection(.enabled)
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("Mensajes Cifrados")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func encrypt(_ text: String, _ key: String) -> String {
        let keyHash = sha256(key)
        let textBytes = [UInt8](text.utf8)
        var result = [UInt8]()
        for (i, byte) in textBytes.enumerated() {
            result.append(byte ^ keyHash[i % keyHash.count])
        }
        return Data(result).base64EncodedString()
    }

    private func decrypt(_ base64: String, _ key: String) -> String {
        guard let data = Data(base64Encoded: base64) else { return "Error: texto cifrado inválido" }
        let keyHash = sha256(key)
        var result = [UInt8]()
        for (i, byte) in data.enumerated() {
            result.append(byte ^ keyHash[i % keyHash.count])
        }
        return String(bytes: result, encoding: .utf8) ?? "Error: no se pudo descifrar"
    }

    private func sha256(_ string: String) -> [UInt8] {
        let data = Data(string.utf8)
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { buf in
            _ = CC_SHA256(buf.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash
    }
}
