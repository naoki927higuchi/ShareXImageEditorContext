# ShareX Image Editor Context — Windows 11 modern menu

## モダンメニュー版（実装・登録済み）

`Command.cpp` がネイティブの IExplorerCommand を実装し、`AppxManifest.xml` の
windows.comServer / windows.fileExplorerContextMenus で登録します。
画像だけに「ShareXイメージエディタで開く」を表示し、選択された各パスを
ShareX.exe -ImageEditor に渡します。旧版の install.ps1 は使用しないでください。

```powershell
pwsh -NoProfile -File .\publish-modern.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\install-modern.ps1
```

今回のマシンでは登録に成功し、パッケージ Status=Ok、登録COMの起動、PNGで表示・READMEで非表示を確認済みです。
Explorerの右クリック表示とShareXの実際の編集画面は別途目視確認が必要です。
登録後は dist フォルダーを移動・削除しないでください。
反映されなければサインアウトして再サインインしてください。

この実装は展開済みパッケージの開発用登録です。別PCでは開発者モード等のポリシーによって
登録を拒否されることがあります。生成MSIXは未署名なので、配布用途では署名が必要です。
開発者モードや証明書の設定はスクリプトから変更しません。

ShareXの場所を明示する場合:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install-modern.ps1 -ShareXPath 'D:\Apps\ShareX\ShareX.exe'
```

削除は `install-modern.ps1 -Uninstall`。パッケージ登録だけを削除し、ソースやShareX本体は残します。
対象は png/jpg/jpeg/bmp/gif/tif/tiff/webp/ico。複数選択は全項目が対象画像のときに表示します。
ビルドは x64、Visual Studio 2022 Professional C++ と Windows SDK 10.0.26100.0、.NET 8 SDK以降を想定しています。
配置場所が異なる場合は build-native.cmd / publish-modern.ps1 のツールパスを変更してください。

設計根拠: https://learn.microsoft.com/en-us/windows/apps/desktop/modernize/integrate-packaged-app-with-file-explorer

## 以下は旧メニュー版の参考情報

Windows 11 の画像ファイル用コンテキストメニューから ShareX のイメージエディタを開くための小さなラッパーです。

## ビルドと登録

PowerShell でこのフォルダーを開き、次を実行します。

```powershell
.\publish.ps1
.\install.ps1
```

画像ファイルを右クリックして「ShareXイメージエディタで開く」を選ぶと、`ShareX.exe -ImageEditor "選択したパス"` が起動します。複数選択にも対応しています。

削除:

```powershell
.\install.ps1 -Uninstall
```

登録先は HKCU のため管理者権限は不要です。Windows 11 のビルドによっては自作の shell verb が新メニューではなく「その他のオプション」に表示されます。その場合、モダンメニューへの確実な統合には MSIX のパッケージ ID と `IExplorerCommand` の packaged COM 登録が必要です。

## 配布ZIPの公開運用

開発中のZIPはローカル管理のみとし、公開時に選定したZIPだけをGitHubへ送ります。
出力先・検証・公開準備の手順は [RELEASE-POLICY.md](RELEASE-POLICY.md) を参照してください。

## GitHubから取得する配布ZIP

- [ShareXImageEditorContext 1.0.1](distribution/ShareXImageEditorContext-1.0.1-x64.zip) / [SHA256](distribution/ShareXImageEditorContext-1.0.1-x64.zip.sha256)

アクセス権のあるユーザーがZIPのファイル画面からダウンロードできます。ZIP全体を展開し、同梱説明書に従ってください。

## ソースと配布物の公開

[最新バイナリー](distribution/README.md)からWindows版ZIPをダウンロードできます。ソース一式はこのリポジトリで公開しています。共同開発、Issues、Pull requestsは受け付けていません。
