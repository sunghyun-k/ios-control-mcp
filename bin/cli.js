#!/usr/bin/env node

const { spawn } = require("child_process");
const path = require("path");
const fs = require("fs");

const binDir = path.join(__dirname, "..", "vendor");
const mcpServer = path.join(binDir, "MCPServer");
const agentApp = path.join(binDir, "AutomationServerTests-Runner.app");

if (!fs.existsSync(mcpServer)) {
  console.error("Error: MCPServer binary not found.");
  console.error("Please reinstall the package: npm install ios-control-mcp");
  process.exit(1);
}

const child = spawn(mcpServer, process.argv.slice(2), {
  stdio: "inherit",
  env: {
    ...process.env,
    IOS_CONTROL_AGENT_APP: agentApp,
  },
});

child.on("error", (err) => {
  console.error("Failed to start MCPServer:", err.message);
  process.exit(1);
});

child.on("exit", (code) => {
  process.exit(code ?? 0);
});
