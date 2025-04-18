package com.example.androidapp_part22.models

data class UserCredentials(
    val id: String,     // Email
    val password: String
)

data class LoginRequest(
    val user: UserCredentials
)