package com.example.androidapp_part22.activities

import android.app.DatePickerDialog
import android.app.TimePickerDialog
import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.widget.ArrayAdapter
import android.widget.AutoCompleteTextView
import android.widget.Button
import android.widget.ImageButton
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.fragment.app.Fragment
import com.example.androidapp_part22.fragments.JournalFragment
import com.example.androidapp_part22.fragments.MedicationsFragment
import com.example.androidapp_part22.fragments.ReportsFragment
import com.example.androidapp_part22.helpers.ProfileImageHelper
import com.example.androidapp_part22.logic.ScheduleManager
import com.example.androidapp_part22.models.Appointment
import com.example.androidapp_part22.models.AppointmentStatus
import com.example.androidapp_part22.models.AppointmentType
import com.example.androidapp_part22.models.Patient
import com.example.androidapp_part22.R
import com.google.android.material.switchmaterial.SwitchMaterial
import com.google.android.material.tabs.TabLayout
import com.google.android.material.textfield.TextInputEditText
import com.mikhaellopez.circularimageview.CircularImageView
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

class PatientProfileActivity : AppCompatActivity() {

    private lateinit var profileImageHelper: ProfileImageHelper
    private lateinit var profileImage: CircularImageView
    private lateinit var patientNameTextView: TextView
    private lateinit var patientAgeGenderTextView: TextView
    private lateinit var patientIdTextView: TextView
    private lateinit var tabLayout: TabLayout
    private lateinit var backButton: ImageButton
    private lateinit var searchPatientButton: ImageButton
    private lateinit var editPatientButton: ImageButton
    private lateinit var toolbarTitle: TextView
    private lateinit var patient: Patient
    private lateinit var scheduleManager: ScheduleManager

    // Tab indices - updated without Upload tab
    private val TAB_JOURNAL = 0
    private val TAB_REPORTS = 1
    private val TAB_MEDICATIONS = 2

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_patient_profile)

        // Get the patient data from intent
        patient = intent.getParcelableExtra("SELECTED_PATIENT") ?: run {
            finish() // Close activity if no patient data
            return
        }

        // Initialize the helper
        profileImageHelper = ProfileImageHelper(this)
        scheduleManager = ScheduleManager()

        // Initialize views
        initViews()

        // Setup toolbar actions
        setupToolbarActions()

        // Setup UI with patient data
        setupPatientInfo()

        // Setup tabs
        setupTabLayout()

        // Load the default fragment (Journal now that Upload is removed)
        loadFragment(JournalFragment.newInstance(patient))
    }

    private fun initViews() {
        // Toolbar views
        backButton = findViewById(R.id.backButton)
        searchPatientButton = findViewById(R.id.searchPatientButton)
        editPatientButton = findViewById(R.id.editPatientButton)
        toolbarTitle = findViewById(R.id.toolbarTitle)

        // Patient info views
        profileImage = findViewById(R.id.patientProfileImage)
        patientNameTextView = findViewById(R.id.patientNameTextView)
        patientAgeGenderTextView = findViewById(R.id.patientAgeGenderTextView)
        patientIdTextView = findViewById(R.id.patientIdTextView)

        // Profile picture setup - still leaving this for patient profile picture
        profileImage.setOnClickListener {
            profileImageHelper.showImageSourceDialog()
        }

        // Tab layout
        tabLayout = findViewById(R.id.tabLayout)
    }

    private fun setupToolbarActions() {
        // Set the patient name in the toolbar title
        toolbarTitle.text = "Patient Profile"

        // Back button setup
        backButton.setOnClickListener {
            finishWithAnimation()
        }

        // Search button setup
        searchPatientButton.setOnClickListener {
            Toast.makeText(this, "Search feature coming soon", Toast.LENGTH_SHORT).show()
        }

        // Edit button setup
        editPatientButton.setOnClickListener {
            showEditOptions()
        }
    }

    private fun showEditOptions() {
        val options = arrayOf("Edit Profile", "Add Note", "Schedule Appointment", "Archive Patient")

        AlertDialog.Builder(this)
            .setTitle("Patient Options")
            .setItems(options) { _, which ->
                when (which) {
                    0 -> Toast.makeText(this, "Edit Profile feature coming soon", Toast.LENGTH_SHORT).show()
                    1 -> {
                        // Switch to Journal tab and focus on new entry
                        tabLayout.getTabAt(TAB_JOURNAL)?.select()
                        // Would need a method in JournalFragment to focus on new entry input
                    }
                    2 -> showScheduleAppointmentDialog()
                    3 -> Toast.makeText(this, "Archive Patient feature coming soon", Toast.LENGTH_SHORT).show()
                }
            }
            .show()
    }

    private fun setupPatientInfo() {
        patientNameTextView.text = patient.name
        patientAgeGenderTextView.text = "Age: ${patient.age}, Gender: ${patient.gender}"
        patientIdTextView.text = "ID: ${patient.id}"
    }

    private fun setupTabLayout() {
        // Clear existing tabs if any
        tabLayout.removeAllTabs()

        // Add tabs - without Upload tab
        tabLayout.addTab(tabLayout.newTab().setText("Journal"))
        tabLayout.addTab(tabLayout.newTab().setText("Reports"))
        tabLayout.addTab(tabLayout.newTab().setText("Medications"))

        // Set tab selection listener
        tabLayout.addOnTabSelectedListener(object : TabLayout.OnTabSelectedListener {
            override fun onTabSelected(tab: TabLayout.Tab) {
                when (tab.position) {
                    TAB_JOURNAL -> loadFragment(JournalFragment.newInstance(patient))
                    TAB_REPORTS -> loadFragment(ReportsFragment.newInstance(patient))
                    TAB_MEDICATIONS -> loadFragment(MedicationsFragment.newInstance(patient))
                }
            }

            override fun onTabUnselected(tab: TabLayout.Tab?) { /* Not needed */ }
            override fun onTabReselected(tab: TabLayout.Tab?) { /* Not needed */ }
        })
    }

    private fun loadFragment(fragment: Fragment) {
        supportFragmentManager.beginTransaction()
            .replace(R.id.fragmentContainer, fragment)
            .commit()
    }

    // New method to handle scheduling appointments for this specific patient
    private fun showScheduleAppointmentDialog() {
        val dialogView = LayoutInflater.from(this)
            .inflate(R.layout.dialog_create_appointment, null)

        // Setup dialog view elements - note that we pre-fill the patient information

        // Pre-select the current patient
        val patientDropdown = dialogView.findViewById<AutoCompleteTextView>(R.id.patientAutoComplete)
        patientDropdown.setText(patient.name)
        patientDropdown.isEnabled = false // Disable changing the patient

        // Setup other dialog elements (date picker, time picker, etc.)
        setupDialogDatePicker(dialogView)
        setupDialogTimePicker(dialogView)
        setupDialogDurationDropdown(dialogView)
        setupDialogTypeDropdown(dialogView)

        // Create and show dialog
        val dialog = AlertDialog.Builder(this)
            .setView(dialogView)
            .create()

        // Setup button actions
        dialogView.findViewById<Button>(R.id.cancelButton).setOnClickListener {
            dialog.dismiss()
        }

        dialogView.findViewById<Button>(R.id.saveButton).setOnClickListener {
            if (validateAppointmentInputs(dialogView)) {
                saveNewAppointment(dialogView)
                dialog.dismiss()
                Toast.makeText(this, "Appointment scheduled successfully", Toast.LENGTH_SHORT).show()
            }
        }

        dialog.show()
    }

    // Helper methods for appointment scheduling dialog
    private fun setupDialogDatePicker(dialogView: View) {
        val dateEditText = dialogView.findViewById<TextInputEditText>(R.id.dateEditText)
        val dateFormat = SimpleDateFormat("MMMM dd, yyyy", Locale.getDefault())

        // Set initial date to tomorrow
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.DAY_OF_MONTH, 1)
        dateEditText.setText(dateFormat.format(calendar.time))

        // Setup date picker dialog
        dateEditText.setOnClickListener {
            val currentDate = Calendar.getInstance()

            val datePickerDialog = DatePickerDialog(
                this,
                { _, year, monthOfYear, dayOfMonth ->
                    val selectedDate = Calendar.getInstance()
                    selectedDate.set(Calendar.YEAR, year)
                    selectedDate.set(Calendar.MONTH, monthOfYear)
                    selectedDate.set(Calendar.DAY_OF_MONTH, dayOfMonth)

                    dateEditText.setText(dateFormat.format(selectedDate.time))
                },
                currentDate.get(Calendar.YEAR),
                currentDate.get(Calendar.MONTH),
                currentDate.get(Calendar.DAY_OF_MONTH)
            )

            datePickerDialog.show()
        }
    }

    private fun setupDialogTimePicker(dialogView: View) {
        val timeEditText = dialogView.findViewById<TextInputEditText>(R.id.timeEditText)
        val timeFormat = SimpleDateFormat("hh:mm a", Locale.getDefault())

        // Set initial time (10:00 AM)
        val initialTime = Calendar.getInstance()
        initialTime.set(Calendar.HOUR_OF_DAY, 10)
        initialTime.set(Calendar.MINUTE, 0)
        timeEditText.setText(timeFormat.format(initialTime.time))

        // Setup time picker dialog
        timeEditText.setOnClickListener {
            val currentTime = Calendar.getInstance()

            val timePickerDialog = TimePickerDialog(
                this,
                { _, hourOfDay, minute ->
                    val selectedTime = Calendar.getInstance()
                    selectedTime.set(Calendar.HOUR_OF_DAY, hourOfDay)
                    selectedTime.set(Calendar.MINUTE, minute)

                    timeEditText.setText(timeFormat.format(selectedTime.time))
                },
                currentTime.get(Calendar.HOUR_OF_DAY),
                currentTime.get(Calendar.MINUTE),
                false
            )

            timePickerDialog.show()
        }
    }

    private fun setupDialogDurationDropdown(dialogView: View) {
        val durationDropdown = dialogView.findViewById<AutoCompleteTextView>(R.id.durationAutoComplete)
        val durationOptions = listOf("15 minutes", "30 minutes", "45 minutes", "60 minutes", "90 minutes")

        val adapter = ArrayAdapter(
            this,
            android.R.layout.simple_dropdown_item_1line,
            durationOptions
        )

        durationDropdown.setAdapter(adapter)
        durationDropdown.setText(durationOptions[1], false) // Default to 30 minutes
    }

    private fun setupDialogTypeDropdown(dialogView: View) {
        val typeDropdown = dialogView.findViewById<AutoCompleteTextView>(R.id.typeAutoComplete)
        val appointmentTypes = AppointmentType.values().map { it.displayName }

        val adapter = ArrayAdapter(
            this,
            android.R.layout.simple_dropdown_item_1line,
            appointmentTypes
        )

        typeDropdown.setAdapter(adapter)
        typeDropdown.setText(appointmentTypes[0], false) // Default to Check-up
    }

    private fun validateAppointmentInputs(dialogView: View): Boolean {
        val dateEditText = dialogView.findViewById<TextInputEditText>(R.id.dateEditText)
        val timeEditText = dialogView.findViewById<TextInputEditText>(R.id.timeEditText)

        if (dateEditText.text.isNullOrEmpty()) {
            Toast.makeText(this, "Please select a date", Toast.LENGTH_SHORT).show()
            return false
        }

        if (timeEditText.text.isNullOrEmpty()) {
            Toast.makeText(this, "Please select a time", Toast.LENGTH_SHORT).show()
            return false
        }

        return true
    }

    private fun saveNewAppointment(dialogView: View) {
        val date = dialogView.findViewById<TextInputEditText>(R.id.dateEditText).text.toString()
        val time = dialogView.findViewById<TextInputEditText>(R.id.timeEditText).text.toString()
        val durationText = dialogView.findViewById<AutoCompleteTextView>(R.id.durationAutoComplete).text.toString()
        val typeText = dialogView.findViewById<AutoCompleteTextView>(R.id.typeAutoComplete).text.toString()
        val notes = dialogView.findViewById<TextInputEditText>(R.id.notesEditText).text.toString()
        val reminderSet = dialogView.findViewById<SwitchMaterial>(R.id.reminderSwitch).isChecked

        // Extract duration in minutes from the selected option
        val durationInMinutes = durationText.split(" ")[0].toInt()

        // Find the appointment type based on display name
        val appointmentType = AppointmentType.values().find { it.displayName == typeText }
            ?: AppointmentType.CHECKUP

        // Create new appointment
        val appointment = Appointment(
            patientId = patient.id,
            patientName = patient.name,
            doctorId = "doc123", // Current logged-in doctor
            doctorName = "Dr. Smith", // Should be replaced with actual logged-in doctor's name
            date = date,
            time = time,
            duration = durationInMinutes,
            type = appointmentType,
            status = AppointmentStatus.SCHEDULED,
            notes = notes,
            reminderSet = reminderSet
        )

        // Add appointment using schedule manager
        scheduleManager.addAppointment(appointment)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        profileImageHelper.handlePermissionResult(requestCode, permissions, grantResults)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        profileImageHelper.handleActivityResult(requestCode, resultCode, data, profileImage)
    }

    private fun finishWithAnimation() {
        finish()
        overridePendingTransition(R.anim.slide_in_right, R.anim.slide_out_left)
    }

    override fun onBackPressed() {
        super.onBackPressed()
        finishWithAnimation()
    }
}