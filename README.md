# TownWalk — お散歩ショッピング

静的サイト（ビルド不要）。そのまま Vercel にデプロイできます。

## デプロイ手順

このフォルダで、ターミナルから:

    vercel --prod

初回は次を聞かれます（すべて Enter でOK）:

- Set up and deploy? → y
- Which scope? → 自分のアカウントを選択
- Link to existing project? → n
- What's your project's name? → townwalk （好きな名前で可）
- In which directory is your code located? → ./
- 設定を上書きするか → n

完了すると本番URLが表示されます。

## 中身

- index.html … ゲーム本体（HTML/CSS/JSのみ・依存パッケージなし）
- assets/ … 画像14点 + フォント + アプリアイコン
- manifest.webmanifest … PWA設定（横画面固定・ホーム画面追加用）
- vercel.json … assets を1年間キャッシュする設定
