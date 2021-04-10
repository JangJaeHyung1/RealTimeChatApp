# MessageKit을 사용한 실시간 Chat 앱
[MessageKit]: https://github.com/MessageKit/MessageKit
MessageKit[MessageKit]

## 적용 사항
- Firebase Auth와 GoogleSignIn로 구현한 구글 로그인, 이메일 로그인
- 실시간 대화 기능
- location 메세지 기능
- photo, video 메세지 기능
- modal에서 이름 키워드로 사용자 검색, 검색된 사용자와 메세지 주고 받기
- 대화목록에서 대화 삭제
- 다크모드 적용
- Firebase Crashlytics 적용 (비정상적 종료에 대한 분석)

### 그 외
* 사용자 등록 시 Auth에 계정 데이터(이름, 이메일, 프로필이미지)를 저장
* 메세지의 이미지는 Firebase storage에 저장
* 보내는 메세지 정보: 메세지 내용, 보내는 시간, 보내는 사람, 받는 사람, 메세지id, 메세지type(text,location,image,video)
* 메세지 정보는 Fireabase Realtime db
* SDWebImage을 사용하여 프로필 이미지와 메세지 이미지의 로드속도를 줄임 (이미지를 캐시에 저장)
* MapKit과 CoreLocation을 사용하여 위치 정보와 지도에 위치를 나타내도록 함
* MVC 패턴으로 디자인 구성
* MessageKit의 configureAvatarView를 사용하여 메세지 보내는 사람의 사진 표시

## 시현 영상

https://youtu.be/09a-FKx2zqc
