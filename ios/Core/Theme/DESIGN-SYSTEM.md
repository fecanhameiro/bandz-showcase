# Bandz Design System

This document provides a comprehensive guide to using the Bandz design system, which ensures consistency and maintainability across the app.

## Table of Contents

1. [Introduction](#introduction)
2. [Core Systems](#core-systems)
   - [Spacing System](#spacing-system)
   - [Typography System](#typography-system)
   - [Color System](#color-system)
   - [Layout System](#layout-system)
   - [Elevation System](#elevation-system)
3. [UI Components](#ui-components)
   - [Basic Components](#basic-components)
   - [Music Components](#music-components)
4. [Theme Controller](#theme-controller)
5. [Usage Guidelines](#usage-guidelines)
6. [Examples](#examples)

## Introduction

The Bandz design system provides a consistent set of tools, components, and guidelines for building user interfaces across the app. It consists of core systems for spacing, typography, color, layout, and elevation, as well as a comprehensive set of UI components built on these systems.

## Core Systems

### Spacing System

The spacing system defines standardized spacing values to ensure consistent spacing throughout the app. All spacing values are derived from a base unit to maintain a harmonious visual rhythm.

**Key Features**:
- Consistent scaling with values: 2, 4, 8, 12, 16, 24, 32, 40, 48, 64
- Standardized padding configurations (small, medium, large)
- Consistent corner radiuses
- View extensions for applying spacing

**Usage**:
```swift
// Apply spacing to a view
Text("Hello")
    .padding(.vertical, SpacingSystem.spacing(.medium))
    .padding(.horizontal, SpacingSystem.spacing(.large))

// Use padding presets
VStack {
    // Content
}
.padding(SpacingSystem.Padding.medium)

// Apply corner radius
Rectangle()
    .cornerRadius(SpacingSystem.CornerRadius.medium)
```

### Typography System

The typography system ensures consistent text styling throughout the app by defining a set of text styles with predefined font families, sizes, weights, and line heights.

**Key Features**:
- Text style hierarchy (h1, h2, h3, subtitle, body, caption, etc.)
- Consistent font sizes and weights
- Line height standardization
- View extensions for applying typography

**Usage**:
```swift
// Apply typography to text
Text("Hello")
    .typography(.title)

// Use BandzText component for standardized text
BandzText("Hello", style: .title)
```

### Color System

The color system defines a set of semantic colors with variations to ensure consistent color usage throughout the app. Colors are defined in the asset catalog with appropriate light and dark mode variations.

**Key Features**:
- Semantic color naming (primary, secondary, accent, etc.)
- Color variations with different opacity levels
- Gradient definitions
- View extensions for applying colors

**Usage**:
```swift
// Apply color to a view
Text("Hello")
    .bandzForegroundStyle(.primary)

// Apply gradient background
Rectangle()
    .primaryGradientBackground()
```

### Layout System

The layout system provides tools for creating responsive layouts that adapt to different screen sizes and orientations.

**Key Features**:
- Screen size-based adaptations
- Consistent content width
- Responsive padding
- View extensions for applying layouts

**Usage**:
```swift
// Apply responsive layout
VStack {
    // Content
}
.responsiveLayout()
```

### Elevation System

The elevation system defines standardized shadow and elevation styles to create visual hierarchy and depth in the UI.

**Key Features**:
- Standardized elevation levels (none, low, medium, high)
- Consistent shadow properties
- View extensions for applying elevation

**Usage**:
```swift
// Apply elevation to a view
Rectangle()
    .elevation(.medium)
```

## UI Components

### Basic Components

The BandzUIKit provides a set of standardized UI components built on top of the core systems:

1. **BandzText**: Standardized text component with built-in typography styles
2. **BandzContainer**: Standardized container with consistent padding and styling
3. **BandzVStack/BandzHStack**: Standardized stack components with consistent spacing
4. **BandzTextField**: Standardized text field with validation
5. **BandzCard**: Standardized card component with various styles
6. **BandzListItem**: Standardized list item component

**Usage**:
```swift
// Text component
BandzText("Hello", style: .title)

// Container component
BandzContainer {
    Text("Content")
}

// Card component
BandzCard(style: .elevated) {
    Text("Card content")
}
```

### Music Components

Specialized UI components for music and artist-related functionality:

1. **BandzStreamingServiceCard**: For displaying music streaming services
2. **BandzGenreCard**: For displaying music genres
3. **BandzArtistCard**: For displaying artist information
4. **BandzTrackListItem**: For displaying music tracks
5. **BandzPlayerControls**: For music player controls
6. **BandzEventCard**: For displaying music events

**Usage**:
```swift
// Streaming service card
BandzStreamingServiceCard(
    service: .spotify,
    isSelected: true
) {
    // Selection action
}

// Genre card
BandzGenreCard(
    genre: .rock,
    isSelected: false
) {
    // Selection action
}

// Track list item
BandzTrackListItem(
    title: "Song Title",
    artist: "Artist Name",
    duration: "3:45"
) {
    // Selection action
}
```

## Theme Controller

The BandzThemeController provides a centralized way to manage theme settings and apply them consistently across the app.

**Key Features**:
- Color scheme management (light/dark)
- Font size scaling
- Haptic feedback settings
- Responsive padding based on device size
- Shadow generation based on elevation
- View extensions for applying theme settings

**Usage**:
```swift
// Access the theme controller
@Environment(\.themeController) private var themeController

// Generate haptic feedback
themeController.generateHapticFeedback(.medium)

// Apply scaled font
Text("Hello")
    .scaledFont(.title)

// Apply responsive padding
VStack {
    // Content
}
.bandzResponsivePadding()
```

## Usage Guidelines

1. **Always use the design system components**: Avoid creating custom styles or components when a design system equivalent exists.

2. **Maintain semantic meaning**: Use colors and typography based on their semantic meaning, not their appearance.

3. **Respect spacing guidelines**: Use the predefined spacing values rather than custom values.

4. **Ensure responsiveness**: Use the responsive layout tools to ensure the UI adapts well to different screen sizes.

5. **Follow accessibility guidelines**: Ensure text meets minimum size requirements and color contrast ratios.

## Examples

### Basic Screen Layout

```swift
struct ExampleView: View {
    var body: some View {
        BandzContainer {
            BandzVStack(spacing: SpacingSystem.spacing(.large)) {
                BandzText("Welcome", style: .title)
                    .bandzForegroundStyle(.primary)
                
                BandzCard {
                    BandzText("This is a card component", style: .body)
                        .bandzForegroundStyle(.secondary)
                }
                
                BandzButton("Continue", style: .primary) {
                    // Action
                }
            }
        }
        .responsiveLayout()
        .primaryGradientBackground()
    }
}
```

### Music Genre Selection

```swift
struct GenreSelectionView: View {
    @State private var selectedGenres: Set<BandzGenreCard.Genre> = []
    
    var body: some View {
        ScrollView {
            BandzVStack(spacing: SpacingSystem.spacing(.medium)) {
                BandzText("Select Your Favorite Genres", style: .title2)
                
                ForEach(BandzGenreCard.Genre.allCases, id: \.self) { genre in
                    BandzGenreCard(
                        genre: genre,
                        isSelected: selectedGenres.contains(genre)
                    ) {
                        toggleGenre(genre)
                    }
                }
                
                BandzButton("Continue", style: .primary) {
                    // Continue action
                }
                .padding(.top, SpacingSystem.spacing(.large))
            }
            .padding(SpacingSystem.Padding.large)
        }
        .responsiveLayout()
    }
    
    private func toggleGenre(_ genre: BandzGenreCard.Genre) {
        if selectedGenres.contains(genre) {
            selectedGenres.remove(genre)
        } else {
            selectedGenres.insert(genre)
        }
        BandzThemeController.shared.generateSelectionFeedback()
    }
}
```