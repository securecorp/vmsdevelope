from django.shortcuts import render, redirect
from django.contrib.auth.models import User
from .models import Projectresult
from django.contrib.auth.decorators import login_required

@login_required
def main(request):
    projects = Projectresult.objects.all()
    context = {'projects': projects}
    return render(request, 'index.html', context)

def index(request):
    if request.user.is_authenticated:
        return redirect('/projects/main')
    else:
        return redirect('/accounts/login')
