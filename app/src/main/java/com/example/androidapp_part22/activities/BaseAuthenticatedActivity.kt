package com.example.androidapp_part22.activities

import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.example.androidapp_part22.auth.SessionManager
import javax.inject.Inject

abstract class BaseAuthenticatedActivity : AppCompatActivity() {

    @Inject
    lateinit var sessionManager: SessionManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Check if user is logged in
        if (!sessionManager.isLoggedIn()) {
            redirectToLogin()
            return
        }

        // Check if user has the required role
        if (!hasRequiredRole()) {
            redirectToLogin()
            return
        }
    }

    // This method should be implemented by subclasses to check role requirements
    abstract fun hasRequiredRole(): Boolean

    private fun redirectToLogin() {
        val intent = Intent(this, LoginActivity::class.java)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        startActivity(intent)
        finish()
    }
}