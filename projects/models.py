from django.db import models


#선택창을 사전 정의하여 상수화 합니다.
VUL_CATEGORY_CHOICES = (
    ('Web', 'Web Application'),
    ('And', 'Android Mobile App'),
    ('iOS', 'iOS Mobile App'),
    ('C/S', 'Client & Server Program')
)

VUL_LEVEL_CHOICES = (
    ('H', 'High'),
    ('M', 'Medium'),
    ('L', 'Low'),
    ('I', 'Information')
)

PROJECT_STATUS_VALUES = (
    ('unorganized', 'unorganized'),
    ('standby', 'standby'),
    ('progressing', 'progressing'),
    ('confirming', 'confirming'),
    ('finished', 'finished'),
)


#취약점을 정의합니다.
class Vulnerabilities(models.Model):

    vul_category = models.CharField(
        max_length=5,
        choices=VUL_CATEGORY_CHOICES,
        default='Web',
        verbose_name = '취약점 구분'
    )

    vul_id = models.CharField(max_length=10, verbose_name = '취약점 ID')

    vul_name = models.CharField(max_length=50, verbose_name = '취약점명')

    vul_level = models.CharField(
        max_length=3,
        choices=VUL_LEVEL_CHOICES,
        verbose_name='위험도'
    )

    vul_description = models.CharField(max_length=100, verbose_name = '취약점 설명')

    vul_countermeasure = models.TextField(max_length=300,verbose_name = '취약점 조치방법')

    vul_countermeasure_code = models.TextField(max_length=300, verbose_name = '취약점 조치 샘플코드')

    def __str__(self):
        return self.vul_name


    class Meta:
        verbose_name_plural = "3. 취약점 관리"


# 점검대상 시스템, 즉 자산을 정의합니다.
class Assets(models.Model):
    service_name = models.CharField(max_length=20, unique=True)
    service_ip = models.CharField(max_length=20)
    service_owner = models.ForeignKey('Owners', on_delete=models.CASCADE)

    # project_start = models.DateField(auto_now=True, auto_now_add=False)
    # project_finish = models.DateField(auto_now=True, auto_now_add=False)
    # project_status = models.CharField(
    #     max_length =15,
    #     choices = PROJECT_STATUS_VALUES,
    # )

    def __str__(self):
        return self.service_name


    class Meta:
        verbose_name_plural = "1. 자산관리"

# 자산의 소유자를 정의합니다.
class Owners(models.Model):
    name = models.CharField(max_length=20)
    contract = models.CharField(max_length=20)
    email = models.EmailField(max_length=50, unique=True)

    def __str__(self):
        return self.name


    class Meta:
        verbose_name_plural = "2. 담당자관리"

class Projectresult(models.Model):
    target = models.ForeignKey('Assets', on_delete=models.CASCADE)
    vul_name = models.ForeignKey('Vulnerabilities', on_delete=models.CASCADE)
    # vul_name = models.CharField(max_length=10)#'Vulnerabilities', on_delete=models.CASCADE)
    vul_url = models.CharField(max_length=100)
    vul_param = models.CharField(max_length=50)
    vul_comment = models.CharField(max_length=300)
    vul_cause_comment = models.TextField(max_length=300)

    class Meta:
        verbose_name_plural = "4. 진단결과"

    def __str__(self):
        return self.vul_url
        # return '%s-%s-%s' % (self.target, self.vul_name, self.vul_url)

class Fulfillment(models.Model):
    fulfill_vul = models.ForeignKey('Projectresult', on_delete=models.CASCADE)
    # vul_name = models.ForeignKey('Vulnerabilities', on_delete=models.CASCADE)
    # # vul_name = models.CharField(max_length=10)#'Vulnerabilities', on_delete=models.CASCADE)
    # vul_url = models.CharField(max_length=100)
    fulfill_vul_param = models.CharField(max_length=50)
    # vul_comment = models.CharField(max_length=300)
    fulfill_vul_evi = models.TextField(max_length=300)

    def __str__(self):
        return self.fulfill_vul
        # return '%s-%s-%s' % (self.target, self.vul_name, self.vul_url)


    class Meta:
        verbose_name_plural = "5. 이행점검 결과"