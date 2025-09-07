package com.stamayo.plugins.muticamera

import com.getcapacitor.Logger

class MultiCamera {
    fun echo(value: String): String {
        Logger.info("Echo", value)
        return value
    }
}
