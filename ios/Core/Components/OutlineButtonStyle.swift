import SwiftUI

/// Estilo de botão com bordas (outline) para o app
struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.white, lineWidth: 2)
            )
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Componente de botão outline para onboarding
struct OutlineButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
        }
        .buttonStyle(OutlineButtonStyle())
    }
}

/// Extensão para acesso ao estilo de botão
extension ButtonStyle where Self == OutlineButtonStyle {
    /// Retorna um estilo de botão com bordas brancas
    static var outline: OutlineButtonStyle {
        OutlineButtonStyle()
    }
}

// MARK: - Preview
struct OutlineButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient.primaryGradientBandz.ignoresSafeArea()
            
            VStack(spacing: 20) {
                OutlineButton(title: "Iniciar", action: {
                    print("Botão pressionado")
                })
                
                Button("Outro Estilo") {
                    print("Botão pressionado")
                }
                .buttonStyle(.outline)
            }
            .padding()
        }
    }
}
