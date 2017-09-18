[![Build Status](https://travis-ci.org/IBM/GameOn-Java-Microservices-on-Kubernetes.svg?branch=master)](https://travis-ci.org/IBM/GameOn-Java-Microservices-on-Kubernetes)

# 폴리글롯 에코시스템 내에서 쿠버네티스에 GameOn! Java 마이크로서비스 구축하기

*다른 언어로 보기: [English](README.md).*

본 코드는 폴리글롯 에코시스템과 공존하는 쿠버네티스 클러스에 마이크로서비스 기반의 애플리케이션인 [Game On!](https://book.gameontext.org)을 구축하는 방법을 소개합니다. Game On!은 레트로 스타일의 텍스트 기반 어드벤처 게임으로, 마이크로서비스 아키텍처 및 관련 개념 분석에 사용될 수 있습니다. GameOn! 구축에는 코어(core)와 플랫폼(platform)이라는 두 가지 마이크로서비스들의 집합이 수반됩니다. 코어 마이크로서비스는 Java로 작성되며, 다른 폴리글롯 마이크로서비스들과 공존합니다. 아울러, 여러 마이크로서비스들에 대하여 서비스 발견, 등록, 라우팅 등을 제공하는 플랫폼 서비스가 있습니다. 두 가지 모두 쿠버네티스 클러스터에 의해 관리되는 도커(Docker) 컨테이너에서 실행됩니다.

![gameon](images/gameon-microservices-code2.png)

### 코어 마이크로서비스:

[MicroProfile](http://microprofile.io) 스펙의 일부로서 [JAX-RS](https://en.wikipedia.org/wiki/Java_API_for_RESTful_Web_Services), [CDI](https://dzone.com/articles/cdi-di-p1) 등을 사용하는 다섯 가지의 Java 마이크로서비스가 있습니다.

- [Player](https://github.com/gameontext/gameon-player): CRUD 오퍼레이션과 API 토큰 관리를 위한 공용 API를 제공하는 player Java 마이크로서비스로서, 게임 플레이어를 나타냅니다.
- [Auth](https://github.com/gameontext/gameon-auth): 선택된 "소셜 로그인"을 통해 플레이어들의 연결과 신원 확인을 지원하는 Java 마이크로서비스입니다.
- [Mediator](https://github.com/gameontext/gameon-mediator): WebSphere Liberty 기반의 Java에 구현되는 서비스로서, Websocket를 통해 플레이어들을 룸(room)으로 연결합니다.
- [Map](https://github.com/gameontext/gameon-map): Java EE 애플리케이션으로, JAX-RS 기반의 공용 REST API를 제공하는 WebSphere Liberty에서 실행되고, NoSQL 데이터 저장소(couchdb 또는 Cloudant)에 데이터를 저장합니다.
- [Room](https://github.com/gameontext/gameon-room): Java 기반의 room 구현.

이 밖에도, Proxy와 WebApp이 코어 마이크로서비스를 완성합니다.

- [Proxy](https://github.com/gameontext/gameon-proxy): HAProxy를 기반으로 하여 전체 애플리케이션의 단일 파사드로서 API 컬렉션의 표면화를 담당합니다.
- [WebApp](https://github.com/gameontext/gameon-webapp): Webapp은 UI의 프론트엔드를 구성하는 정적 파일을 제공하는 단순 nginx 프로세스입니다.

### 플랫폼 서비스:

- [Service Discovery, Registry 및 Routing](https://www.amalgam8.io/): 서비스 레지스트리 및 라우팅 구성요소로서 이를 통해 서비스 발견과 서비스 프록싱(Service Proxying)이 구현됩니다. 이 밖에도 각 마이크로서비스와 관련된 사이드카가 레지스트리를 통해 마이크로서비스를 자동 등록합니다.
- [Redis](): 사이드카에 의해 사용되는 주소를 저장합니다
- [Kafka](https://kafka.apache.org): 서비스와 플랫폼에서 사용되는 Pub/Sub 솔루션입니다.

## 전제조건

게임을 로컬에 구축하려면 [여기](https://github.com/gameontext/gameon#local-room-development)의 GameOn 리포지토리에 있는 docker-compose를 통해 지시사항을 따르십시오.

이 곳에 소개된 절차를 따르려면 IBM 블루믹스 컨테이너 서비스([IBM Bluemix Container Service](https://github.com/IBM/container-journey-template))를 통해 쿠버네티스 클러스터를 생성하여 클라우드에 구축하십시오. 이 곳의 코드는 Travis를 사용하여 [블루믹스 컨테이너 서비스의 쿠버네티스 클러스터](https://console.ng.bluemix.net/docs/containers/cs_ov.html#cs_ov)에 대하여 정기적으로 테스트됩니다.

## 블루믹스에 쿠버네티스 클러스터 구축하기
GameOn!을 블루믹스에 직접 구축하려면, 아래의 ‘Deploy to Bluemix’ 버튼을 클릭하여 샘플 구축을 위한 블루믹스 데브옵스 서비스 툴체인과 파이프라인을 생성하십시오. 그렇지 않은 경우, [단계](#단계)로 이동하십시오.

> 우선, 쿠버네티스 클러스터를 생성한 뒤, 사용자의 블루믹스 계정에 완전히 구축되었는지 확인해야 합니다.

[![Create Toolchain](https://github.com/IBM/container-journey-template/blob/master/images/button.png)](https://console.ng.bluemix.net/devops/setup/deploy/?repository=https://github.com/IBM/GameOn-Java-Microservices-on-Kubernetes)

[툴체인 설명](https://github.com/IBM/container-journey-template/blob/master/Toolchain_Instructions_new.md)에 따라 툴체인 및 파이프라인을 완료하십시오.

## 단계
1. [코어 서비스 yaml 파일 수정하기](#1-코어-서비스-yaml-파일-수정하기)
2. [클러스터 볼륨 생성하기](#2-클러스터-볼륨-생성하기)
3. [플랫폼 서비스 생성하기](#3-플랫폼-서비스-생성하기)
4. [코어 서비스 생성하기](#4-코어-서비스-생성하기)
5. [GameOn 앱 살펴보기](#5-GameOn-앱-살펴보기)
  - 5.1 [소셜 로그인 추가하기](#51-소셜-로그인-추가하기)
  - 5.2 [룸(Room) 추가하기](#52-룸(room)-추가하기)

#### [문제 해결](#문제-해결-1)

# 1. 코어 서비스 yaml 파일 수정하기
`gameon-configmap.yaml` 파일에서 다음과 같은 값을 변경하십시오. `PLACEHOLDER_IP` 값을 클러스터의 퍼블릭 IP값으로 대체 하십시오. `bx cs workers <your-cluster-name>` 명령으로 Bluemix Container 서비스에 대한 IP을 얻을 수 있습니다. 예) `192.168.99.100`
> minikube에서는, `minikube ip` 명령으로 IP를 얻을 수 있습니다

```yaml
FRONT_END_PLAYER_URL: https://PLACEHOLDER_IP:30443/players/v1/accounts
FRONT_END_SUCCESS_CALLBACK: https://PLACEHOLDER_IP:30443/#/login/callback
FRONT_END_FAIL_CALLBACK: https://PLACEHOLDER_IP:30443/#/game
FRONT_END_AUTH_URL: https://PLACEHOLDER_IP:30443/auth
...
PROXY_DOCKER_HOST: 'PLACEHOLDER_IP'
```

값을 변경하는 가장 쉬운 방법은 다음 명령을 실행하거나 
`sed -i s#PLACEHOLDER_IP#<Public-IP-of-your-cluster#g gameon-configmap.yaml`  
혹은 `sed -i '' s#PLACEHOLDER_IP#<Public-IP-of-your-cluster>#g gameon-configmap.yaml` 을 실행하는 것입니다.

그 다음, 클러스터에 config map을 적용합니다:
```bash
$ kubectl create -f gameon-configmap.yaml
configmap "gameon-env" created
```

# 2. 클러스터 볼륨 생성하기
사용자 클러스터에 볼륨을 생성해야 합니다. 이때, 제공된 yaml 파일을 사용할 수 있습니다. 클러스터 볼륨은 필요한 keystore를 저장하며 [코어 서비스](#코어-서비스)에서 사용됩니다.
```bash
$ kubectl create -f local-volume.yaml
persistent volumes "local-volume-1" created
persistent volumes "keystore-claim" created
```

이제, **setup.yaml** 파일을 사용하여 필요한 keystore를 생성할 수 있습니다. 이때, keystore와 함께 Pod가 생성될 것입니다.
```bash
$ kubectl create -f setup.yaml
```

> [containers/setup/ 폴더](containers/setup)에서 keystore 생성을 위한 Dockerfile과 스크립트를 찾을 수 있습니다. 제공된 Dockerfile을 이용하면 나만의 이미지 구축이 가능합니다.

setup Pod가 실행되었다면, 이후로 다시 실행되지 않습니다. `kubectl delete pod setup` 명령을 이용하여 Pod를 삭제 할 수 있습니다 (선택 사항).

Pod이 keystore 가져오기에 성공했는지 여부를 Pod의 로그를 통해 확인할 수 있습니다.
```bash
$ kubectl logs setup
Checking for keytool...
Checking for openssl...
Generating key stores using <Public-IP-of-your-cluster>:30443
Certificate stored in file <keystore/gameonca.crt>
Certificate was added to keystore
Certificate reply was installed in keystore
Certificate stored in file <keystore/app.pem>
MAC verified OK
Certificate was added to keystore
Entry for alias <*> successfully imported.
...
Entry for alias <**> successfully imported.
Import command completed:  104 entries successfully imported, 0 entries failed or cancelled
```

# 3. 플랫폼 서비스 생성하기
이제, 게임 앱의 [플랫폼 서비스](#플랫폼-서비스)와 배치를 생성할 수 있습니다.
```bash
$ kubectl create -f platform
OR alternatively
$ kubectl create -f platform/controller.yaml
$ kubectl create -f platform/<file-name>.yaml
...
$ kubectl create -f platform/registry.yaml
```

컨트롤 플래인(컨트롤러 및 레지스트리)의 작동 여부 확인:
```bash
$ curl -sw "%{http_code}" "<Public IP of your cluster>:31200/health" -o /dev/null
$ curl -sw "%{http_code}" "<Public IP of your kubernetes>:31300/uptime" -o /dev/null
```
두 가지 모두 200을 출려하면, 다음 단계로 이동할 수 있습니다.
> 참고: Pod 설치 완료까지 대략 1-2 분이 소요될 수 있습니다.

# 4. 코어 서비스 생성하기
마지막 단계로, 앱의 **[코어 서비스](#코어-마이크로서비스)**와 배치를 생성할 수 있습니다.
*(소셜 로그인을 원할 경우, [코어 서비스](#코어-마이크로서비스) 구축에 앞서 [여기](#a-adding-social-logins)의 절차를 이행하십시오)*


```bash
$ kubectl create -f core
OR alternatively
$ kubectl create -f core/auth.yaml
$ kubectl create -f core/<file-name>.yaml
...
$ kubectl create -f core/webapp.yaml
```
[코어 서비스](#코어-마이크로서비스)가 설치를 완료했는지 확인하려면 프록시의 Pod 로그를 확인해야 합니다. **kubectl get pods**를 이용하여 프록시의 Pod 이름을 확인할 수 있습니다
```bash
kubectl logs proxy-***-**
```
map, auth, mediator, player, room 서버들을 검색해야 합니다. 서버 작동 여부를 확인하십시오.
```bash
[WARNING] 094/205214 (11) : Server room/room1 is UP, reason: Layer7 check passed ...
[WARNING] 094/205445 (11) : Server auth/auth1 is UP, reason: Layer7 check passed ...
[WARNING] 094/205531 (11) : Server map/map1 is UP, reason: Layer7 check passed ...
[WARNING] 094/205531 (11) : Server mediator/mediator1 is UP, reason: Layer7 check passed ...
[WARNING] 094/205531 (11) : Server player/player1 is UP, reason: Layer7 check passed ...
```
> 서비스들이 완전히 설치될 때까지 대략 5-10 분이 소요될 수 있습니다.

# 5. GameOn 앱 살펴보기

블루믹스 쿠버네티스 컨테이너 서비스에 앱이 성공적으로 구축됐다면, IP 주소 및 할당된 포트를 통해 앱에 접속할 수 있습니다.
> https://169.xxx.xxx.xxx:30443/
> https로 30443 포트 번호를 사용해야 합니다.

* 위 주소에서 앱의 홈페이지가 확인됩니다.
![Homepage](images/home.png)
* Enter를 클릭하여 Anonymous User로 로그인하십시오(Github, 트위터 등에서 사용자 계정을 사용하고 싶다면, 사용자의 소셜 로그인 API 키를 설치해야 합니다.)
![User](images/user.png)
* 원하는 **사용자 이름**과 **좋아하는 색상**을 입력합니다
![Game](images/game.png)
* **축하합니다! 이제 블루믹스에서 사용자만의 GameOn 앱이 실행됩니다! 새로운 room의 생성과 소셜 로그인 추가 방법을 계속해서 소개합니다.**
* GameOn 앱의 명령어:
  * `/help` - 사용 가능한 모든 명령들을 나열합니다
  * `/sos` - 첫 번째 room으로 되돌아갑니다
  * `/exits` - 사용 가능한 나가기(exit)를 모두 나열합니다
  * `/go <N,S,E,W>` - 해당 방향의 room으로 이동합니다

# 5.1 소셜 로그인 추가하기
소셜 로그인을 추가하여 친구들과 함께 room들을 탐험할 수 있습니다. 소셜 로그인을 추가하려면 사용하고자 하는 소셜 앱에 개발자 계정이 있어야 합니다.

> Y편집된 사용자 yaml 파일로  **[코어 서비스](#코어-마이크로서비스)**를 재구축해야 합니다. 그 다음 단계에서 API 키를 추가할 장소를 확인할 수 있습니다.


## Github
[New OAuth Application](https://github.com/settings/applications/new)에서 애플리케이션을 등록하십시오
![Github](images/github.png)
Homepage URL에서 클러스터의 IP 주소와 포트 30443을 입력하십시오.
> https://169.xxx.xxx.xxx:30443/#/

Authorization 콜백 URL에서 IP 주소와 포트 30443을 입력하고, 앱의 auth 서비스로 포인팅해야 합니다.
> https://169.xxx.xxx.xxx:30443/auth/GitHubCallback

위 내용은 클러스터가 새로 생성된 경우 나중에라도 GitHub에서 편집할 수 있습니다.
앱의 **Client ID**와 **Client Secret**을 기록해 놓으십시오.
**[코어 서비스](#코어-마이크로서비스)**의 yaml 파일에서 환경 변수에 추가해야 합니다
```yaml
...
- name: GITHUB_APP_ID
  value : '<yourGitHubClientId>'
- name: GITHUB_APP_SECRET
  value : '<yourGitHubClientSecret>'
...
```
> 애플리케이션은 키(이름) **GITHUB_APP_ID** 및 **GITHUB_APP_SECRET**을 사용하며, yaml 파일 내의 키들과 정확히 일치해야 합니다.

## Twitter

[Create new app](https://apps.twitter.com/app/new)에서 트위터 계정으로 애플리케이션을 등록할 수 있습니다
![Twitter](images/twitter.png)

이름 필드에 원하는 애플이케이션 이름을 입력하십시오. Homepage URL의 경우, 클러스터의 IP 주소와 포트 30443을 입력해야 합니다.
> https://169.xxx.xxx.xxx:30443/#/

Authorization 콜백 URL에는 IP 주소와 포트 30443을 입력하고, 앱의 auth 서비스로 포인팅해야 합니다.
> https://169.xxx.xxx.xxx:30443/auth/TwitterAuth

등록을 마친 트위터 애플리케이션의 Keys and Access Tokens 섹션으로 이동하여 앱의 **Consumer Key**와 **Consumer Secret**을 기록해 놓으십시오. **[코어 서비스](#코어-마이크로서비스)**의 yaml 파일에서 환경 변수에 추가해야 합니다.
```yaml
...
- name: TWITTER_CONSUMER_KEY
  value : '<yourGitHubClientId>'
- name: TWITTER_CONSUMER_SECRET
  value : '<yourGitHubClientSecret>'
...
```
> 애플리케이션은 키(이름) **TWITTER_CONSUMER_KEY** 및 **TWITTER_CONSUMER_SECRET**을 사용하며, yaml 파일 내의 키들과 정확히 일치해야 합니다.

# 5.2 룸(Room) 추가하기

GameOn 팀의 [**본 지침**](https://gameontext.gitbooks.io/gameon-gitbook/content/walkthroughs/createRoom.html)을 따라 나만의 룸(room)을 빌드할 수 있습니다. GameOn 팀은 Java, Swift, Go 등으로 작성된 샘플 room들을 갖고 있습니다.

본 과정에서는 **[Java로 작성된 샘플 room](https://github.com/gameontext/sample-room-java)**을 빌드하게 될 것입니다. 샘플 room은 GameOn 앱과 동일한 클러스터에 빌드됩니다.

다음 명령을 실행하면 room이 생성됩니다.
```bash
$ kubectl create -f sample-room
```

빌드된 room을 클러스터에 등록하려면 앱의 UI를 사용해야 합니다.
* 우측 상단의 Registered Rooms를 클릭하십시오.
![addroom](images/addroom1.png)

* 필요한 room 정보를 입력하십시오. (*Github Repo 필드와 Health Endpoint 필드는 빈칸 처리합니다.*) 그런 다음, `Register`를 클릭하십시오
> 참고: 샘플에서 Java Room은 포트 9080을 사용하며, Swift Room은 포트 8080을 사용합니다.

![addroom](images/addroom2.png)
* Map에 room을 성공적으로 등록했습니다. UI에서 `/listmyrooms`와 같은 명령을 입력하거나 id와 `/teleport <id-of-the-room>`를 이용하여 room으로 직접 이동할 수 있습니다. [GameOn 앱에 대해 알아 보십시오](#5-GameOn-앱-살펴보기).

* [**여기**](https://gameontext.gitbooks.io/gameon-gitbook/content/walkthroughs/registerRoom.html)에서 세부적인 room 등록 정보를 확인할 수 있습니다.
* [GameOn 가이드](https://gameontext.gitbooks.io/gameon-gitbook/content/walkthroughs/createRoom.html)에 따라 나만의 room을 빌드할 수 있습니다.

## 문제 해결
* 브라우저에서 앱에 접속할 수 없는 경우, 포트 30443에 `https://`를 이용 중인지 확인해 보십시오.
* 특정 서비스에 문제가 있는 경우, `kubectl logs <pod-name-of-the-service>` 또는 `kubectl logs <pod-name-of-the-service> -f`를 이용하여 해당 서비스의 로그를 확인하십시오.
* Persistent Volumne에서 데이터를 clean/delete 하려면 Persistent Volumne Claim을 삭제해야 합니다.
  * `kubectl delete pvc -l app=gameon`
  * PV claim 삭제 후, `kubectl delete pv local-volume-1`을 이용하여 PV를 삭제 할 수 있습니다. 이로써 keystore가 volume에서 삭제됩니다.
* 플랫폼 서비스 삭제하기:
  * `kubectl delete -f platform`
* 코어 서비스 삭제하기:
  * `kubectl delete -f core`
* 모두 삭제하기:
  * `kubectl delete svc,deploy,pvc -l app=gameon`
  * `kubectl delete pod setup`
  * `kubectl delete pv local-volume-1`
  * `kubectl delete -f gameon-configmap.yaml`

## 참조

* [GameOn](https://gameontext.org) - 오리지널 게임 앱. 본 과정은 [deploying GameOn using Docker](https://book.gameontext.org/walkthroughs/local-docker.html)을 기반으로 작성되었습니다.

## 라이센스

[Apache 2.0](http://www.apache.org/licenses/LICENSE-2.0)
