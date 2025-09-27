#!/bin/bash

# metadata.json を読み込んで package.xml を生成するスクリプト
# 事前に: sf force:mdapi:describemetadata --target-org developer --json > metadata.json
# 必要: jq インストール済み

INPUT="metadata.json"
OUTPUT="package.xml"
API_VERSION="61.0"

if [ ! -f "$INPUT" ]; then
  echo "Error: $INPUT が見つかりません。まずは sf force:mdapi:describemetadata を実行してください。"
  exit 1
fi

echo '<?xml version="1.0" encoding="UTF-8"?>' > $OUTPUT
echo '<Package xmlns="http://soap.sforce.com/2006/04/metadata">' >> $OUTPUT

# metadata.json から xmlName をすべて抜き出して package.xml の <types> を生成
jq -r '.result.metadataObjects[].xmlName' $INPUT | sort | uniq | while read type; do
  echo "  <types>" >> $OUTPUT
  echo "    <members>*</members>" >> $OUTPUT
  echo "    <name>$type</name>" >> $OUTPUT
  echo "  </types>" >> $OUTPUT
done

echo "  <version>$API_VERSION</version>" >> $OUTPUT
echo '</Package>' >> $OUTPUT

echo "✅ package.xml を生成しました: $OUTPUT"

