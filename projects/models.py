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
        return '%s' % self.vul_name


    class Meta:
        verbose_name_plural = "3. 취약점 관리"


# 점검대상 시스템, 즉 자산을 정의합니다.
class Assets(models.Model):
    service_name = models.CharField(max_length=20, verbose_name = '서비스명', unique=True)
    service_ip = models.CharField(max_length=20, verbose_name = '서비스IP')
    service_domain = models.CharField(max_length=50,verbose_name='서비스URL')
    service_info_os = models.CharField(max_length=20, verbose_name='구성_OS종류')
    service_info_web = models.CharField(max_length=20, verbose_name='구성_WEB종류')
    service_info_db = models.CharField(max_length=20, verbose_name='구성_DB종류')
    service_owner = models.ForeignKey('Owners', on_delete=models.CASCADE, verbose_name='서비스 소유자')

    # project_start = models.DateField(auto_now=True, auto_now_add=False)
    # project_finish = models.DateField(auto_now=True, auto_now_add=False)
    # project_status = models.CharField(
    #     max_length =15,
    #     choices = PROJECT_STATUS_VALUES,
    # )

    def __str__(self):
        return '%s' % self.service_name


    class Meta:
        verbose_name_plural = "1. 자산관리"

# 자산의 소유자를 정의합니다.
class Owners(models.Model):
    name = models.CharField(max_length=20, verbose_name='담당자명')
    contract = models.CharField(max_length=20, verbose_name='전화번호')
    email = models.EmailField(max_length=50, unique=True, verbose_name='이메일')

    def __str__(self):
        return '%s' % self.name


    class Meta:
        verbose_name_plural = "2. 담당자관리"

class Projectresult(models.Model):
    project_name = models.ForeignKey('ProjectManagement', on_delete=models.CASCADE, verbose_name='프로젝트명')
    target = models.ForeignKey('Assets', on_delete=models.CASCADE, verbose_name='점검대상 서비스명')
    vul_name = models.ForeignKey('Vulnerabilities', on_delete=models.CASCADE, verbose_name='취약점 명')
    # vul_name = models.CharField(max_length=10)#'Vulnerabilities', on_delete=models.CASCADE)
    vul_url = models.CharField(max_length=100, verbose_name='취약한 URL')
    vul_param = models.CharField(max_length=50, verbose_name='취약한 파라메터')
    vul_comment = models.TextField(max_length=300, verbose_name='취약점 도출방법')
    vul_cause_comment = models.TextField(max_length=300, verbose_name='기타설명')

    class Meta:
        verbose_name_plural = "5. 진단결과"

    def __str__(self):
        return '%s' % self.vul_url
        # return '%s-%s-%s' % (self.target, self.vul_name, self.vul_url)

class ProjectManagement(models.Model):
    project_name = models.CharField(max_length=50, verbose_name='프로젝트명')
    project_startdate = models.DateField(verbose_name='프로젝트 시작일')
    project_enddate = models.DateField(verbose_name='프로젝트 종료일')
    project_manager = models.ForeignKey('Owners', on_delete=models.CASCADE, verbose_name='담당자명')
    project_price = models.IntegerField(verbose_name='프로젝트 금액')
    project_MM = models.FloatField(max_length=12, verbose_name='프로젝트 투입공수')
    project_description = models.TextField(max_length=200, verbose_name='비고')

    class Meta:
        verbose_name_plural = "4. 프로젝트 관리"

    def __str__(self):
        return '%s' % self.project_name


class Fulfillment(models.Model):
    fulfill_vul = models.ForeignKey('Projectresult', on_delete=models.CASCADE, verbose_name='이행대상')
    fulfill_count = models.IntegerField(verbose_name='이행점검 차수')
    fulfill_vul_param = models.CharField(max_length=50, verbose_name='조치완료 파라메터')
    fulfill_vul_complete = models.IntegerField(verbose_name='조치 파라메터 수')
    fulfill_vul_evi = models.TextField(max_length=300, verbose_name='조치완료 확인')

    def __str__(self):
        return '%s' % self.fulfill_vul
        # return '%s-%s-%s' % (self.target, self.vul_name, self.vul_url)


    class Meta:
        verbose_name_plural = "6. 이행점검 결과"