package io.github.hyperisland

import kotlin.concurrent.thread

internal object RootShell {
    data class CommandResult(
        val stdout: ByteArray,
        val stderr: String,
        val exitCode: Int,
    )

    fun run(command: String): CommandResult {
        val process = Runtime.getRuntime().exec(arrayOf("su", "-c", command))
        val stderr = StringBuilder()

        val stderrThread = thread(start = true, isDaemon = true, name = "root-shell-stderr") {
            process.errorStream.bufferedReader().use { reader ->
                stderr.append(reader.readText())
            }
        }

        return try {
            val stdout = process.inputStream.use { input ->
                input.readBytes()
            }
            val exitCode = process.waitFor()
            try {
                stderrThread.join()
            } catch (_: InterruptedException) {
                Thread.currentThread().interrupt()
            }

            CommandResult(
                stdout = stdout,
                stderr = stderr.toString(),
                exitCode = exitCode,
            )
        } finally {
            runCatching { process.inputStream.close() }
            runCatching { process.errorStream.close() }
            runCatching { process.outputStream.close() }
            process.destroy()
        }
    }
}
