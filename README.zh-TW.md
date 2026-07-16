# pc-steward（電腦管家）

**Windows 的 AI 電腦健檢管家——用證據診斷「你這台」機器的效能瓶頸，白話解釋原因，只修你批准的項目，而且每個變更都可還原。**

[English README](README.md)

## 為什麼還需要另一個優化工具？

現有的 Windows 優化工具（WinUtil、Win11Debloat、Sophia Script⋯）擅長套用**通用調整清單**——每台機器都是同一批勾選框。pc-steward 走相反的路線：讓 AI **實際查看你電腦正在發生的事**——記憶體壓力、分頁檔換頁、哪些程式吃掉多少 RAM、開機自啟動了什麼、磁碟健康度、錯誤日誌——先推理出「你的」瓶頸在哪，再給建議。

產出讀起來像醫生的診斷書，而不是設定清單：

> 🔴 **記憶體不足是你的主要瓶頸。** 總共 15.2 GB、只剩 1.7 GB 可用、認可使用率 82%。分頁檔高峰達 5.4 GB——資料正被換頁到硬碟上，這就是切換視窗會卡的原因。最大戶：Discord 的 6 個程序（744 MB）、Chrome 的 24 個程序（1.1 GB）⋯而且開機自啟動超過 20 個程式。

## 以架構保證安全

讓 AI 碰系統設定需要信任。pc-steward 用結構來保證，而不是口頭承諾：

1. **掃描完全唯讀。** 7 個掃描器只收集資料（輸出 JSON），無法修改任何東西。
2. **修復只能透過白名單腳本。** AI 只能呼叫內建的 action 腳本，不能自行組合任何變更系統的指令。
3. **每次變更前自動備份。** action 腳本會先把受影響的登錄檔機碼匯出成 `.reg` 檔。還原＝跑一個腳本，或直接雙擊備份檔。
4. **非破壞性機制。** 停用開機自啟動走 Windows 官方的 `StartupApproved` 機制（跟工作管理員的「停用」按鈕完全相同），不刪除任何東西；安全軟體項目在腳本層級直接拒絕。
5. **沒有你的批准，什麼都不會發生。** 掃描 → 報告 → **你決定** → 修復 → 驗證。

## 安裝

核心是 agent 中立的（PowerShell 腳本＋純 Markdown 操作手冊），每個 AI 工具只需要一層薄薄的轉接器。

### Claude Code

**以 plugin 安裝（建議）：**

```
/plugin marketplace add Lother13501350/pc-steward
/plugin install pc-steward
```

**或手動安裝 skill：** 把 `skills/pc-steward/` 複製到 `~/.claude/skills/` 目錄。

### OpenAI Codex

```
git clone https://github.com/Lother13501350/pc-steward
cd pc-steward
codex
```

接著直接說「我的電腦好慢」——Codex 會自動讀取 [AGENTS.md](AGENTS.md)，遵循同一套工作流程與安全守則。

想要全域 `/pc-steward` 指令的話：把 `adapters/codex/pc-steward.md` 複製到 `~/.codex/prompts/`，把檔案裡的 `<REPO_PATH>` 改成你 clone 的路徑（只需改一次），之後在任何目錄都能用 `/pc-steward` 呼叫。

### 其他 agent CLI（Cursor、Gemini CLI⋯）

任何會讀取 `AGENTS.md` 的 agent 都跟 Codex 一樣：clone 這個 repo、在裡面啟動你的 agent、然後開口問。

需求：Windows 10/11、Windows PowerShell 5.1+（內建）。在 WSL 裡的 agent 可直接呼叫 `powershell.exe`。

## 使用方式

直接跟 Claude Code 說話：

- 「電腦越來越慢，幫我健檢一下」
- 「掃描一下我的電腦有什麼效能瓶頸」
- 「幫我清理開機自啟動」
- *"My laptop feels slow lately, can you check what's wrong?"*

Claude 會執行掃描器、給你一份按嚴重度排序、附證據的診斷報告，然後把可修復項目列成選單。你點頭之前，什麼都不會被改動。

## 內容物

```
skills/pc-steward/
├── SKILL.md                     # 管家的工作流程與安全守則
└── scripts/
    ├── scanners/                # 唯讀，輸出 JSON
    │   ├── system.ps1           # CPU、RAM、開機時長、GPU、電源計畫
    │   ├── processes.ps1        # RAM/CPU 佔用大戶、多程序應用分組
    │   ├── startup.ps1          # 所有自啟動項目＋啟用/停用狀態
    │   ├── disks.ps1            # 磁碟健康、剩餘空間、分頁檔
    │   ├── services.ps1         # 執行中的第三方服務
    │   ├── events.ps1           # 系統錯誤與儲存裝置警告（7 天）
    │   └── junk.ps1             # 可清理位置（暫存、快取、資源回收筒）
    └── actions/                 # 白名單、可還原的變更
        ├── disable-startup.ps1  # 工作管理員等級的停用，附 .reg 備份
        └── restore-startup.ps1  # 從備份還原
```

## 開發路線

- **v0.2** —— 垃圾清理 action（暫存/快取，含隔離區）、MCP server（讓 Claude Desktop 等所有 MCP 客戶端都能使用）
- **v0.3** —— 獨立 CLI（自帶 API key）、社群貢獻掃描模組
- **之後** —— GUI、macOS/Linux 掃描器

## 貢獻

歡迎 Issue 和 PR。掃描器貢獻必須唯讀；action 貢獻必須備份狀態並說明還原路徑。

## 授權

[MIT](LICENSE)
