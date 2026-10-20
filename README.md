# SmartBadge Video Tools

**実機確認済みの動画変換レシピ / Device-tested FFmpeg conversion recipe for SmartBadge**

ドウシシャ SmartBadge EB180TSL 系デジタル缶バッジ向けに、手元の動画を小型ディスプレイ用の MP4 に変換するスクリプトです。2026-10-21、**9秒間の連続ゲーム映像が滑らかに再生できることを実機で確認**しました。

## 検証済みプロファイル v1.0

| 項目 | 設定 |
| --- | --- |
| 形式 | MP4 / H.264 Constrained Baseline (`libx264 -profile:v baseline`) |
| H.264 level | 3.0 |
| フレームレート | 24 fps |
| 動画サイズ | 360 × 360 px |
| ピクセル形式 | `yuv420p` |
| 音声 | なし (`-an`) |
| 品質 | CRF 20 |
| GOP / B-frame | `-g 48 -bf 0` |
| 確認済み再生時間 | **9秒・216フレーム**（上限を意味するものではありません） |
| 映像の配置 | 見せたい範囲を crop して黒背景キャンバスに中央配置 |

> **互換性に関する注意**: 上記は特定のSmartBadge実機で成功した設定です。型番・アプリのバージョン・素材による違いや再生可能な最大秒数について、メーカーの保証値を示すものではありません。

## クイックスタート

macOS: `brew install ffmpeg`。LinuxでもFFmpegがあれば実行できます。

```bash
chmod +x scripts/convert.sh
# 一般的な入力：縦横比を維持して安全領域（270×270px）に収めます
./scripts/convert.sh input.mp4 badge.mp4 0 9 none 270 270

# 実機で成功したパックマン素材専用のcrop設定
./scripts/convert.sh source.mkv badge-pacman.mp4 52 9 550:624:365:57 232 264
```

引数は `INPUT OUTPUT [START_SECONDS=0] [DURATION_SECONDS=9] [CROP=none] [WIDTH=270] [HEIGHT=270]`。
`CROP` は `width:height:x:y`、座標はFFmpegの自動回転処理後の画像基準です。**別の動画ではcrop値を調整してください**。任意のcrop指定時は指定した `WIDTH×HEIGHT` にスケールするため、見せたい範囲と縦横比を合わせるのが理想です。表示サイズは最大360px・偶数値で指定します。

パックマンの例は元動画の **0:52〜1:01** を使用し、迷路のみを切り出したものです。元動画は本リポジトリに含めません。

## 動作確認

```bash
bash tests/smoke.sh
ffprobe -v error -select_streams v:0 \
  -show_entries stream=codec_name,profile,width,height,r_frame_rate,nb_frames,pix_fmt:format=duration,size \
  -of default=noprint_wrappers=1 badge.mp4
```

9秒出力の期待値は H.264 Constrained Baseline / 360×360 / 24fps / `yuv420p` / 216 frames / 9.000s です。**ファイルの検査だけでは実機再生を保証できません**。アプリ経由で転送し、実機で動作を確認してください。

## GIFとの比較

今回の実機では、12fps GIFはカクつき、15～24fps GIFは本体上で静止する現象がありました。一方、24fps・H.264 Baseline MP4は滑らかでした。また、9秒MP4の画面内カウンターが `SEC 08` に到達し、実際の9秒連続ゲームプレイ動画も正常に再生されました。詳しくは[検証記録](docs/validation.md)。

## 素材の権利

動画ファイル・ゲーム映像・YouTubeのダウンロードファイルは**このリポジトリには含めていません**。変換元の利用許諾や著作権を確認のうえ利用してください。`.gitignore` で一般的な動画形式を除外しています。

## ライセンス

公開時点ではライセンス未設定です。公開リポジトリであっても、コードの再利用許諾は別途指定が必要です。
