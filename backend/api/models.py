from django.db import models
from django.contrib.auth.models import User
import qrcode
from io import BytesIO
from django.core.files import File
from PIL import Image

class Student(models.Model):
    matric_no = models.CharField(max_length=20, unique=True, primary_key=True)
    full_name = models.CharField(max_length=200)
    gender = models.CharField(max_length=10)
    department = models.CharField(max_length=100)
    qr_code_image = models.ImageField(upload_to='qr_codes/', blank=True, null=True)

    def __str__(self):
        return self.full_name
    
class Lecturer(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    staff_id = models.CharField(max_length=20, unique=True)
    full_name = models.CharField(max_length=200)
    department = models.CharField(max_length=100)

    def __str__(self):
        return self.full_name

class Course(models.Model):
    course_code = models.CharField(max_length=10, unique=True, primary_key=True)
    course_title = models.CharField(max_length=200)
    lecturer = models.ForeignKey(Lecturer, on_delete=models.SET_NULL, blank=True, null=True)

    def __str__(self):
        return self.course_title

class AttendanceRecord(models.Model):
    student = models.ForeignKey(Student, on_delete=models.CASCADE)
    course = models.ForeignKey(Course, on_delete=models.CASCADE)
    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.student.full_name} - {self.course.course_code} at {self.timestamp.strftime('%Y-%m-%d %H:%M')}"