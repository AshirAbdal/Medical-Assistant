package com.example.androidapp_part22.models

data class LoginResponse(
    val success: Boolean,
    val message: String,
    val sessionId: String?,
    val user: UserData?
)

data class UserData(
    val id: String,
    val username: String,
    val name: String,
    val role: String
)