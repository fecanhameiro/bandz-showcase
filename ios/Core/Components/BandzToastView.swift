import SwiftUI

struct BandzToastView: View {
    let toast: BandzToast
    @SwiftUI.Environment(ToastCenter.self) private var center: ToastCenter?
    @SwiftUI.Environment(\.colorScheme) private var colorScheme
    @SwiftUI.Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var style: BandzToastStyle { toast.kind.style }

    var body: some View {
        let title = localized(toast.titleKey, args: toast.titleArgs)
        let message = toast.messageKey.map { localized($0, args: toast.messageArgs) }
        HStack(alignment: .top, spacing: SpacingSystem.Size.sm) {
            Image(systemName: toast.icon ?? style.icon)
                .foregroundColor(style.iconColor)
            VStack(alignment: .leading, spacing: SpacingSystem.Size.xxxs) {
                Text(title)
                    .bodyMedium()
                    .bandzForegroundStyle(.primary)
                if let message {
                    Text(message)
                        .bodyRegular()
                        .foregroundColor(ColorSystem.Text.primary.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer()
            Button {
                center?.dismiss(id: toast.id)
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(ColorSystem.Text.primary.opacity(0.7))
            }
            .accessibilityLabel(Text("toast.generic.dismiss"))
        }
        .padding(SpacingSystem.Inset.card)
        .background(background)
        .overlay(border)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
        .onTapGesture { toast.onTap?() }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.translation.height < -20 {
                        center?.dismiss(id: toast.id)
                    }
                }
        )
        .allowsHitTesting(true)
        .accessibilityLabel(accessibilityLabel(title: title, message: message))
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: SpacingSystem.CornerRadius.large)
            .fill(.ultraThinMaterial.opacity(0.8))
            .overlay(
                RoundedRectangle(cornerRadius: SpacingSystem.CornerRadius.large)
                    .fill(style.backgroundColor)
            )
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: SpacingSystem.CornerRadius.large)
            .stroke(style.borderColor, lineWidth: 1)
    }

    private func localized(_ key: String, args: [CVarArg]) -> String {
        String(format: NSLocalizedString(key, comment: ""), arguments: args)
    }

    private func accessibilityLabel(title: String, message: String?) -> Text {
        if let override = toast.accessibilityOverride {
            return Text(override)
        }
        let combined = [title, message].compactMap { $0 }.joined(separator: " ")
        return Text(combined)
    }
}

#if DEBUG
struct BandzToastView_Previews: PreviewProvider {
    static let center = ToastCenter()

    static let successToast = BandzToast(
        kind: .success,
        titleKey: "Sucesso!",
        messageKey: "Operação concluída com êxito.",
        ttl: .infinity,
        haptics: nil
    )

    static let errorToast = BandzToast(
        kind: .error,
        titleKey: "Erro",
        messageKey: "Não foi possível completar a ação.",
        ttl: .infinity,
        haptics: nil
    )

    static let longToast = BandzToast(
        kind: .success,
        titleKey: "Download finalizado",
        messageKey: "Seu conteúdo foi baixado e está disponível offline. Você pode acessá-lo a qualquer momento na aba Biblioteca.",
        ttl: .infinity,
        haptics: nil
    )

    static var previews: some View {
        Group {
            previewStack
                .preferredColorScheme(.light)
                .previewDisplayName("Light")

            previewStack
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark")

            previewStackLargeText
                .preferredColorScheme(.light)
                .previewDisplayName("Large Text")
        }
    }

    private static var previewStack: some View {
        GradientBackgroundView{
            ZStack(alignment: .top) {
             
                VStack(spacing: SpacingSystem.Size.sm) {
                    BandzToastView(toast: successToast)
                        .environment(center)
                    BandzToastView(toast: errorToast)
                        .environment(center)
                }
                .padding(.top, 20)
                .padding(.horizontal, SpacingSystem.Inset.card)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
    }

    private static var previewStackLargeText: some View {
        ZStack(alignment: .top) {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: SpacingSystem.Size.sm) {
                BandzToastView(toast: longToast)
                    .environment(center)
            }
            .padding(.top, 20)
            .padding(.horizontal, SpacingSystem.Inset.card)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .environment(\.sizeCategory, .accessibilityExtraLarge)
    }
}
#endif
