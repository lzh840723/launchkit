# NFT Query API

English | 中文 | 日本語

## [ ENGLISH ]
----------------------------------------------------------------
A simple FastAPI service to query the number of NFTs owned by an address.

### Features
- Query the balance of any ERC-721 contract for a given owner
- Uses Infura Ethereum node

### Installation

1. Clone the repo and enter directory:
   ```bash
   cd nft-query
   ```

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Create `.env` file and set your Infura Project ID:
   ```
   INFURA_KEY=your_infura_project_id
   ```
   > You can refer to `.env.example`

4. Run service:
   ```bash
   uvicorn app:app --reload --port 8001
   ```

### Usage
```
GET http://localhost:8001/nft/{contract_address}/{owner_address}
```

Example:
```
GET http://localhost:8001/nft/0x1234567890abcdef1234567890abcdef12345678/0xabcdabcdabcdabcdabcdabcdabcdabcdabcdabcd
```

Response:
```json
{
  "contract": "0x1234567890abcdef1234567890abcdef12345678",
  "owner": "0xabcdabcdabcdabcdabcdabcdabcdabcdabcdabcd",
  "balance": 2
}
```

### Project Structure
```
nft-query/
 ├─ app.py             # FastAPI main app
 ├─ requirements.txt   # Python dependencies
 ├─ README.md          # Documentation
 ├─ .gitignore         # Git ignore file
 └─ .env.example       # Env vars example
```

---

## [ 中文 / Chinese ]
----------------------------------------------------------------
一个基于 FastAPI 的简单服务，用来查询某个地址持有的 NFT 数量。

### 功能
- 查询任意 ERC-721 合约下某个地址的持有数量
- 使用 Infura 提供的 Ethereum 节点

### 安装步骤

1. 克隆项目并进入目录：
   ```bash
   cd nft-query
   ```

2. 安装依赖：
   ```bash
   pip install -r requirements.txt
   ```

3. 新建 `.env` 文件，并设置 Infura 项目 ID：
   ```
   INFURA_KEY=你的Infura项目ID
   ```
   > 可以参考 `.env.example`

4. 启动服务：
   ```bash
   uvicorn app:app --reload --port 8001
   ```

### 使用方法
调用接口：
```
GET http://localhost:8001/nft/{contract_address}/{owner_address}
```

示例：
```
GET http://localhost:8001/nft/0x1234567890abcdef1234567890abcdef12345678/0xabcdabcdabcdabcdabcdabcdabcdabcdabcdabcd
```

返回：
```json
{
  "contract": "0x1234567890abcdef1234567890abcdef12345678",
  "owner": "0xabcdabcdabcdabcdabcdabcdabcdabcdabcdabcd",
  "balance": 2
}
```

### 目录结构
```
nft-query/
 ├─ app.py             # FastAPI 主程序
 ├─ requirements.txt   # Python 依赖
 ├─ README.md          # 使用说明
 ├─ .gitignore         # 忽略文件配置
 └─ .env.example       # 环境变量示例
```

---

## [ 日本語 / Japanese ]
----------------------------------------------------------------
FastAPI ベースの簡単なサービスで、特定のアドレスが保有する NFT 数を照会できます。

### 機能
- 任意の ERC-721 コントラクトにおけるアドレスの保有数量を取得
- Infura Ethereum ノードを利用

### インストール手順

1. リポジトリをクローンし、ディレクトリに移動：
   ```bash
   cd nft-query
   ```

2. 依存関係をインストール：
   ```bash
   pip install -r requirements.txt
   ```

3. `.env` ファイルを作成し、Infura プロジェクト ID を設定：
   ```
   INFURA_KEY=あなたのInfuraプロジェクトID
   ```
   > `.env.example` を参考にできます

4. サービスを起動：
   ```bash
   uvicorn app:app --reload --port 8001
   ```

### 使い方
API 呼び出し：
```
GET http://localhost:8001/nft/{contract_address}/{owner_address}
```

例：
```
GET http://localhost:8001/nft/0x1234567890abcdef1234567890abcdef12345678/0xabcdabcdabcdabcdabcdabcdabcdabcdabcdabcd
```

レスポンス：
```json
{
  "contract": "0x1234567890abcdef1234567890abcdef12345678",
  "owner": "0xabcdabcdabcdabcdabcdabcdabcdabcdabcdabcd",
  "balance": 2
}
```

### ディレクトリ構造
```
nft-query/
 ├─ app.py             # FastAPI メインアプリ
 ├─ requirements.txt   # Python 依存関係
 ├─ README.md          # ドキュメント
 ├─ .gitignore         # Git 無視設定
 └─ .env.example       # 環境変数サンプル
```
