package com.example.fall_helper

import android.content.Context
import android.net.Uri
import androidx.media3.common.MediaItem
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.EditedMediaItemSequence
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.Transformer
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class VideoConsolidationBridge(
    private val context: Context
) {
    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "consolidateSegments" -> consolidateSegments(call, result)
            else -> result.notImplemented()
        }
    }

    private fun consolidateSegments(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        val segmentPaths = call.argument<List<String>>("segmentPaths")
        val outputPath = call.argument<String>("outputPath")

        if (segmentPaths.isNullOrEmpty()) {
            result.error("invalid_args", "segmentPaths vazio ou nulo.", null)
            return
        }

        if (outputPath.isNullOrBlank()) {
            result.error("invalid_args", "outputPath vazio ou nulo.", null)
            return
        }

        val outputFile = File(outputPath)
        if (outputFile.exists()) {
            outputFile.delete()
        }
        outputFile.parentFile?.mkdirs()

        val editedItems = segmentPaths.map { path ->
            val mediaItem = MediaItem.fromUri(Uri.fromFile(File(path)))
            EditedMediaItem.Builder(mediaItem).build()
        }

        val sequence = EditedMediaItemSequence.Builder(editedItems).build()
        val composition = Composition.Builder(listOf(sequence)).build()

        val transformer = Transformer.Builder(context)
            .addListener(
                object : Transformer.Listener {
                    override fun onCompleted(
                        composition: Composition,
                        exportResult: ExportResult
                    ) {
                        result.success(outputPath)
                    }

                    override fun onError(
                        composition: Composition,
                        exportResult: ExportResult,
                        exportException: ExportException
                    ) {
                        result.error(
                            "transformer_error",
                            exportException.message ?: "Erro na consolidação.",
                            null
                        )
                    }
                }
            )
            .build()

        transformer.start(composition, outputPath)
    }
}