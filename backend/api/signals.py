# backend/api/signals.py

from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Student
import qrcode
from io import BytesIO
from django.core.files import File

# Note: We no longer need to import PIL.Image

@receiver(post_save, sender=Student)
def create_student_qr_code(sender, instance, created, **kwargs):
    """
    This function is triggered after a Student object is saved.
    """
    # 'created' is a boolean that is True only if a new record was created.
    if created:
        # Generate the data string for the QR code
        qr_data = f"Matric No: {instance.matric_no}\nName: {instance.full_name}\nGender: {instance.gender}"
        
        # Generate the QR code directly as an image object
        img = qrcode.make(qr_data)
        
        # Save the image to a temporary buffer in memory
        buffer = BytesIO()
        img.save(buffer, format='PNG') # Specify the format
        
        # Create a filename and save the image from the buffer to the student's field
        fname = f'qr_code-{instance.matric_no}.png'
        instance.qr_code_image.save(fname, File(buffer), save=True)