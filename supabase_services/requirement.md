**1. 한복 프리셋 이미지 불러오기**

- **기능**: 사용자가 modern/traditional 한복 프리셋 이미지를 선택.
- **흐름**: Flutter → Edge Function
    - Flutter에서 프리셋 조회 요청 → Edge Function에서 데이터베이스 조회 후 URL 반환 → Flutter에서 화면에 표시.

**2. 이미지 업로드**

- **기능**: 사용자가 자신의 이미지를 업로드.
- **흐름**: Flutter → Edge Function
    - Flutter에서 이미지 업로드 요청 → Edge Function에서 user-images 스토리지에 저장 → user_images 테이블에 URL 기록 → Flutter로 URL 반환.

**3. 한복 이미지 생성 요청**

- **기능**: 업로드된 이미지와 프리셋으로 한복 이미지 생성 요청.
- **흐름**: Flutter → Edge Function → GKE
    - Flutter에서 생성 요청 → Edge Function이 GKE로 요청 전달 → GKE에서 처리 후 결과 준비 → Edge Function에서 task_id 생성 및 Flutter로 반환.

**4. 웹훅 처리**

- **기능**: GKE에서 생성된 결과를 저장.
- **흐름**: GKE → Edge Function
    - GKE에서 결과 전송 → Edge Function이 result-images 스토리지에 저장 → result_images 테이블에 기록.

**5. 상태 체크**

- **기능**: 이미지 생성 상태 확인.
- **흐름**: Flutter → Edge Function
    - Flutter에서 상태 확인 요청 (2~3초)→ Edge Function이 result_images 테이블 확인 후 상태 반환.

**6. 결과 화면**

- **기능**: 생성된 한복 이미지 표시.
- **흐름**: Flutter → Edge Function
    - Flutter에서 주기적으로 상태 확인 → Edge Function에서 완료된 결과 URL 반환 → Flutter에서 화면 업데이트.