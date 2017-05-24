package com.rarnu.base.component.floatwindow

import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.IBinder
import android.view.LayoutInflater
import android.view.View

/**
 * Created by rarnu on 3/25/16.
 *
 * android.permission.SYSTEM_ALERT_WINDOW
 */
abstract class FloatService : Service(), FloatWindowListener {

    companion object {
        fun showFloatWindow(context: Context, service: Class<out FloatService>) {
            val inServiceFloat = Intent(context, service)
            context.startService(inServiceFloat)
        }

        fun hideFloatWindow(context: Context, service: Class<out FloatService>) {
            val inServiceFloat = Intent(context, service)
            context.stopService(inServiceFloat)
        }
    }

    private var _fv: FloatWindow? = null
    private var _view: View? = null

    abstract fun getViewResId(): Int

    abstract fun initView(view: View?)

    abstract fun getX(): Int

    abstract fun getY(): Int

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        _fv?.hide()
        super.onDestroy()
    }


    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val inflater = LayoutInflater.from(this)
        _view = inflater.inflate(getViewResId(), null)
        initView(_view)
        _fv = FloatWindow(this, _view, this)
        val init_x = getX()
        val init_y = getY()
        _fv?.show(init_x, init_y)
        return super.onStartCommand(intent, flags, startId)
    }


}