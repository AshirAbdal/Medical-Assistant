package com.example.androidapp_part22.fragments


import com.example.androidapp_part22.activities.PatientType

public final class AllPatientsFragment : PatientListFragment() {
    override val patientType: PatientType = PatientType.ALL_PATIENTS
}