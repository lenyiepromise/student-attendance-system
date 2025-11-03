# backend/api/admin.py

from django.contrib import admin
from django.urls import path
from django.shortcuts import render, redirect
from django.contrib import messages
from .models import Student, Lecturer, Course, AttendanceRecord
import csv
import io

class StudentAdmin(admin.ModelAdmin):
    list_display = ('matric_no', 'full_name', 'department', 'qr_code_image')
    readonly_fields = ('qr_code_image',)
    
    # This tells Django to use our custom template for the student list page
    change_list_template = "admin/change_list.html"

    # This adds our custom URL for the upload page
    def get_urls(self):
        urls = super().get_urls()
        my_urls = [
            path('upload-csv/', self.upload_csv, name='upload_csv'),
        ]
        return my_urls + urls

    # This is the view that handles the CSV upload logic
    def upload_csv(self, request):
        if request.method == "POST":
            csv_file = request.FILES.get("csv_file")
            
            if not csv_file:
                messages.error(request, 'No file was uploaded.')
                return redirect("..")
            
            if not csv_file.name.endswith('.csv'):
                messages.error(request, 'This is not a CSV file.')
                return redirect("..")

            try:
                # Read the file in memory
                decoded_file = csv_file.read().decode('utf-8')
                io_string = io.StringIO(decoded_file)
                
                # Skip the header row
                next(io_string) 
                
                students_created = 0
                students_updated = 0
                for row in csv.reader(io_string, delimiter=','):
                    # Assumes CSV format: matric_no,full_name,gender,department
                    # We use .strip() to remove any accidental whitespace
                    matric_no = row[0].strip()
                    
                    # Use update_or_create to either create a new student or update an existing one
                    _, created = Student.objects.update_or_create(
                        matric_no=matric_no,
                        defaults={
                            'full_name': row[1].strip(),
                            'gender': row[2].strip(),
                            'department': row[3].strip(),
                        }
                    )
                    if created:
                        students_created += 1
                    else:
                        students_updated += 1
                
                messages.success(request, f"Upload complete. Created: {students_created} new students. Updated: {students_updated} existing students.")
            
            except Exception as e:
                messages.error(request, f"An error occurred while processing the file: {e}")

            # Redirect back to the student list page
            return redirect("..")

        # This is a simple form for the upload page, we can create a template for it later
        form = '<form action="." method="POST" enctype="multipart/form-data">' \
               + '<p>Upload a CSV file with columns: matric_no, full_name, gender, department</p>' \
               + '<input type="file" name="csv_file" required>' \
               + '<button type="submit">Upload</button>' \
               + '</form>'

        # We will render this form directly, which is simpler
        context = {'form': form}
        return render(request, "admin/csv_upload.html", context)


# Unregister and re-register Student with our custom admin class
try:
    admin.site.unregister(Student)
except admin.sites.NotRegistered:
    pass
admin.site.register(Student, StudentAdmin)

# These models use the default admin interface
admin.site.register(Lecturer)
admin.site.register(Course)
admin.site.register(AttendanceRecord)