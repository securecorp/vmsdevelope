from django.db import models
from django.contrib.auth.models import AbstractUser, UserManager

# Create your models here.


class AccountManager(UserManager):
    pass


class Account(AbstractUser):
    objects = AccountManager()
