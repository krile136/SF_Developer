#!/bin/bash
# auto_package_xml_full.sh
# Salesforce DX 用：metadata.json から package.xml / package_dev.xml を生成し、
# 取得不可メタデータを自動除外して retrieve

METADATA_JSON="metadata.json"
MANIFEST_DIR="."
PACKAGE_XML="$MANIFEST_DIR/package.xml"
PACKAGE_DEV_XML="$MANIFEST_DIR/package_dev.xml"
BLACKLIST="$MANIFEST_DIR/blacklist.txt"
EXCLUDELIST="$MANIFEST_DIR/exclude.txt"

mkdir -p $MANIFEST_DIR
touch $BLACKLIST
touch $EXCLUDELIST

generate_package_xml() {
    echo "1. package.xml を生成中..."

    cat <<EOF > $PACKAGE_XML
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
EOF

    cat <<EOF > $PACKAGE_DEV_XML
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
EOF

    # ブラックリストと除外リストを Bash 配列に読み込む
    mapfile -t BLACKLIST_ARRAY < $BLACKLIST
    mapfile -t EXCLUDELIST_ARRAY < $EXCLUDELIST

    # jq に渡す配列を作成
    BL_JSON=$(printf '%s\n' "${BLACKLIST_ARRAY[@]}" | jq -R . | jq -s .)
    EX_JSON=$(printf '%s\n' "${EXCLUDELIST_ARRAY[@]}" | jq -R . | jq -s .)

    # metadata.json から type を抽出し、ブラックリストを除外 → package.xml
    jq -r --argjson bl "$BL_JSON" '
        .result.metadataObjects[]
        | select(.xmlName != null)
        | select(.xmlName as $t | ($bl | index($t) | not))
        | "    <types>\n        <members>*</members>\n        <name>\(.xmlName)</name>\n    </types>"
    ' "$METADATA_JSON" >> $PACKAGE_XML

    # metadata.json から type を抽出し、ブラックリストと除外リストを除外 → package_dev.xml
    jq -r --argjson bl "$BL_JSON" --argjson ex "$EX_JSON" '
        .result.metadataObjects[]
        | select(.xmlName != null)
        | select(.xmlName as $t | ($bl | index($t) | not))
        | select(.xmlName as $t | ($ex | index($t) | not))
        | "    <types>\n        <members>*</members>\n        <name>\(.xmlName)</name>\n    </types>"
    ' "$METADATA_JSON" >> $PACKAGE_DEV_XML

    cat <<EOF >> $PACKAGE_XML
    <version>61.0</version>
</Package>
EOF

    cat <<EOF >> $PACKAGE_DEV_XML
    <version>61.0</version>
</Package>
EOF
}

retrieve_metadata() {
    echo "2. Salesforce DX retrieve 実行..."
    sf project retrieve start --manifest $PACKAGE_XML 2>&1 | tee $MANIFEST_DIR/retrieve.log
}

filter_errors() {
    echo "3. 取得エラーを解析..."
    CLEAN_LOG=$(sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' "$MANIFEST_DIR/retrieve.log")

    NEW_ERRORS=$(echo "$CLEAN_LOG" | grep -oP "Missing metadata type definition in registry for id '\K[^']+" | sort -u || true)

    if [ -n "$NEW_ERRORS" ]; then
        echo "$NEW_ERRORS" >> $BLACKLIST
        sort -u -o $BLACKLIST $BLACKLIST
        echo "⚠ 新しいブラックリスト項目を追加: $NEW_ERRORS"
        return 1
    else
        return 0
    fi
}

# まず metadata.json を取得
echo "0. metadata.json を取得..."
sf force:mdapi:describemetadata --json > $METADATA_JSON

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
echo "package_dev.xml: $PACKAGE_DEV_XML"
echo "ブラックリスト: $BLACKLIST"
echo "除外リスト: $EXCLUDELIST"

