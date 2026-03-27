package com.bandz.bandz.common.navigation.navgraph

import androidx.compose.runtime.remember
import androidx.navigation.NavController
import androidx.navigation.NavGraphBuilder
import androidx.navigation.compose.composable
import androidx.navigation.navigation
import com.bandz.bandz.common.navigation.NavigationRoutes.ARTIST_DETAILS_SCREEN
import com.bandz.bandz.common.navigation.NavigationRoutes.EVENT_DETAILS_SCREEN
import com.bandz.bandz.common.navigation.NavigationRoutes.HOME_NAV_GRAPH
import com.bandz.bandz.common.navigation.NavigationRoutes.HOME_SCREEN
import com.bandz.bandz.common.navigation.NavigationRoutes.NOTIFICATIONS_SCREEN
import com.bandz.bandz.common.navigation.NavigationRoutes.PLACE_DETAILS_SCREEN
import com.bandz.bandz.common.navigation.NavigationRoutes.PROFILE_SCREEN
import com.bandz.bandz.common.navigation.NavigationRoutes.SEARCH_SCREEN
import com.bandz.bandz.common.navigation.NavigationRoutes.SHARE_SCREEN
import com.bandz.bandz.common.navigation.enterTransition
import com.bandz.bandz.common.navigation.exitTransition
import com.bandz.bandz.common.navigation.popEnterTransition
import com.bandz.bandz.common.navigation.popExitTransition
import com.bandz.bandz.common.utils.enum.BottomBarState.GONE
import com.bandz.bandz.common.utils.enum.BottomBarState.VISIBLE
import com.bandz.bandz.common.utils.enum.LocalBottomBarState
import com.bandz.bandz.presentation.artist_details.ArtistDetailsScreen
import com.bandz.bandz.presentation.event_details.EventDetailsScreen
import com.bandz.bandz.presentation.home.HomeScreen
import com.bandz.bandz.presentation.notifications.NotificationsScreen
import com.bandz.bandz.presentation.place_details.PlaceDetailsScreen
import com.bandz.bandz.presentation.profile.ProfileScreen
import com.bandz.bandz.presentation.search.SearchScreen
import com.bandz.bandz.presentation.share.ShareScreen
import com.bandz.bandz.presentation.share.ShareViewModel
import org.koin.androidx.compose.koinViewModel

fun NavGraphBuilder.mainGraph(navController: NavController) {
    navigation(
        startDestination = HOME_SCREEN,
        route = HOME_NAV_GRAPH
    ) {
        composable(
            route = HOME_SCREEN,
            enterTransition = enterTransition,
            exitTransition = exitTransition,
            popEnterTransition = popEnterTransition,
            popExitTransition = popExitTransition,
        ) {
            LocalBottomBarState.current.value = VISIBLE
            HomeScreen(goToEvent = { id ->
                navController.navigate("$EVENT_DETAILS_SCREEN/$id")
            })
        }

        composable(
            route = "$EVENT_DETAILS_SCREEN/{eventId}",
            enterTransition = enterTransition,
            exitTransition = exitTransition,
            popEnterTransition = popEnterTransition,
            popExitTransition = popExitTransition,
        ) { backStackEntry ->
            val parentEntry = remember(backStackEntry) {
                navController.getBackStackEntry(HOME_NAV_GRAPH)
            }
            val shareViewModel: ShareViewModel = koinViewModel(viewModelStoreOwner = parentEntry)
            val eventId = backStackEntry.arguments?.getString("eventId")
            LocalBottomBarState.current.value = VISIBLE
            EventDetailsScreen(
                eventId = eventId.orEmpty(),
                shareViewModel = shareViewModel,
                backPressed = {
                    navController.popBackStack()
                },
                selectEvent = {},
                shareEvent = {
                    navController.navigate(route = SHARE_SCREEN)
                },
                selectArtist = { artistId ->
                    navController.navigate("$ARTIST_DETAILS_SCREEN/$artistId")
                },
                selectPlace = { placeId ->
                    navController.navigate("$PLACE_DETAILS_SCREEN/$placeId")
                })
        }

        composable(
            route = "$ARTIST_DETAILS_SCREEN/{artistId}",
            enterTransition = enterTransition,
            exitTransition = exitTransition,
            popEnterTransition = popEnterTransition,
            popExitTransition = popExitTransition,
        ) { backStackEntry ->
            val parentEntry = remember(backStackEntry) {
                navController.getBackStackEntry(HOME_NAV_GRAPH)
            }
            val shareViewModel: ShareViewModel = koinViewModel(viewModelStoreOwner = parentEntry)
            val artistId = backStackEntry.arguments?.getString("artistId")
            LocalBottomBarState.current.value = VISIBLE
            ArtistDetailsScreen(
                artistId = artistId.orEmpty(),
                shareViewModel = shareViewModel,
                backPressed = {
                    navController.popBackStack()
                },
                selectEvent = { eventId ->
                    navController.navigate("$EVENT_DETAILS_SCREEN/$eventId")
                }, shareArtist = {
                    navController.navigate(route = SHARE_SCREEN)
                })
        }

        composable(
            route = "$PLACE_DETAILS_SCREEN/{placeId}",
            enterTransition = enterTransition,
            exitTransition = exitTransition,
            popEnterTransition = popEnterTransition,
            popExitTransition = popExitTransition,
        ) { backStackEntry ->
            val parentEntry = remember(backStackEntry) {
                navController.getBackStackEntry(HOME_NAV_GRAPH)
            }
            val shareViewModel: ShareViewModel = koinViewModel(viewModelStoreOwner = parentEntry)
            val placeId = backStackEntry.arguments?.getString("placeId")
            LocalBottomBarState.current.value = VISIBLE
            PlaceDetailsScreen(
                placeId = placeId.orEmpty(),
                shareViewModel = shareViewModel,
                backPressed = {
                    navController.popBackStack()
                },
                selectEvent = { eventId ->
                    navController.navigate("$EVENT_DETAILS_SCREEN/$eventId")
                },
                sharePlace = {
                    navController.navigate(route = SHARE_SCREEN)
                })
        }

        composable(
            route = SEARCH_SCREEN,
            enterTransition = enterTransition,
            exitTransition = exitTransition,
            popEnterTransition = popEnterTransition,
            popExitTransition = popExitTransition,
        ) {
            LocalBottomBarState.current.value = VISIBLE
            SearchScreen()
        }

        composable(
            route = NOTIFICATIONS_SCREEN,
            enterTransition = enterTransition,
            exitTransition = exitTransition,
            popEnterTransition = popEnterTransition,
            popExitTransition = popExitTransition,
        ) {
            LocalBottomBarState.current.value = VISIBLE
            NotificationsScreen()
        }

        composable(
            route = PROFILE_SCREEN,
            enterTransition = enterTransition,
            exitTransition = exitTransition,
            popEnterTransition = popEnterTransition,
            popExitTransition = popExitTransition,
        ) {
            LocalBottomBarState.current.value = VISIBLE
            ProfileScreen()
        }

        composable(
            route = SHARE_SCREEN,
            enterTransition = enterTransition,
            exitTransition = exitTransition,
            popEnterTransition = popEnterTransition,
            popExitTransition = popExitTransition,
        ) { backStackEntry ->
            val parentEntry = remember(backStackEntry) {
                navController.getBackStackEntry(HOME_NAV_GRAPH)
            }
            val shareViewModel: ShareViewModel = koinViewModel(viewModelStoreOwner = parentEntry)
            LocalBottomBarState.current.value = GONE
            ShareScreen(viewModel = shareViewModel, backPressed = {
                navController.popBackStack()
            })
        }
    }
}