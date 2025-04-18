package com.example.androidapp_part22.auth

import android.content.Context
import android.content.SharedPreferences
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SessionManager @Inject constructor(context: Context) {

    companion object {
        private const val PREF_NAME = "MedicalAppSession"
        private const val KEY_SESSION_ID = "session_id"
        private const val KEY_USER_ID = "user_id"
        private const val KEY_USERNAME = "username"
        private const val KEY_USER_ROLE = "user_role"
        private const val KEY_NAME = "name"
        private const val KEY_IS_LOGGED_IN = "is_logged_in"
    }

    private val prefs: SharedPreferences = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)

    fun createSession(sessionId: String, userId: String, username: String, name: String, role: String) {
        prefs.edit().apply {
            putString(KEY_SESSION_ID, sessionId)
            putString(KEY_USER_ID, userId)
            putString(KEY_USERNAME, username)
            putString(KEY_NAME, name)
            putString(KEY_USER_ROLE, role)
            putBoolean(KEY_IS_LOGGED_IN, true)
            apply()
        }
    }

    fun getSessionId(): String? = prefs.getString(KEY_SESSION_ID, null)

    fun getUserId(): String? = prefs.getString(KEY_USER_ID, null)

    fun getUsername(): String? = prefs.getString(KEY_USERNAME, null)

    fun getName(): String? = prefs.getString(KEY_NAME, null)

    fun getUserRole(): String? = prefs.getString(KEY_USER_ROLE, null)

    fun isLoggedIn(): Boolean = prefs.getBoolean(KEY_IS_LOGGED_IN, false)

    fun isDoctor(): Boolean = getUserRole() == "DOCTOR"

    fun isPatient(): Boolean = getUserRole() == "PATIENT"

    fun clearSession() {
        prefs.edit().clear().apply()
    }
}