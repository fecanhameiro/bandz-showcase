package com.bandz.bandz.domain.usecases

import android.util.Log
import com.bandz.bandz.common.utils.helper.ImageHelper
import com.bandz.bandz.common.utils.Resource
import com.bandz.bandz.common.utils.extension.formatHour
import com.bandz.bandz.common.utils.extension.getMonthName
import com.bandz.bandz.data.vo.EventDetailVO
import com.bandz.bandz.data.vo.EventsHomeVO
import com.bandz.bandz.data.vo.EventsListVO
import com.bandz.bandz.domain.repository.EventRepository
import com.google.firebase.firestore.GeoPoint
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.map
import java.time.ZoneId
import java.util.Calendar
import java.util.Date
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.pow
import kotlin.math.sin
import kotlin.math.sqrt
import java.time.format.DateTimeFormatter
import java.time.format.TextStyle
import java.util.Locale

class EventsUseCaseImpl(val eventsRepository: EventRepository) : EventsUseCase {

    companion object {
        private const val MAX_DISTANCE_KM = 9999.0 // Distância máxima em quilômetros
        private const val EARTH_RADIUS_KM = 6371.0 // Raio da Terra em quilômetros
        private const val TAG = "EventsPerformance"
    }

    override fun getEventsHome(
        userStyles: List<String>,
        userLocation: GeoPoint
    ): Flow<Resource<List<EventsListVO>>> {
        return flow {
            val totalStartTime = System.nanoTime()
            Log.i(TAG, "🚀 Iniciando request de eventos")

            eventsRepository.getEvents()
                .collect { resource ->
                    when (resource) {
                        is Resource.Success -> {
                            val firebaseTime =
                                (System.nanoTime() - totalStartTime) / 1_000_000 // Convertendo para milissegundos
                            Log.i(TAG, "⚡ Tempo de resposta do Firebase: ${firebaseTime}ms")

                            val events = resource.data
                            Log.i(TAG, "📦 Quantidade de eventos recebidos: ${events?.size ?: 0}")

                            // Enrichment process
                            val enrichStartTime = System.nanoTime()
                            val enrichedEvents = enrichEventsData(events ?: listOf())
                            val enrichTime = (System.nanoTime() - enrichStartTime) / 1_000_000
                            Log.i(TAG, "🔄 Tempo de enriquecimento dos dados: ${enrichTime}ms")

                            // Processing
                            val processStartTime = System.nanoTime()
                            val result = processEventsFromHome(
                                enrichedEvents,
                                userStyles,
                                userLocation
                            )
                            val processTime = (System.nanoTime() - processStartTime) / 1_000_000
                            Log.i(TAG, "⚙️ Tempo de processamento dos eventos: ${processTime}ms")

                            // Total time
                            val totalTime = (System.nanoTime() - totalStartTime) / 1_000_000
                            Log.i(
                                TAG, """
                                📊 Resumo dos tempos:
                                → Firebase: ${firebaseTime}ms
                                → Enriquecimento: ${enrichTime}ms
                                → Processamento: ${processTime}ms
                                → Tempo total: ${totalTime}ms
                                → Eventos processados: ${result.sumOf { it.events.size }}
                            """.trimIndent()
                            )

                            emit(Resource.Success(result) as Resource<List<EventsListVO>>)
                        }

                        is Resource.Error -> {
                            Log.e(TAG, "❌ Erro ao buscar eventos: ${resource.message}")
                            emit(
                                Resource.Error<List<EventsListVO>>(
                                    resource.message ?: "Um erro inesperado ocorreu"
                                )
                            )
                        }

                        is Resource.Loading -> {
                            Log.i(TAG, "⏳ Carregando eventos...")
                            emit(Resource.Loading<List<EventsListVO>>())
                        }
                    }
                }
        }.flowOn(Dispatchers.IO)
    }


    override fun getEventDetails(eventId: String): Flow<Resource<EventDetailVO>> {
        return eventsRepository.getEventDetails(eventId).map { resource ->
            when (resource) {
                is Resource.Success -> {
                    val imageHelper = ImageHelper()
                    val calendar = Calendar.getInstance()

                    val daysOfWeek = arrayOf(
                        "Domingo", "Segunda-feira", "Terça-feira",
                        "Quarta-feira", "Quinta-feira", "Sexta-feira", "Sábado"
                    )
                    val dayOfWeek = daysOfWeek[calendar.get(Calendar.DAY_OF_WEEK) - 1]

                    val eventDetail = resource.data?.copy(
                        infoDateEvent = resource.data.eventDate?.formatEventDate(),
                        address = concatAddress(resource.data),
                        artistImage = imageHelper.generateImageUrl(
                            path = imageHelper.artistPath,
                            isSmall = false,
                            isProfile = true,
                            id = resource.data.artistId,
                        ).orEmpty(),
                        day = calendar.get(Calendar.DAY_OF_MONTH).toString(),
                        month = calendar.get(Calendar.MONTH).getMonthName().substring(0, 3)
                            .uppercase() + ".",
                        year = calendar.get(Calendar.YEAR).toString(),
                        dayOfWeek = dayOfWeek.substring(0, 3).uppercase() + ".",
                    )
                    if (eventDetail == null) {
                        Resource.Error("Evento não encontrado")
                    } else {
                        Resource.Success(eventDetail)
                    }
                }

                is Resource.Error -> resource
                is Resource.Loading -> resource
            }
        }
    }

    override fun getEventsByArtistForPlace(
        artistId: String,
        placeId: String,
        placeName: String,
        artistName: String,
        eventId: String,
        userLocation: GeoPoint
    ): Flow<Resource<List<EventsListVO>>> {
        return eventsRepository.getEvents().map { resource ->
            when (resource) {
                is Resource.Success -> {
                    val events = resource.data
                    val enrichedEvents = enrichEventsData(events ?: listOf())
                    Resource.Success(
                        processEventsForArtistAndPlace(
                            events = enrichedEvents,
                            artistId = artistId,
                            placeId = placeId,
                            artistName = artistName,
                            placeName = placeName,
                            userLocation = userLocation,
                            eventId = eventId
                        )
                    )
                }

                is Resource.Error -> Resource.Error(
                    resource.message ?: "Um erro inesperado ocorreu"
                )

                is Resource.Loading -> Resource.Loading()
            }
        }
    }

    override fun getEventsByArtist(
        artistId: String,
        artistName: String,
        userLocation: GeoPoint
    ): Flow<Resource<List<EventsListVO>>> {
        return eventsRepository.getEvents().map { resource ->
            when (resource) {
                is Resource.Success -> {
                    val events = resource.data
                    val enrichedEvents = enrichEventsData(events ?: listOf())
                    Resource.Success(
                        processEventsForArtist(
                            events = enrichedEvents,
                            artistId = artistId,
                            artistName = artistName,
                            userLocation = userLocation,
                        )
                    )
                }

                is Resource.Error -> Resource.Error(
                    resource.message ?: "Um erro inesperado ocorreu"
                )

                is Resource.Loading -> Resource.Loading()
            }
        }
    }

    override fun getEventsByPlace(
        placeId: String,
        placeName: String,
        userLocation: GeoPoint
    ): Flow<Resource<List<EventsListVO>>> {
        return eventsRepository.getEvents().map { resource ->
            when (resource) {
                is Resource.Success -> {
                    val events = resource.data
                    val enrichedEvents = enrichEventsData(events ?: listOf())
                    Resource.Success(
                        processEventsForPlace(
                            events = enrichedEvents,
                            placeId = placeId,
                            placeName = placeName,
                            userLocation = userLocation,
                        )
                    )
                }

                is Resource.Error -> Resource.Error(
                    resource.message ?: "Um erro inesperado ocorreu"
                )

                is Resource.Loading -> Resource.Loading()
            }
        }
    }

    override fun getEventsByPlace2(placeId: String): Flow<Resource<List<EventsHomeVO>>> {
        return eventsRepository.getEvents().map { resource ->
            when (resource) {
                is Resource.Success -> {
                    val events = resource.data
                    val enrichedEvents = enrichEventsData(events ?: listOf())
                    Resource.Success(enrichedEvents.filter { it.placeId == placeId })
                }

                is Resource.Error -> Resource.Error(
                    resource.message ?: "Um erro inesperado ocorreu"
                )

                is Resource.Loading -> Resource.Loading()
            }
        }
    }

    override fun getEventsByArtist2(artistId: String): Flow<Resource<List<EventsHomeVO>>> {
        return eventsRepository.getEvents().map { resource ->
            when (resource) {
                is Resource.Success -> {
                    val events = resource.data
                    val enrichedEvents = enrichEventsData(events ?: listOf())
                    Resource.Success(enrichedEvents.filter { it.artistId == artistId })
                }

                is Resource.Error -> Resource.Error(
                    resource.message ?: "Um erro inesperado ocorreu"
                )

                is Resource.Loading -> Resource.Loading()
            }
        }
    }

    private fun Date.formatEventDate(): String {
        val localDate = this.toInstant()
            .atZone(ZoneId.systemDefault())
            .toLocalDateTime()

        val dayOfWeek = localDate.dayOfWeek.getDisplayName(
            TextStyle.FULL,
            Locale("pt", "BR")
        )

        val formatter = DateTimeFormatter
            .ofPattern("'$dayOfWeek', dd 'de' MMMM '|' HH:mm")
            .withLocale(Locale("pt", "BR"))

        return localDate.format(formatter)
    }

    private fun concatAddress(event: EventDetailVO): String {
        return listOfNotNull(
            event.placeAddress,
            event.placeAddressNumber,
            event.placeCity,
            event.placeState?.let { "- $it" }
        ).joinToString(", ")
    }

    private fun enrichEventsData(events: List<EventsHomeVO>): List<EventsHomeVO> {
        val startTime = System.nanoTime()
        Log.i(TAG, "🔄 Iniciando enriquecimento de ${events.size} eventos")

        return events.map { event ->
            val calendar = Calendar.getInstance()
            calendar.time = event.eventDate

            val daysOfWeek = arrayOf(
                "Domingo", "Segunda-feira", "Terça-feira",
                "Quarta-feira", "Quinta-feira", "Sexta-feira", "Sábado"
            )
            val dayOfWeek = daysOfWeek[calendar.get(Calendar.DAY_OF_WEEK) - 1]

            event.copy(
                hour = event.eventDate.formatHour(),
                day = calendar.get(Calendar.DAY_OF_MONTH).toString(),
                month = calendar.get(Calendar.MONTH).getMonthName().substring(0, 3)
                    .uppercase() + ".",
                year = calendar.get(Calendar.YEAR).toString(),
                dayOfWeek = dayOfWeek.substring(0, 3).uppercase() + ".",
            )
        }.also {
            val enrichTime = (System.nanoTime() - startTime) / 1_000_000
            Log.i(TAG, "✅ Enriquecimento concluído em ${enrichTime}ms")
        }
    }


    private suspend fun processEventsFromHome(
        events: List<EventsHomeVO>,
        userStyles: List<String>,
        userLocation: GeoPoint
    ): List<EventsListVO> {
        val startTime = System.nanoTime()
        Log.i(TAG, "⚙️ Iniciando processamento de ${events.size} eventos")

        val now = Date()

        val filteredEvents = events
            .filter { it.eventDate.after(now) }
            .map { event ->
                event to calculateDistance(userLocation, event.location)
            }

        Log.i(TAG, "📍 Eventos futuros encontrados: ${filteredEvents.size}")

        val result = listOf(
            createNearbyStyleEvents(filteredEvents, userStyles),
            createNearbyEvents(filteredEvents),
            createStyleEvents(filteredEvents, userStyles)
        ).filter { it.events.isNotEmpty() }

        val processTime = (System.nanoTime() - startTime) / 1_000_000
        Log.i(
            TAG, """
            ✅ Processamento concluído em ${processTime}ms
            → Categorias geradas: ${result.size}
            → Total de eventos: ${result.sumOf { it.events.size }}
            ${result.joinToString("\n") { "→ ${it.title}: ${it.events.size} eventos" }}
        """.trimIndent()
        )

        return result
    }

    private suspend fun createNearbyStyleEvents(
        events: List<Pair<EventsHomeVO, Double>>,
        userStyles: List<String>
    ): EventsListVO {
        val nearbyStyleEvents = events
            .filter { (event, distance) ->
                distance <= MAX_DISTANCE_KM &&
                        (event.style in userStyles || event.genres.any { it in userStyles })
            }
            .sortedBy { it.second }
            .map { it.first }

        return EventsListVO(
            title = "Eventos do seu estilo próximos a você",
            description = "Eventos que combinam com você",
            events = nearbyStyleEvents
        )
    }

    private suspend fun createNearbyEvents(
        events: List<Pair<EventsHomeVO, Double>>
    ): EventsListVO {
        val nearbyEvents = events
            .filter { (_, distance) -> distance <= MAX_DISTANCE_KM }
            .sortedBy { it.second }
            .map { it.first }

        return EventsListVO(
            title = "Eventos próximos a você",
            description = "Eventos gerais próximos a você",
            events = nearbyEvents
        )
    }

    private suspend fun createStyleEvents(
        events: List<Pair<EventsHomeVO, Double>>,
        userStyles: List<String>
    ): EventsListVO {
        val styleEvents = events
            .filter { (event, _) ->
                event.style in userStyles || event.genres.any { it in userStyles }
            }
            .sortedBy { (event, _) -> event.eventDate }
            .map { it.first }

        return EventsListVO(
            title = "Eventos do seu estilo",
            description = "Eventos que combinam com você",
            events = styleEvents
        )
    }


    private suspend fun processEventsForArtistAndPlace(
        events: List<EventsHomeVO>,
        userLocation: GeoPoint,
        artistId: String,
        placeId: String,
        artistName: String,
        placeName: String,
        eventId: String
    ): List<EventsListVO> {
        val now = Date()

        // Filtrar eventos futuros e calcular distâncias
        val filteredEvents = events
            .filter { it.eventDate.after(now) }
            .map { event ->
                event to calculateDistance(userLocation, event.location)
            }

        val result = listOf(
            createArtistEvents(
                events = filteredEvents,
                artistId = artistId,
                artistName = artistName,
                eventId = eventId
            ),
            createPlaceEvents(
                events = filteredEvents,
                placeId = placeId,
                placeName = placeName
            )
        )

        // Filtrar para retornar apenas listas com eventos
        return result.filter { it.events.isNotEmpty() }
    }

    private suspend fun processEventsForPlace(
        events: List<EventsHomeVO>,
        userLocation: GeoPoint,
        placeId: String,
        placeName: String,
    ): List<EventsListVO> {
        val now = Date()

        // Filtrar eventos futuros e calcular distâncias
        val filteredEvents = events
            .filter { it.eventDate.after(now) }
            .map { event ->
                event to calculateDistance(userLocation, event.location)
            }

        val result = listOf(
            createPlaceEvents(
                events = filteredEvents,
                placeId = placeId,
                placeName = placeName
            ),
        )

        // Filtrar para retornar apenas listas com eventos
        return result.filter { it.events.isNotEmpty() }
    }


    private suspend fun processEventsForArtist(
        events: List<EventsHomeVO>,
        userLocation: GeoPoint,
        artistId: String,
        artistName: String,
    ): List<EventsListVO> {
        val now = Date()

        // Filtrar eventos futuros e calcular distâncias
        val filteredEvents = events
            .filter { it.eventDate.after(now) }
            .map { event ->
                event to calculateDistance(userLocation, event.location)
            }

        val result = listOf(
            createArtistEvents(
                events = filteredEvents,
                artistId = artistId,
                artistName = artistName,
                eventId = ""
            ),
        )

        // Filtrar para retornar apenas listas com eventos
        return result.filter { it.events.isNotEmpty() }
    }

    private suspend fun createArtistEvents(
        events: List<Pair<EventsHomeVO, Double>>,
        artistId: String,
        artistName: String,
        eventId: String
    ): EventsListVO {
        val now = Date()
        val artistEvents = events
            .filter { (event, _) ->
                event.artistId == artistId && event.eventDate.after(now)
//                        && event.id != eventId
                //TODO - remover comentário acima para evento atual não ser exibido como futuro evento do artista
            }
            .sortedBy { (event, _) -> event.eventDate }
            .map { it.first }

        return EventsListVO(
            title = "Próximas apresentações",
            description = "$artistName irá apresentar também nos locais",
            events = artistEvents
        )
    }

    private suspend fun createPlaceEvents(
        events: List<Pair<EventsHomeVO, Double>>,
        placeId: String,
        placeName: String,
    ): EventsListVO {
        val now = Date()
        val placeEvents = events
            .filter { (event, distance) ->
                event.placeId == placeId &&
                        event.eventDate.after(now) &&
                        distance <= MAX_DISTANCE_KM
            }
            .sortedBy { (event, _) -> event.eventDate }
            .map { it.first }

        return EventsListVO(
            title = "Próximos eventos",
            description = "No $placeName também irão se apresentar",
            events = placeEvents
        )
    }

    private fun calculateDistance(point1: GeoPoint, point2: GeoPoint): Double {
        val lat1 = Math.toRadians(point1.latitude)
        val lon1 = Math.toRadians(point1.longitude)
        val lat2 = Math.toRadians(point2.latitude)
        val lon2 = Math.toRadians(point2.longitude)

        val dLat = lat2 - lat1
        val dLon = lon2 - lon1

        val a = sin(dLat / 2).pow(2) + cos(lat1) * cos(lat2) * sin(dLon / 2).pow(2)
        val c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return EARTH_RADIUS_KM * c
    }

}