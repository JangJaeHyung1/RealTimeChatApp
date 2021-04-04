# MessageKit을 사용한 실시간 Chat 앱

## 적용 사항
- Firebase Auth와 GoogleSignIn로 구현한 구글 로그인, 이메일 로그인
- 실시간 대화 기능
- location 메세지 기능
- photo, video 메세지 기능
- modal에서 이름 키워드로 사용자 검색, 검색된 사용자와 메세지 주고 받기
- 대화목록에서 대화 삭제
- 다크모드 적용

### 그 외
* 사용자 등록 시 Auth에 계정 데이터(이름, 이메일, 프로필이미지)를 저장하도록 함
* 보내는 메세지 정보: 메세지 내용, 보내는 시간, 보내는 사람, 받는 사람, 메세지id로 구성
* SDWebImage을 사용하여 프로필 이미지 set 캐시를 줄였음
* MapKit과 CoreLocation을 사용하여 위치 정보와 지도에 위치를 나타내도록 함
* MVC 패턴으로 디자인 구성
* MessageKit의 configureAvatarView를 사용하여 메세지 보내는 사람의 사진 표시

## 시현 영상

## 시현 이미지
