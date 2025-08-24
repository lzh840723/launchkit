# 🛡️ Smart Contract Security Audit MVP

## 📖 English

### Overview

This project is a **Dockerized MVP** for smart contract security auditing.
It provides:

* 🔑 Token-based authentication (`generate_token.py`)
* 📊 Security audit reports (`mvp_secure_data/audit_report.json`)
* 🗄️ PostgreSQL + Redis integration
* ⚡ FastAPI backend with response time <1s (optimized with caching & async calls)

### Features

* Docker Compose deployment (`docker-compose.yml`)
* API authentication with JWT
* Security report output in JSON
* Persistent storage via volumes

### Project Structure

```
audit_docker_mvp/
├── mvp_deploy_data/mvp_secure_data/   # Stores security audit data
│   └── audit_report.json              # Security audit results (JSON)
├── app.py                             # FastAPI application entrypoint
├── generate_token.py                  # Generate JWT tokens
├── Dockerfile                         # Docker build instructions
├── docker-compose.yml                 # Orchestration config
├── requirements.txt                   # Python dependencies
├── .env.example                       # Example environment variables
└── README.md                          # Documentation
```

### Run & Test
1. **Create a .env file in the root directory**
   ```ini
   INFURA_KEY=your_infura_key
   SECRET_KEY=your_jwt_secret
   POSTGRES_USER=your_postgres_user_here
   POSTGRES_PASSWORD=your_postgres_password_here
   POSTGRES_DB=your_postgres_db_name_here
   DATA_DIR=/your/data/directory/here
   ```
   ※ Refer to .env.example for details.

2. **Build & start**

   ```bash
   docker-compose up --build
   ```
3. **Generate token**

   ```bash
   docker compose exec app python generate_token.py
   ```
4. **Test API**

   ```bash
   curl -X 'GET' \
     'http://localhost:8000/security_audit/0xdac17f958d2ee523a2206206994597c13d831ec7?chain_name=ethereum' \
     -H 'accept: application/json' \
     -H 'Authorization: Bearer <YOUR_TOKEN>'
   ```
5. **Check results**

   * JSON report: `mvp_deploy_data/mvp_secure_data/audit_report.json`
   * Database: connect to `blockchain_db` (PostgreSQL, port 5433)
   ```bash
   docker compose exec db psql -U lzh -d blockchain_db -c "SELECT COUNT(*) FROM security_audits;"
   ```


---

## 📖 中文

### 概述

这是一个 **智能合约安全审计的 Docker 化 MVP**。
提供以下功能：

* 🔑 Token 身份验证 (`generate_token.py`)
* 📊 安全审计报告 (`audit_report.json`)
* 🗄️ PostgreSQL + Redis 集成
* ⚡ FastAPI 后端，响应时间 <1s（优化了缓存和异步调用）

### 特性

* 使用 Docker Compose 部署
* 基于 JWT 的 API 鉴权
* 审计结果以 JSON 文件输出
* 数据通过 volume 持久化

### 项目结构

（同上）

### 运行 & 测试方法

1. **请在根目录创建 `.env` 文件，包含以下内容**
   ```ini
   INFURA_KEY=your_infura_key
   SECRET_KEY=your_jwt_secret
   POSTGRES_USER=your_postgres_user_here
   POSTGRES_PASSWORD=your_postgres_password_here
   POSTGRES_DB=your_postgres_db_name_here
   DATA_DIR=/your/data/directory/here
   ```
   ※ 请参照.env.example
2. **启动服务**

   ```bash
   docker-compose up --build
   ```
3. **生成 Token**

   ```bash
   docker compose exec app python generate_token.py
   ```
4. **测试接口**

   ```bash
   curl -X 'GET' \
     'http://localhost:8000/security_audit/0xdac17f958d2ee523a2206206994597c13d831ec7?chain_name=ethereum' \
     -H 'accept: application/json' \
     -H 'Authorization: Bearer <你的TOKEN>'
   ```
5. **确认结果**

   * JSON 文件：`mvp_deploy_data/mvp_secure_data/audit_report.json`
   * 数据库：连接 PostgreSQL (`blockchain_db`, 端口 5433)
   ```bash
   docker compose exec db psql -U lzh -d blockchain_db -c "SELECT COUNT(*) FROM security_audits;"
   ```

---

## 📖 日本語

### 概要

これは **スマートコントラクトセキュリティ監査の Docker 化 MVP** です。
提供機能：

* 🔑 トークン認証 (`generate_token.py`)
* 📊 監査レポート (`audit_report.json`)
* 🗄️ PostgreSQL + Redis 統合
* ⚡ FastAPI バックエンド（レスポンス <1秒）

### 特徴

* Docker Compose によるデプロイ
* JWT ベースの API 認証
* 監査結果は JSON 出力
* データは volume による永続化

### プロジェクト構成

（同上）

### 実行 & テスト
1. **ルートに .env ファイルを作成し、以下を記入してください：**
   ```ini
   INFURA_KEY=your_infura_key
   SECRET_KEY=your_jwt_secret
   POSTGRES_USER=your_postgres_user_here
   POSTGRES_PASSWORD=your_postgres_password_here
   POSTGRES_DB=your_postgres_db_name_here
   DATA_DIR=/your/data/directory/here
   ```
   ※ .env.exampleを参照
2. **サービス起動**

   ```bash
   docker-compose up --build
   ```
3. **トークン生成**

   ```bash
   docker compose exec app python generate_token.py
   ```
4. **API テスト**

   ```bash
   curl -X 'GET' \
     'http://localhost:8000/security_audit/0xdac17f958d2ee523a2206206994597c13d831ec7?chain_name=ethereum' \
     -H 'accept: application/json' \
     -H 'Authorization: Bearer <あなたのTOKEN>'
   ```
5. **出力確認**

   * JSON ファイル：`mvp_deploy_data/mvp_secure_data/audit_report.json`
   * DB：PostgreSQL (`blockchain_db`, ポート 5433)
   ```bash
   docker compose exec db psql -U lzh -d blockchain_db -c "SELECT COUNT(*) FROM security_audits;"
   ```