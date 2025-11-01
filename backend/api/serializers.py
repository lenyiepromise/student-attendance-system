from rest_framework import serializers
from .models import Student, Course, AttendanceRecord

class StudentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Student
        fields = ['matric_no', 'full_name', 'department']

class CourseSerializer(serializers.ModelSerializer):
    # This will look up the lecturer's full name.
    # It will show 'N/A' if no lecturer is assigned.
    lecturer_name = serializers.CharField(source='lecturer.full_name', read_only=True, default='N/A')

    class Meta:
        model = Course
        fields = ['course_code', 'course_title', 'lecturer_name']

class AttendanceReportSerializer(serializers.ModelSerializer):
    student = StudentSerializer()
    class Meta:
        model = AttendanceRecord
        fields = ['student', 'timestamp']