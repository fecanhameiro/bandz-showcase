package com.bandz.bandz.presentation.home

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.painter.Painter
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import com.airbnb.lottie.compose.LottieAnimation
import com.airbnb.lottie.compose.LottieCompositionSpec.RawRes
import com.airbnb.lottie.compose.LottieConstants
import com.airbnb.lottie.compose.rememberLottieComposition
import com.bandz.bandz.R.drawable
import com.bandz.bandz.R.raw
import com.bandz.bandz.common.components.RecommendationComponent
import com.bandz.bandz.common.components.ShimmerTransition
import com.bandz.bandz.common.components.commons.SpacerHeight
import com.bandz.bandz.common.components.commons.TextFutura
import com.bandz.bandz.common.components.commons.TextNormal
import com.bandz.bandz.common.components.commons.TopBarCustom
import com.bandz.bandz.common.shimmers.RecommendationShimmerComponent
import com.bandz.bandz.common.utils.extension.shadowM
import com.bandz.bandz.common.utils.getHomeBackgroundGradient
import com.google.accompanist.pager.ExperimentalPagerApi
import com.google.accompanist.pager.HorizontalPager
import com.google.accompanist.pager.rememberPagerState
import kotlinx.coroutines.delay
import org.koin.androidx.compose.getViewModel
import org.koin.androidx.compose.koinViewModel
import java.util.Locale

@Composable
fun HomeScreen(
    viewModel: HomeViewModel = koinViewModel(),
    goToEvent: (id: String) -> Unit
) {

    val state by viewModel.state.collectAsState()

    Content(state = state, goToEvent = goToEvent)
}


@Composable
@OptIn(ExperimentalPagerApi::class)
private fun Content(
    state: HomeState,
    goToEvent: (id: String) -> Unit
) {
    val pagerState = rememberPagerState()
    var currentPage by remember { mutableStateOf(0) }
    val pages = 3

    LaunchedEffect(Unit) {
        while (true) {
            delay(timeMillis = 5000)
            currentPage = (currentPage + 1) % pages
            pagerState.animateScrollToPage(currentPage)
        }
    }

    val scrollState = rememberScrollState()
    val backgroundColor by animateColorAsState(
        if (scrollState.value > 0) Color.White.copy(alpha = 0.3F) else Color.Transparent,
        label = ""
    )

    Box(
        modifier = Modifier.background(brush = getHomeBackgroundGradient(isSystemInDarkTheme()))
    ) {
        TopBarCustom(
            backgroundColor = backgroundColor,
            showLogo = true
        )

        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            state = rememberLazyListState(),
            verticalArrangement = Arrangement.spacedBy(6.dp),
            contentPadding = PaddingValues(
                bottom = 78.dp
            )
        ) {
            item {
                HorizontalPager(
                    count = 3,
                    state = pagerState
                ) { page ->
                    CardMain()
                }
            }

            item {
                ShimmerTransition(
                    isLoading = state.loading,
                    shimmerContent = {
                        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            repeat(2) {
                                RecommendationShimmerComponent()
                            }
                        }
                    },
                    content = {
                        when {
                            state.hasEvents -> {
                                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                    state.events.forEach { event ->
                                        RecommendationComponent(
                                            categoryRecommendation = event,
                                            selectRecommendation = goToEvent
                                        )
                                    }
                                }
                            }

                            else -> {
                                TextFutura(
                                    text = "Não há eventos futuros",
                                    fontSize = 16,
                                    modifier = Modifier.fillMaxWidth(),
                                    textAlign = TextAlign.Center,
                                )
                            }
                        }
                    })
            }

//            when {
//                state.loading -> {
//                    items(2) {
//                        RecommendationShimmerComponent()
//                    }
//                }
//                state.hasEvents -> {
//                    items(items = state.events) { event ->
//                        RecommendationComponent(
//                            categoryRecommendation = event,
//                            selectRecommendation = { id ->
//                                goToEvent(id)
//                            }
//                        )
//                    }
//                }
//
//                else -> {
//                    item {
//                        TextFutura(
//                            text = "Não há eventos futuros",
//                            fontSize = 16,
//                            modifier = Modifier.fillMaxWidth(),
//                            textAlign = TextAlign.Center,
//                        )
//                    }
//                }
//            }
        }
    }
}

@Composable
fun CardMain() {
    Box(
        modifier = Modifier
            .height(364.dp)
            .fillMaxWidth()
    ) {
        Image(
            painter = painterResource(id = drawable.agua_de_jhow),
            contentDescription = "photo artist",
            modifier = Modifier
                .fillMaxWidth()
                .height(364.dp),
            alpha = 0.8f,
            contentScale = ContentScale.Crop
        )
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(100.dp)
                .align(Alignment.BottomCenter)
                .zIndex(1f)
                .background(
                    Brush.verticalGradient(
                        listOf(
                            Color.Transparent,
//                            Color(0xFF83CCB1),
                            Color(0xFF19AFB8),
                            Color(0xFF19AFB8)
                        ),
                        startY = 1f,
                        endY = 550f
                    )
                )
        )

        Box(
            modifier = Modifier
                .padding(end = 16.dp)
                .align(alignment = Alignment.BottomEnd)
                .zIndex(1f)
        ) {
            RoundImageButtonPlus(
                modifier = Modifier
                    .size(32.dp)
                    .shadowM(color = Color.White, blurRadius = 12.dp, borderRadius = 30.dp),
                image = painterResource(drawable.agua_de_jhow),
                contentDescription = "Botão redondo",
                onClick = { /* Lógica de clique */ }
            )
        }

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .align(Alignment.BottomCenter)
                .zIndex(2f)
        ) {
            TextFutura(
                text = "Água de Jhow",
                fontSize = 32,
                modifier = Modifier.fillMaxWidth(),
                textAlign = TextAlign.Center,
                letterSpacing = 0.10f
            )

            SpacerHeight(height = 2)

            TextNormal(
                text = "samba/pagode e mpb",
                fontSize = 14,
                fontWeight = 500,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth(),
                letterSpacing = 0.05f
            )

        }


    }

}

@Composable
private fun CardInfoHomeComponent(words: List<String>) {
    var selectedIndex by remember { mutableStateOf(0) }
    var updatedWords by remember { mutableStateOf(words) }
    LazyColumn() {
        items(3) {
            ItemInfo(words[it])
        }
    }
}

@Composable
private fun ItemInfo(word: String) {
    val colorCard = Color.Black.copy(alpha = 0.5f)
    Card(
        colors = CardDefaults.cardColors(containerColor = colorCard),
        modifier = Modifier
            .border(
                width = 0.dp,
                color = colorCard,
                shape = RoundedCornerShape(
                    bottomEnd = 8.dp,
                    topEnd = 8.dp,
                    bottomStart = 0.dp,
                    topStart = 0.dp
                )
            )
            .wrapContentHeight()
    ) {
        Text(
            text = word.uppercase(Locale.ROOT),
            color = Color.White,
            style = MaterialTheme.typography.labelSmall,
            fontSize = 8.sp,
            modifier = Modifier.padding(2.dp)
        )
    }

}

@Composable
private fun RoundImageButtonPlus(
    image: Painter,
    modifier: Modifier = Modifier,
    contentDescription: String,
    onClick: () -> Unit
) {
    val compositionPlus by rememberLottieComposition(RawRes(raw.animation_plus))

    Box(
        modifier = modifier
            .border(width = 1.dp, color = Color.White, shape = CircleShape)
            .shadow(
                elevation = 8.dp,
                shape = CircleShape,
                clip = true
            )
            .clip(CircleShape)
            .clickable { onClick.invoke() },
        contentAlignment = Alignment.Center
    ) {
        LottieAnimation(
            composition = compositionPlus,
            modifier = Modifier
                .size(100.dp)
                .zIndex(1f)
                .fillMaxSize(),
            contentScale = ContentScale.Inside,
            iterations = LottieConstants.IterateForever
        )

        Image(
            painter = image,
            contentDescription = contentDescription,
            modifier = Modifier.fillMaxSize()
        )
    }
}

fun moveSelectedWordToFirstPosition(words: List<String>, selectedIndex: Int): List<String> {
    val updatedWords = words.toMutableList()
    if (selectedIndex != 0) {
        val selectedWord = updatedWords.removeAt(selectedIndex)
        updatedWords.add(0, selectedWord)
    }
    return updatedWords
}
