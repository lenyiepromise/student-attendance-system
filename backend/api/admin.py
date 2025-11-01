# backend/api/admin.py

from django.contrib import admin
from .models import Student, Lecturer, Course, AttendanceRecord

class StudentAdmin(admin.ModelAdmin):
    """
    Customizes the way the Student model is displayed in the admin panel.
    """
    # This shows these fields in the list view of all students
    list_display = ('matric_no', 'full_name', 'department', 'qr_code_image')
    
    # This makes the QR code field read-only in the admin panel.
    # Our code generates it, so no one should be able to upload one manually.
    readonly_fields = ('qr_code_image',)

    # --- THIS IS THE KEY PART OF THE FIX ---
    # This method dynamically shows or hides fields based on whether
    # you are ADDING a new student or EDITING an existing one.
    def get_fields(self, request, obj=None):
        if obj: # If 'obj' exists, it means we are editing an existing student
            return ('matric_no', 'full_name', 'gender', 'department', 'qr_code_image')
        else: # If 'obj' is None, it means we are adding a new student
            # We HIDE the qr_code_image field on the "Add student" page
            return ('matric_no', 'full_name', 'gender', 'department')

# We unregister the default Student admin and register our custom one
admin.site.register(Student, StudentAdmin)

# Register the other models as normal
admin.site.register(Lecturer)
admin.site.register(Course)
admin.site.register(AttendanceRecord)