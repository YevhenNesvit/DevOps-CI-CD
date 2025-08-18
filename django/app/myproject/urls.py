from django.contrib import admin
from django.http import HttpResponse
from django.urls import path

def index(_):
    return HttpResponse('Hello from Django in Docker (Nginx → Django → PostgreSQL)!')

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', index, name='index'),
]
