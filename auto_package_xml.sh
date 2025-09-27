#!/bin/bash
# auto_package_xml_full.sh
# Salesforce DX 用：metadata.json から package.xml を生成し、取得不可メタデータを自動除外して retrieve

TARGET_ORG="developer"
METADATA_JSON="metadata.json"
MANIFEST_DIR="./manifest"
PACKAGE_XML="$MANIFEST_DIR/package.xml"
BLACKLIST="$MANIFEST_DIR/blacklist.txt"

mkdir -p $MANIFEST_DIR
touch $BLACKLIST

generate_package_xml() {
    echo "1. package.xml を生成中..."
    cat <<EOF > $PACKAGE_XML
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
EOF
    # ブラックリストを Bash 配列に読み込む
    mapfile -t BLACKLIST_ARRAY < $BLACKLIST

    # metadata.json から type を抽出し、ブラックリストを除外
    jq -r --argjson bl "$(printf '%s\n' "${BLACKLIST_ARRAY[@]}" | jq -R . | jq -s .)" '
        .result.metadataObjects[]
        | select(.xmlName != null)
        | select(.xmlName as $t | ($bl | index($t) | not))
        | "    <types>\n        <members>*</members>\n        <name>\(.xmlName)</name>\n    </types>"
    ' $METADATA_JSON >> $PACKAGE_XML

    cat <<EOF >> $PACKAGE_XML
    <version>61.0</version>
</Package>
EOF
}

retrieve_metadata() {
    echo "2. Salesforce DX retrieve 実行..."
    sf project retrieve start --manifest $PACKAGE_XML --target-org $TARGET_ORG 2>&1 | tee $MANIFEST_DIR/retrieve.log
}

filter_errors() {
    echo "3. 取得エラーを解析..."
    CLEAN_LOG=$(sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' "$MANIFEST_DIR/retrieve.log")

    # registry に存在しないタイプを抽出
    NEW_ERRORS=$(echo "$CLEAN_LOG" | grep -oP "Missing metadata type definition in registry for id '\K[^']+" | sort -u || true)

    if [ -n "$NEW_ERRORS" ]; then
        echo "$NEW_ERRORS" >> $BLACKLIST
        sort -u -o $BLACKLIST $BLACKLIST
        echo "⚠ 新しいブラックリスト項目を追加: $NEW_ERRORS"
        return 1  # 新規エラーあり
    else
        return 0  # 新規エラーなし
    fi
}

# まず metadata.json を取得
echo "0. metadata.json を取得..."
sf force:mdapi:describemetadata --target-org $TARGET_ORG --json > $METADATA_JSON

# 自動除外ループ
MAX_RETRIES=20
RETRY=0
while [ $RETRY -lt $MAX_RETRIES ]; do
    generate_package_xml
    retrieve_metadata
    if filter_errors; then
        echo "✔ 取得完了！新しいエラーはありません"
        break
    else
        echo "⚠ ブラックリストに追加されたタイプがあります。再生成します..."
    fi
    RETRY=$((RETRY+1))
done

echo "==== 完了 ===="
echo "package.xml: $PACKAGE_XML"
echo "ブラックリスト: $BLACKLIST"

