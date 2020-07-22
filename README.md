# CI/CD Persistent - OpenShift Container Platform 4.3
  ref : https://github.com/siamaksade/openshift-cd-demo/

  설치되는 항목.
  <table>
    <tbody>
    <tr>
        <td>Service</td>
        <td>Version</td>  
    </tr>
    <tr>
        <td>Jenkins</td>
        <td>2.204.2</td> 
    </tr>
    <tr>
        <td>Gogs</td>
        <td>0.11.34</td>
    </tr>
    <tr>
        <td>Nexus</td>
        <td>3.13.0</td>
    </tr>
    <tr>
        <td>Sonarqube</td>
        <td>7.1.0</td>
    </tr>        
    </tbody>
  </table>  

  ## 1. CI/CD Project 생성
	
  ```shell
  # Project 생성
  PROJECT_NAME=cicd-test
  oc new-project $PROJECT_NAME --display-name="CI/CD"
  oc project $PROJECT_NAME
  ```  
  <!-- # Jenkins 접근권한 부여 
  oc policy add-role-to-group edit system:serviceaccounts:$PROJECT_NAME -n $PROJECT_NAME
	
  # project 에 admin roll 부여[ocp admin 계정만 실행가능]
  oc adm policy add-role-to-user admin admin -n $PROJECT_NAME >/dev/null 2>&1
	
  # pod-network 에 project 추가[ocp admin 계정만 실행가능]
  oc adm pod-network join-projects --to=$PROJECT_NAME >/dev/null 2>&1
  -->


  ## 2. Jenkins 설치(persistent)
	
  2-1. [Manually] Jenkins PersistentVolume 생성을 위한 준비작업 (jenkins data , maven repository)
  
  ```shell
  # data directory 생성.
  mkdir -m 777 -p /shared/$PROJECT_NAME/jenkins-data

  # maven repository directory 생성.
  mkdir -m 777 -p /shared/$PROJECT_NAME/jenkins-maven-repository

  # /etc/exports 에 추가
  /shared/$PROJECT_NAME/jenkins-data 192.168.138.0/24(rw,sync,no_wdelay,no_root_squash,insecure)
  /shared/$PROJECT_NAME/jenkins-maven-repository 192.168.138.0/24(rw,sync,no_wdelay,no_root_squash,insecure)

  # exports 적용
  exportfs -r
  ```
  2-2. Jenkins 설치.
  ```shell
  # [참고]Jenkins persistent openshift image 로 설치.
  # oc new-app jenkins-persistent -n $PROJECT_NAME

  # Jenkins persistent template 으로 설치.
  PERSISTENT_VOLUME_IP=$(hostname -I | awk '{print $1}')
  oc new-app -f ./yaml/jenkins-persistent-template.yaml \
    --param=PROJECT_NAME=$PROJECT_NAME \
    --param=JENKINS_DATA_DIRECTORY=/shared/$PROJECT_NAME/jenkins-data \
    --param=JENKINS_MAVEN_REPO=/shared/$PROJECT_NAME/jenkins-maven-repository \
    --param=PERSISTENT_VOLUME_IP=$PERSISTENT_VOLUME_IP 
  ```
  ※ Delete PV.
  ```shell
  oc delete pv $PROJECT_NAME-jenkins-data
  oc delete pv $PROJECT_NAME-jenkins-maven-repository
  ```
	
  ## 3. GOGS 설치(persistent)

  3-1. [Manually] Gogs PersistentVolume 생성을 위한 준비작업 (gogs data , gogs postgresql)
  
  ```shell
  # data directory 생성.
  mkdir -m 777 -p /shared/$PROJECT_NAME/gogs-data

  # postgresql directory 생성.
  mkdir -m 777 -p /shared/$PROJECT_NAME/gogs-postgres-data

  # /etc/exports 에 추가
  /shared/$PROJECT_NAME/gogs-data 192.168.138.0/24(rw,sync,no_wdelay,no_root_squash,insecure)
  /shared/$PROJECT_NAME/gogs-postgres-data 192.168.138.0/24(rw,sync,no_wdelay,no_root_squash,insecure)

  # exports 적용
  exportfs -r	
  ```

  3-2. Gogs 설치.	
  ```shell
  # Get HOSTNAME from Jenkins
  HOSTNAME=$(oc get route jenkins -o template --template='{{.spec.host}}' | sed "s/jenkins-$PROJECT_NAME.//g")
  GOGS_HOSTNAME="gogs-$PROJECT_NAME.$HOSTNAME"
  # Get IP Address
  PERSISTENT_VOLUME_IP=$(hostname -I | awk '{print $1}')
	
  # GOGS persistent 설치.
  oc new-app -f ./yaml/gogs-persistent-template.yaml \
    --param=PROJECT_NAME=$PROJECT_NAME \
    --param=GOGS_VERSION=0.11.34 \
    --param=SKIP_TLS_VERIFY=true \
    --param=DATABASE_VERSION=9.6 \
    --param=HOSTNAME=$GOGS_HOSTNAME \
    --param=GOGS_POSTGRESQL_DATA_DIRECTORY=/shared/$PROJECT_NAME/gogs-postgres-data \
    --param=GOGS_DATA_DIRECTORY=/shared/$PROJECT_NAME/gogs-data  \
    --param=PERSISTENT_VOLUME_IP=$PERSISTENT_VOLUME_IP 
  ```
  ※ Delete PV.
  ```shell
  oc delete pv $PROJECT_NAME-gogs-data
  oc delete pv $PROJECT_NAME-gogs-postgres-data
  ```

  ## 4. Sonarqube 설치(persistent)
	
  4-1. [Manually] Sonarqube PersistentVolume 생성을 위한 준비작업 (sonarqube data, sonarqube postgresql)
  
  ```shell
  # data directory 생성.
  mkdir -m 777 -p /shared/$PROJECT_NAME/sonarqube-data

  # postgresql directory 생성.
  mkdir -m 777 -p /shared/$PROJECT_NAME/sonarqube-postgres-data

  # /etc/exports 에 추가
  /shared/$PROJECT_NAME/sonarqube-data 192.168.138.0/24(rw,sync,no_wdelay,no_root_squash,insecure)
  /shared/$PROJECT_NAME/sonarqube-postgres-data 192.168.138.0/24(rw,sync,no_wdelay,no_root_squash,insecure)

  # exports 적용
  exportfs -r	
  ```

  4-2. Sosnarqube 설치.	
  ```shell
  # Get IP Address
  PERSISTENT_VOLUME_IP=$(hostname -I | awk '{print $1}')
	
  # Sonarqube persistent 설치.
  oc new-app -f ./yaml/sonarqube-persistent-template.yaml \
    --param=PROJECT_NAME=$PROJECT_NAME \
    --param=SONARQUBE_MEMORY_LIMIT=2Gi \
    --param=SONAR_POSTGRESQL_DATA_DIRECTORY=/shared/$PROJECT_NAME/sonarqube-postgres-data \
    --param=SONAR_DATA_DIRECTORY=/shared/$PROJECT_NAME/sonarqube-data  \
    --param=PERSISTENT_VOLUME_IP=$PERSISTENT_VOLUME_IP 
  ```
  ※ Delete PV.
  ```shell
  oc delete pv $PROJECT_NAME-sonarqube-data
  oc delete pv $PROJECT_NAME-sonarqube-postgres-data
  ```
	
  ## 5. Nexus 설치(persistent)

  5-1. [Manually] Nexus PersistentVolume 생성을 위한 준비작업 
  - Nexus data 를 위한 1개의 PV 생성
  
  ```shell
  # data directory 생성.
  mkdir -m 777 -p /shared/$PROJECT_NAME/nexus-data

  # /etc/exports 에 추가
  /shared/$PROJECT_NAME/nexus-data 192.168.138.0/24(rw,sync,no_wdelay,no_root_squash,insecure)

  # exports 적용
  exportfs -r
  ```

  5-2. Nexus 설치.	
  ```shell
  # Get IP Address
  PERSISTENT_VOLUME_IP=$(hostname -I | awk '{print $1}')
	
  # Nexus persistent 설치.
  oc new-app -f ./yaml/nexus-persistent-template.yaml \
    --param=PROJECT_NAME=$PROJECT_NAME \
    --param=NEXUS_DATA_DIRECTORY=/shared/$PROJECT_NAME/nexus-data  \
    --param=PERSISTENT_VOLUME_IP=$PERSISTENT_VOLUME_IP 
  ```

  ※ Delete PV.
  ```shell
  oc delete pv $PROJECT_NAME-nexus-data
  ```
