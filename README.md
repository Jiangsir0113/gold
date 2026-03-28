# 金账 - 黄金投资追踪 App

实时监控国内外金价，记录黄金交易账本，计算持仓盈亏。

## 功能

- **行情页**：实时显示 AU9999 国内金价、伦敦金 XAU/USD、美元人民币汇率，含当日价格走势迷你图，WebSocket 每分钟自动推送
- **账本页**：记录买入/卖出交易，支持添加、编辑、删除
- **持仓页**：显示总持仓克数、加权平均成本、浮动盈亏、已实现盈亏，含历史市值曲线图
- **设置页**：配置服务器地址和 API Key，支持导出交易记录 CSV

## 技术栈

### 后端 (`gold-server/`)
| 组件 | 技术 |
|------|------|
| Web 框架 | FastAPI + Uvicorn |
| 实时推送 | WebSocket |
| 定时爬虫 | APScheduler（60秒间隔） |
| 缓存 | Redis 7（Hash + Sorted Set） |
| 数据库 | SQLite + SQLAlchemy 2.0 |
| 鉴权 | API Key（X-API-Key Header） |
| 部署 | Nginx + systemd，腾讯云 Ubuntu 24 |

### 数据源
| 品种 | 主源 | 备用源 |
|------|------|--------|
| AU9999 国内金价 | 东方财富（secid=118.Au9999） | 新浪财经 |
| XAU/USD 伦敦金 | 新浪财经 | 东方财富 |
| USD/CNY 汇率 | 新浪财经 | — |

### 移动端 (`gold-app/`)
| 组件 | 技术 |
|------|------|
| 框架 | Flutter 3.x（Android + iOS） |
| 状态管理 | Riverpod |
| 实时价格 | WebSocket（自动重连） |
| HTTP | Dio |
| 图表 | fl_chart |
| 本地存储 | SharedPreferences |

## 项目结构

```
gold/
├── gold-server/          # FastAPI 后端
│   ├── scrapers/         # 金价爬虫（AU9999、XAU/USD、USD/CNY）
│   ├── api/              # REST API（价格、账本、盈亏）
│   ├── deploy/           # systemd 服务文件 + Nginx 配置
│   └── tests/            # 单元测试（25个）
└── gold-app/             # Flutter 移动端
    └── lib/
        ├── models/       # 数据模型
        ├── services/     # WebSocket + HTTP 服务
        ├── providers/    # Riverpod 状态管理
        ├── screens/      # 四个页面
        └── widgets/      # 公共组件
```

## 部署后端

```bash
# 1. 安装依赖
sudo apt install -y python3 python3-venv python3-pip redis-server nginx git
sudo systemctl enable redis-server && sudo systemctl start redis-server

# 2. 克隆代码
cd /opt
sudo git clone https://github.com/Jiangsir0113/gold.git gold-server
sudo chown -R $USER:$USER /opt/gold-server
cd /opt/gold-server

# 3. 虚拟环境
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 4. 配置环境变量
cp .env.example .env
# 编辑 .env，填入 API_KEY

# 5. 启动服务
sudo cp deploy/gold-server.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable gold-server && sudo systemctl start gold-server

# 6. 配置 Nginx
sudo cp deploy/nginx.conf /etc/nginx/sites-available/gold-server
sudo ln -s /etc/nginx/sites-available/gold-server /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx
```

## 构建 App

```bash
cd gold-app
flutter pub get
flutter build apk --release
```

APK 路径：`build/app/outputs/flutter-apk/app-release.apk`

首次启动后进入**设置页**，填入服务器地址和 API Key 后保存。

## API 接口

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/prices/latest` | 获取最新金价 |
| GET | `/api/prices/history` | 获取当日价格历史 |
| WS | `/ws/prices` | WebSocket 实时价格推送 |
| GET | `/api/transactions` | 获取所有交易记录 |
| POST | `/api/transactions` | 添加交易记录 |
| PUT | `/api/transactions/{id}` | 修改交易记录 |
| DELETE | `/api/transactions/{id}` | 删除交易记录 |
| GET | `/api/transactions/export` | 导出 CSV |
| GET | `/api/summary` | 获取持仓汇总 |
| GET | `/api/summary/history` | 获取历史快照 |

所有接口需在请求头携带 `X-API-Key: <your-key>`，WebSocket 通过 `?api_key=<your-key>` 鉴权。
