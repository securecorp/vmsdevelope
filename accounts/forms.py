from django import forms
from django.contrib.auth.forms import UserCreationForm, UserChangeForm
from .models import Account


class AccountCreationForm(UserCreationForm):

    class Meta(UserCreationForm.Meta):
        model = Account
        fields = UserCreationForm.Meta.fields


class AccountChangeForm(UserChangeForm):

    class Meta:
        model = Account
        fields = UserChangeForm.Meta.fields