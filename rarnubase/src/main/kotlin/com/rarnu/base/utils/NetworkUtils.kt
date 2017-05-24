package com.rarnu.base.utils

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkInfo
import com.rarnu.base.R
import com.rarnu.base.command.Command
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.Inet4Address
import java.net.NetworkInterface
import java.net.SocketException
import java.text.DecimalFormat
import java.util.*
import kotlin.concurrent.thread

/**
 * Created by rarnu on 3/28/16.
 */
object NetworkUtils {

    var loadingNetwork = false
    var networkInfo: NetworkInfo? = null
    var networkSpeed: String? = null

    fun getNetworkInfo(context: Context): NetworkInfo? = (context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager).activeNetworkInfo

    fun ping(hostname: String): String? {
        var pingResult = "timeout"
        try {
            val process = Runtime.getRuntime().exec("ping " + hostname)
            val stdout = BufferedReader(InputStreamReader(process.inputStream))
            var line: String?
            val tmr = Timer()
            tmr.schedule(object : TimerTask() {
                override fun run() {
                    this.cancel()
                    tmr.cancel()
                    process.destroy()
                }
            }, 3000)
            while (true) {
                line = stdout.readLine()
                if (line != null) {
                    pingResult = line
                    tmr.cancel()
                    process.destroy()
                }
                break
            }
            process.waitFor()
        } catch (e: Exception) {

        }
        return pingResult
    }

    fun testNetworkSpeed(): String? {
        val cmdResult = Command.runCommand("ping -c 5 -s 1024 www.163.com", false, null)
        if (cmdResult.error != "") {
            return null
        }
        val str = cmdResult.result.split("\n")
        val list = arrayListOf<PingInfo>()
        var info: PingInfo?
        for (s in str) {
            info = parseString(s)
            if (info != null) {
                list.add(info)
            }
        }
        return getNetworkSpeed(list)
    }


    fun getNetworkStatusDesc(context: Context): String =
            if (loadingNetwork) {
                context.getString(R.string.loading_network_status)
            } else {
                var status = context.getString(R.string.no_connect_found)
                if (networkInfo != null) {
                    status = context.getString(R.string.network_status_fmt,
                            networkInfo!!.typeName,
                            networkInfo!!.subtypeName,
                            networkStatusToReadableString(context, networkInfo!!.state),
                            networkInfo!!.extraInfo ?: context.getString(R.string.not_contained),
                            context.getString(if (networkInfo!!.isRoaming) R.string.yes else R.string.no),
                            context.getString(if (networkInfo!!.isFailover) R.string.supported else R.string.unsupported),
                            context.getString(if (networkInfo!!.isAvailable) R.string.available else R.string.unavailable),
                            networkSpeed)
                }
                status
            }

    fun doGetNetworkInfoT(context: Context) {
        thread {
            loadingNetwork = true
            networkInfo = getNetworkInfo(context)
            networkSpeed = testNetworkSpeed()
            loadingNetwork = false
        }
    }

    private fun parseString(str: String?): PingInfo? {
        var info: PingInfo? = null
        try {
            if (str!!.contains("icmp_seq=") && str.contains("ttl=") && str.contains("time=")) {
                info = PingInfo()
                info.byteCount = 1024
                var nstr = str.replace(" ", "").trim()
                nstr = nstr.substring(str.lastIndexOf("="))
                nstr = nstr.replace("ms", "").replace("=", "").trim()
                info.time = nstr.toDouble()
            }
        } catch (e: Exception) {

        }
        return info
    }

    private fun getNetworkSpeed(list: MutableList<PingInfo>?): String? {
        if (list == null || list.size == 0) {
            return null
        }
        var timeCount = 0.0
        for (info in list) {
            timeCount += info.time
        }
        timeCount /= list.size
        val speed = 1024.0 / timeCount
        val speedStr = DecimalFormat("#.##").format(speed)
        return "${speedStr}K/s"
    }

    private fun networkStatusToReadableString(context: Context, state: NetworkInfo.State): String = when (state) {
        NetworkInfo.State.CONNECTED -> context.getString(R.string.network_connected)
        NetworkInfo.State.CONNECTING -> context.getString(R.string.network_connecting)
        NetworkInfo.State.DISCONNECTED -> context.getString(R.string.network_disconnected)
        NetworkInfo.State.DISCONNECTING -> context.getString(R.string.network_disconnecting)
        NetworkInfo.State.SUSPENDED -> context.getString(R.string.network_suspended)
        NetworkInfo.State.UNKNOWN -> context.getString(R.string.network_unknown)
        else -> context.getString(R.string.network_unknown)
    }

    val ipAddressV4: String?
        get() {
            try {
                val en = NetworkInterface.getNetworkInterfaces()
                while (en.hasMoreElements()) {
                    val intf = en.nextElement()
                    val enumIpAddr = intf.inetAddresses
                    while (enumIpAddr.hasMoreElements()) {
                        val inetAddress = enumIpAddr.nextElement()
                        if (!inetAddress.isLoopbackAddress && inetAddress is Inet4Address) {
                            return inetAddress.getHostAddress().toString()
                        }
                    }
                }
            } catch (ex: SocketException) {

            }

            return null
        }

    class PingInfo {
        var byteCount = 0
        var time = 0.0
    }
}