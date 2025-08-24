# Token API (FastAPI)
- ERC20 balance with decimals/symbol
- JWT (HS256, 1h), CORS

English | 中文 | 日本語

## [ ENGLISH ]
----------------------------------------------------------------
### Quick Start
1) pip install -r requirements.txt
2) cp .env.example .env   (fill: INFURA_KEY, SECRET_KEY)
3) Create `.env` file and set Infura project ID:
   ```
   INFURA_KEY=your_infura_project_id
   SECRET_KEY=your_secret_key
   ```
   > You can refer to `.env.example`
4) uvicorn app:app --reload
5) open http://localhost:8000/docs

**Env:** INFURA_KEY, SECRET_KEY

### Demo
1) Generate JWT  
   ```bash
   python generate_token.py   # copy the printed token
   ```

2) Call
   ```http
   GET http://localhost:8000/health
   GET http://localhost:8000/balance?contract=<ERC20>&owner=<address>
   Header: Authorization: Bearer <your_token>
   ```

## [ 中文 / Chinese ]
----------------------------------------------------------------
### 快速启动
1) pip install -r requirements.txt
2) cp .env.example .env   （填写：INFURA_KEY, SECRET_KEY）
3) 新建 `.env` 文件，并设置 Infura 项目 ID：
   ```
   INFURA_KEY=你的Infura项目ID
   SECRET_KEY=你的SecretKey
   ```
   > 可以参考 `.env.example`
4) uvicorn app:app --reload
5) 打开 http://localhost:8000/docs

**环境变量：** INFURA_KEY，SECRET_KEY

### 演示
1）生成 JWT  
   ```bash
   python generate_token.py   （复制输出的 token）
   ```

2）调用
   ```http
   GET http://localhost:8000/health
   GET http://localhost:8000/balance?contract=<ERC20>&owner=<address>
   请求头：Authorization: Bearer <你的token>
   ```

## [ 日本語 / Japanese ]
----------------------------------------------------------------
### クイックスタート
1) pip install -r requirements.txt
2) cp .env.example .env   （INFURA_KEY と SECRET_KEY を設定）
3) `.env` ファイルを新規作成し、Infura プロジェクト ID を設定：
   ```
   INFURA_KEY=あなたのInfuraプロジェクトID
   SECRET_KEY=あなたのSecretKey
   ```
   > `.env.example` を参考にできます
4) uvicorn app:app --reload
5) http://localhost:8000/docs を開く

**環境変数：** INFURA_KEY, SECRET_KEY

### デモ
1) JWT を生成  
   ```bash
   python generate_token.py   （出力トークンをコピー）
   ```

2) 呼び出し
   ```http
   GET http://localhost:8000/health
   GET http://localhost:8000/balance?contract=<ERC20>&owner=<address>
   ヘッダー: Authorization: Bearer <your_token>
   ```

---

### Notes
- Do not commit .env.
- Ensure the token is generated with the same SECRET_KEY used by the server.
