//
//  UnifiedTileView.swift
//  Bandz
//
//  Created by Felipe Canhameiro on 23/06/25.
//

import SwiftUI
import NukeUI


// MARK: - PlaceImageShimmer Component

struct PlaceImageShimmer: View {
    let title: String
    @SwiftUI.Environment(\.colorScheme) private var colorScheme
    @State private var animationOffset: CGFloat = -1
    @State private var isAnimating: Bool = false

    private var shimmerFill: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.10)
            : Color.white.opacity(0.35)
    }

    private var shimmerStroke: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.15)
            : Color.white.opacity(0.4)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background glass effect - mesmo padrao do card
                Circle()
                    .fill(shimmerFill)
                    .overlay(
                        Circle()
                            .stroke(shimmerStroke, lineWidth: 1)
                    )
                    .overlay(
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0),
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.5),
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * 0.6)
                            .offset(x: animationOffset * geometry.size.width * 1.8)
                            .blendMode(.overlay)
                    )
                    .clipShape(Circle())
                    .onAppear {
                        guard !isAnimating else { return }
                        isAnimating = true
                        animationOffset = -1
                        Logger.shared.debug("Shimmer starting animation for \(title)", context: "UnifiedTileView")
                        withAnimation(
                            .linear(duration: 1.8)
                            .repeatForever(autoreverses: false)
                        ) {
                            animationOffset = 1.0
                        }
                    }
                    .onDisappear {
                        isAnimating = false
                        animationOffset = -1
                    }

                // Nome do place
                VStack {
                    Spacer()
                    Text(title)
                        .caption()
                        .bandzForegroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal, SpacingSystem.Size.xxs)
                    Spacer()
                }
            }
        }
    }
}

// MARK: - TileType Enum

enum TileType {
    case genre(Color, fallbackImage: String = "bandz_place_holder")     // Genres: borda colorida + fallback
    case place(fallbackImage: String = "bandz_place_holder")            // Places: borda padrão + fallback
    case streaming(Color, fallbackImage: String = "bandz_place_holder") // Streaming: borda colorida + fallback
    
    var isPlace: Bool {
        switch self {
        case .place:
            return true
        default:
            return false
        }
    }
}

// MARK: - Tile Visual Source
enum TileVisual {
    case asset(String)
    case url(String)
    case calendarDay(Int)
    case location(animate: Bool)
    case calendar
}

// MARK: - Tile Size Variant
enum TileSize {
    case regular
    case compact
}

enum TileActionMode {
    case selection    // Toggle on/off (genres, places)
    case button       // Ação única (streaming)
}

// MARK: - UnifiedTileView

struct UnifiedTileView: View {
    let title: String
    let subtitle: String?
    let imageName: String
    let tileType: TileType
    let actionMode: TileActionMode
    let isSelected: Bool
    let isAnimating: Bool
    let animationDelay: Double
    let showDistance: Bool
    let distanceText: String?
    let visualOverride: TileVisual? // Optional override (asset or URL)
    let size: TileSize // Size variant (regular or compact)
    let onTap: () -> Void
    
    @State private var isPressed = false
    @State private var tileAnimating = true
    @SwiftUI.Environment(\.colorScheme) private var colorScheme
    
    let imageSize: CGFloat = 1.6

    // MARK: - Size Metrics
    private var circleDiameter: CGFloat {
        switch size {
        case .regular: return SpacingSystem.Size.xxxl * 2
        case .compact: return SpacingSystem.Size.xxl * 1.6
        }
    }

    private var imageSide: CGFloat {
        switch size {
        case .regular: return SpacingSystem.Size.xxxl * imageSize
        case .compact: return SpacingSystem.Size.xxl * 1.25
        }
    }

    private var cardHeight: CGFloat {
        switch size {
        case .regular:
            return subtitle != nil ? SpacingSystem.Size.xxxl * 4 : SpacingSystem.Size.xxxl * 3.5
        case .compact:
            return subtitle != nil ? SpacingSystem.Size.xxl * 3.6 : SpacingSystem.Size.xxl * 3.1
        }
    }
    
    /// Retorna a cor da borda baseada no TileType
    private var borderColor: Color {
        switch tileType {
            case .genre(let color, _):
                return color  // Genres: cor da collection
            case .place(_):
                return ColorSystem.Icon.primary  // Places: cor padrão
            case .streaming(let color, _):
                return color  // Streaming: cor específica do serviço
        }
    }
    
    // MARK: - Explicit initializer to expose optional params
    init(
        title: String,
        subtitle: String?,
        imageName: String,
        tileType: TileType,
        actionMode: TileActionMode,
        isSelected: Bool,
        isAnimating: Bool,
        animationDelay: Double,
        showDistance: Bool,
        distanceText: String?,
        visualOverride: TileVisual? = nil,
        size: TileSize = .regular,
        onTap: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.imageName = imageName
        self.tileType = tileType
        self.actionMode = actionMode
        self.isSelected = isSelected
        self.isAnimating = isAnimating
        self.animationDelay = animationDelay
        self.showDistance = showDistance
        self.distanceText = distanceText
        self.visualOverride = visualOverride
        self.size = size
        self.onTap = onTap
    }

    // MARK: - Computed Card Styles
    private var cardFill: Color {
        colorScheme == .dark
            ? ColorSystem.System.surface1.opacity(0.85)
            : Color.white.opacity(0.4)
    }

    private var cardStroke: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.10)
            : Color.white.opacity(0.25)
    }

    private var glowColor: Color {
        isSelected && colorScheme == .dark
            ? borderColor.opacity(0.45)
            : Color.clear
    }

    private var circleBackgroundColor: Color {
        switch tileType {
        case .streaming:
            return colorScheme == .dark
                ? Color.white.opacity(0.08)
                : Color.white.opacity(isSelected ? 0.5 : 0.25)
        default:
            return Color.white.opacity(isSelected ? 0.5 : 0.3)
        }
    }

    /// Retorna a imagem de fallback baseada no TileType
    private var fallbackImageName: String {
        switch tileType {
            case .genre(_, let fallbackImage):
                return fallbackImage
            case .place(let fallbackImage):
                return fallbackImage
            case .streaming(_, let fallbackImage):
                return fallbackImage
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: SpacingSystem.Size.md) {
                // Image Container
                ZStack {
                    // Background circle - neutral when not selected, colored when selected
                    Circle()
                        .fill(circleBackgroundColor)
                        .frame(width: circleDiameter, height: circleDiameter)
                    
                    // Image with fallback to bandz logo
                    Group {
                        // If override provided, respect it regardless of tile type
                        if let visual = visualOverride {
                            switch visual {
                            case .asset(let name):
                                if UIImage(named: name) != nil {
                                    Image(name)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: imageSide, height: imageSide)
                                        .clipShape(Circle())
                                } else {
                                    Image(fallbackImageName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: imageSide, height: imageSide)
                                        .clipShape(Circle())
                                }
                            case .calendarDay(let day):
                                // Render a simple calendar badge with the day number
                                VStack(spacing: 4) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: imageSide * 0.28, weight: .semibold))
                                        .foregroundStyle(ColorSystem.Text.primary)
                                        .minimumScaleFactor(0.5)
                                    Text("\(day)")
                                        .font(.system(size: imageSide * 0.6, weight: .bold))
                                        .foregroundStyle(ColorSystem.Text.primary)
                                        .minimumScaleFactor(0.5)
                                }
                                .frame(width: imageSide, height: imageSide)
                                .clipShape(Circle())
                            case .calendar:
                                Image(systemName: "calendar")
                                    .font(.system(size: imageSide * 0.62, weight: .semibold))
                                    .foregroundStyle(ColorSystem.Text.primary)
                                    .frame(width: imageSide, height: imageSide)
                                    .clipShape(Circle())
                            case .location(let animate):
                                LocationSymbol(size: imageSide, animate: animate)
                            case .url(let urlString):
                                TileRemoteImage(
                                    urlString: urlString,
                                    title: title,
                                    imageSize: imageSide,
                                    fallbackImageName: fallbackImageName
                                )
                            }
                        } else {
                            switch tileType {
                            case .genre, .streaming:
                                // Genres & Streaming: Asset local do catalog com fallback
                                if UIImage(named: imageName) != nil {
                                    // Asset existe
                                    Image(imageName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: imageSide, height: imageSide)
                                        .clipShape(Circle())
                                } else {
                                    // Asset não existe, usar fallback
                                    Image(fallbackImageName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: imageSide, height: imageSide)
                                        .clipShape(Circle())
                                }
                            case .place:
                                TileRemoteImage(
                                    urlString: imageName,
                                    title: title,
                                    imageSize: imageSide,
                                    fallbackImageName: fallbackImageName
                                )
                        }
                        }
                    }
                    .overlay(
                        Circle()
                            .stroke(
                                isSelected ? borderColor : Color.clear,
                                lineWidth: 3
                            )
                    )
                    .overlay(alignment: .bottom) {
                        // Distance tag centralizada no bottom do círculo
                        if showDistance, let distanceText = distanceText, tileType.isPlace {
                            Text(distanceText)
                                .micro()
                                .foregroundStyle(.white)
                                .padding(.horizontal, SpacingSystem.Size.xxs + SpacingSystem.Size.xxxs)
                                .padding(.vertical, SpacingSystem.Size.xxxs)
                                .background(
                                    Capsule()
                                        .fill(Color.black.opacity(0.75))
                                )
                                .offset(y: SpacingSystem.Size.xs)
                        }
                    }
                }
                
                // Title
                Text(title)
                    .bodyEmphasized(alignment: .center)
                    .bandzForegroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.horizontal, SpacingSystem.Size.xs)
                
                // Subtitle (conditional)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .hashtag(color: ColorSystem.Text.subtitle, alignment: .center)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: cardHeight)
            .background(
                RoundedRectangle(cornerRadius: SpacingSystem.CornerRadius.large)
                    .fill(cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: SpacingSystem.CornerRadius.large)
                            .stroke(cardStroke, lineWidth: 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: SpacingSystem.CornerRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: SpacingSystem.CornerRadius.large)
                    .strokeBorder(
                        isSelected ? borderColor : Color.clear,
                        lineWidth: 2
                    )
            )
            .scaleEffect(isPressed ? 0.96 : (isSelected ? 1.02 : 1.0))
            .elevation(isSelected ? .medium : .subtle)
            .shadow(color: glowColor, radius: 18, x: 0, y: 0)
            .overlay(alignment: .topTrailing) {
                // Selection Indicator - apenas para modo selection
                if actionMode == .selection && isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: LayoutSystem.ElementSize.smallIcon, weight: .semibold))
                        .foregroundStyle(borderColor)
                        .background(
                            Circle()
                                .fill(ColorSystem.Icon.backgroundPrimary)
                                .frame(width: LayoutSystem.ElementSize.smallIcon * 0.65, height: LayoutSystem.ElementSize.smallIcon * 0.65)
                        )
                        .offset(x: SpacingSystem.Size.xxs + SpacingSystem.Size.xxxs, y: -(SpacingSystem.Size.xxs + SpacingSystem.Size.xxxs))
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(tileAnimating ? 1.0 : 0.9)
        .opacity(tileAnimating ? 1.0 : 0.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onAppear {
            // Maximum stagger delay for the initial entrance animation.
            // Tiles beyond this threshold are off-screen (scrolled) and should appear instantly
            // to avoid the "pop-in" effect when the user scrolls during the entrance animation.
            let maxStaggerDelay: Double = 0.6

            if !isAnimating || animationDelay > maxStaggerDelay {
                tileAnimating = true
            } else {
                tileAnimating = false
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(animationDelay))
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        tileAnimating = true
                    }
                }
            }
        }
        .onTapGesture {
            // Haptic feedback on press
            HapticManager.shared.impact(style: .light)

            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }

            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(100))
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                onTap()
            }
        }
    }
    
}

// MARK: - Tile Remote Image

private struct TileRemoteImage: View {
    let urlString: String
    let title: String
    let imageSize: CGFloat
    let fallbackImageName: String

    var body: some View {
        if let imageURL = URL(string: urlString) {
            let _ = Logger.shared.debug("Loading image URL: \(urlString)", context: "UnifiedTileView")
            LazyImage(url: imageURL) { state in
                if let image = state.image {
                    let _ = Logger.shared.debug("Image loaded successfully for \(title)", context: "UnifiedTileView")
                    image.resizable().scaledToFill()
                } else if state.error != nil {
                    let _ = Logger.shared.error("Image not found for \(title) - using fallback", context: "UnifiedTileView")
                    Image(fallbackImageName)
                        .resizable()
                        .scaledToFit()
                } else {
                    PlaceImageShimmer(title: title)
                }
            }
            .frame(width: imageSize, height: imageSize)
            .clipShape(Circle())
            .contentShape(Circle())
        } else {
            let _ = Logger.shared.warning("Invalid URL for \(title): '\(urlString)'", context: "UnifiedTileView")
            Image(fallbackImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: imageSize, height: imageSize)
                .clipShape(Circle())
        }
    }
}

// MARK: - Location Symbol
private struct LocationSymbol: View {
    let size: CGFloat
    let animate: Bool
    @State private var pulse = false

    var body: some View {
        ZStack {
            Image(systemName: "location.fill")
                .font(.system(size: size * 0.6, weight: .bold))
                .foregroundStyle(ColorSystem.Text.primary)
                .scaleEffect(animate ? (pulse ? 1.08 : 0.92) : 1.0)
                .opacity(animate ? (pulse ? 1.0 : 0.82) : 1.0)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .onAppear {
            guard animate else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}





// MARK: - Preview
#Preview {
    VStack {
        // Exemplo com Genre
        UnifiedTileView(
            title: "Rock",
            subtitle: "Alternative • Indie",
            imageName: "rock_icon",
            tileType: .genre(Color.red),
            actionMode: .selection,
            isSelected: true,
            isAnimating: true,
            animationDelay: 0.0,
            showDistance: false,
            distanceText: nil
        ) {
            print("Genre tapped")
        }
        
        // Exemplo com Place
        UnifiedTileView(
            title: "Grainne's",
            subtitle: nil,
            imageName: "https://example.com/grainnes.jpg",
            tileType: .place(),
            actionMode: .selection,
            isSelected: true,
            isAnimating: true,
            animationDelay: 0.1,
            showDistance: true,
            distanceText: "1.2km"
        ) {
            print("Place tapped")
        }
        
        // Exemplo com Streaming (Button)
        UnifiedTileView(
            title: "Spotify",
            subtitle: nil,
            imageName: "spotify_logo",
            tileType: .streaming(.green),
            actionMode: .button,
            isSelected: true,
            isAnimating: true,
            animationDelay: 0.2,
            showDistance: false,
            distanceText: nil
        ) {
            print("Connect to Spotify")
        }
    }
    .padding()
    .padding(.horizontal, 80)
    .background(Color.green.opacity(0.1))
}
