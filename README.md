# agent-server

在 Ubuntu 上一键部署 [Gradio Agent APP](https://github.com/luochang212/dive-into-langgraph/tree/main/app)。

## 🚀 快速开始

在 [Ubuntu Server 24.04 LTS](https://ubuntu.com/download/raspberry-pi) 上运行以下命令，即可一键安装：

```bash
curl -fsSL https://raw.githubusercontent.com/luochang212/agent-server/main/agent-server-setup.sh | bash
```

> 配合  系统使用最佳

## 🌟 功能特性

该脚本自动完成以下配置工作：

- **👷 系统基础**：更新 apt，安装 pipx 和 uv
- **📓 开发环境**：安装 jupyterlab，并实现开机自启
- **🐳 容器环境**：安装 docker，配置国内 docker 镜像源
- **🤖 应用服务**：自动拉取 Gradio APP 代码，初始化环境配置

## ⚙️ 后续配置

1. 进入应用目录：
   ```bash
   cd ~/proj/agent-server
   ```

2. 编辑 `.env` 文件，填入阿里百炼的 `API_KEY`：
   ```bash
   vim .env
   ```

3. 启动 Agent 服务：
   ```bash
   sudo docker compose up -d
   ```

## 🌻 服务访问

如果你的电脑与 Ubuntu 服务器在同一个局域网下，通过以下地址访问服务：

| 服务名称 | 访问地址 |
| :--- | :--- |
| **JupyterLab** | `http://<服务器IP>:8888` |
| **Gradio APP** | `http://<服务器IP>:7860` |

> **Note:** 使用 `ip addr` 命令在服务器上查看其局域网 IP 地址
