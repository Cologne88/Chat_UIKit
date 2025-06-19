# Chat UIKit

## Product Introduction
Build real-time social messaging capabilities with all the features into your applications and websites based on powerful and feature-rich chat APIs, SDKs and UIKit components.

<table style="text-align:center; vertical-align:middle; width:440px">
  <tr>
    <th style="text-align:center;" width="160px">Android App</th>
    <th style="text-align:center;" width="160px">iOS App</th>
  </tr>
  <tr>
    <td><img style="width:160px" src="https://qcloudimg.tencent-cloud.cn/raw/078fbb462abd2253e4732487cad8a66d.png"/></td>
    <td><img style="width:160px" src="https://qcloudimg.tencent-cloud.cn/raw/b1ea5318e1cfce38e4ef6249de7a4106.png"/></td>
   </tr>
</table>

TUIKit is a UI component library based on Tencent Chat SDK. It provides universal UI components to offer features such as conversation, chat, search, relationship chain, group, and audio/video call features.

<img src=https://qcloudimg.tencent-cloud.cn/raw/9c893f1a9c6368c82d44586907d5293d.png width=70% />

## Changelog
### 8.6.7019 @2025.05.28 - Enhanced Version
**SDK**
- Push SDK supports multilingual internationalization.
- Push SDK supports Meizu message categorization.
- Cloud group search now returns join options and invitation options.
- Cloud group member search now returns member avatars.
- **iOS platform introduces Swift version of UIKit**.
- Upgraded QUIC plugin to support iOS simulator.
- **Enhanced OC SDK with Swift Optional property support**.
- Optimized long-connection IP freeze strategy with channel type added.
- Fixed occasional issue where push-only accounts triggered IM commands.
- Fixed missing device model setting in Flutter SDK on Android.
- Fixed callback thread inconsistency when Flutter SDK coexists with RoomKit.
- Fixed occasional callback conflicts between Flutter SDK and RoomEngine.
