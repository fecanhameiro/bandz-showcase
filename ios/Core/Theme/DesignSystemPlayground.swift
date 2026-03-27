// 
// DesignSystemPlayground.swift
// Bandz
//
// This file provides examples of how to use the design system components.
// It's not part of the main app build, but serves as a reference and playground
// for developers working with the design system.
//

import SwiftUI

// MARK: - Typography Examples

struct TypographyExamplesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SpacingSystem.Size.lg) {
                BandzText("Typography System", style: Typography.TextStyle.h1)
                    .padding(.bottom, SpacingSystem.Size.md)
                
                Group {
                    BandzText("Title Style (H1)", style: Typography.TextStyle.h1)
                    BandzText("Title2 Style (H2)", style: Typography.TextStyle.h2)
                    BandzText("Title3 Style (H3)", style: Typography.TextStyle.h3)
                    BandzText("Subtitle Style", style: Typography.TextStyle.subtitle)
                    BandzText("Body Style: The quick brown fox jumps over the lazy dog.", style: Typography.TextStyle.bodyRegular)
                    BandzText("Caption Style: The quick brown fox jumps over the lazy dog.", style: Typography.TextStyle.caption)
                }
                
                Divider().padding(.vertical, SpacingSystem.Size.md)
                
                BandzText("With Custom Colors", style: Typography.TextStyle.h3)
                    .padding(.bottom, SpacingSystem.Size.sm)
                
                Group {
                    BandzText("Primary Color", style: Typography.TextStyle.bodyRegular)
                        .foregroundColor(Color("Primary"))
                    
                    BandzText("Secondary Color", style: Typography.TextStyle.bodyRegular)
                        .foregroundColor(Color("Secondary"))
                    
                    BandzText("Accent Color", style: Typography.TextStyle.bodyRegular)
                        .foregroundColor(Color("Accent"))
                }
            }
            .padding(EdgeInsets(
                top: SpacingSystem.Size.lg,
                leading: SpacingSystem.Size.lg,
                bottom: SpacingSystem.Size.lg,
                trailing: SpacingSystem.Size.lg
            ))
        }
    }
}

// MARK: - Spacing Examples

struct SpacingExamplesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SpacingSystem.Size.lg) {
                BandzText("Spacing System", style: Typography.TextStyle.h1)
                    .padding(.bottom, SpacingSystem.Size.md)
                
                // Spacing blocks
                Group {
                    VStack(alignment: .leading, spacing: SpacingSystem.Size.xxs) {
                        BandzText("XXSmall (2pt)", style: Typography.TextStyle.caption)
                        
                        Rectangle()
                            .fill(Color("Accent"))
                            .frame(width: SpacingSystem.Size.xxxs, height: 20)
                    }
                    
                    VStack(alignment: .leading, spacing: SpacingSystem.Size.xxs) {
                        BandzText("XSmall (4pt)", style: Typography.TextStyle.caption)
                        
                        Rectangle()
                            .fill(Color("Accent"))
                            .frame(width: SpacingSystem.Size.xxs, height: 20)
                    }
                    
                    VStack(alignment: .leading, spacing: SpacingSystem.Size.xxs) {
                        BandzText("Small (8pt)", style: Typography.TextStyle.caption)
                        
                        Rectangle()
                            .fill(Color("Accent"))
                            .frame(width: SpacingSystem.Size.xs, height: 20)
                    }
                    
                    VStack(alignment: .leading, spacing: SpacingSystem.Size.xxs) {
                        BandzText("Medium (16pt)", style: Typography.TextStyle.caption)
                        
                        Rectangle()
                            .fill(Color("Accent"))
                            .frame(width: SpacingSystem.Size.md, height: 20)
                    }
                    
                    VStack(alignment: .leading, spacing: SpacingSystem.Size.xxs) {
                        BandzText("Large (24pt)", style: Typography.TextStyle.caption)
                        
                        Rectangle()
                            .fill(Color("Accent"))
                            .frame(width: SpacingSystem.Size.lg, height: 20)
                    }
                    
                    VStack(alignment: .leading, spacing: SpacingSystem.Size.xxs) {
                        BandzText("XLarge (32pt)", style: Typography.TextStyle.caption)
                        
                        Rectangle()
                            .fill(Color("Accent"))
                            .frame(width: SpacingSystem.Size.xl, height: 20)
                    }
                    
                    VStack(alignment: .leading, spacing: SpacingSystem.Size.xxs) {
                        BandzText("XXLarge (48pt)", style: Typography.TextStyle.caption)
                        
                        Rectangle()
                            .fill(Color("Accent"))
                            .frame(width: SpacingSystem.Size.xxxl, height: 20)
                    }
                }
                
                Divider().padding(.vertical, SpacingSystem.Size.md)
                
                BandzText("Padding Presets", style: Typography.TextStyle.h3)
                    .padding(.bottom, SpacingSystem.Size.sm)
                
                // Padding examples
                Group {
                    VStack(alignment: .leading, spacing: SpacingSystem.Size.xxs) {
                        BandzText("Small Padding", style: Typography.TextStyle.caption)
                        
                        Text("Content")
                            .padding(EdgeInsets(top: SpacingSystem.Size.xs, leading: SpacingSystem.Size.xs, bottom: SpacingSystem.Size.xs, trailing: SpacingSystem.Size.xs))
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(SpacingSystem.CornerRadius.small)
                    }
                    .padding(.bottom, SpacingSystem.Size.sm)
                    
                    VStack(alignment: .leading, spacing: SpacingSystem.Size.xxs) {
                        BandzText("Medium Padding", style: Typography.TextStyle.caption)
                        
                        Text("Content")
                            .padding(EdgeInsets(top: SpacingSystem.Size.md, leading: SpacingSystem.Size.md, bottom: SpacingSystem.Size.md, trailing: SpacingSystem.Size.md))
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(SpacingSystem.CornerRadius.small)
                    }
                    .padding(.bottom, SpacingSystem.Size.sm)
                    
                    VStack(alignment: .leading, spacing: SpacingSystem.Size.xxs) {
                        BandzText("Large Padding", style: Typography.TextStyle.caption)
                        
                        Text("Content")
                            .padding(EdgeInsets(top: SpacingSystem.Size.lg, leading: SpacingSystem.Size.lg, bottom: SpacingSystem.Size.lg, trailing: SpacingSystem.Size.lg))
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(SpacingSystem.CornerRadius.small)
                    }
                    .padding(.bottom, SpacingSystem.Size.sm)
                }
                
                Divider().padding(.vertical, SpacingSystem.Size.md)
                
                BandzText("Corner Radius", style: Typography.TextStyle.h3)
                    .padding(.bottom, SpacingSystem.Size.sm)
                
                // Corner radius examples
                Group {
                    VStack(alignment: .leading, spacing: SpacingSystem.Size.xxs) {
                        BandzText("Small Radius", style: Typography.TextStyle.caption)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 100, height: 50)
                            .cornerRadius(SpacingSystem.CornerRadius.small)
                    }
                    .padding(.bottom, SpacingSystem.Size.sm)
                    
                    VStack(alignment: .leading, spacing: SpacingSystem.Size.xxs) {
                        BandzText("Medium Radius", style: Typography.TextStyle.caption)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 100, height: 50)
                            .cornerRadius(SpacingSystem.CornerRadius.medium)
                    }
                    .padding(.bottom, SpacingSystem.Size.sm)
                    
                    VStack(alignment: .leading, spacing: SpacingSystem.Size.xxs) {
                        BandzText("Large Radius", style: Typography.TextStyle.caption)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 100, height: 50)
                            .cornerRadius(SpacingSystem.CornerRadius.large)
                    }
                    .padding(.bottom, SpacingSystem.Size.sm)
                }
            }
            .padding(EdgeInsets(
                top: SpacingSystem.Size.lg,
                leading: SpacingSystem.Size.lg,
                bottom: SpacingSystem.Size.lg,
                trailing: SpacingSystem.Size.lg
            ))
        }
    }
}

// MARK: - Color Examples

struct ColorExamplesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SpacingSystem.Size.lg) {
                BandzText("Color System", style: Typography.TextStyle.h1)
                    .padding(.bottom, SpacingSystem.Size.md)
                
                // Primary colors
                VStack(alignment: .leading, spacing: SpacingSystem.Size.md) {
                    BandzText("Primary Colors", style: Typography.TextStyle.h3)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: SpacingSystem.Size.md) {
                        colorSwatch(name: "Primary", color: Color("Primary"))
                        colorSwatch(name: "Secondary", color: Color("Secondary"))
                        colorSwatch(name: "Accent", color: Color("Accent"))
                       // colorSwatch(name: "BackgroundPrimary", color: Color("BackgroundPrimary"))
                    }
                }
                
                Divider().padding(.vertical, SpacingSystem.Size.md)
                
                // Text colors
                VStack(alignment: .leading, spacing: SpacingSystem.Size.md) {
                    BandzText("Text Colors", style: Typography.TextStyle.h3)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: SpacingSystem.Size.md) {
                        colorSwatch(name: "TextPrimary", color: Color("TextPrimary"))
                        colorSwatch(name: "TextSecondary", color: Color("TextSecondary"))
                    }
                }
                
                Divider().padding(.vertical, SpacingSystem.Size.md)
                
                // Gradients
                VStack(alignment: .leading, spacing: SpacingSystem.Size.md) {
                    BandzText("Gradients", style: Typography.TextStyle.h3)
                    
                    VStack(spacing: SpacingSystem.Size.md) {
                        gradientSwatch(
                            name: "Primary Gradient",
                            colors: [
                                Color("GradientPrimaryTopLeading"),
                                Color("GradientPrimaryBottomTrailing")
                            ]
                        )
                        
                        gradientSwatch(
                            name: "Secondary Gradient",
                            colors: [
                                Color("GradientSecondaryTopLeading"),
                                Color("GradientSecondaryBottomTrailing")
                            ]
                        )
                    }
                }
            }
            .padding(EdgeInsets(
                top: SpacingSystem.Size.lg,
                leading: SpacingSystem.Size.lg,
                bottom: SpacingSystem.Size.lg,
                trailing: SpacingSystem.Size.lg
            ))
        }
    }
    
    private func colorSwatch(name: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: SpacingSystem.Size.xxs) {
            Rectangle()
                .fill(color)
                .frame(height: 60)
                .cornerRadius(SpacingSystem.CornerRadius.small)
            
            BandzText(name, style: Typography.TextStyle.caption)
        }
    }
    
    private func gradientSwatch(name: String, colors: [Color]) -> some View {
        VStack(alignment: .leading, spacing: SpacingSystem.Size.xxs) {
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: colors),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 60)
                .cornerRadius(SpacingSystem.CornerRadius.small)
            
            BandzText(name, style: Typography.TextStyle.caption)
        }
    }
}

// MARK: - Elevation Examples

struct ElevationExamplesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SpacingSystem.Size.lg) {
                BandzText("Elevation System", style: Typography.TextStyle.h1)
                    .padding(.bottom, SpacingSystem.Size.md)
                
                // Elevation examples
                Group {
                    VStack(alignment: .leading, spacing: SpacingSystem.Size.xxs) {
                        BandzText("No Elevation", style: Typography.TextStyle.bodyRegular)
                        
                        Rectangle()
                            .fill(Color.white)
                            .frame(height: 80)
                            .cornerRadius(SpacingSystem.CornerRadius.medium)
                            .elevation(ElevationSystem.Level.none)
                    }
                    .padding(.bottom, SpacingSystem.Size.md)
                    
                    VStack(alignment: .leading, spacing: SpacingSystem.Size.xxs) {
                        BandzText("Low Elevation", style: Typography.TextStyle.bodyRegular)
                        
                        Rectangle()
                            .fill(Color.white)
                            .frame(height: 80)
                            .cornerRadius(SpacingSystem.CornerRadius.medium)
                            .elevation(ElevationSystem.Level.subtle)
                    }
                    .padding(.bottom, SpacingSystem.Size.md)
                    
                    VStack(alignment: .leading, spacing: SpacingSystem.Size.xxs) {
                        BandzText("Medium Elevation", style: Typography.TextStyle.bodyRegular)
                        
                        Rectangle()
                            .fill(Color.white)
                            .frame(height: 80)
                            .cornerRadius(SpacingSystem.CornerRadius.medium)
                            .elevation(ElevationSystem.Level.medium)
                    }
                    .padding(.bottom, SpacingSystem.Size.md)
                    
                    VStack(alignment: .leading, spacing: SpacingSystem.Size.xxs) {
                        BandzText("High Elevation", style: Typography.TextStyle.bodyRegular)
                        
                        Rectangle()
                            .fill(Color.white)
                            .frame(height: 80)
                            .cornerRadius(SpacingSystem.CornerRadius.medium)
                            .elevation(ElevationSystem.Level.high)
                    }
                    .padding(.bottom, SpacingSystem.Size.md)
                }
            }
            .padding(EdgeInsets(
                top: SpacingSystem.Size.lg,
                leading: SpacingSystem.Size.lg,
                bottom: SpacingSystem.Size.lg,
                trailing: SpacingSystem.Size.lg
            ))
        }
        .background(Color.gray.opacity(0.1))
    }
}

// MARK: - UI Component Examples

struct UIComponentExamplesView: View {
    @State private var textInput = ""
    @State private var isPlaying = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SpacingSystem.Size.lg) {
                BandzText("UI Components", style: Typography.TextStyle.h1)
                    .padding(.bottom, SpacingSystem.Size.md)
                
                // Container examples
                Group {
                    BandzText("Containers", style: Typography.TextStyle.h3)
                        .padding(.bottom, SpacingSystem.Size.sm)
                    
                    BandzContainer(
                        horizontalPadding: SpacingSystem.Size.md, 
                        verticalPadding: SpacingSystem.Size.md,
                        backgroundColor: Color.gray.opacity(0.1),
                        elevation: ElevationSystem.Level.subtle,
                        cornerRadius: SpacingSystem.CornerRadius.medium
                    ) {
                        BandzText("Standard Container", style: Typography.TextStyle.bodyRegular)
                    }
                    
                    BandzContainer(
                        horizontalPadding: SpacingSystem.Size.lg, 
                        verticalPadding: SpacingSystem.Size.lg,
                        backgroundColor: Color("Accent").opacity(0.1),
                        elevation: ElevationSystem.Level.medium,
                        cornerRadius: SpacingSystem.CornerRadius.large
                    ) {
                        BandzText("Accent Container with Larger Padding", style: Typography.TextStyle.bodyRegular)
                    }
                }
                
                Divider().padding(.vertical, SpacingSystem.Size.md)
                
                // Card examples
                Group {
                    BandzText("Cards", style: Typography.TextStyle.h3)
                        .padding(.bottom, SpacingSystem.Size.sm)
                    
                    BandzCard(style: .elevated) {
                        VStack(alignment: .leading, spacing: SpacingSystem.Size.sm) {
                            BandzText("Elevated Card", style: Typography.TextStyle.subtitle)
                            BandzText("This card has a shadow to create depth.", style: Typography.TextStyle.bodyRegular)
                        }
                    }
                    
                    BandzCard(style: .outlined) {
                        VStack(alignment: .leading, spacing: SpacingSystem.Size.sm) {
                            BandzText("Outlined Card", style: Typography.TextStyle.subtitle)
                            BandzText("This card has a border without shadow.", style: Typography.TextStyle.bodyRegular)
                        }
                    }
                    
                    BandzCard(style: .filled) {
                        VStack(alignment: .leading, spacing: SpacingSystem.Size.sm) {
                            BandzText("Filled Card", style: Typography.TextStyle.subtitle)
                            BandzText("This card has a subtle background fill.", style: Typography.TextStyle.bodyRegular)
                        }
                    }
                }
                
                Divider().padding(.vertical, SpacingSystem.Size.md)
                
                // Form components
                Group {
                    BandzText("Form Components", style: Typography.TextStyle.h3)
                        .padding(.bottom, SpacingSystem.Size.sm)
                    
                    BandzTextField(
                        title: "Username",
                        placeholder: "Enter your username",
                        text: $textInput,
                        validation: { text in
                            return !text.isEmpty
                        }
                    )
                }
            }
            .padding(EdgeInsets(
                top: SpacingSystem.Size.lg,
                leading: SpacingSystem.Size.lg,
                bottom: SpacingSystem.Size.lg,
                trailing: SpacingSystem.Size.lg
            ))
        }
    }
}

// MARK: - Design System Playground

struct DesignSystemPlayground: View {
    enum Tab {
        case typography
        case spacing
        case colors
        case elevation
        case components
    }
    
    @State private var selectedTab: Tab = .typography
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Category", selection: $selectedTab) {
                    Text("Typography").tag(Tab.typography)
                    Text("Spacing").tag(Tab.spacing)
                    Text("Colors").tag(Tab.colors)
                    Text("Elevation").tag(Tab.elevation)
                    Text("Components").tag(Tab.components)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                selectedView
                    .animation(.default, value: selectedTab)
            }
            .navigationTitle("Design System")
        }
    }
    
    @ViewBuilder
    private var selectedView: some View {
        switch selectedTab {
        case .typography:
            TypographyExamplesView()
        case .spacing:
            SpacingExamplesView()
        case .colors:
            ColorExamplesView()
        case .elevation:
            ElevationExamplesView()
        case .components:
            UIComponentExamplesView()
        }
    }
}

struct DesignSystemPlayground_Previews: PreviewProvider {
    static var previews: some View {
        DesignSystemPlayground()
    }
}
