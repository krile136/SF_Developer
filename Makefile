initialRetrieve:
	@echo "初回Retrieve実行"
	@(cd ./manifest && \
	 chmod +x generate_package.sh auto_package_xml.sh && \
	 ./generate_package.sh && \
	 ./auto_package_xml.sh)
	@echo "初回Retrieve終了"

retrieve:
	@echo "メタデータの取得を開始します(exclude.txtに記載されているメタデータを除く)"
	sf project retrieve start --manifest ./manifest/package_dev.xml	

