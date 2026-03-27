package com.bandz.bandz.di

import com.bandz.bandz.common.utils.LocationManager
import com.bandz.bandz.presentation.artist_details.ArtistDetailsViewModel
import com.bandz.bandz.presentation.event_details.EventDetailsViewModel
import com.bandz.bandz.presentation.home.HomeViewModel
import com.bandz.bandz.presentation.login.LoginViewModel
import com.bandz.bandz.presentation.onboarding.OnBoardingViewModel
import com.bandz.bandz.presentation.onboarding.pages.location.OnBoardingLocationViewModel
import com.bandz.bandz.presentation.onboarding.pages.places.OnBoardingPlacesViewModel
import com.bandz.bandz.presentation.onboarding.pages.styles.OnBoardingStylesViewModel
import com.bandz.bandz.presentation.place_details.PlaceDetailsViewModel
import com.bandz.bandz.presentation.profile.ProfileViewModel
import com.bandz.bandz.presentation.register.RegisterViewModel
import com.bandz.bandz.presentation.search.SearchViewModel
import com.bandz.bandz.presentation.share.ShareViewModel
import org.koin.android.ext.koin.androidContext
import org.koin.core.module.dsl.singleOf
import org.koin.core.module.dsl.viewModelOf
import org.koin.dsl.module

val presentationDi = module {

    singleOf(::LocationManager)

    viewModelOf(::HomeViewModel)
    viewModelOf(::EventDetailsViewModel)
    viewModelOf(::ArtistDetailsViewModel)
    viewModelOf(::PlaceDetailsViewModel)
    viewModelOf(::ProfileViewModel)
    viewModelOf(::SearchViewModel)
    viewModelOf(::ShareViewModel)
    viewModelOf(::LoginViewModel)
    viewModelOf(::OnBoardingViewModel)
    viewModelOf(::OnBoardingStylesViewModel)
    viewModelOf(::OnBoardingPlacesViewModel)
    viewModelOf(::OnBoardingLocationViewModel)
    viewModelOf(::RegisterViewModel)
}
