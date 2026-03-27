//
//  OnboardingCarouselData.swift
//  Bandz
//
//  Created by Felipe Canhameiro on 08/05/25.
//

import Foundation

struct OnboardingCarouselData: Identifiable {
    let id = UUID()
    var title: String
    var file: String // Nome do arquivo Lottie
    var description: String
}
