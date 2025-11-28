# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

- ios-control: iOS 시뮬레이터 자동화 MCP

## 프로젝트 구조

- MCPServer: MCP 서버 코드.
- SimulatorAgent: iOS 시뮬레이터 조작을 위한 Xcode 프로젝트. UITest를 통해 시뮬레이터를 조작하는 hack을 적용. HTTP 서버를 실행하여 MCP 서버와 통신.
- Common: MCPServer와 SimulatorAgent의 HTTP 요청, 응답 공통 코드.

## 주요 명령어

- make mcp: MCP 서버 빌드.
- make mcp-run: MCP 서버 빌드 및 실행.
- make agent: SimulatorAgent 빌드.
- make agent-run: SimulatorAgent 빌드 및 실행.
- make clean: 빌드 결과물 정리.

## Instructions

- Always answer in 한국어.
- 작업이 완료되면 커밋 수행.
