from django.db import models
from django.conf import settings
from django.contrib.auth.models import AbstractUser

# Create your models here.
class birder(models.Model):
    id = models.CharField(max_length=20, primary_key=True)
    class Meta:
        db_table = 'birder'

class species(models.Model):
    species_code = models.CharField(max_length=20, primary_key=True)
    common_name = models.CharField(max_length=100)
    scientific_name = models.CharField(max_length=100)
    class Meta:
        db_table = 'species'

class log(models.Model):
    num = models.BigAutoField(primary_key=True)
    
    birder = models.ForeignKey(
        birder,
        on_delete=models.CASCADE,
        db_column='id',
        to_field='id'
    )
    
    species_code = models.ForeignKey(
        species,
        on_delete=models.SET_NULL,
        null=True,
        db_column='species_code',
        to_field='species_code'
    )
    
    location = models.CharField(max_length=100)
    
    longitude = models.DecimalField(max_digits=5, decimal_places=2)
    latitude = models.DecimalField(max_digits=4, decimal_places=2)
    obs_date = models.DateTimeField()

    class Meta:
        db_table = 'log'