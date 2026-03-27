package com.bandz.bandz.di

import com.bandz.bandz.domain.usecases.ArtistUseCase
import com.bandz.bandz.domain.usecases.ArtistUseCaseImpl
import com.bandz.bandz.domain.usecases.AuthUseCase
import com.bandz.bandz.domain.usecases.AuthUseCaseImpl
import com.bandz.bandz.domain.usecases.EventsUseCase
import com.bandz.bandz.domain.usecases.EventsUseCaseImpl
import com.bandz.bandz.domain.usecases.LocationUseCase
import com.bandz.bandz.domain.usecases.LocationUseCaseImpl
import com.bandz.bandz.domain.usecases.PlacesUseCase
import com.bandz.bandz.domain.usecases.PlacesUseCaseImpl
import com.bandz.bandz.domain.usecases.StylesUseCase
import com.bandz.bandz.domain.usecases.StylesUseCaseImpl
import com.bandz.bandz.domain.usecases.UserUseCase
import com.bandz.bandz.domain.usecases.UserUseCaseImpl
import org.koin.dsl.module

val domainModule = module {
    factory<AuthUseCase> { AuthUseCaseImpl(authRepository = get()) }
    factory<StylesUseCase> { StylesUseCaseImpl(stylesRepository = get()) }
    factory<PlacesUseCase> { PlacesUseCaseImpl(repository = get()) }
    factory<LocationUseCase> { LocationUseCaseImpl(locationRepository = get()) }
    factory<UserUseCase> { UserUseCaseImpl(userRepository = get()) }
    factory<EventsUseCase> { EventsUseCaseImpl(eventsRepository = get()) }
    factory<ArtistUseCase> { ArtistUseCaseImpl(artistRepository = get()) }
}
