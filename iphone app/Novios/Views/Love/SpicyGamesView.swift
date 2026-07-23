import SwiftUI
import FirebaseFirestore

public struct SpicyGamesView: View {
    @ObservedObject private var couple = CoupleService.shared
    @ObservedObject private var theme = ThemeManager.shared
    @State private var selectedTab = 0
    @State private var selectedLevel: SpicyLevel = .suave
    @Environment(\.dismiss) private var dismiss

    private let db = Firestore.firestore()

    private var coupleId: String {
        [CoupleService.diegoUid, CoupleService.yosmariUid].sorted().joined(separator: "_")
    }

    private var gamesRef: CollectionReference {
        db.collection("couples").document(coupleId).collection("games")
    }

    private let myName: String = {
        AuthService.shared.currentUser?.displayName ?? (AuthService.shared.currentUser?.id == CoupleService.diegoUid ? "Diego" : "Yosmari")
    }()

    private let partnerName: String = {
        AuthService.shared.currentUser?.id == CoupleService.diegoUid ? "Yosmari" : "Diego"
    }()

    private let myUid: String = AuthService.shared.currentUser?.id ?? ""

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                VStack(spacing: 0) {
                    tabSelector
                    if selectedTab == 0 { sendTab } else { inboxTab }
                }
            }
            .navigationTitle("Zona Picante 🔥")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Cerrar") { dismiss() } } }
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            tabButton("Enviar", 0)
            tabButton("Recibidos", 1)
        }
        .frame(height: 44)
        .background(theme.textSecondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func tabButton(_ label: String, _ idx: Int) -> some View {
        let sel = selectedTab == idx
        return Button {
            selectedTab = idx
        } label: {
            HStack(spacing: 6) {
                Image(systemName: sel ? "heart.fill" : "heart").font(.system(size: 12))
                Text(label).appFont(size: 13, weight: .semibold)
            }
            .foregroundColor(sel ? .white : .secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(sel ? levelColor : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 22))
        }
    }

    // MARK: - Level Selector

    private var levelSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(SpicyLevel.allCases, id: \.self) { level in
                    let sel = level == selectedLevel
                    Button {
                        selectedLevel = level
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: level.iconName).font(.system(size: 14))
                            Text(level.rawValue).appFont(size: 13, weight: .semibold)
                        }
                        .foregroundColor(sel ? .white : level.color)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(sel ? level.color : level.color.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    }
                }
            }
        }
    }

    // MARK: - Send Tab

    private var sendTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle().fill(LinearGradient(colors: [theme.primary, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 70, height: 70)
                            .shadow(color: theme.primary.opacity(0.3), radius: 20)
                        Image(systemName: "heart.fill").foregroundColor(.white).font(.system(size: 30))
                    }
                    Text("\(myName)  •  \(partnerName)").appFont(size: 14).foregroundColor(.secondary)
                    Text("Envía un reto a tu pareja").appFont(size: 12).foregroundColor(.secondary.opacity(0.6))
                }

                levelSelector

                challengeCard(icon: "face.smiling", title: "Verdad", desc: "Genera y envía una pregunta a tu pareja", action: { sendChallenge(type: "verdad") })
                challengeCard(icon: "flame.fill", title: "Reto", desc: "Genera y envía un desafío a tu pareja", action: { sendChallenge(type: "reto") })
                challengeCard(icon: "camera.fill", title: "Foto Reto", desc: "Envía una foto reto a tu pareja", action: { sendPhotoChallenge() })

                HStack(spacing: 6) {
                    Image(systemName: "cloud.fill").font(.system(size: 12))
                    Text("♾️ Envío online a su teléfono").appFont(size: 11, weight: .semibold)
                }
                .foregroundColor(levelColor)
                .padding(.horizontal, 14).padding(.vertical, 6)
                .background(levelColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .padding(16)
        }
    }

    private func challengeCard(icon: String, title: String, desc: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14).fill(levelColor.opacity(0.15)).frame(width: 48, height: 48)
                    Image(systemName: icon).font(.system(size: 22)).foregroundColor(levelColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(title).appFont(size: 16, weight: .semibold).foregroundColor(theme.textPrimary)
                        Text(selectedLevel.rawValue.uppercased()).appFont(size: 9, weight: .bold).foregroundColor(levelColor).padding(.horizontal, 8).padding(.vertical, 2).background(levelColor.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    Text(desc).appFont(size: 11).foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(.secondary)
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Inbox Tab

    private var inboxTab: some View {
        ChallengesListView(gamesRef: gamesRef, myName: myName, myUid: myUid, partnerName: partnerName, levelColor: levelColor, theme: theme)
    }

    // MARK: - Send Logic

    private func sendChallenge(type: String) {
        let level = selectedLevel
        let content = generateContent(type: type, level: level)
        let vc = UIHostingController(rootView: ChallengePreviewView(type: type, level: level, content: content, gamesRef: gamesRef, myName: myName, myUid: myUid, partnerName: partnerName, theme: theme))
        if let top = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController }).first {
            var t = top; while let p = t.presentedViewController { t = p }; t.present(vc, animated: true)
        }
    }

    private func sendPhotoChallenge() {
        let level = selectedLevel
        let content = photoChallenges[level]!.randomElement() ?? "Tómate una foto divertida"
        let vc = UIHostingController(rootView: PhotoChallengeView(content: content, level: level, gamesRef: gamesRef, myName: myName, myUid: myUid, partnerName: partnerName, theme: theme))
        if let top = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController }).first {
            var t = top; while let p = t.presentedViewController { t = p }; t.present(vc, animated: true)
        }
    }

    private var levelColor: Color { selectedLevel.color }

    private func generateContent(type: String, level: SpicyLevel) -> String {
        let list = type == "verdad" ? truths[level]! : dares[level]!
        return list.randomElement() ?? (type == "verdad" ? "¿Qué piensas cuando no estoy?" : "Hazme reír")
    }

    // MARK: - Static Content (from Android couple_content.dart)

    private let truths: [SpicyLevel: [String]] = [
        .suave: [
            "¿Qué fue lo primero que te gustó de mí?",
            "¿Cuál es tu recuerdo favorito juntos?",
            "¿Qué canción te recuerda a nosotros?",
            "¿Qué es lo que más te gusta de nuestra relación?",
            "¿Cuál fue tu cita favorita conmigo?",
            "¿Qué piensas cuando no estamos juntos?",
            "¿Qué sueñas hacer conmigo en el futuro?",
            "¿Qué fue lo que te hizo saber que me amabas?",
            "¿Cuál es tu cualidad favorita de mí?",
            "¿Qué es lo que más te gusta de mi personalidad?",
            "¿Cuál es tu mejor recuerdo de nuestra primera semana juntos?",
            "¿Qué película te gustaría ver conmigo esta noche?",
            "¿Cuál es tu lugar favorito al que hemos ido juntos?",
            "¿Qué te hace sentir más conectad@ conmigo?",
            "¿Cuál fue el momento más divertido que hemos compartido?",
            "¿Qué te gusta hacer en tus días libres conmigo?",
            "¿Cuál es tu comida favorita que cocino?",
            "¿Qué te gusta de cómo te trato?",
            "¿Cuál fue el mejor regalo que te he dado?",
            "¿Qué te hace sentir especial en nuestra relación?",
        ],
        .picante: [
            "¿Qué parte de mi cuerpo te atrae más?",
            "¿Cuál ha sido el beso más caliente que hemos tenido?",
            "¿Qué ropa interior mía te gusta más?",
            "¿Cuál es tu fantasía más recurrente conmigo?",
            "¿Dónde es el lugar más atrevido donde quisieras tener sexo?",
            "¿Qué posición sexual disfrutas más?",
            "¿Qué es lo que más te excita de mí?",
            "¿Has tenido alguna fantasía conmigo que no me hayas contado?",
            "¿Qué es lo que más te gusta de besarme?",
            "¿Cuál fue nuestro encuentro más intenso?",
            "¿Qué parte de tu cuerpo te gusta que toque?",
            "¿Qué es lo que más te gusta cuando estamos en la cama?",
            "¿Qué jean o pantalón mío te gusta más?",
            "¿Cuál ha sido el momento más caliente que hemos tenido en público?",
            "¿Qué te gustaría que hiciera más seguido en la intimidad?",
            "¿Prefieres luces encendidas o apagadas?",
            "¿Qué te gusta que te susurre al oído?",
            "¿Cuál es la parte más sensible de tu cuerpo?",
            "¿Te gusta cuando tomo la iniciativa en la cama?",
            "¿Qué te gusta de cómo me muevo?",
        ],
        .extremo: [
            "¿Cuál es tu práctica sexual favorita conmigo?",
            "¿Qué objeto o juguete sexual te gustaría probar?",
            "¿Cuál ha sido el orgasmo más intenso conmigo?",
            "¿Te gustaría hacer un video íntimo juntos?",
            "¿Qué harías si te dijera que quiero un trío?",
            "¿Qué tan seguido te gustaría tener sexo idealmente?",
            "¿Cuál es tu mayor fetiche que aún no hemos explorado?",
            "¿Te gustaría ir a un sex shop juntos?",
            "¿Qué te parece si grabamos un audio teniendo sexo?",
            "¿Qué opinas de los juegos de rol en la cama?",
            "¿Cuál ha sido el lugar más peligroso donde hemos tenido sexo?",
            "¿Te gusta experimentar cosas nuevas en la cama?",
            "¿Cuántas veces al día piensas en sexo?",
            "¿Qué te gustaría que hiciera con mis manos durante el sexo?",
            "¿Te gustaría tener sexo en un lugar público pero seguro?",
            "¿Qué piensas del BDSM suave?",
            "¿Qué opinas de los juegos de sumisión/dominación?",
            "¿Te gusta que te amarren o amarrarme?",
            "¿Cuál es la parte más sucia que te gusta hacer?",
            "¿Qué te excita que no se lo has contado a nadie?",
        ],
        .xxx: [
            "Describe con lujo de detalle lo que harías si entrara ahora y te tuviera que complacer",
            "¿Cuál es tu fantasía sexual más salvaje que quieres cumplir conmigo?",
            "Dime exactamente cómo te gusta que te toque para que te vengas más fuerte",
            "Si pudieras elegir cualquier escenario de película porno para nosotros, ¿cuál sería?",
            "¿Qué te haría venirte más rápido: que te bese el cuello o que te muerda las orejas?",
            "¿En qué lugar público te atreverías a tener sexo si supiéramos que nadie nos ve?",
            "Describe cómo sería la sesión de sexo más salvaje que quieres tener",
            "¿Cuál es el límite de intensidad que te gustaría cruzar conmigo?",
            "¿Qué te parece la idea de usar hielo o algo caliente durante el sexo?",
            "¿Te gustaría ser completamente dominante conmigo o que yo lo sea?",
            "¿Qué tal si compartimos fotos íntimas solo para nosotros con caras?",
            "¿Cuánto tiempo seguido podrías tener sexo sin parar?",
            "¿Qué te parece si hacemos un juego de rol donde soy un desconocido que te seduce?",
            "Describe exactamente cómo te gusta que te bese desde los pies hasta los labios",
            "¿Qué tan fuerte te gusta que te agarre durante el sexo?",
            "¿Cuál es la palabra o frase más sucia que te gusta escuchar en la cama?",
            "Si tuvieras que elegir solo una posición para el resto de tu vida, ¿cuál sería?",
            "¿Qué tal si usamos un vibrador mientras te penetro?",
            "¿Qué tan seguido te masturbas pensando en mí?",
            "¿Qué harías si estuviera atad@ y completamente a tu merced?",
        ],
    ]

    private let dares: [SpicyLevel: [String]] = [
        .suave: [
            "Dame un abrazo de 10 segundos sin soltarme",
            "Bésame en la mejilla lentamente",
            "Toma mi mano y dime algo bonito mirándome a los ojos",
            "Hazme una caricia en la cara por 30 segundos",
            "Baila conmigo una canción lenta",
            "Cántame tu canción favorita de amor",
            "Prepárame un café o té y tráemelo con una nota",
            "Dame un masaje en los hombros por 2 minutos",
            "Escribe algo lindo en mi brazo con tu dedo",
            "Hazme cosquillas por 15 segundos",
            "Cuéntame un secreto dulce que nunca le hayas dicho a nadie",
            "Dibuja algo bonito en un papel y regálamelo",
            "Haz una lista mental de 5 cosas que te gustan de nosotros",
            "Cúbreme los ojos y llévame a algún lugar de la casa",
            "Susúrrame algo tierno al oído por 10 segundos",
            "Inventa un apodo nuevo y dulce para nosotros",
            "Dame 3 cumplidos sinceros",
            "Haz una promesa en voz alta sobre nuestro futuro",
            "Mírame fijamente 20 segundos sin reírte",
            "Escribe un mini poema de 2 líneas para mí",
        ],
        .picante: [
            "Dame un beso de 10 segundos en los labios",
            "Bésame el cuello y susúrrame algo hot al oído",
            "Siéntate en mis piernas y no te muevas por 1 minuto",
            "Quítame una prenda de ropa con los dientes",
            "Pasa tu mano por debajo de mi camisa por 15 segundos",
            "Baila para mí una canción sensual",
            "Lámeme el cuello lentamente",
            "Dame un masaje en los muslos durante 2 minutos",
            "Acaríciame la pierna desde el tobillo hasta arriba",
            "Muérdeme el labio inferior suavemente",
            "Házme un striptease de una sola prenda",
            "Bésame desde el cuello hasta el pecho",
            "Dime al oído lo que me harías esta noche en detalle",
            "Pon música sensual y baila pegad@ a mí",
            "Tócame por encima de la ropa donde más te guste",
            "Haz el sonido que haces cuando tienes placer",
            "Bésame apasionadamente por 20 segundos sin parar",
            "Pasa tu dedo por mis labios lentamente",
            "Ponte detrás de mí y abrázame por la cintura",
            "Hazme una caricia en la entrepierna por encima de la ropa",
        ],
        .extremo: [
            "Quítame toda la ropa de la cintura para arriba solo con una mano",
            "Pon hielo en tu boca y bésame el pecho",
            "Arrodíllate frente a mí y bésame el estómago hasta abajo",
            "Haz una simulación de sexo oral sobre mi ropa por 1 minuto",
            "Átame las manos con una corbata o bufanda y haz lo que quieras",
            "Pasa 3 minutos estimulándome solo con tu lengua, sin manos",
            "Gime mi nombre mientras te tocas frente a mí",
            "Ponte de espaldas a mí y deja que te bese toda la espalda",
            "Usa una prenda de ropa íntima mía puesta por 10 minutos",
            "Muéstrame exactamente cómo te tocas cuando estás sol@",
            "Déjame ponerte una venda en los ojos y hacerte lo que quiera por 5 minutos",
            "Ponte en cuatro y quédate así 30 segundos mientras te acaricio",
            "Lame todo mi cuerpo desde el cuello hasta los pies",
            "Frota tu cuerpo contra el mío hasta que ambos respiremos fuerte",
            "Hazme un oral completo sin parar hasta que me venga",
            "Ponte de rodillas y suplica por lo que quieras que te haga",
            "Déjame atarte a la cama por 10 minutos",
            "Siéntate en mi cara y no te muevas por 30 segundos",
            "Hazte un selfie provocativo y envíamelo",
            "Bailemos desnudos una canción completa",
        ],
        .xxx: [
            "Arrodíllate y bésame los pies hasta llegar a mis labios",
            "Déjame ponerte un collar y tratarte como mi mascota por 15 minutos",
            "Coge mi mano y haz que me toque como más te guste",
            "Ponte de espaldas y deja que te penetre mientras te miro al espejo",
            "Gime bien fuerte mientras te hago lo que más te gusta, que te oigan",
            "Dame 3 órdenes sexuales y las seguiré sin chistar si aceptas",
            "Hazme un oral debajo de la mesa mientras como fingiendo que no pasa nada",
            "Tócate frente al espejo mientras te miro sin tocarte",
            "Déjame grabarte un video corto teniendo sexo conmigo",
            "Prepárame un baño y métete conmigo completamente desnud@",
            "Chúpame un dedo mientras te penetro",
            "Ponte mis bóxers o tanga y úsalos por el resto del juego",
            "Dime las 5 palabras más sucias que se te ocurran al oído",
            "Restriega tu cuerpo contra el mío hasta que me venga encima de ti",
            "Déjame masturbarme frente a ti mientras me ves a los ojos",
            "Haz que me venga solo con tus palabras, sin tocarme",
            "Ponte el plug anal si tenemos uno y úsalo por 30 minutos",
            "Hazte una foto con mi semen o fluidos y ponla de fondo de pantalla",
            "Déjame hacerte todo lo que quiera por 20 minutos sin decir que no",
            "Manda un audio tuyo gimiendo y diciendo cosas sucias a tu pareja",
        ],
    ]

    private let photoChallenges: [SpicyLevel: [String]] = [
        .suave: [
            "Selfie sonriendo juntos",
            "Foto de su mano sosteniendo la mía",
            "Selfie en el espejo de cuerpo completo",
            "Foto de tus ojos bien de cerca",
            "Selfie con tu outfit favorito",
            "Foto de tu lugar favorito de la casa",
            "Selfie con tu peluche o objeto favorito",
            "Foto de lo que estás viendo/leyendo ahora",
            "Selfie con una expresión graciosa",
            "Foto de tu café o bebida favorita",
        ],
        .picante: [
            "Selfie provocativo con ropa interior",
            "Foto de tus labios haciendo un puchero sexy",
            "Selfie en la cama con sábanas",
            "Foto de tu espalda o hombros",
            "Selfie con una prenda mía puesta",
            "Foto de tus piernas desde abajo",
            "Selfie mirando hacia arriba",
            "Foto de tu cadera con ropa interior",
            "Selfie con el cabello revuelto",
            "Foto de tu boca abierta y mirada intensa",
        ],
        .extremo: [
            "Selfie completamente desnud@ pero sin mostrar tu cara",
            "Foto de tu pecho o torso",
            "Selfie en ropa interior desde atrás",
            "Foto de tu zona erógena favorita",
            "Selfie con una mano en tu entrepierna",
            "Foto de tus nalgas con ropa interior",
            "Selfie de tu cuerpo con poca luz",
            "Foto de ti en la ducha (sin mostrar partes íntimas si no quieres)",
            "Selfie acostad@ en posiciones sensuales",
            "Foto de ti con mi ropa interior puesta",
        ],
        .xxx: [
            "Selfie mostrando partes íntimas sin cara (para privacidad)",
            "Foto de tu cuerpo con fluidos",
            "Selfie en una posición sexual sugerente",
            "Foto desde arriba de tu cuerpo desnudo",
            "Selfie con un juguete sexual si tienes",
            "Video corto de 3 segundos moviendo las caderas",
            "Foto mostrando exactamente lo que quieres que te haga",
            "Selfie después de masturbarte",
            "Foto en el espejo completamente desnud@",
            "Video de 5 segundos gimiendo mi nombre",
        ],
    ]
}

// MARK: - Spicy Level

private enum SpicyLevel: String, CaseIterable {
    case suave = "Suave"
    case picante = "Picante"
    case extremo = "Extremo"
    case xxx = "XXX"

    var color: Color {
        switch self {
        case .suave: return Color(red: 0.4, green: 0.73, blue: 0.42)
        case .picante: return Color(red: 1, green: 0.72, blue: 0.3)
        case .extremo: return Color(red: 1, green: 0.36, blue: 0.54)
        case .xxx: return Color(red: 0.82, green: 0.18, blue: 0.18)
        }
    }

    var iconName: String {
        switch self {
        case .suave: return "face.smiling"
        case .picante: return "flame.fill"
        case .extremo: return "flame.circle.fill"
        case .xxx: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Challenge Preview

private struct ChallengePreviewView: View {
    let type: String
    let level: SpicyLevel
    let content: String
    let gamesRef: CollectionReference
    let myName: String
    let myUid: String
    let partnerName: String
    let theme: ThemeManager
    @State private var sending = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                VStack(spacing: 20) {
                    Text(type == "verdad" ? "Verdad" : "Reto")
                        .appFont(size: 14, weight: .semibold)
                        .foregroundColor(level.color)
                    GlassCard(cornerRadius: 20) {
                        VStack(spacing: 12) {
                            Image(systemName: type == "verdad" ? "face.smiling" : "flame.fill")
                                .font(.system(size: 24))
                                .foregroundColor(level.color)
                            Text(content)
                                .appFont(size: 16, weight: .semibold)
                                .multilineTextAlignment(.center)
                                .foregroundColor(theme.textPrimary)
                        }
                    }

                    Text(level.rawValue)
                        .appFont(size: 11, weight: .bold)
                        .foregroundColor(level.color)
                        .padding(.horizontal, 12).padding(.vertical, 4)
                        .background(level.color.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    if sending {
                        ProgressView("Enviando...").appFont(size: 13)
                    }

                    HStack(spacing: 16) {
                        Button("Regenerar") { dismiss() }
                            .buttonStyle(.bordered)
                            .disabled(sending)
                        Button("Enviar a pareja") {
                            sendToFirestore()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(level.color)
                        .disabled(sending)
                    }
                }
                .padding(24)
            }
            .navigationTitle("\(type == "verdad" ? "Verdad" : "Reto") - \(level.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } } }
        }
    }

    private func sendToFirestore() {
        sending = true
        Task {
            let id = UUID().uuidString
            let cid = [CoupleService.diegoUid, CoupleService.yosmariUid].sorted().joined(separator: "_")
            try? await gamesRef.document(id).setData([
                "type": type, "content": content, "level": level.rawValue,
                "senderId": myUid, "senderName": myName, "status": "pending", "timestamp": FieldValue.serverTimestamp()
            ])
            try? await Firestore.firestore().collection("couples").document(cid).collection("activities").addDocument(data: [
                "text": "\(myName) te envió un reto: \"\(content)\" 🌶️",
                "type": "game", "icon": "game", "timestamp": FieldValue.serverTimestamp()
            ])
            await MainActor.run { dismiss() }
        }
    }
}

// MARK: - Photo Challenge

private struct PhotoChallengeView: View {
    let content: String
    let level: SpicyLevel
    let gamesRef: CollectionReference
    let myName: String
    let myUid: String
    let partnerName: String
    let theme: ThemeManager
    @State private var selectedImage: UIImage?
    @State private var uploading = false
    @State private var sending = false
    @State private var showPicker = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                ScrollView {
                    VStack(spacing: 20) {
                        GlassCard(cornerRadius: 20) {
                            VStack(spacing: 12) {
                                Image(systemName: "camera.fill").font(.system(size: 32)).foregroundColor(level.color)
                                Text(content).appFont(size: 16, weight: .semibold).multilineTextAlignment(.center).foregroundColor(theme.textPrimary)
                            }
                        }

                        if let img = selectedImage {
                            Image(uiImage: img).resizable().scaledToFit().frame(height: 200).clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            Button("Tomar foto 📸") { showPicker = true }
                                .buttonStyle(.borderedProminent).tint(level.color)
                        }

                        if uploading || sending {
                            ProgressView(sending ? "Enviando a \(partnerName)..." : "Subiendo...").appFont(size: 13)
                        }

                        if selectedImage != nil && !sending {
                            Button("Enviar a pareja") { uploadAndSend() }
                                .buttonStyle(.borderedProminent).tint(level.color)
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Foto Reto - \(level.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } } }
            .sheet(isPresented: $showPicker) {
                ImagePicker(sourceType: .camera) { img in selectedImage = img }
            }
        }
    }

    private func uploadAndSend() {
        guard let image = selectedImage, let data = image.jpegData(compressionQuality: 0.6) else { return }
        sending = true
        let b64 = data.base64EncodedString()
        Task {
            let mid = UUID().uuidString
            try? await gamesRef.firestore.document("chat_media/\(mid)").setData(["data": b64, "mimeType": "image/jpeg"])
            try? await gamesRef.document(UUID().uuidString).setData([
                "type": "foto", "content": content, "level": level.rawValue,
                "senderId": myUid, "senderName": myName, "status": "pending",
                "photoUrl": "firestore://chat_media/\(mid)", "timestamp": FieldValue.serverTimestamp()
            ])
            await MainActor.run { dismiss() }
        }
    }
}

// MARK: - Image Picker (Camera)

private struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let completion: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ ui: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let completion: (UIImage) -> Void
        init(completion: @escaping (UIImage) -> Void) { self.completion = completion }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage { completion(img) }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { picker.dismiss(animated: true) }
    }
}

// MARK: - Challenges List View

private struct ChallengesListView: View {
    let gamesRef: CollectionReference
    let myName: String
    let myUid: String
    let partnerName: String
    let levelColor: Color
    let theme: ThemeManager
    @State private var challenges: [[String: Any]] = []
    @State private var listener: ListenerRegistration?

    var body: some View {
        Group {
            if challenges.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray.fill").font(.system(size: 64)).foregroundColor(.secondary.opacity(0.2))
                    Text("Sin desafíos aún").appFont(size: 15).foregroundColor(.secondary)
                    Text("Tu pareja te enviará desafíos aquí").appFont(size: 12).foregroundColor(.secondary.opacity(0.5))
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(Array(challenges.enumerated()), id: \.offset) { _, c in
                            ChallengeCardView(c: c, isMine: c["senderId"] as? String == myUid, myName: myName, myUid: myUid, partnerName: partnerName, gamesRef: gamesRef, theme: theme)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .onAppear { startListening() }
        .onDisappear { stopListening() }
    }

    private func startListening() {
        listener = gamesRef.addSnapshotListener { snapshot, _ in
            guard let docs = snapshot?.documents else { return }
            challenges = docs.compactMap { doc -> [String: Any]? in
                let d = doc.data()
                guard let t = d["type"] as? String, ["verdad", "reto", "foto"].contains(t) else { return nil }
                var m = d; m["id"] = doc.documentID; return m
            }.sorted { (a, b) -> Bool in
                let ta = (a["timestamp"] as? Timestamp)?.dateValue() ?? Date.distantPast
                let tb = (b["timestamp"] as? Timestamp)?.dateValue() ?? Date.distantPast
                return ta > tb
            }
        }
    }

    private func stopListening() { listener?.remove(); listener = nil }
}

// MARK: - Challenge Card

private struct ChallengeCardView: View {
    let c: [String: Any]
    let isMine: Bool
    let myName: String
    let myUid: String
    let partnerName: String
    let gamesRef: CollectionReference
    let theme: ThemeManager
    @State private var showRespond = false

    private var type: String { c["type"] as? String ?? "" }
    private var content: String { c["content"] as? String ?? "" }
    private var level: String { c["level"] as? String ?? "Suave" }
    private var status: String { c["status"] as? String ?? "pending" }
    private var photoUrl: String { c["photoUrl"] as? String ?? "" }
    private var response: String { c["response"] as? String ?? "" }
    private var responsePhotoUrl: String { c["responsePhotoUrl"] as? String ?? "" }
    private var senderName: String { c["senderName"] as? String ?? partnerName }
    private var isPending: Bool { status == "pending" }
    private var levelColor: Color {
        switch level {
        case "Suave": return Color(red: 0.4, green: 0.73, blue: 0.42)
        case "Picante": return Color(red: 1, green: 0.72, blue: 0.3)
        case "Extremo": return Color(red: 1, green: 0.36, blue: 0.54)
        case "XXX": return Color(red: 0.82, green: 0.18, blue: 0.18)
        default: return .secondary
        }
    }

    var body: some View {
        GlassCard(cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: type == "verdad" ? "face.smiling" : type == "foto" ? "camera.fill" : "flame.fill")
                        .font(.system(size: 16)).foregroundColor(levelColor)
                    Text(isMine ? "Tú" : senderName).appFont(size: 13, weight: .semibold).foregroundColor(theme.textPrimary)
                    Spacer()
                    Text(level.uppercased()).appFont(size: 9, weight: .bold).foregroundColor(levelColor).padding(.horizontal, 8).padding(.vertical, 2).background(levelColor.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 10))
                    if isPending {
                        Circle().fill(Color.orange).frame(width: 8, height: 8)
                    }
                }
                Text(content).appFont(size: 14).foregroundColor(theme.textPrimary).lineSpacing(4)

                if !photoUrl.isEmpty {
                    AsyncImage(url: URL(string: photoUrl)) { img in
                        img.resizable().scaledToFit().cornerRadius(8).frame(maxHeight: 150)
                    } placeholder: {
                        Color.gray.opacity(0.2).frame(height: 100).cornerRadius(8)
                    }
                }

                if !response.isEmpty || !responsePhotoUrl.isEmpty {
                    Divider()
                    HStack(spacing: 4) {
                        Image(systemName: "arrowshape.turn.up.left.fill").font(.system(size: 10)).foregroundColor(.green)
                        Text("Respuesta:").appFont(size: 11, weight: .semibold).foregroundColor(.green)
                    }
                    if !response.isEmpty { Text(response).appFont(size: 13).foregroundColor(.secondary) }
                    if !responsePhotoUrl.isEmpty {
                        AsyncImage(url: URL(string: responsePhotoUrl)) { img in
                            img.resizable().scaledToFit().cornerRadius(8).frame(maxHeight: 120)
                        } placeholder: {
                            Color.gray.opacity(0.2).frame(height: 80).cornerRadius(8)
                        }
                    }
                }

                if !isMine && isPending {
                    Button("Responder") { showRespond = true }
                        .buttonStyle(.borderedProminent).tint(levelColor).controlSize(.small).frame(maxWidth: .infinity)
                }
            }
        }
        .sheet(isPresented: $showRespond) {
            RespondView(challengeId: c["id"] as? String ?? "", content: content, photoUrl: photoUrl, senderName: senderName, levelColor: levelColor, gamesRef: gamesRef, myName: myName, myUid: myUid, theme: theme)
        }
    }
}

// MARK: - Respond View

private struct RespondView: View {
    let challengeId: String
    let content: String
    let photoUrl: String
    let senderName: String
    let levelColor: Color
    let gamesRef: CollectionReference
    let myName: String
    let myUid: String
    let theme: ThemeManager
    @State private var textResponse = ""
    @State private var responseImage: UIImage?
    @State private var showPicker = false
    @State private var uploading = false
    @State private var responding = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                ScrollView {
                    VStack(spacing: 16) {
                        GlassCard(cornerRadius: 16) {
                            Text(content).appFont(size: 14).foregroundColor(theme.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tu respuesta...").appFont(size: 13, weight: .semibold).foregroundColor(.secondary)
                            TextEditor(text: $textResponse).frame(minHeight: 80).padding(8).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.3)))
                        }

                        if let img = responseImage {
                            Image(uiImage: img).resizable().scaledToFit().frame(height: 120).clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            Button("Agregar foto 📸") { showPicker = true }
                                .buttonStyle(.bordered).tint(.secondary)
                        }

                        if responding { ProgressView("Enviando respuesta...").appFont(size: 13) }

                        Button("Enviar respuesta") { sendResponse() }
                            .buttonStyle(.borderedProminent).tint(levelColor)
                            .disabled((textResponse.trimmingCharacters(in: .whitespaces).isEmpty && responseImage == nil) || responding)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Responder a \(senderName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } } }
            .sheet(isPresented: $showPicker) { ImagePicker(sourceType: .camera) { img in responseImage = img } }
        }
    }

    private func sendResponse() {
        responding = true
        Task {
            var fields: [String: Any] = ["status": "responded", "responseTimestamp": FieldValue.serverTimestamp()]
            let text = textResponse.trimmingCharacters(in: .whitespaces)
            if !text.isEmpty { fields["response"] = text }
            if let img = responseImage, let data = img.jpegData(compressionQuality: 0.6) {
                let b64 = data.base64EncodedString()
                let mid = UUID().uuidString
            try? await Firestore.firestore().document("chat_media/\(mid)").setData(["data": b64, "mimeType": "image/jpeg"])
                fields["responsePhotoUrl"] = "firestore://chat_media/\(mid)"
            }
            try? await gamesRef.document(challengeId).updateData(fields)
            let cid = [CoupleService.diegoUid, CoupleService.yosmariUid].sorted().joined(separator: "_")
            try? await Firestore.firestore().collection("couples").document(cid).collection("activities").addDocument(data: [
                "text": "Respondió al reto con: \"\(textResponse.prefix(50))\" 🌶️💌",
                "type": "game", "icon": "game", "timestamp": FieldValue.serverTimestamp()
            ])
            await MainActor.run { dismiss() }
        }
    }
}


