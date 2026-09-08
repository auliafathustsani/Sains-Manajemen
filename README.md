# Sains-Manajemen

# Project #1 — 10 Expert Advisor (EA) dengan Bantuan AI

Repository ini berisi 10 Expert Advisor (EA) untuk MetaTrader 5 yang dikembangkan sebagai bagian dari tugas mata kuliah Sains Manajemen. Setiap EA menggunakan strategi trading yang berbeda dengan referensi video YouTube.

Pembuatan dan pengembangan kode MQL5 dilakukan dengan bantuan AI. Seluruh EA kemudian melalui proses backtest awal, optimasi parameter, dan backtest akhir menggunakan MT5 Strategy Tester. Backtest akhir dilakukan menggunakan metode Every Tick Based on Real Ticks.

**Nama:** Aulia Fathus Tsani  
**NIU:** 534388  
**Mata Kuliah:** Sains Manajemen  

---

## Daftar 10 Expert Advisor

| No. | Folder | Topik/Strategi | Referensi | Link YouTube | Status |
|---:|---|---|---|---|---|
| 1 | [`EA01-Turnaround-Tuesday`](EA01-Turnaround-Tuesday/) | Turnaround Tuesday EA | René Balke – BM Trading | [Watch Video](https://youtu.be/3DI7IOyCQLg) | ✅ Selesai |
| 2 | [`EA02-Bollinger-Bands`](EA02-Bollinger-Bands/) | Bollinger Bands Mean Reversion EA | Antovis Analytics | [Watch Video](https://youtu.be/Z0rQqBUyusk) | ✅ Selesai |
| 3 | [`EA03-MACD-Crossover`](EA03-MACD-Crossover/) | MACD Crossover EA | MQL5 Programming Tutorial | [Watch Video](https://youtu.be/tSCtmXv25nM) | ✅ Selesai |
| 4 | [`EA04-Donchian-Channel`](EA04-Donchian-Channel/) | Donchian Channel Breakout EA | René Balke – BM Trading | [Part 1](https://youtu.be/uz_BX5T1ER8) · [Part 2](https://youtu.be/8bUe42xTgw8) | ✅ Selesai |
| 5 | [`EA05-RSI-Reversal`](EA05-RSI-Reversal/) | RSI Overbought/Oversold Reversal EA | Antovis Analytics | [Watch Video](https://youtu.be/jjI8_omc8Gc) | ✅ Selesai |
| 6 | [`EA06-Moving-Average-Crossover`](EA06-Moving-Average-Crossover/) | Moving Average Crossover EA | Antovis Analytics | [Watch Video](https://youtu.be/h8lZCEpiFOI) | ✅ Selesai |
| 7 | [`EA07-Supertrend`](EA07-Supertrend/) | Supertrend Following EA | René Balke – BM Trading | [Part 1](https://youtu.be/acaqusyaeXc) · [Part 2](https://youtu.be/f-2EHVL-Nj0) | ✅ Selesai |
| 8 | [`EA08-Range-Breakout`](EA08-Range-Breakout/) | Time-Based Range Breakout EA | René Balke – BM Trading | [Main Video](https://youtu.be/1Y6j8_9Hzgk) · [Optimization](https://youtu.be/qCdqheZrK7M) | ✅ Selesai |
| 9 | [`EA09-Stochastic-MA`](EA09-Stochastic-MA/) | Stochastic Oscillator dengan Moving Average Filter | René Balke – BM Trading | [Watch Video](https://youtu.be/YrzfNo8iKlw) | ✅ Selesai |
| 10 | [`EA10-RSI-Grid`](EA10-RSI-Grid/) | RSI Grid Trading EA | René Balke – Fx Bot Trading | [Watch Video](https://youtu.be/M1t_gg-nO48) | ✅ Selesai |

---

## Penjelasan Singkat Strategi

### 1. Turnaround Tuesday EA

EA membuka posisi berdasarkan pola pergerakan harga dari hari Senin menuju Selasa. Posisi dibuka ketika harga mengalami setback dengan nilai tertentu dan ditutup sesuai jadwal strategi.

### 2. Bollinger Bands EA

EA menggunakan Bollinger Bands untuk mendeteksi kondisi ketika harga bergerak terlalu jauh dari rata-ratanya. Posisi dibuka dengan asumsi harga akan kembali menuju nilai rata-rata.

### 3. MACD Crossover EA

EA menggunakan persilangan garis utama dan signal MACD. Persilangan ke atas digunakan sebagai sinyal buy, sedangkan persilangan ke bawah digunakan sebagai sinyal sell.

### 4. Donchian Channel EA

EA menggunakan batas tertinggi dan terendah harga dalam periode tertentu. Posisi dibuka ketika harga menembus batas atas atau batas bawah Donchian Channel.

### 5. RSI Reversal EA

EA menggunakan kondisi overbought dan oversold pada indikator RSI untuk mendeteksi kemungkinan pembalikan arah harga.

### 6. Moving Average Crossover EA

EA menggunakan persilangan dua Moving Average dengan periode berbeda. Persilangan Moving Average cepat dan lambat digunakan untuk menentukan sinyal buy atau sell.

### 7. Supertrend EA

EA menggunakan Average True Range dan multiplier untuk membentuk indikator Supertrend. Perubahan arah Supertrend digunakan sebagai sinyal masuk pasar.

### 8. Range Breakout EA

EA mencatat rentang harga pada jam tertentu. Posisi dibuka ketika harga menembus batas atas atau bawah rentang tersebut sebelum waktu perdagangan berakhir.

### 9. Stochastic Moving Average EA

EA menggabungkan Stochastic Oscillator dengan Moving Average. Stochastic digunakan untuk membaca momentum, sedangkan Moving Average digunakan sebagai filter arah tren.

### 10. RSI Grid EA

EA menggunakan RSI sebagai sinyal pembukaan posisi awal, kemudian menambahkan posisi dengan jarak grid tertentu. EA menggunakan fixed lot tanpa martingale, jumlah posisi maksimum, target keuntungan basket, dan batas kerugian basket.

---

## Konfigurasi Backtest

Konfigurasi berikut digunakan agar hasil pengujian antar-EA dapat dibandingkan secara konsisten:

| Pengaturan | Nilai |
|---|---|
| Platform | MetaTrader 5 |
| Symbol utama | EURUSD |
| Pengecualian symbol | EA01 menggunakan DE40 |
| Timeframe utama | H1 |
| Periode pengujian | 8 September 2023 – 8 September 2026 |
| Forward testing | No |
| Initial deposit | USD 10,000 |
| Leverage | 1:100 |
| Final modelling | Every Tick Based on Real Ticks |
| History quality | 100% |
| Optimization criterion | Balance Max |
| Visual mode | Disabled |

Optimasi awal dilakukan menggunakan Fast Genetic Based Algorithm atau Slow Complete Algorithm sesuai jumlah kombinasi parameter. Parameter terpilih kemudian diuji ulang menggunakan Every Tick Based on Real Ticks.

---

## Parameter Akhir

| EA | Parameter Utama Hasil Optimasi |
|---|---|
| EA01 Turnaround Tuesday | Open Hour 19, Close Hour 19, Setback Threshold 400 |
| EA02 Bollinger Bands | Period 45, Deviation 2.75, SL 1000, TP 1000 |
| EA03 MACD Crossover | Fast 8, Slow 35, Signal 15, SL 600, TP 900 |
| EA04 Donchian Channel | Period 20, SL 1200, TP 1800 |
| EA05 RSI Reversal | RSI 25, Oversold 40, Overbought 60, SL 600, TP 900 |
| EA06 Moving Average Crossover | Fast MA 20, Slow MA 60, EMA, SL 1200, TP 900 |
| EA07 Supertrend | ATR Period 5, Multiplier 4.0, SL 1500, TP 1500 |
| EA08 Range Breakout | Range Start 0, Range End 7, Trade End 20, SL 900, TP 1800 |
| EA09 Stochastic MA | K 15, D 3, Slowing 3, Oversold 30, Overbought 85, MA 20, SL 1200, TP 1200 |
| EA10 RSI Grid | RSI 14, Oversold 30, Overbought 75, Grid Distance 300, Max Positions 5, Basket Profit 15, Basket Loss 50 |

---

## Hasil Backtest Akhir

| EA | Net Profit | Profit Factor | Total Trades | Equity Drawdown | Sharpe Ratio |
|---|---:|---:|---:|---:|---:|
| EA01 Turnaround Tuesday | 1,648.86 | 1.30 | 64 | 12.53% | 1.96 |
| EA02 Bollinger Bands | 84.97 | 1.22 | 229 | 0.41% | 0.98 |
| EA03 MACD Crossover | 36.75 | 1.02 | 1,293 | 1.04% | — |
| EA04 Donchian Channel | 15.95 | 1.02 | 434 | 1.50% | 0.07 |
| EA05 RSI Reversal | 147.39 | 1.17 | 345 | 0.61% | 0.79 |
| EA06 Moving Average Crossover | 88.53 | 1.13 | 309 | 0.63% | 0.62 |
| EA07 Supertrend | 101.92 | 1.12 | 408 | 1.11% | 0.49 |
| EA08 Range Breakout | 112.67 | 1.13 | 747 | 0.92% | 1.06 |
| EA09 Stochastic MA | 225.62 | 1.55 | 131 | 0.59% | 1.56 |
| EA10 RSI Grid | 520.84 | 1.50 | 382 | 1.62% | 1.04 |

---

## Ringkasan Hasil

Seluruh EA memperoleh net profit positif pada pengujian akhir. EA01 Turnaround Tuesday menghasilkan net profit tertinggi sebesar USD 1,648.86. Namun, EA ini juga memiliki equity drawdown paling tinggi, yaitu 12.53%.

EA10 RSI Grid menghasilkan net profit tertinggi kedua sebesar USD 520.84 dengan profit factor 1.50 dan equity drawdown 1.62%. Meskipun hasil backtest-nya baik, penggunaan sistem grid tetap memiliki risiko kerugian yang lebih besar ketika pasar bergerak kuat dalam satu arah.

EA09 Stochastic MA memberikan hasil yang cukup seimbang dengan net profit USD 225.62, profit factor 1.55, Sharpe ratio 1.56, dan equity drawdown hanya 0.59%. Berdasarkan keseimbangan profit dan risiko, EA09 menjadi salah satu EA dengan performa paling stabil dalam pengujian ini.

EA03 MACD Crossover dan EA04 Donchian Channel masih menghasilkan keuntungan. Namun, profit factor keduanya hanya 1.02 sehingga performanya tergolong marginal dan masih memerlukan pengujian lebih lanjut.

---

## Struktur Folder

Setiap folder Expert Advisor menggunakan susunan berikut:

```text
EAxx-Nama-Strategi/
├── reports/
│   ├── ReportTester-EAxx.html
│   └── ReportTester-EAxx.pdf
├── screenshots/
│   └── Backtest_After_Optimization_EAxx.png
├── src/
│   └── EAxx_NamaStrategi.mq5
└── README.md

