# DeFi Audit API

## English

### Overview

This project provides a simple API for auditing Ethereum smart
contracts.\
It checks for common vulnerabilities, privilege risks, and security best
practices.

### Project Structure

    defi-audit/
    ├─ app.py            # FastAPI server
    ├─ audit.py          # Core auditing logic
    ├─ requirements.txt  # Python deps
    ├─ .env.example      # ENV template (INFURA_KEY=...)
    ├─ .gitignore        # ignore rules
    └─ README.md         # docs (EN/中文/日本語)

### Quick Start

``` bash
git clone <repo>
cd defi-audit

# Install deps
pip install -r requirements.txt

# Copy env and set API key
cp .env.example .env   # fill INFURA_KEY

# Run server
uvicorn app:app --host 0.0.0.0 --port 8002 --reload
```

### Test Example

``` bash
curl "http://localhost:8002/audit?contract=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48&chain=ethereum"
```

## 中文

### 概述

这是一个用于以太坊智能合约审计的简单 API。\
它可以检测常见漏洞、权限风险以及常见的安全检查。

### 项目结构

    defi-audit/
    ├─ app.py            # FastAPI 服务端
    ├─ audit.py          # 核心审计逻辑
    ├─ requirements.txt  # Python 依赖
    ├─ .env.example      # 环境变量模板 (INFURA_KEY=...)
    ├─ .gitignore        # 忽略规则
    └─ README.md         # 文档 (EN/中文/日本語)

### 使用方法

``` bash
git clone <repo>
cd defi-audit

# 安装依赖
pip install -r requirements.txt

# 复制 env 文件并填写 API key
cp .env.example .env   # 填写 INFURA_KEY

# 启动服务
uvicorn app:app --host 0.0.0.0 --port 8002 --reload
```

### 测试示例

``` bash
curl "http://localhost:8002/audit?contract=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48&chain=ethereum"
```

## 日本語

### 概要

このプロジェクトは、Ethereum スマートコントラクトの簡易監査 API です。\
一般的な脆弱性、オーナー権限リスク、セキュリティチェックを検出します。

### プロジェクト構造

    defi-audit/
    ├─ app.py            # FastAPI サーバー
    ├─ audit.py          # 監査ロジック
    ├─ requirements.txt  # Python 依存関係
    ├─ .env.example      # 環境変数テンプレート (INFURA_KEY=...)
    ├─ .gitignore        # 無視ルール
    └─ README.md         # ドキュメント (EN/中文/日本語)

### 使い方

``` bash
git clone <repo>
cd defi-audit

# 依存関係をインストール
pip install -r requirements.txt

# env ファイルをコピーして API key を設定
cp .env.example .env   # INFURA_KEY を設定

# サーバーを起動
uvicorn app:app --host 0.0.0.0 --port 8002 --reload
```

### テスト例

``` bash
curl "http://localhost:8002/audit?contract=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48&chain=ethereum"
```
