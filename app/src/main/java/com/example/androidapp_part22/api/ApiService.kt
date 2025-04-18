package com.example.androidapp_part22.api

import com.example.androidapp_part22.models.LoginRequest
import com.example.androidapp_part22.models.LoginResponse
import com.example.androidapp_part22.models.LogoutResponse
import com.example.androidapp_part22.models.UserProfileResponse
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.Header
import retrofit2.http.POST

interface ApiService {
    @POST("auth/login")
    suspend fun login(@Body loginRequest: LoginRequest): Response<LoginResponse>

    @POST("auth/logout")
    suspend fun logout(@Header("Session-ID") sessionId: String): Response<LogoutResponse>

    @GET("user/profile")
    suspend fun getUserProfile(@Header("Session-ID") sessionId: String): Response<UserProfileResponse>
}