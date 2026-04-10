package io.github.hyperisland.utils

import java.util.concurrent.TimeUnit
import kotlin.concurrent.thread

internal object RootShell {
    data class CommandResult(
        val stdout: ByteArray,
        val stderr: String,
        val exitCode: Int,
    ) {
        override fun equals(other: Any?): Boolean {
            if (this === other) return true
            if (other !is CommandResult) return false

            return stdout.contentEquals(other.stdout) &&
                    stderr == other.stderr &&
                    exitCode == other.exitCode
        }

        override fun hashCode(): Int {
            var result = stdout.contentHashCode()
            result = 31 * result + stderr.hashCode()
            result = 31 * result + exitCode
            return result
        }
    }

    fun run(command: String, timeoutMs: Long = 10_000L): CommandResult {
        val process = Runtime.getRuntime().exec(arrayOf("su", "-c", command))
        val stderr = StringBuilder()

        val stderrThread = thread(start = true, isDaemon = true, name = "root-shell-stderr") {
            process.errorStream.bufferedReader().use { reader ->
                stderr.append(reader.readText())
            }
        }

        val stdout = process.inputStream.use { input ->
            input.readBytes()
        }

        val completed = process.waitFor(timeoutMs, TimeUnit.MILLISECONDS)
        if (!completed) {
            process.destroyForcibly()
            stderrThread.join(1_000)
            return CommandResult(stdout, "timeout after ${timeoutMs}ms", -1)
        }

        val exitCode = process.exitValue()
        stderrThread.join(2_000)

        return CommandResult(
            stdout = stdout,
            stderr = stderr.toString(),
            exitCode = exitCode,
        )
    }
}
