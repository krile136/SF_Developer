initialRetrieve:
	@echo "初回Retrieve実行"
	@(cd ./manifest && \
	 chmod +x generate_package.sh auto_package_xml.sh && \
	 ./generate_package.sh && \
	 ./auto_package_xml.sh)
	@echo "初回Retrieve終了"

