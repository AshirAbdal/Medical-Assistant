package com.example.androidapp_part22.fragments

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.TextView
import androidx.appcompat.app.AlertDialog
import androidx.fragment.app.Fragment
import com.example.androidapp_part22.R
import com.example.androidapp_part22.models.Patient
import com.google.android.material.floatingactionbutton.FloatingActionButton
import com.google.android.material.snackbar.Snackbar
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class DiagnosisFragment : Fragment() {

    private var patient: Patient? = null
    private lateinit var noDiagnosisText: TextView
    private lateinit var diagnosisContainer: LinearLayout
    private lateinit var addDiagnosisFab: FloatingActionButton

    // List to store diagnosis entries
    private val diagnosisEntries = mutableListOf<DiagnosisEntry>()

    companion object {
        fun newInstance(patient: Patient): DiagnosisFragment {
            val fragment = DiagnosisFragment()
            val args = Bundle()
            args.putParcelable("patient", patient)
            fragment.arguments = args
            return fragment
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        patient = arguments?.getParcelable("patient")
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_diagnosis, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        // Initialize views
        noDiagnosisText = view.findViewById(R.id.noDiagnosisText)
        diagnosisContainer = view.findViewById(R.id.diagnosisContainer)
        addDiagnosisFab = view.findViewById(R.id.addDiagnosisFab)

        // Setup FAB
        addDiagnosisFab.setOnClickListener {
            showAddDiagnosisDialog()
        }

        // Load initial diagnosis data
        loadDiagnosisData()
    }

    private fun loadDiagnosisData() {
        // Clear existing entries
        diagnosisEntries.clear()
        diagnosisContainer.removeAllViews()

        // In a real app, you would fetch diagnosis entries from a database
        // For demo, we'll add some sample entries based on patient ID
        if (patient != null) {
            val mockEntries = getMockDiagnosisEntries(patient!!.id)
            diagnosisEntries.addAll(mockEntries)
        }

        // Display entries
        if (diagnosisEntries.isEmpty()) {
            noDiagnosisText.visibility = View.VISIBLE
            diagnosisContainer.visibility = View.GONE
        } else {
            noDiagnosisText.visibility = View.GONE
            diagnosisContainer.visibility = View.VISIBLE

            // Add diagnosis entry views
            for (entry in diagnosisEntries) {
                addDiagnosisEntryView(entry)
            }
        }
    }

    private fun getMockDiagnosisEntries(patientId: String): List<DiagnosisEntry> {
        return when {
            patientId.contains("1") -> listOf(
                DiagnosisEntry(
                    "Hypertension (I10)",
                    "March 15, 2025",
                    "Essential (primary) hypertension. Patient presents with consistently elevated blood pressure readings above 140/90 mmHg."
                ),
                DiagnosisEntry(
                    "Type 2 Diabetes (E11.9)",
                    "February 20, 2025",
                    "Type 2 diabetes mellitus without complications. HbA1c: 7.8%"
                )
            )
            patientId.contains("3") -> listOf(
                DiagnosisEntry(
                    "Osteoarthritis (M19.90)",
                    "March 25, 2025",
                    "Primary osteoarthritis affecting both knees and fingers. X-rays show moderate joint space narrowing."
                ),
                DiagnosisEntry(
                    "Hyperlipidemia (E78.5)",
                    "March 1, 2025",
                    "Mixed hyperlipidemia with elevated LDL (155 mg/dL) and triglycerides (210 mg/dL)."
                ),
                DiagnosisEntry(
                    "Gastroesophageal Reflux Disease (K21.9)",
                    "January 10, 2025",
                    "GERD without esophagitis. Patient complains of frequent heartburn, especially after meals."
                )
            )
            else -> listOf(
                DiagnosisEntry(
                    "Iron Deficiency Anemia (D50.9)",
                    "March 10, 2025",
                    "Iron deficiency anemia, unspecified. Hemoglobin: 10.2 g/dL, Ferritin: 8 ng/mL"
                )
            )
        }
    }

    private fun addDiagnosisEntryView(entry: DiagnosisEntry) {
        val inflater = LayoutInflater.from(context)
        val entryView = inflater.inflate(R.layout.item_diagnosis, diagnosisContainer, false)

        // Find views in the entry layout
        val titleText = entryView.findViewById<TextView>(R.id.diagnosisTitleText)
        val dateText = entryView.findViewById<TextView>(R.id.diagnosisDateText)
        val descriptionText = entryView.findViewById<TextView>(R.id.diagnosisDescriptionText)
        val editButton = entryView.findViewById<Button>(R.id.editDiagnosisButton)
        val deleteButton = entryView.findViewById<Button>(R.id.deleteDiagnosisButton)

        // Set data to views
        titleText.text = entry.title
        dateText.text = "Date: ${entry.date}"
        descriptionText.text = entry.description

        // Set click listeners
        editButton.setOnClickListener {
            showEditDiagnosisDialog(entry, entryView)
        }

        deleteButton.setOnClickListener {
            confirmDeleteDiagnosis(entry, entryView)
        }

        // Add the entry view to the container
        diagnosisContainer.addView(entryView)
    }

    private fun showAddDiagnosisDialog() {
        val dialogView = LayoutInflater.from(requireContext())
            .inflate(R.layout.dialog_add_diagnosis, null)

        val titleEditText = dialogView.findViewById<EditText>(R.id.diagnosisTitleEditText)
        val descriptionEditText = dialogView.findViewById<EditText>(R.id.diagnosisDescriptionEditText)

        val dialog = AlertDialog.Builder(requireContext())
            .setTitle("Add Diagnosis")
            .setView(dialogView)
            .setPositiveButton("Save", null) // Set null to prevent automatic dismissal
            .setNegativeButton("Cancel", null)
            .create()

        dialog.setOnShowListener {
            val saveButton = dialog.getButton(AlertDialog.BUTTON_POSITIVE)
            saveButton.setOnClickListener {
                val title = titleEditText.text.toString().trim()
                val description = descriptionEditText.text.toString().trim()

                if (title.isEmpty()) {
                    titleEditText.error = "Title is required"
                    return@setOnClickListener
                }

                // Get current date
                val dateFormat = SimpleDateFormat("MMMM dd, yyyy", Locale.getDefault())
                val currentDate = dateFormat.format(Date())

                // Create new diagnosis entry
                val newEntry = DiagnosisEntry(title, currentDate, description)
                diagnosisEntries.add(0, newEntry) // Add to beginning of the list

                // Update UI
                if (diagnosisContainer.visibility == View.GONE) {
                    noDiagnosisText.visibility = View.GONE
                    diagnosisContainer.visibility = View.VISIBLE
                }

                // Add the new entry view
                addDiagnosisEntryView(newEntry)

                // Show success message
                Snackbar.make(requireView(), "Diagnosis added successfully", Snackbar.LENGTH_SHORT).show()

                // Dismiss the dialog
                dialog.dismiss()
            }
        }

        dialog.show()
    }

    private fun showEditDiagnosisDialog(entry: DiagnosisEntry, entryView: View) {
        val dialogView = LayoutInflater.from(requireContext())
            .inflate(R.layout.dialog_add_diagnosis, null)

        val titleEditText = dialogView.findViewById<EditText>(R.id.diagnosisTitleEditText)
        val descriptionEditText = dialogView.findViewById<EditText>(R.id.diagnosisDescriptionEditText)

        // Pre-fill with existing data
        titleEditText.setText(entry.title)
        descriptionEditText.setText(entry.description)

        val dialog = AlertDialog.Builder(requireContext())
            .setTitle("Edit Diagnosis")
            .setView(dialogView)
            .setPositiveButton("Update", null) // Set null to prevent automatic dismissal
            .setNegativeButton("Cancel", null)
            .create()

        dialog.setOnShowListener {
            val updateButton = dialog.getButton(AlertDialog.BUTTON_POSITIVE)
            updateButton.setOnClickListener {
                val title = titleEditText.text.toString().trim()
                val description = descriptionEditText.text.toString().trim()

                if (title.isEmpty()) {
                    titleEditText.error = "Title is required"
                    return@setOnClickListener
                }

                // Update entry
                entry.title = title
                entry.description = description

                // Update UI
                val titleText = entryView.findViewById<TextView>(R.id.diagnosisTitleText)
                val descriptionText = entryView.findViewById<TextView>(R.id.diagnosisDescriptionText)
                titleText.text = title
                descriptionText.text = description

                // Show success message
                Snackbar.make(requireView(), "Diagnosis updated successfully", Snackbar.LENGTH_SHORT).show()

                // Dismiss the dialog
                dialog.dismiss()
            }
        }

        dialog.show()
    }

    private fun confirmDeleteDiagnosis(entry: DiagnosisEntry, entryView: View) {
        AlertDialog.Builder(requireContext())
            .setTitle("Delete Diagnosis")
            .setMessage("Are you sure you want to delete this diagnosis entry?")
            .setPositiveButton("Delete") { _, _ ->
                // Remove from data list
                diagnosisEntries.remove(entry)

                // Remove from UI
                diagnosisContainer.removeView(entryView)

                // Show empty state if no entries left
                if (diagnosisEntries.isEmpty()) {
                    noDiagnosisText.visibility = View.VISIBLE
                    diagnosisContainer.visibility = View.GONE
                }

                // Show success message
                Snackbar.make(requireView(), "Diagnosis deleted", Snackbar.LENGTH_SHORT).show()
            }
            .setNegativeButton("Cancel", null)
            .show()
    }

    // Data class for diagnosis entries
    data class DiagnosisEntry(
        var title: String,
        val date: String,
        var description: String
    )
}