package io.github.hyperisland.utils

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

    fun run(command: String): CommandResult {
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
        val exitCode = process.waitFor()
        stderrThread.join()

        return CommandResult(
            stdout = stdout,
            stderr = stderr.toString(),
            exitCode = exitCode,
        )
    }
}
