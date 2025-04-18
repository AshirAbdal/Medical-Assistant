package com.example.androidapp_part22.activities

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Toast
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import com.example.androidapp_part22.R
import com.example.androidapp_part22.databinding.ActivityLoginBinding  // Make sure this import exists
import com.example.androidapp_part22.repository.AuthRepository
import com.example.androidapp_part22.viewmodels.LoginViewModel
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class LoginActivity : AppCompatActivity() {

    private lateinit var binding: ActivityLoginBinding
    private val viewModel: LoginViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityLoginBinding.inflate(layoutInflater)
        setContentView(binding.root)

        // Set up the UI
        setupUI()

        // Observe view model state
        observeViewModel()
    }

    private fun setupUI() {
        // Set click listener for sign in button
        binding.signInButton.setOnClickListener {
            val email = binding.emailEditText.text.toString().trim()
            val password = binding.passwordEditText.text.toString().trim()

            if (validateInputs(email, password)) {
                viewModel.login(email, password)
            }
        }

        // Set click listener for forgot password
        binding.forgotPasswordTextView.setOnClickListener {
            Toast.makeText(this, "Forgot password feature coming soon", Toast.LENGTH_SHORT).show()
        }
    }

    private fun validateInputs(email: String, password: String): Boolean {
        var isValid = true

        if (email.isEmpty()) {
            binding.emailTextInputLayout.error = "Email is required"
            isValid = false
        } else if (!android.util.Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
            binding.emailTextInputLayout.error = "Please enter a valid email"
            isValid = false
        } else {
            binding.emailTextInputLayout.error = null
        }

        if (password.isEmpty()) {
            binding.passwordTextInputLayout.error = "Password is required"
            isValid = false
        } else {
            binding.passwordTextInputLayout.error = null
        }

        return isValid
    }

    private fun observeViewModel() {
        // Observe login state changes
        viewModel.loginState.observe(this) { result ->
            when (result) {
                is AuthRepository.AuthResult.Success -> {
                    // Determine which dashboard to open based on user role
                    if (viewModel.isDoctor()) {
                        startActivity(Intent(this, DashboardActivity::class.java))
                    } else {
                        // For now, use DashboardActivity for both
                        startActivity(Intent(this, DashboardActivity::class.java))
                    }
                    finish()
                }

                is AuthRepository.AuthResult.Error -> {
                    // Show error message
                    binding.errorMessageTextView.text = result.message
                    binding.errorMessageTextView.visibility = View.VISIBLE
                }

                AuthRepository.AuthResult.Loading -> {
                    // Show loading state if needed
                    binding.errorMessageTextView.visibility = View.GONE
                }
            }
        }

        // Observe loading state
        viewModel.isLoading.observe(this) { isLoading ->
            binding.signInButton.isEnabled = !isLoading
            binding.progressBar.visibility = if (isLoading) View.VISIBLE else View.GONE
        }
    }
}