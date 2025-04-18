package com.example.androidapp_part22.activities

import android.annotation.SuppressLint
import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import android.preference.PreferenceManager
import android.view.MotionEvent
import android.view.View
import android.view.inputmethod.InputMethodManager
import android.widget.ImageButton
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.coordinatorlayout.widget.CoordinatorLayout
import androidx.fragment.app.Fragment
import com.example.androidapp_part22.R
import com.example.androidapp_part22.auth.SessionManager
import com.example.androidapp_part22.fragments.AllPatientsFragment
import com.example.androidapp_part22.fragments.BillingFragment
import com.example.androidapp_part22.fragments.MyPatientsFragment
import com.example.androidapp_part22.fragments.PatientListFragment
import com.example.androidapp_part22.fragments.ScheduleFragment
import com.example.androidapp_part22.fragments.SettingsFragment
import com.example.androidapp_part22.fragments.UpcomingAppointmentsFragment
import com.example.androidapp_part22.repository.AuthRepository
import com.google.android.material.tabs.TabLayout
import com.google.android.material.textfield.TextInputEditText
import com.google.android.material.textfield.TextInputLayout
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import javax.inject.Inject

@AndroidEntryPoint
class DashboardActivity : BaseAuthenticatedActivity(), SharedPreferences.OnSharedPreferenceChangeListener {

    private lateinit var searchInput: TextInputEditText
    private lateinit var searchLayout: TextInputLayout
    private lateinit var searchButton: ImageButton
    private lateinit var notificationsButton: ImageButton
    private lateinit var menuButton: ImageButton
    private lateinit var toolbarTitle: TextView
    private lateinit var tabLayout: TabLayout
    private lateinit var appPrefs: SharedPreferences
    private var currentSearchListener: SearchListener? = null
    private var isSearchVisible = false

    @Inject
    lateinit var authRepository: AuthRepository

    // Tab indices - updated after removing Settings tab
    val TAB_MY_PATIENTS = 0
    val TAB_ALL_PATIENTS = 1
    val TAB_SCHEDULE = 2

    override fun hasRequiredRole(): Boolean {
        // Allow doctors to access the dashboard
        return sessionManager.isDoctor()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        // The BaseAuthenticatedActivity will check session validity first
        super.onCreate(savedInstanceState)

        // If authentication check passed, continue with normal initialization
        appPrefs = PreferenceManager.getDefaultSharedPreferences(this)
        appPrefs.registerOnSharedPreferenceChangeListener(this)

        applySavedTheme()
        setContentView(R.layout.activity_dashboard)

        // Update toolbar with user info
        updateUserInfo()

        initViews()
        setupSearchView()
        setupTabLayout()
        loadInitialFragment()
        setupTouchListener()
    }

    private fun updateUserInfo() {
        // You can use the sessionManager to display the user's name or other info in the UI
        val userName = sessionManager.getName() ?: "Doctor"
        // Update UI if needed
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun setupTouchListener() {
        findViewById<CoordinatorLayout>(R.id.rootLayout).setOnTouchListener { _, event ->
            handleTouchOutsideSearch(event)
            false
        }
    }

    private fun handleTouchOutsideSearch(event: MotionEvent) {
        if (event.action == MotionEvent.ACTION_DOWN && isSearchVisible) {
            val searchInput = findViewById<TextInputEditText>(R.id.searchInput)
            val rect = android.graphics.Rect().apply { searchInput.getGlobalVisibleRect(this) }

            // Convert touch coordinates correctly
            val touchX = event.rawX.toInt()
            val touchY = event.rawY.toInt()

            if (!rect.contains(touchX, touchY)) {
                toggleSearchVisibility(false)
            }
        }
    }

    private fun hideKeyboard() {
        val imm = getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager
        currentFocus?.let {
            imm.hideSoftInputFromWindow(it.windowToken, 0)
        }
    }

    private fun applySavedTheme() {
        when (appPrefs.getString("theme", "System Default")) {
            "Light" -> androidx.appcompat.app.AppCompatDelegate.setDefaultNightMode(androidx.appcompat.app.AppCompatDelegate.MODE_NIGHT_NO)
            "Dark" -> androidx.appcompat.app.AppCompatDelegate.setDefaultNightMode(androidx.appcompat.app.AppCompatDelegate.MODE_NIGHT_YES)
            else -> androidx.appcompat.app.AppCompatDelegate.setDefaultNightMode(androidx.appcompat.app.AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM)
        }
    }

    private fun loadInitialFragment() {
        // Load My Patients fragment with Upcoming Appointments above it
        val myPatientsFragment = MyPatientsFragment()

        supportFragmentManager.beginTransaction()
            .replace(R.id.contentFrame, myPatientsFragment)
            .commit()

        // Add upcoming appointments widget at the top of the content frame
        supportFragmentManager.beginTransaction()
            .add(R.id.dashboardWidgetsContainer, UpcomingAppointmentsFragment.newInstance())
            .commit()

        currentSearchListener = myPatientsFragment
    }

    private fun initViews() {
        searchButton = findViewById(R.id.searchButton)
        searchLayout = findViewById(R.id.searchLayout)
        searchInput = findViewById(R.id.searchInput)
        notificationsButton = findViewById(R.id.notificationsButton)
        menuButton = findViewById(R.id.menuButton)
        toolbarTitle = findViewById(R.id.toolbarTitle)
        tabLayout = findViewById(R.id.tabLayout)

        // Set click listeners for the toolbar buttons
        searchButton.setOnClickListener {
            toggleSearchVisibility(!isSearchVisible)
        }

        notificationsButton.setOnClickListener {
            Toast.makeText(this, "Notifications feature coming soon", Toast.LENGTH_SHORT).show()
        }

        // Set up 3-dot menu button
        menuButton.setOnClickListener {
            showOptionsMenu()
        }
    }

    private fun showOptionsMenu() {
        val options = arrayOf("Billing", "Settings", "About", "Help", "Logout")

        AlertDialog.Builder(this)
            .setTitle("Options")
            .setItems(options) { _, which ->
                when (which) {
                    0 -> navigateToBilling()
                    1 -> navigateToSettings()
                    2 -> showAboutDialog()
                    3 -> Toast.makeText(this, "Help feature coming soon", Toast.LENGTH_SHORT).show()
                    4 -> confirmLogout()
                }
            }
            .show()
    }

    private fun navigateToBilling() {
        // Hide widgets container when showing billing
        findViewById<View>(R.id.dashboardWidgetsContainer).visibility = View.GONE

        // Hide tab layout when showing billing
        tabLayout.visibility = View.GONE

        // Load the billing fragment with a meaningful back stack entry name
        supportFragmentManager.beginTransaction()
            .replace(R.id.contentFrame, BillingFragment.newInstance())
            .addToBackStack("dashboard_to_billing")
            .commit()

        // Update the toolbar title
        toolbarTitle.text = "Billing"
    }

    private fun navigateToSettings() {
        // Hide widgets container when showing settings
        findViewById<View>(R.id.dashboardWidgetsContainer).visibility = View.GONE

        // Hide tab layout when showing settings
        tabLayout.visibility = View.GONE

        // Load the settings fragment
        supportFragmentManager.beginTransaction()
            .replace(R.id.contentFrame, SettingsFragment())
            .addToBackStack("settings")
            .commit()

        // Update the toolbar title
        toolbarTitle.text = "Settings"
    }

    private fun showAboutDialog() {
        AlertDialog.Builder(this)
            .setTitle("About Medical Assistant")
            .setMessage("Version 1.0\n\nMedical Assistant helps healthcare providers manage patients, appointments, and clinical notes efficiently.")
            .setPositiveButton("OK", null)
            .show()
    }

    private fun confirmLogout() {
        AlertDialog.Builder(this)
            .setTitle("Logout")
            .setMessage("Are you sure you want to logout?")
            .setPositiveButton("Yes") { _, _ ->
                // Perform logout via the repository
                CoroutineScope(Dispatchers.Main).launch {
                    authRepository.logout()

                    // After logout is complete, redirect to login screen
                    val intent = Intent(this@DashboardActivity, LoginActivity::class.java)
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                    startActivity(intent)
                    finish()
                }
            }
            .setNegativeButton("No", null)
            .show()
    }

    private fun toggleSearchVisibility(show: Boolean) {
        isSearchVisible = show

        if (show) {
            searchLayout.visibility = View.VISIBLE
            searchButton.visibility = View.GONE
            toolbarTitle.visibility = View.GONE  // Hide title when search is visible
            searchInput.requestFocus()

            // Show keyboard
            val imm = getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager
            imm.showSoftInput(searchInput, InputMethodManager.SHOW_IMPLICIT)
        } else {
            searchLayout.visibility = View.GONE
            searchButton.visibility = View.VISIBLE
            toolbarTitle.visibility = View.VISIBLE  // Show title when search is hidden
            searchInput.text?.clear()
            hideKeyboard()

            // Clear search results
            currentSearchListener?.onSearch("")
        }
    }

    private fun setupSearchView() {
        searchInput.setOnEditorActionListener { textView, _, _ ->
            currentSearchListener?.onSearch(textView.text.toString().trim())
            true
        }
    }

    // Public method to get the current tab position
    fun getCurrentTabPosition(): Int {
        return tabLayout.selectedTabPosition
    }

    // Public method to switch to a specific tab
    fun selectTab(tabIndex: Int) {
        if (tabIndex >= 0 && tabIndex < tabLayout.tabCount) {
            switchToTab(tabIndex)
        }
    }

    fun switchToTab(tabIndex: Int) {
        // Select the tab in the UI
        tabLayout.getTabAt(tabIndex)?.select()

        // Clear any existing fragments in the dashboard widgets container
        supportFragmentManager.findFragmentById(R.id.dashboardWidgetsContainer)?.let {
            supportFragmentManager.beginTransaction().remove(it).commit()
        }

        // Make sure dashboard widgets container is visible before adding to it
        findViewById<View>(R.id.dashboardWidgetsContainer).visibility = View.VISIBLE

        when (tabIndex) {
            TAB_MY_PATIENTS -> {
                val fragment = MyPatientsFragment()
                supportFragmentManager.beginTransaction()
                    .replace(R.id.contentFrame, fragment)
                    .commitNow()

                // Add upcoming appointments widget for My Patients tab
                supportFragmentManager.beginTransaction()
                    .add(R.id.dashboardWidgetsContainer, UpcomingAppointmentsFragment.newInstance())
                    .commit()

                currentSearchListener = fragment
                toolbarTitle.text = "My Patients"
            }
            TAB_ALL_PATIENTS -> {
                val fragment = AllPatientsFragment()
                supportFragmentManager.beginTransaction()
                    .replace(R.id.contentFrame, fragment)
                    .commitNow()

                // If you want to show widgets for All Patients too
                supportFragmentManager.beginTransaction()
                    .add(R.id.dashboardWidgetsContainer, UpcomingAppointmentsFragment.newInstance())
                    .commit()

                currentSearchListener = fragment
                toolbarTitle.text = "All Patients"
            }
            TAB_SCHEDULE -> {
                val fragment = ScheduleFragment.newInstance()
                supportFragmentManager.beginTransaction()
                    .replace(R.id.contentFrame, fragment)
                    .commitNow()

                // Hide widgets for schedule view
                findViewById<View>(R.id.dashboardWidgetsContainer).visibility = View.GONE

                currentSearchListener = null
                toolbarTitle.text = "Schedule"
            }
        }
    }

    private fun setupTabLayout() {
        tabLayout.addOnTabSelectedListener(object : TabLayout.OnTabSelectedListener {
            override fun onTabSelected(tab: TabLayout.Tab) {
                // Hide search when changing tabs
                if (isSearchVisible) {
                    toggleSearchVisibility(false)
                }

                // Use the helper method to handle tab switching
                switchToTab(tab.position)
            }

            override fun onTabUnselected(tab: TabLayout.Tab) {}
            override fun onTabReselected(tab: TabLayout.Tab) {}
        })
    }

    override fun onBackPressed() {
        if (isSearchVisible) {
            toggleSearchVisibility(false)
            return
        }

        if (supportFragmentManager.backStackEntryCount > 0) {
            // Get the current backstack entry name before popping
            val currentEntry = supportFragmentManager.getBackStackEntryAt(
                supportFragmentManager.backStackEntryCount - 1
            ).name

            // Pop the back stack
            supportFragmentManager.popBackStack()

            // Restore UI elements when returning from any fragment in back stack
            findViewById<View>(R.id.dashboardWidgetsContainer).visibility = View.VISIBLE
            tabLayout.visibility = View.VISIBLE

            // If returning from settings, explicitly refresh the current tab
            if (currentEntry == "settings") {
                val currentTab = tabLayout.selectedTabPosition
                switchToTab(currentTab)
            }
        } else {
            super.onBackPressed()
        }
    }

    override fun onResume() {
        super.onResume()

        // Apply potential font changes to fragments
        supportFragmentManager.fragments.forEach { fragment ->
            if (fragment is PatientListFragment && fragment.isAdded) {
                fragment.applyFontSettings()
            }
        }

        // Set up a fragment manager listener to detect when settings fragment is removed
        supportFragmentManager.addOnBackStackChangedListener {
            if (supportFragmentManager.backStackEntryCount == 0 &&
                toolbarTitle.text == "Settings") {

                // Restore UI when returning from settings
                findViewById<View>(R.id.dashboardWidgetsContainer).visibility = View.VISIBLE
                tabLayout.visibility = View.VISIBLE

                // Update title based on selected tab
                when (tabLayout.selectedTabPosition) {
                    TAB_MY_PATIENTS -> toolbarTitle.text = "My Patients"
                    TAB_ALL_PATIENTS -> toolbarTitle.text = "All Patients"
                    TAB_SCHEDULE -> toolbarTitle.text = "Schedule"
                }
            }
        }
    }

    override fun onSharedPreferenceChanged(sharedPreferences: SharedPreferences?, key: String?) {
        when (key) {
            "theme" -> applySavedTheme()
            "textSize", "fontStyle" -> {
                // Refresh currently visible fragment
                supportFragmentManager.fragments.forEach { fragment ->
                    if (fragment is PatientListFragment && fragment.isAdded) {
                        fragment.applyFontSettings()
                    }
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        appPrefs.unregisterOnSharedPreferenceChangeListener(this)
    }
}

// Define PatientType enum
enum class PatientType {
    MY_PATIENTS, ALL_PATIENTS
}

// Define SearchListener interface
interface SearchListener {
    fun onSearch(query: String)
}