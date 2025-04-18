package com.example.androidapp_part22.viewmodels

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.androidapp_part22.auth.SessionManager
import com.example.androidapp_part22.repository.AuthRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class LoginViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val sessionManager: SessionManager
) : ViewModel() {

    private val _loginState = MutableLiveData<AuthRepository.AuthResult>()
    val loginState: LiveData<AuthRepository.AuthResult> = _loginState

    private val _isLoading = MutableLiveData<Boolean>()
    val isLoading: LiveData<Boolean> = _isLoading

    init {
        // Check if user is already logged in
        if (authRepository.checkLoginStatus()) {
            _loginState.value = AuthRepository.AuthResult.Success(
                username = sessionManager.getUsername() ?: "",
                role = sessionManager.getUserRole() ?: ""
            )
        }
    }

    fun login(email: String, password: String) {
        viewModelScope.launch {
            _isLoading.value = true
            _loginState.value = AuthRepository.AuthResult.Loading

            val result = authRepository.login(email, password)
            _loginState.value = result

            _isLoading.value = false
        }
    }

    fun isDoctor(): Boolean = sessionManager.isDoctor()

    fun isPatient(): Boolean = sessionManager.isPatient()
}