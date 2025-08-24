# 基础镜像，轻量版 Python 3.12
FROM python:3.12-slim
# 环境变量
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
# 设置工作目录
WORKDIR /app 
# 复制依赖文件
COPY requirements.txt .  
# 安装依赖，不缓存
RUN pip install --no-cache-dir -r requirements.txt  
# 复制所有代码
COPY . .  
# 暴露端口
EXPOSE 8000  
# 挂载卷，用于 HDD 数据持久化
VOLUME /app/data  
# 启动命令
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]  