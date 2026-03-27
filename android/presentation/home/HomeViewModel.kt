package com.bandz.bandz.presentation.home

import android.app.Application
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bandz.bandz.common.utils.AppConstants
import com.bandz.bandz.common.utils.helper.GeoPointHelper
import com.bandz.bandz.common.utils.Resource
import com.bandz.bandz.common.utils.preferences.PreferencesEnum
import com.bandz.bandz.common.utils.preferences.PreferencesManager
import com.bandz.bandz.domain.usecases.EventsUseCase
import com.bandz.bandz.domain.usecases.UserUseCase
import com.google.firebase.firestore.GeoPoint
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class HomeViewModel(
    application: Application,
    private val eventsUseCase: EventsUseCase,
    private val userUseCase: UserUseCase,
    private val preferencesManager: PreferencesManager,
) : ViewModel() {

    private val sharedPreferences = PreferencesManager(application.applicationContext)

    private val _state = MutableStateFlow(HomeState())
    val state: StateFlow<HomeState> = _state.asStateFlow()

    init {
        getUserInfo()
    }

    private fun getUserInfo() {
        viewModelScope.launch {
            val userId = preferencesManager.getString(PreferencesEnum.FIREBASE_TOKEN.name)
            val geoPointHelper = GeoPointHelper()
            userUseCase.getUser(userId).collect { result ->
                when (result) {
                    is Resource.Success -> {
                        sharedPreferences.saveString(
                            PreferencesEnum.USER_LOCATION.name,
                            geoPointHelper.geoPointToString(
                                result.data?.location ?: GeoPoint(
                                    AppConstants.LATITUDE, AppConstants.LONGITUDE
                                )
                            )
                        )
                        getHomeEvents(
                            userLocation = result.data?.location ?: GeoPoint(0.0, 0.0),
                            preferredStyles = result.data?.styles ?: listOf()
                        )
                    }

                    is Resource.Loading -> {
                        _state.value = HomeState(loading = true)
                    }

                    is Resource.Error -> {
                        _state.value = HomeState(error = result.message!!)
                    }
                }
            }
        }
    }

    private fun getHomeEvents(userLocation: GeoPoint, preferredStyles: List<String>) {
        viewModelScope.launch {
            eventsUseCase.getEventsHome(
                userLocation = userLocation,
                userStyles = preferredStyles
            ).collect { result ->
                _state.value = when (result) {
                    is Resource.Success -> {
                        HomeState(
                            events = result.data.orEmpty(),
                            hasEvents = result.data?.isNotEmpty() == true
                        )
                    }

                    is Resource.Loading -> HomeState(loading = true)
                    is Resource.Error -> HomeState(error = result.message.orEmpty())
                }
            }
        }
    }


}