.PHONY: mcp mcp-run agent agent-run device-agent device-agent-run playground clean release-arm64 release-x64 release-universal release

# 버전 정보 (package.json에서 읽기)
VERSION := $(shell node -p "require('./package.json').version")
VERSION_FILE := MCPServer/Sources/MCPServer/Version.swift

# 공통 경로
BUILD_DIR := $(CURDIR)/.build
RELEASE_DIR := $(CURDIR)/release
AGENT_BUILD_DIR := $(BUILD_DIR)/SimulatorAgent
AGENT_PROJECT := SimulatorAgent/SimulatorAgent.xcodeproj
AGENT_APP := $(AGENT_BUILD_DIR)/Build/Products/Debug-iphonesimulator/SimulatorAgentTests-Runner.app
AGENT_BUNDLE_ID := simulatoragent.SimulatorAgentTests.xctrunner

# 실기기용 경로
DEVICE_AGENT_BUILD_DIR := $(BUILD_DIR)/DeviceAgent
DEVICE_AGENT_APP := $(DEVICE_AGENT_BUILD_DIR)/Build/Products/Debug-iphoneos/SimulatorAgentTests-Runner.app

# 시뮬레이터 UDID (make UDID=xxx 로 지정 가능)
UDID ?= $(shell $(CURDIR)/scripts/find-simulator.sh)

# 실기기 UDID (make DEVICE_UDID=xxx 로 지정 가능)
DEVICE_UDID ?=

# 개발 팀 ID (코드 사이닝용, make TEAM=xxx 로 지정 가능)
TEAM ?=

# 버전 파일 생성
generate-version:
	@echo "Generating version file for $(VERSION)..."
	@mkdir -p $(dir $(VERSION_FILE))
	@echo "// Auto-generated file - DO NOT EDIT" > $(VERSION_FILE)
	@echo "let appVersion = \"$(VERSION)\"" >> $(VERSION_FILE)

# MCP 서버 빌드
mcp: generate-version
	@echo "Building MCP Server version $(VERSION)..."
	swift build --package-path MCPServer --scratch-path $(BUILD_DIR)/MCPServer

# MCP 서버 실행
mcp-run: generate-version
	@echo "Running MCP Server version $(VERSION)..."
	IOS_CONTROL_AGENT_APP=$(AGENT_APP) swift run --package-path MCPServer --scratch-path $(BUILD_DIR)/MCPServer MCPServer

# SimulatorAgent .app 빌드
agent:
	xcodebuild build-for-testing \
		-project $(AGENT_PROJECT) \
		-scheme SimulatorAgent \
		-destination 'generic/platform=iOS Simulator' \
		-derivedDataPath $(AGENT_BUILD_DIR)

# Playground 실행 (테스트용)
playground:
	swift run --package-path MCPServer --scratch-path $(BUILD_DIR)/MCPServer Playground $(ARGS)

# SimulatorAgent 빌드 + 설치 + 실행
agent-run: agent
ifndef UDID
	$(error 시뮬레이터를 찾을 수 없습니다.)
endif
	xcrun simctl boot $(UDID) 2>/dev/null || true
	xcrun simctl install $(UDID) $(AGENT_APP)
	xcrun simctl launch --console-pty $(UDID) $(AGENT_BUNDLE_ID)

# 실기기용 Agent 빌드 (TEAM은 선택사항, Xcode에 계정이 등록되어 있으면 자동 서명)
device-agent:
	xcodebuild build-for-testing \
		-project $(AGENT_PROJECT) \
		-scheme SimulatorAgent \
		-destination 'generic/platform=iOS' \
		-derivedDataPath $(DEVICE_AGENT_BUILD_DIR) \
		$(if $(TEAM),DEVELOPMENT_TEAM=$(TEAM)) \
		CODE_SIGN_STYLE=Automatic

# 실기기에서 Agent 실행 (xcodebuild test)
device-agent-run:
ifndef DEVICE_UDID
	$(error DEVICE_UDID가 설정되지 않았습니다. make device-agent-run DEVICE_UDID=<UDID> 형식으로 실행하세요.)
endif
	xcodebuild test \
		-project $(AGENT_PROJECT) \
		-scheme SimulatorAgent \
		-destination "id=$(DEVICE_UDID)" \
		-derivedDataPath $(DEVICE_AGENT_BUILD_DIR) \
		-only-testing:SimulatorAgentTests/SimulatorAgentTests/testRunServer \
		$(if $(TEAM),DEVELOPMENT_TEAM=$(TEAM)) \
		CODE_SIGN_STYLE=Automatic

# 클린
clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(RELEASE_DIR)
	rm -rf MCPServer/.build
	rm -rf Common/.build
	rm -f $(VERSION_FILE)

# 릴리즈 빌드 (arm64)
release-arm64: generate-version agent
	@echo "Building MCPServer $(VERSION) for arm64..."
	swift build --package-path MCPServer --scratch-path $(BUILD_DIR)/MCPServer -c release
	@echo "Packaging arm64 release..."
	rm -rf $(RELEASE_DIR)/arm64
	mkdir -p $(RELEASE_DIR)/arm64
	cp $(BUILD_DIR)/MCPServer/release/MCPServer $(RELEASE_DIR)/arm64/
	cp -R $(AGENT_APP) $(RELEASE_DIR)/arm64/
	cd $(RELEASE_DIR)/arm64 && tar -czvf ../ios-control-mcp-darwin-arm64.tar.gz *
	@echo "Done! arm64 release: $(RELEASE_DIR)/ios-control-mcp-darwin-arm64.tar.gz"

# 릴리즈 빌드 (x86_64)
release-x64: generate-version agent
	@echo "Building MCPServer $(VERSION) for x86_64..."
	swift build --package-path MCPServer --scratch-path $(BUILD_DIR)/MCPServer-x64 -c release --arch x86_64
	@echo "Packaging x64 release..."
	rm -rf $(RELEASE_DIR)/x64
	mkdir -p $(RELEASE_DIR)/x64
	cp $(BUILD_DIR)/MCPServer-x64/release/MCPServer $(RELEASE_DIR)/x64/
	cp -R $(AGENT_APP) $(RELEASE_DIR)/x64/
	cd $(RELEASE_DIR)/x64 && tar -czvf ../ios-control-mcp-darwin-x64.tar.gz *
	@echo "Done! x64 release: $(RELEASE_DIR)/ios-control-mcp-darwin-x64.tar.gz"

# 릴리즈 빌드 (universal binary)
release-universal: generate-version agent
	@echo "Building MCPServer $(VERSION) for arm64..."
	swift build --package-path MCPServer --scratch-path $(BUILD_DIR)/MCPServer -c release
	@echo "Building MCPServer $(VERSION) for x86_64..."
	swift build --package-path MCPServer --scratch-path $(BUILD_DIR)/MCPServer-x64 -c release --arch x86_64
	@echo "Creating universal binary..."
	mkdir -p $(BUILD_DIR)/universal
	lipo -create \
		$(BUILD_DIR)/MCPServer/release/MCPServer \
		$(BUILD_DIR)/MCPServer-x64/release/MCPServer \
		-output $(BUILD_DIR)/universal/MCPServer
	@echo "Packaging universal release..."
	rm -rf $(RELEASE_DIR)/universal
	mkdir -p $(RELEASE_DIR)/universal
	cp $(BUILD_DIR)/universal/MCPServer $(RELEASE_DIR)/universal/
	cp -R $(AGENT_APP) $(RELEASE_DIR)/universal/
	cd $(RELEASE_DIR)/universal && tar -czvf ../ios-control-mcp-darwin-universal.tar.gz *
	@echo "Done! universal release: $(RELEASE_DIR)/ios-control-mcp-darwin-universal.tar.gz"

# 모든 릴리즈 빌드 (arm64 + x64 + universal)
release: release-arm64 release-x64 release-universal
	@echo "All releases built successfully!"
	@ls -lh $(RELEASE_DIR)/*.tar.gz
