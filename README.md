# 📎 Auto Toon(팀명: 3큼폭발)

![서비스이미지-003](https://github.com/user-attachments/assets/e5aaeb48-2b41-47b1-9161-83266d1b9b36)





## 👀 서비스 소개
* 서비스명: Auto Toon
* 서비스설명: 더 넓은 사용자 데이터를 위한 LG전자의 새로운 서비스, 일상 일기를 작성하면 4컷 만화로 생성해주는 어플리케이션 ‘AutoToon’

<br>

## 📅 프로젝트 기간
2025.05.01 ~ 2025.06.17 
<br>

## ⭐ 주요 기능
* 일기 작성하기(하루 한번 가능, 추가작성시에는 일기장 아이템 구매해야함)
* 일기 수정하기(1번은 프리, 2번째는 수정아이템 구매해야함)
* 일기 삭제하기
* 네컷만화 생성하기
* 캘린더에서 일기 상세보기
* 캘린더에서 감정 통계보기
* 내정보에서 크레딧 및 내정보 확인인, 수정테이프 및 일기장 아이템 구매
<br>

## ⚙ 시스템 아키텍처(구조) 예시 
![image](https://github.com/user-attachments/assets/d8cb3a0b-38c8-4d71-bac6-cbda91990b6f)



<br>

## 📌 SW유스케이스
![image](https://github.com/user-attachments/assets/798755f0-6dc9-47b3-b0f9-96ede0d7cf34)





<br>

## 📌 서비스 흐름도
![image](https://github.com/user-attachments/assets/a54ff95b-1e28-491b-b14f-5991e12a320f)




<br>

## 📌 ER다이어그램
![Auto Toon db](https://github.com/user-attachments/assets/dabb0db9-8e93-40bd-9030-774e4ac30192)




<br>

## 🖥 화면 구성

### 회원가입/로그인
<p align="center">
  <img src="https://github.com/user-attachments/assets/28560c7d-afb0-4c55-8e82-f80244e27600" width="30%" />
  <img src="https://github.com/user-attachments/assets/87364b56-8a14-43f4-8630-f4edec87137f" width="30%" />
  <img src="https://github.com/user-attachments/assets/91353a73-b050-4f52-a682-a27338176867" width="30%" />
</p>



<br>

### 일기작성/네컷만화 생성
<p align="center">
  <img src="https://github.com/user-attachments/assets/853cf9be-ea77-4d39-af14-fc9a90977720" width="30%" />
  <img src="https://github.com/user-attachments/assets/20461451-2c9f-4f99-8877-27336470939c" width="30%" />
  <img src="https://github.com/user-attachments/assets/4593b15e-4b78-4603-bc81-810ff6db94bc" width="30%" />

</p>

<br>

### 캘린더 및 감정통계 조회
<p align="center">
  <img src="https://github.com/user-attachments/assets/6fb4eee5-3da8-438d-b584-f85dc26e8f4f" width="30%" />
  <img src="https://github.com/user-attachments/assets/9b0928fe-dbb3-4dc8-b470-caebb6cfb3bc" width="30%" />
  <img src="https://github.com/user-attachments/assets/c5a9d8f9-64f3-4cb6-8e05-7e6adfba4bfa" width="30%" />
</p>







<br>

## 👨‍👩‍👦‍👦 팀원 역할
 <img src="https://github.com/user-attachments/assets/4cb11648-2119-4202-95ea-00bdb919b8a8" width="95%" />




## 💡 트러블슈팅

## 1. Colab에서 GPU 메모리 부족(OOM) 오류 트러블슈팅

### 문제 상황

- Colab에서 Flux LoRA 기반 모델을 돌릴 때
    
    **"CUDA out of memory"** 또는 **"ResourceExhaustedError"** 등 GPU 메모리 부족(OOM) 오류가 빈번히 발생함.
    

### 원인

- 기본 Colab GPU 사양의 한계,
- 모델 파라미터, 배치 크기, 이미지 해상도 등이 메모리 사용량 초과

### 해결 과정

1. 이미지 해상도, 배치 크기, torch 모델 옵션을 조정해 메모리 사용량을 줄임
2. 불필요한 torch/tensor 변수 `del` 후 `torch.cuda.empty_cache()` 사용
3. Colab Pro 구독 및 런타임 재시작으로 더 높은 GPU 사양 확보
4. 필요시, 배치 처리 대신 한 번에 하나씩 이미지 생성
5. 중간에 메모리 사용량을 실시간으로 모니터링하여 최적화 진행

### 결과

- Colab 환경에서 연속적인 모델 실행이 가능해졌고, OOM 오류가 크게 줄어듦

---

## 2. ngrok 등 터널링 환경에서 FastAPI 백엔드-모델 서버 연동 문제

### 문제 상황

- FastAPI 백엔드 서버와 Colab 모델 서버를 ngrok을 통해 터널링하여 연결했으나,
    
    이미지 생성 요청 시 **404/500 에러** 또는 **timeout** 발생
    

### 원인

- ngrok 주소가 재시작할 때마다 바뀌어 환경변수/코드에서 경로가 불일치
- ngrok 무료 플랜의 제한(2시간 마다 세션 끊김, 속도 제한)
- 서버 간 CORS, 포트 매칭, URL 잘못 기입 등 설정 미스

### 해결 과정

1. ngrok 유료 플랜으로 고정 도메인(ngrok cloud edge) 설정
2. FastAPI의 `.env` 환경변수에 항상 최신 ngrok URL을 동적으로 반영
3. 서버 실행 시, URL 자동 체크/출력 로그 남기고, 프론트-백-모델 모두 URL 동기화
4. CORS 옵션 및 request/response 체크로 정상 통신 확인

### 결과

- 클라우드 환경에서도 안정적으로 Colab 모델 서버와 백엔드 API가 연동되어,
    
    이미지 생성 파이프라인이 원활하게 동작
    

---

## 3. 모델 실행 중 ImportError, ModuleNotFound, KeyError 등 에러 추적 및 해결

### 문제 상황

- 모델 코드 실행 중 다양한 에러(ImportError, ModuleNotFoundError, KeyError, AttributeError 등)가 반복적으로 발생

### 원인

- 패키지 설치 누락, 버전 불일치,
- 최신/구버전 API의 함수/속성명 차이,
- 모델 config/파라미터 누락 등

### 해결 과정

1. 에러 로그를 꼼꼼히 분석하여 원인 라이브러리/함수/파라미터 파악
2. 공식 문서, Github 이슈, StackOverflow 참고
3. 필요한 패키지 재설치 또는 정확한 버전 지정
4. 함수/속성명 변경된 부분 코드에서 수정
5. config 및 모델 파라미터 입력값 확인 및 재설정

### 결과

- 반복되는 런타임 에러를 모두 해결하고,
    
    모델 로딩/실행/이미지 생성이 문제없이 진행됨
    

---

## 4. 화면에서 이미지가 보여지지 않은 문제

![image](https://github.com/user-attachments/assets/d5c08c2f-c5c4-4b36-bc3b-e53e14bf82bd)


### 문제 상황

- 백엔드에서 생성된 이미지 파일의 로컬 경로(예: `C:/images/20240618_user1_1.png`)를 프론트엔드(Flutter)로 전달했으나,
- 실제 프론트 화면에서는 이미지가 정상적으로 표시되지 않는 현상이 발생함.

### 원인

- 로컬 개발 환경에서는 파일 경로로도 이미지 접근이 가능할 것처럼 보일 수 있으나,
- **클라우드 서버(네이버 클라우드)에서 운영 시, 프론트엔드에서는 서버의 로컬 파일 시스템에 직접 접근할 수 없음.**
- 웹/앱 프론트엔드는 이미지를 반드시 **HTTP(s) URL** 형태로 요청해야만 화면에 표시할 수 있음.

### 해결 과정

- FastAPI의 `StaticFiles` 기능을 사용하여, 이미지가 저장된 폴더를 `/images/`와 같은 HTTP 경로로 서빙하도록 서버 코드를 수정함.
- 프론트엔드에서는 이미지 경로를 파일 경로가 아닌 HTTP URL(예: `https://myserver.com/images/20240618_user1_1.png`)로 받아서 출력하도록 변경함.
- 수정 후, 배포 환경에서도 정상적으로 이미지가 표시되는 것을 확인함.

<br>




<br><br>


