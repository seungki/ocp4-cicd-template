# CI/CD Persistent - OpenShift Container Platform 4.3



  ## 1. CI/CD Project 생성
	
  ```shell
  # Project 생성
	oc new-project $PROJECT_NAME --display-name="CI/CD"
	
	# Jenkins 접근권한 부여
	oc policy add-role-to-group edit system:serviceaccounts:$PROJECT_NAME -n $PROJECT_NAME
	
	# project 에 admin roll 부여[ocp admin 계정만 실행가능]
	oc adm policy add-role-to-user admin admin -n $PROJECT_NAME >/dev/null 2>&1
	
	# pod-network 에 project 추가[ocp admin 계정만 실행가능]
	oc adm pod-network join-projects --to=$PROJECT_NAME >/dev/null 2>&1
  ```  
	
  ## 2. Jenkins 설치(persistent)
	
  ```shell
  # Jenkins persistent 설치.
	oc new-app jenkins-persistent -n $PROJECT_NAME
  ```