from django.contrib import admin
from django.contrib.auth.admin import UserAdmin

from .forms import AccountCreationForm, AccountChangeForm
from .models import Account


class AccountAdmin(UserAdmin):
    model = Account
    add_form = AccountCreationForm
    form = AccountChangeForm


# Register your models here.
admin.site.register(Account, AccountAdmin)
