# backend/api/views.py

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Student, Course, AttendanceRecord, Lecturer
from .serializers import CourseSerializer, AttendanceReportSerializer
import re
from django.utils import timezone
from datetime import timedelta
from django.db.models import Count, Q
from django.db.models.functions import TruncDay

class ListLecturerCourses(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        courses = Course.objects.all().order_by('course_code')
        serializer = CourseSerializer(courses, many=True)
        return Response(serializer.data)

class RecordAttendanceView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        qr_data = request.data.get('qr_data')
        course_code = request.data.get('course_code')

        if not qr_data or not course_code:
            return Response({"error": "QR data and course code are required."}, status=400)

        # --- FIX #1: More Robust QR Code Validation ---
        # We now check if the QR code contains the expected text pattern.
        match = re.search(r"Matric No:\s*(\S+)", qr_data)
        if not match:
            # If the pattern isn't found, it's an invalid QR code.
            return Response({"error": "Invalid QR Code. Please scan a valid student ID QR Code."}, status=400) # 400 Bad Request
        
        matric_no = match.group(1)

        try:
            # Check if a student with this matric number actually exists.
            student = Student.objects.get(matric_no=matric_no)
            course = Course.objects.get(course_code=course_code)
            
            # --- FIX #2: Anti-Double Scan Logic ---
            # We check if a record exists for this student, in this course, within the last 2 hours.
            # You can adjust this time window as needed.
            time_threshold = timezone.now() - timedelta(hours=2)
            recent_scan = AttendanceRecord.objects.filter(
                student=student,
                course=course,
                timestamp__gte=time_threshold
            ).exists()

            if recent_scan:
                # If a recent scan exists, return a specific error message.
                return Response({
                    "error": f"Already Scanned. {student.full_name} has already been marked present for this class."
                }, status=409) # 409 Conflict

            # If all checks pass, create the new attendance record.
            AttendanceRecord.objects.create(student=student, course=course)
            
            # Return a success message including the student's name for better feedback.
            return Response({
                "success": f"Success! Attendance recorded for {student.full_name} ({student.matric_no})."
            }, status=201)

        except Student.DoesNotExist:
            # If the matric number from a valid-looking QR code doesn't exist in the database.
            return Response({"error": f"Student Not Found. No student with matric number '{matric_no}' exists."}, status=404)
        except Course.DoesNotExist:
            return Response({"error": f"Course with code '{course_code}' not found."}, status=404)
        except Exception as e:
            return Response({"error": f"An unexpected server error occurred: {str(e)}"}, status=500)
        
class AttendanceReportView(APIView):
    """
    API endpoint to generate a detailed attendance report for a specific course.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        course_code = request.query_params.get('course_code')
        if not course_code:
            return Response({"error": "A 'course_code' query parameter is required."}, status=400)

        try:
            # 1. Get the course object
            course = Course.objects.get(course_code=course_code)

            # 2. Get all students in the system (a simplification for this project)
            all_students = Student.objects.all().order_by('full_name')

            # 3. Calculate the total number of unique lecture days for this course
            # We group all attendance records by day and count the unique days.
            total_lecture_days = AttendanceRecord.objects.filter(
                course=course
            ).annotate(
                day=TruncDay('timestamp')
            ).values('day').distinct().count()

            if total_lecture_days == 0:
                # If no attendance has been taken, return an empty report
                return Response({
                    "course_title": course.course_title,
                    "total_lecture_days": 0,
                    "report": []
                })

            # 4. Prepare the report for each student
            report_data = []
            for student in all_students:
                # For each student, count how many days they attended this course
                attended_days = AttendanceRecord.objects.filter(
                    course=course,
                    student=student
                ).annotate(
                    day=TruncDay('timestamp')
                ).values('day').distinct().count()
                
                # Calculate the attendance percentage
                percentage = (attended_days / total_lecture_days) * 100 if total_lecture_days > 0 else 0
                
                report_data.append({
                    "matric_no": student.matric_no,
                    "full_name": student.full_name,
                    "attended_days": attended_days,
                    "percentage": round(percentage, 2) # Round to 2 decimal places
                })

            # 5. Assemble and return the final JSON response
            return Response({
                "course_title": course.course_title,
                "total_lecture_days": total_lecture_days,
                "report": report_data
            })

        except Course.DoesNotExist:
            return Response({"error": f"Course with code '{course_code}' not found."}, status=404)
        except Exception as e:
            return Response({"error": f"An unexpected server error occurred: {str(e)}"}, status=500)
class DailyReportView(APIView):
    """
    API endpoint to provide a list of unique lecture days
    and the students who attended on each of those days.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        course_code = request.query_params.get('course_code')
        if not course_code:
            return Response({"error": "A 'course_code' query parameter is required."}, status=400)

        try:
            course = Course.objects.get(course_code=course_code)

            # First, get all unique lecture days for this course
            unique_days = AttendanceRecord.objects.filter(
                course=course
            ).annotate(
                day=TruncDay('timestamp')
            ).values('day').distinct().order_by('-day') # Order by most recent day first

            # Now, for each day, get the list of students who attended
            daily_breakdown = []
            for entry in unique_days:
                lecture_day = entry['day']
                
                # Find all attendance records for this course on this specific day
                attendees_on_day = AttendanceRecord.objects.filter(
                    course=course,
                    timestamp__date=lecture_day
                ).select_related('student').order_by('student__full_name')

                # Get the list of student names and matric numbers
                attendee_list = [
                    {
                        "full_name": record.student.full_name,
                        "matric_no": record.student.matric_no
                    }
                    for record in attendees_on_day
                ]
                
                daily_breakdown.append({
                    "date": lecture_day.strftime("%A, %d %B %Y"), # e.g., "Friday, 31 October 2025"
                    "attendees": attendee_list
                })

            return Response({
                "course_title": course.course_title,
                "daily_breakdown": daily_breakdown
            })

        except Course.DoesNotExist:
            return Response({"error": f"Course with code '{course_code}' not found."}, status=404)
        except Exception as e:
            return Response({"error": f"An unexpected server error occurred: {str(e)}"}, status=500)