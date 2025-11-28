#!/usr/bin/env node

const https = require("https");
const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");
const os = require("os");

const REPO = "sunghyun-k/ios-control-mcp";
const VERSION = require("../package.json").version;
const VENDOR_DIR = path.join(__dirname, "..", "vendor");

function getAssetName() {
  const platform = os.platform();
  const arch = os.arch();

  if (platform !== "darwin") {
    console.error("Error: ios-control-mcp only supports macOS");
    process.exit(1);
  }

  if (arch === "arm64") {
    return `ios-control-mcp-darwin-arm64.tar.gz`;
  } else if (arch === "x64") {
    return `ios-control-mcp-darwin-x64.tar.gz`;
  } else {
    console.error(`Error: Unsupported architecture: ${arch}`);
    process.exit(1);
  }
}

function downloadFile(url) {
  return new Promise((resolve, reject) => {
    https
      .get(url, (res) => {
        if (res.statusCode === 302 || res.statusCode === 301) {
          downloadFile(res.headers.location).then(resolve).catch(reject);
          return;
        }

        if (res.statusCode !== 200) {
          reject(new Error(`HTTP ${res.statusCode}: ${url}`));
          return;
        }

        const chunks = [];
        res.on("data", (chunk) => chunks.push(chunk));
        res.on("end", () => resolve(Buffer.concat(chunks)));
        res.on("error", reject);
      })
      .on("error", reject);
  });
}

async function install() {
  const assetName = getAssetName();
  const downloadUrl = `https://github.com/${REPO}/releases/download/v${VERSION}/${assetName}`;

  console.log(`Downloading ${assetName}...`);

  try {
    const data = await downloadFile(downloadUrl);

    // Create vendor directory
    fs.mkdirSync(VENDOR_DIR, { recursive: true });

    // Write tar.gz file
    const tarPath = path.join(VENDOR_DIR, assetName);
    fs.writeFileSync(tarPath, data);

    // Extract
    console.log("Extracting...");
    execSync(`tar -xzf "${assetName}"`, { cwd: VENDOR_DIR });

    // Cleanup tar file
    fs.unlinkSync(tarPath);

    // Make binary executable
    const mcpServer = path.join(VENDOR_DIR, "MCPServer");
    if (fs.existsSync(mcpServer)) {
      fs.chmodSync(mcpServer, 0o755);
    }

    console.log("ios-control-mcp installed successfully!");
  } catch (err) {
    console.error("Failed to download binary:", err.message);
    console.error("");
    console.error("You can manually download from:");
    console.error(`  https://github.com/${REPO}/releases`);
    process.exit(1);
  }
}

install();
