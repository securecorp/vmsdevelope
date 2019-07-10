from django.contrib import admin

from .models import Projectresult, Vulnerabilities, Owners, Assets, Fulfillment



admin.site.site_header = "Vulnerability Management System"
admin.site.site_title = "VMS Portal"
admin.site.index_title = "Welcome to VMS System"

class FulfillmentInline(admin.StackedInline):
    model = Fulfillment


def merge_project(self, obj):
    return self.hero_set.count()

class ProjectResultAdmin(admin.ModelAdmin):
    # summernote_fields = '__all__'
    # search_fields = ['target']
    sort = ['target']
    filtered = ['target']
    list_display = ['target','vul_name','vul_url','vul_param','vul_comment','vul_cause_comment']
    inlines = [FulfillmentInline]

    # class Meta:
    #     model = Fulfillment
    #     include = ["fulfill_vul"]


class FulfillmentAdmin(admin.ModelAdmin):
    # summernote_fields = '__all__'
    search_fields = ['fulfill_vul']
    list_display = ['fulfill_vul','fulfill_vul_param','fulfill_vul_evi']
    #inlines = [ProjectsInline]

class VulnerabilitiesAdmin(admin.ModelAdmin):
    search_fields = ['vul_name']
    list_display = ['vul_category','vul_id', 'vul_name', 'vul_level','vul_description']

admin.site.register(Projectresult, ProjectResultAdmin)
admin.site.register(Vulnerabilities, VulnerabilitiesAdmin)
admin.site.register(Owners)
admin.site.register(Assets)
admin.site.register(Fulfillment, FulfillmentAdmin)