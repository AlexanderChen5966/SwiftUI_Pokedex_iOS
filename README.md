# PokedexiOS

 iOS 版 Pokédex，使用 SwiftUI + The Composable Architecture (TCA) 實作。介面已簡化為「只顯示圖片」的清單，不再載入或解析 `pokemon_data.json` 與 `pokemon_generations.json`。

## 功能總覽
- 圖像清單：以固定範圍的全國編號（預設 #0001–#0151）顯示圖片。
- 圖像：官方插畫（Official Artwork）或精靈圖（Sprite），可切換異色（Shiny）。

## 技術與架構
- UI：SwiftUI
- 狀態管理：The Composable Architecture (TCA)
- 網路：Alamofire（預設以內建本機 JSON 作為資料來源）
- 圖片載入：SDWebImageSwiftUI

## 資料來源
- 不再讀取 `pokemon_data.json`、`pokemon_generations.json`。
- 清單以內建的整數 ID 範圍組圖（`ImageURLBuilder` 依 ID 組 URL）。

## 圖片 URL 規則
- 官方插畫：`https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/{id}.png`
- 精靈圖（可選異色）：`https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/{shiny?/} {id}.png`

## 介面說明（目前行為）
- 右上角工具列：
  - 圖像樣式（官方/精靈）。
  - Shiny 切換。
- 僅顯示圖片方塊，不含名稱、屬性或詳情導覽。

<!-- 舊版 UI 與狀態說明已移除 -->

## 執行方式
- 需求：Xcode 15+、iOS 16+
- 以 Xcode 開啟專案並執行 App target。
- 依 SwiftPM 於 Xcode 新增相依：ComposableArchitecture、Alamofire、SDWebImageSwiftUI。

## 專案結構
- `Sources/App`：應用入口（`AppFeature`、`AppView`）。
- `Sources/Features/PokedexList`：圖片清單 Feature 與 View。
- `Sources/Data/Image`：圖片 URL 組裝。
- `docs/`：產品說明、規格與資料契約（部分內容描述舊版功能，僅供參考）。

## 備註
- 舊版的 JSON 與過濾/搜尋/詳情功能已移除。
- 若需顯示更多圖片或調整範圍，請修改 `PokedexListFeature.State.ids`。

## 授權
學習用途。
