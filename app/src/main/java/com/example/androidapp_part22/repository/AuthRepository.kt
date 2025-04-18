package com.example.androidapp_part22.repository

import com.example.androidapp_part22.api.ApiService
import com.example.androidapp_part22.auth.SessionManager
import com.example.androidapp_part22.models.LoginRequest
import com.example.androidapp_part22.models.UserCredentials
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthRepository @Inject constructor(
    private val apiService: ApiService,
    private val sessionManager: SessionManager
) {

    sealed class AuthResult {
        data class Success(val username: String, val role: String) : AuthResult()
        data class Error(val message: String) : AuthResult()
        object Loading : AuthResult()
    }

    suspend fun login(email: String, password: String): AuthResult {
        return try {
            val credentials = UserCredentials(id = email, password = password)
            val loginRequest = LoginRequest(user = credentials)
            val response = apiService.login(loginRequest)

            if (response.isSuccessful && response.body()?.success == true) {
                val data = response.body()
                val sessionId = data?.sessionId
                val user = data?.user

                if (sessionId != null && user != null) {
                    // Save session details
                    sessionManager.createSession(
                        sessionId = sessionId,
                        userId = user.id,
                        username = user.username,
                        name = user.name,
                        role = user.role
                    )

                    return AuthResult.Success(user.username, user.role)
                } else {
                    return AuthResult.Error("Invalid session data received")
                }
            } else {
                return AuthResult.Error(response.body()?.message ?: "Login failed")
            }
        } catch (e: Exception) {
            return AuthResult.Error(e.message ?: "Network error occurred")
        }
    }

    suspend fun logout(): Boolean {
        return try {
            val sessionId = sessionManager.getSessionId()
            if (sessionId != null) {
                val response = apiService.logout(sessionId)
                sessionManager.clearSession()
                response.isSuccessful
            } else {
                // No active session, consider logout successful
                sessionManager.clearSession()
                true
            }
        } catch (e: Exception) {
            // Even if API call fails, clear the local session
            sessionManager.clearSession()
            true
        }
    }

    fun checkLoginStatus(): Boolean = sessionManager.isLoggedIn()
}