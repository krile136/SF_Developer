#!/bin/bash

# metadata.json を読み込んで package.xml を生成するスクリプト
# 必要: Salesforce CLI, jq インストール済み

INPUT="metadata.json"
OUTPUT="package.xml"
API_VERSION="61.0"

# metadata.json が無ければ生成
if [ ! -f "$INPUT" ]; then
  echo "⚠ $INPUT が見つかりません。sf force:mdapi:describemetadata を実行して生成します..."
  sf force:mdapi:describemetadata --json > "$INPUT"
  if [ $? -ne 0 ]; then
    echo "❌ metadata.json の生成に失敗しました"
    exit 1
  fi
fi

echo '<?xml version="1.0" encoding="UTF-8"?>' > "$OUTPUT"
echo '<Package xmlns="http://soap.sforce.com/2006/04/metadata">' >> "$OUTPUT"

# metadata.json から xmlName をすべて抜き出して package.xml の <types> を生成
jq -r '.result.metadataObjects[].xmlName' "$INPUT" | sort | uniq | while read type; do
  echo "  <types>" >> "$OUTPUT"
  echo "    <members>*</members>" >> "$OUTPUT"
  echo "    <name>$type</name>" >> "$OUTPUT"
  echo "  </types>" >> "$OUTPUT"
done

echo "  <version>$API_VERSION</version>" >> "$OUTPUT"
echo '</Package>' >> "$OUTPUT"

echo "✅ package.xml を生成しました: $OUTPUT"

