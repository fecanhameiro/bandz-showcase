package com.bandz.bandz.data.repository

import com.bandz.bandz.common.utils.Resource
import com.bandz.bandz.data.entity.EventsEntity
import com.bandz.bandz.data.firebase.CollectionsParam
import com.bandz.bandz.data.mapper.mapToEventDetailsVO
import com.bandz.bandz.data.mapper.mapToEventsHomeVO
import com.bandz.bandz.data.vo.EventDetailVO
import com.bandz.bandz.data.vo.EventsHomeVO
import com.bandz.bandz.domain.repository.EventRepository
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.tasks.await

class EventRepositoryImpl(private val firestore: FirebaseFirestore = FirebaseFirestore.getInstance()) :
    EventRepository {
    override fun getEvents(): Flow<Resource<List<EventsHomeVO>>> {
        return flow {
            emit(Resource.Loading())
            try {
                val today = com.google.firebase.Timestamp.now()
                val snapshot = firestore.collection("BR${CollectionsParam.EVENTS}").whereGreaterThanOrEqualTo("eventDate", today).get().await()
                val events = snapshot.documents.mapNotNull { document ->
                    document.toObject(EventsEntity::class.java)?.copy(id = document.id)
                        ?.mapToEventsHomeVO()
                }
                emit(Resource.Success(events))
            } catch (e: Exception) {
                emit(Resource.Error(e.message ?: "Um erro inesperado ocorreu"))
            }
        }.catch { e ->
            emit(Resource.Error(e.message ?: "Um erro inesperado ocorreu"))
        }
    }

    override fun getEventDetails(eventId: String): Flow<Resource<EventDetailVO>> {
        return flow {
            emit(Resource.Loading())
            try {
                val snapshot = firestore.collection("BR${CollectionsParam.EVENTS}").document(eventId).get()
                    .await()
                val event = snapshot.toObject(EventsEntity::class.java)?.copy(id = snapshot.id)
                    ?.mapToEventDetailsVO()
                if (event != null) {
                    emit(Resource.Success(event))
                } else {
                    emit(Resource.Error("Evento não encontrado"))
                }
            } catch (e: Exception) {
                emit(Resource.Error(e.message ?: "Um erro inesperado ocorreu"))
            }
        }.catch { e ->
            emit(Resource.Error(e.message ?: "Um erro inesperado ocorreu"))
        }
    }

}