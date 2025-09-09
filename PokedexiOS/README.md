# PokedexiOS

iOS 版 Pokédex，使用 SwiftUI + The Composable Architecture (TCA) 實作。提供清單、詳情、搜尋、下拉更新與多種篩選（Mega、Gmax、其他形態、已收服/未收服、世代/地區），並支援官方圖與精靈圖（含異色）。

## 功能總覽
- 搜尋：支援名稱、全國編號、屬性、分類（包含式、忽略大小寫）。
- 篩選：
  - 形態：Mega、Gmax、其他形態（Other Forms）。
  - 收服狀態：全部、已收服、未收服（以 `{id}-{subId 或 0}` 鍵值判定）。
  - 世代/地區：依 `pokemon_generations.json` 的全國編號範圍過濾。
- 圖像：官方插畫（Official Artwork）或精靈圖（Sprite），可切換異色（Shiny）。
- 詳情：顯示基本資料、屬性、特性、弱點等。
- 下拉更新：重新載入資料。

## 技術與架構
- UI：SwiftUI
- 狀態管理：The Composable Architecture (TCA)
- 網路：Alamofire（預設以內建本機 JSON 作為資料來源）
- 圖片載入：SDWebImageSwiftUI

## 資料規格（Data Contracts）
- Pokemon（來源：`pokemon_data.json`）
  - 欄位：`id`, `sub_id`, `name`, `form_name`, `form_type`, `image`, `height`, `weight`, `category`, `gender`, `abilities`[String], `weakness`[String], `types`[String]
- GenerationCategory（來源：`pokemon_generations.json`）
  - 欄位：世代、地區、全國編號範圍（如 `"#0001 - #0151"`）、遊戲版本、特色

## 圖片 URL 規則
- 官方插畫：`https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/{id}.png`
- 精靈圖（可選異色）：`https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/{shiny?/} {id}.png`

## 篩選規格（重要）
- 搜尋：以包含式比對 `name`、`id`、`types`、`category`（全部轉小寫）。
- 形態（Forms）：
  - Mega：`form_type == "mega"`
  - Gmax：`form_type == "gmax"` 或 `"gigantamax"`
  - 其他形態（Other Forms）：`form_name` 有值，且 `form_type` 不在 `{ mega, gmax/gigantamax, alola, galar, hisui, paldea }`
  - 若未選擇任何形態，則不套用形態過濾。
- 收服狀態：
  - 以集合 `caughtSet`（元素格式：`"{id}-{subId 或 0}"`）判斷。
  - 模式：全部（不過濾）、已收服（在集合內）、未收服（不在集合內）。
- 世代/地區：
  - 解析 `national_dex_range` 字串取得上下限，過濾 `id` 落在範圍內之寶可夢。

## UI 行為
- 清單頁右上角工具列：
  - 圖像樣式（官方/精靈）、Shiny 切換。
  - Forms 子選單：切換 Mega/Gmax/Other Forms。
  - Capture 子選單：選擇 全部/已收服/未收服（會以勾勾標記目前選擇）。
  - Generation/Region 子選單：從 `pokemon_generations.json` 載入清單，選擇後以勾勾標記。
- 搜尋列：即時篩選，與其他篩選條件併用。
- 下拉更新：重新呼叫載入（內建會讀本機 JSON）。

## 狀態（State）與動作（Action）
- `PokedexListFeature.State`
  - `all` / `filtered`：完整清單與篩選後清單。
  - `generations` / `selectedGeneration`：世代資料與選擇項目。
  - `formFilters`：形態篩選集合（Mega/Gmax/OtherForms）。
  - `captureFilter`：收服篩選（all/caught/uncaught）。
  - `caughtSet`：已收服鍵值集合（目前為記憶體內）。
  - `imageStyle` / `isShiny` / `searchText` / `isLoading`。
- `PokedexListFeature.Action`
  - 資料載入：`onAppear`、`refreshPulled`、`loadResponse`、`loadGenerationsResponse`
  - UI：`setImageStyle`、`toggleShiny`
  - 篩選：`setCaptureFilter`、`setSelectedGeneration`、`toggleFormFilter`
  - 綁定：`binding(BindingAction<State>)`

## 執行方式
- 需求：Xcode 15+、iOS 16+
- 以 Xcode 開啟專案並執行 App target。
- 依 SwiftPM 於 Xcode 新增相依：ComposableArchitecture、Alamofire、SDWebImageSwiftUI。

## 專案結構
- `Sources/App`：應用入口（`AppFeature`、`AppView`）。
- `Sources/Features/PokedexList`：清單頁 Feature 與 View。
- `Sources/Features/PokemonDetail`：詳情頁 Feature 與 View。
- `Sources/Domain/Models`：資料模型（`Pokemon`、`GenerationCategory`）。
- `Sources/Data/API`：API Client（預設讀取本機 JSON）。
- `Sources/Data/Image`：圖片 URL 組裝。
- `docs/`：產品說明、規格與資料契約。

## 備註
- 專案內建開發用樣本資料（若讀取資料失敗會 fallback）。
- 目前「已收服」狀態尚未持久化；可後續加入 `UserDefaults` 或資料庫。
- 若需在清單卡片/詳情頁提供「收服/取消收服」按鈕，可再行擴充。

## 授權
個人/學習用途。
