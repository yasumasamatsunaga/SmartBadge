# SmartBadge Video Tools

**実機確認済みの動画変換レシピ / Device-tested FFmpeg conversion recipe for SmartBadge**

ドウシシャ SmartBadge EB180TSL 系デジタル缶バッジ向けに、手元の動画を小型ディスプレイ用の MP4 に変換するスクリプトです。2026-10-21、**9秒間の連続動画が滑らかに再生できることを実機で確認**しました。

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

# 任意の部分を切り出す例（座標は入力動画に合わせて変更）
./scripts/convert.sh input.mp4 badge-cropped.mp4 0 9 400:500:100:50 224 280
```

引数は `INPUT OUTPUT [START_SECONDS=0] [DURATION_SECONDS=9] [CROP=none] [WIDTH=270] [HEIGHT=270]`。
`CROP` は `width:height:x:y`、座標はFFmpegの自動回転処理後の画像基準です。**別の動画ではcrop値を調整してください**。任意のcrop指定時は指定した `WIDTH×HEIGHT` にスケールするため、見せたい範囲と縦横比を合わせるのが理想です。表示サイズは最大360px・偶数値で指定します。

上記の切り出し座標は説明用です。対象動画に合わせて座標・サイズを調整してください。素材や変換済み動画は本リポジトリに含めません。

## 動作確認

```bash
bash tests/smoke.sh
ffprobe -v error -select_streams v:0 \
  -show_entries stream=codec_name,profile,width,height,r_frame_rate,nb_frames,pix_fmt:format=duration,size \
  -of default=noprint_wrappers=1 badge.mp4
```

9秒出力の期待値は H.264 Constrained Baseline / 360×360 / 24fps / `yuv420p` / 216 frames / 9.000s です。**ファイルの検査だけでは実機再生を保証できません**。アプリ経由で転送し、実機で動作を確認してください。

## GIFとの比較

今回の実機では、12fps GIFはカクつき、15～24fps GIFは本体上で静止する現象がありました。一方、24fps・H.264 Baseline MP4は滑らかでした。また、9秒MP4の画面内カウンターが `SEC 08` に到達し、9秒間の連続映像も正常に再生されました。詳しくは[検証記録](docs/validation.md)。

## 素材の権利

入力動画や変換済み動画は**このリポジトリには含めていません**。第三者の著作物を使う場合は、利用許諾・著作権などを確認してください。`.gitignore` で一般的な動画形式を除外しています。

## ライセンス

公開時点ではライセンス未設定です。公開リポジトリであっても、コードの再利用許諾は別途指定が必要です。
