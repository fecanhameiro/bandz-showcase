package com.bandz.bandz.di

import com.bandz.bandz.data.repository.ArtistRepositoryImpl
import com.bandz.bandz.data.repository.AuthRepositoryImpl
import com.bandz.bandz.data.repository.EventRepositoryImpl
import com.bandz.bandz.data.repository.LocationRepositoryImpl
import com.bandz.bandz.data.repository.PlacesRepositoryImpl
import com.bandz.bandz.data.repository.StylesRepositoryImpl
import com.bandz.bandz.data.repository.UserRepositoryImpl
import com.bandz.bandz.domain.repository.ArtistRepository
import com.bandz.bandz.domain.repository.AuthRepository
import com.bandz.bandz.domain.repository.EventRepository
import com.bandz.bandz.domain.repository.LocationRepository
import com.bandz.bandz.domain.repository.PlacesRepository
import com.bandz.bandz.domain.repository.StylesRepository
import com.bandz.bandz.domain.repository.UserRepository
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import org.koin.dsl.module

val firebaseModule = module {
    single { FirebaseAuth.getInstance() }
    single { FirebaseFirestore.getInstance() }
}

val repositoryModule = module {
    factory<AuthRepository> { AuthRepositoryImpl(firebaseAuth = get(), firestore = get()) }
    factory<StylesRepository> { StylesRepositoryImpl(firestore = get()) }
    factory<PlacesRepository> { PlacesRepositoryImpl(firestore = get()) }
    factory<UserRepository> { UserRepositoryImpl(firestore = get()) }
    factory<LocationRepository> { LocationRepositoryImpl(firestore = get()) }
    factory<EventRepository> { EventRepositoryImpl(firestore = get()) }
    factory<ArtistRepository> { ArtistRepositoryImpl(firestore = get()) }
}