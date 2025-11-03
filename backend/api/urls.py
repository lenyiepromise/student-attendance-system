# backend/api/urls.py

from django.urls import path
from .views import ListLecturerCourses, RecordAttendanceView, AttendanceReportView, DailyReportView

urlpatterns = [
    path('courses/', ListLecturerCourses.as_view(), name='lecturer-courses'),
    path('record-attendance/', RecordAttendanceView.as_view(), name='record-attendance'),
    path('report/summary/', AttendanceReportView.as_view(), name='attendance-summary-report'),
    path('report/daily/', DailyReportView.as_view(), name='attendance-daily-report'),
]