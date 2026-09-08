# Sains-Manajemen

# Project #1 — 10 Expert Advisor (EA) dengan Bantuan AI

Repository ini berisi 10 Expert Advisor (EA) untuk MetaTrader 5 yang dikembangkan sebagai bagian dari tugas mata kuliah Sains Manajemen. Setiap EA menggunakan strategi trading yang berbeda dengan mengacu pada video tutorial YouTube.

Pembuatan dan pengembangan kode MQL5 dilakukan dengan bantuan AI. Seluruh EA telah melalui tahap penyusunan kode, compile, backtest awal, optimasi parameter, dan backtest akhir menggunakan MT5 Strategy Tester.

**Nama:** Aulia Fathus Tsani
**NIU:** 534388
**Mata Kuliah:** Sains Manajemen

---

## Daftar 10 Expert Advisor

| No. | Folder                                                            | Topik/Strategi                                     | Sumber Referensi            | Link YouTube                                                                              | Status    |
| --: | ----------------------------------------------------------------- | -------------------------------------------------- | --------------------------- | ----------------------------------------------------------------------------------------- | --------- |
|   1 | [`EA01-Turnaround-Tuesday`](EA01-Turnaround-Tuesday/)             | Turnaround Tuesday EA                              | René Balke – BM Trading     | [Watch Video](https://youtu.be/3DI7IOyCQLg)                                               | ✅ Selesai |
|   2 | [`EA02-Bollinger-Bands`](EA02-Bollinger-Bands/)                   | Bollinger Bands Mean Reversion EA                  | Antovis Analytics           | [Watch Video](https://youtu.be/Z0rQqBUyusk)                                               | ✅ Selesai |
|   3 | [`EA03-MACD-Crossover`](EA03-MACD-Crossover/)                     | MACD Crossover EA                                  | MQL5 Programming Tutorial   | [Watch Video](https://youtu.be/tSCtmXv25nM)                                               | ✅ Selesai |
|   4 | [`EA04-Donchian-Channel`](EA04-Donchian-Channel/)                 | Donchian Channel Breakout EA                       | René Balke – BM Trading     | [Part 1](https://youtu.be/uz_BX5T1ER8) · [Part 2](https://youtu.be/8bUe42xTgw8)           | ✅ Selesai |
|   5 | [`EA05-RSI-Reversal`](EA05-RSI-Reversal/)                         | RSI Overbought/Oversold Reversal EA                | Antovis Analytics           | [Watch Video](https://youtu.be/jjI8_omc8Gc)                                               | ✅ Selesai |
|   6 | [`EA06-Moving-Average-Crossover`](EA06-Moving-Average-Crossover/) | Moving Average Crossover EA                        | Antovis Analytics           | [Watch Video](https://youtu.be/h8lZCEpiFOI)                                               | ✅ Selesai |
|   7 | [`EA07-Supertrend`](EA07-Supertrend/)                             | Supertrend Following EA                            | René Balke – BM Trading     | [Part 1](https://youtu.be/acaqusyaeXc) · [Part 2](https://youtu.be/f-2EHVL-Nj0)           | ✅ Selesai |
|   8 | [`EA08-Range-Breakout`](EA08-Range-Breakout/)                     | Time-Based Range Breakout EA                       | René Balke – BM Trading     | [Main Video](https://youtu.be/1Y6j8_9Hzgk) · [Optimization](https://youtu.be/qCdqheZrK7M) | ✅ Selesai |
|   9 | [`EA09-Stochastic-MA`](EA09-Stochastic-MA/)                       | Stochastic Oscillator dengan Moving Average Filter | René Balke – BM Trading     | [Watch Video](https://youtu.be/YrzfNo8iKlw)                                               | ✅ Selesai |
|  10 | [`EA10-RSI-Grid`](EA10-RSI-Grid/)                                 | RSI Grid Trading EA                                | René Balke – Fx Bot Trading | [Watch Video](https://youtu.be/M1t_gg-nO48)                                               | ✅ Selesai |

---

## Penjelasan Strategi

### EA01 — Turnaround Tuesday

EA ini menggunakan pola pergerakan harga dari hari Senin menuju Selasa. Posisi dibuka ketika harga mengalami setback dengan nilai tertentu, kemudian ditutup berdasarkan waktu yang telah ditentukan.

### EA02 — Bollinger Bands

EA ini menggunakan Bollinger Bands untuk mendeteksi kondisi ketika harga bergerak terlalu jauh dari nilai rata-ratanya. Posisi dibuka dengan asumsi bahwa harga akan kembali menuju garis tengah Bollinger Bands.

### EA03 — MACD Crossover

EA ini menggunakan persilangan garis utama dan garis signal pada indikator MACD. Persilangan ke atas digunakan sebagai sinyal buy, sedangkan persilangan ke bawah digunakan sebagai sinyal sell.

### EA04 — Donchian Channel

EA ini menggunakan batas harga tertinggi dan terendah dalam periode tertentu. Posisi dibuka ketika harga menembus batas atas atau batas bawah Donchian Channel.

### EA05 — RSI Reversal

EA ini menggunakan indikator RSI untuk membaca kondisi overbought dan oversold. Kondisi tersebut digunakan untuk mendeteksi kemungkinan terjadinya pembalikan arah harga.

### EA06 — Moving Average Crossover

EA ini menggunakan persilangan dua Moving Average dengan periode berbeda. Persilangan Moving Average cepat dan lambat digunakan untuk menghasilkan sinyal buy atau sell.

### EA07 — Supertrend

EA ini menggunakan Average True Range dan multiplier untuk membentuk indikator Supertrend. Perubahan arah Supertrend digunakan sebagai sinyal pembukaan posisi.

### EA08 — Range Breakout

EA ini mencatat rentang harga selama periode waktu tertentu. Posisi dibuka ketika harga menembus batas atas atau batas bawah rentang sebelum waktu perdagangan berakhir.

### EA09 — Stochastic Moving Average

EA ini menggabungkan Stochastic Oscillator dengan Moving Average. Stochastic digunakan untuk membaca momentum dan kondisi overbought atau oversold, sedangkan Moving Average digunakan sebagai filter arah tren.

### EA10 — RSI Grid

EA ini menggunakan RSI untuk menentukan pembukaan posisi awal, kemudian menambahkan posisi baru berdasarkan jarak grid. EA menggunakan ukuran lot tetap tanpa martingale, jumlah posisi maksimum, target keuntungan basket, dan batas kerugian basket.

---

## Konfigurasi Backtest

Konfigurasi pengujian dibedakan antara EA01 Turnaround Tuesday dan EA02–EA10 karena EA01 menggunakan instrumen dan ketentuan volume yang berbeda.

### Konfigurasi EA01 Turnaround Tuesday

| Pengaturan                | Nilai                               |
| ------------------------- | ----------------------------------- |
| Expert Advisor            | EA01 Turnaround Tuesday             |
| Symbol                    | DE40                                |
| Tester timeframe          | M1                                  |
| Signal timeframe dalam EA | H1                                  |
| Periode pengujian         | 8 September 2023 – 8 September 2026 |
| Forward testing           | No                                  |
| Initial deposit           | USD 10,000                          |
| Fixed lot                 | 1.0                                 |
| Final modelling           | Every Tick Based on Real Ticks      |
| History quality           | 100%                                |
| Visual mode               | Disabled                            |

EA01 menggunakan lot 1.0 karena menyesuaikan batas minimum volume perdagangan pada symbol DE40. Walaupun pengujian dijalankan pada timeframe M1, pengambilan sinyal di dalam EA tetap menggunakan timeframe H1.

### Konfigurasi EA02–EA10

| Pengaturan             | Nilai                               |
| ---------------------- | ----------------------------------- |
| Symbol                 | EURUSD                              |
| Tester timeframe       | H1                                  |
| Signal timeframe       | H1                                  |
| Periode pengujian      | 8 September 2023 – 8 September 2026 |
| Forward testing        | No                                  |
| Delay                  | Zero Latency, Ideal Execution       |
| Initial deposit        | USD 10,000                          |
| Leverage               | 1:100                               |
| Fixed lot              | 0.01                                |
| Final modelling        | Every Tick Based on Real Ticks      |
| History quality        | 100%                                |
| Visual mode            | Disabled                            |
| Profit in pips         | Disabled                            |
| Optimization criterion | Balance Max                         |

Tahap optimasi dilakukan menggunakan Fast Genetic Based Algorithm atau Slow Complete Algorithm sesuai jumlah kombinasi parameter. Untuk mempercepat proses, optimasi dapat menggunakan 1 Minute OHLC. Kombinasi parameter terpilih kemudian diuji kembali menggunakan Every Tick Based on Real Ticks sebelum ditetapkan sebagai hasil akhir.

---

## Parameter Akhir

| EA                            | Parameter Utama                                                                                          |
| ----------------------------- | -------------------------------------------------------------------------------------------------------- |
| EA01 Turnaround Tuesday       | Open Hour 19, Close Hour 19, Setback Threshold 400                                                       |
| EA02 Bollinger Bands          | Period 45, Deviation 2.75, SL 1000, TP 1000                                                              |
| EA03 MACD Crossover           | Fast 8, Slow 35, Signal 15, SL 600, TP 900                                                               |
| EA04 Donchian Channel         | Period 20, SL 1200, TP 1800                                                                              |
| EA05 RSI Reversal             | RSI 25, Oversold 40, Overbought 60, SL 600, TP 900                                                       |
| EA06 Moving Average Crossover | Fast MA 20, Slow MA 60, EMA, SL 1200, TP 900                                                             |
| EA07 Supertrend               | ATR Period 5, Multiplier 4.0, SL 1500, TP 1500                                                           |
| EA08 Range Breakout           | Range Start 0, Range End 7, Trade End 20, SL 900, TP 1800                                                |
| EA09 Stochastic MA            | K 15, D 3, Slowing 3, Oversold 30, Overbought 85, MA 20, SL 1200, TP 1200                                |
| EA10 RSI Grid                 | RSI 14, Oversold 30, Overbought 75, Grid Distance 300, Max Positions 5, Basket Profit 15, Basket Loss 50 |

---

## Hasil Backtest Akhir

| EA                            | Net Profit | Profit Factor | Total Trades | Equity Drawdown | Sharpe Ratio |
| ----------------------------- | ---------: | ------------: | -----------: | --------------: | -----------: |
| EA01 Turnaround Tuesday       |   1,648.86 |          1.30 |           64 |          12.53% |         1.96 |
| EA02 Bollinger Bands          |      84.97 |          1.22 |          229 |           0.41% |         0.98 |
| EA03 MACD Crossover           |      36.75 |          1.02 |        1,293 |           1.04% |            — |
| EA04 Donchian Channel         |      15.95 |          1.02 |          434 |           1.50% |         0.07 |
| EA05 RSI Reversal             |     147.39 |          1.17 |          345 |           0.61% |         0.79 |
| EA06 Moving Average Crossover |      88.53 |          1.13 |          309 |           0.63% |         0.62 |
| EA07 Supertrend               |     101.92 |          1.12 |          408 |           1.11% |         0.49 |
| EA08 Range Breakout           |     112.67 |          1.13 |          747 |           0.92% |         1.06 |
| EA09 Stochastic MA            |     225.62 |          1.55 |          131 |           0.59% |         1.56 |
| EA10 RSI Grid                 |     520.84 |          1.50 |          382 |           1.62% |         1.04 |

---

## Analisis Hasil

Berdasarkan backtest akhir, seluruh EA memperoleh net profit positif. EA01 Turnaround Tuesday menghasilkan net profit tertinggi sebesar USD 1,648.86. Namun, EA tersebut juga memiliki equity drawdown paling tinggi, yaitu 12.53%.

EA10 RSI Grid menghasilkan net profit tertinggi kedua sebesar USD 520.84 dengan profit factor 1.50 dan equity drawdown 1.62%. Meskipun memperoleh hasil yang baik dalam backtest, strategi grid memiliki risiko ketika pasar bergerak kuat secara terus-menerus dalam satu arah.

EA09 Stochastic MA menunjukkan hasil yang cukup seimbang dengan net profit USD 225.62, profit factor 1.55, Sharpe ratio 1.56, dan equity drawdown 0.59%. Berdasarkan perbandingan profit factor, Sharpe ratio, dan drawdown, EA09 menjadi salah satu EA dengan performa paling stabil dalam pengujian ini.

EA03 MACD Crossover dan EA04 Donchian Channel masih menghasilkan keuntungan. Namun, profit factor kedua EA hanya sebesar 1.02 sehingga performanya tergolong marginal dan memerlukan pengujian lebih lanjut.

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
```

Keterangan:

* `reports/` berisi laporan lengkap hasil backtest dalam format HTML dan PDF.
* `screenshots/` berisi screenshot hasil backtest setelah optimasi.
* `src/` berisi source code Expert Advisor dalam format MQL5.
* `README.md` berisi penjelasan strategi, sumber video, parameter, dan hasil pengujian masing-masing EA.

---

## Cara Menjalankan EA

1. Unduh file `.mq5` dari folder `src/`.
2. Buka MetaTrader 5.
3. Pilih `File > Open Data Folder`.
4. Buka folder `MQL5/Experts/`.
5. Salin file `.mq5` ke dalam folder tersebut.
6. Buka file melalui MetaEditor.
7. Tekan `F7` untuk melakukan compile.
8. Pastikan proses compile menghasilkan 0 error.
9. Kembali ke MetaTrader 5.
10. Buka Strategy Tester menggunakan `Ctrl+R`.
11. Pilih Expert Advisor yang akan diuji.
12. Atur symbol, timeframe, periode, deposit, leverage, dan modelling.
13. Klik Start untuk menjalankan backtest.

---

## Tahapan Optimasi

Tahapan optimasi yang dilakukan dalam project ini meliputi:

1. Menentukan parameter utama yang berpengaruh terhadap strategi.
2. Menentukan nilai Start, Step, dan Stop untuk setiap parameter.
3. Menjalankan Fast Genetic Based Algorithm atau Slow Complete Algorithm.
4. Mengurutkan hasil optimasi berdasarkan nilai Result atau Balance Max.
5. Memilih kombinasi parameter dengan mempertimbangkan profit, profit factor, jumlah transaksi, expected payoff, dan drawdown.
6. Menguji kembali parameter terpilih menggunakan Every Tick Based on Real Ticks.
7. Membandingkan hasil optimasi dengan hasil real ticks.
8. Menyimpan laporan dan screenshot hasil backtest akhir.

Hasil optimasi menggunakan 1 Minute OHLC tidak langsung ditetapkan sebagai hasil final karena performanya dapat berubah ketika diuji menggunakan data tick yang lebih detail. Oleh karena itu, hasil final dalam repository ini berasal dari pengujian ulang menggunakan Every Tick Based on Real Ticks.

---

## Kesimpulan

Project ini berhasil mengembangkan, mengoptimasi, dan menguji 10 Expert Advisor dengan strategi yang berbeda. Hasil pengujian menunjukkan bahwa seluruh EA menghasilkan net profit positif, tetapi masing-masing memiliki karakteristik keuntungan dan risiko yang berbeda.

EA01 Turnaround Tuesday menghasilkan keuntungan paling tinggi, sedangkan EA10 RSI Grid menghasilkan keuntungan tertinggi kedua. EA09 Stochastic MA menunjukkan keseimbangan performa yang baik berdasarkan profit factor, Sharpe ratio, dan equity drawdown.

Hasil tersebut menunjukkan bahwa pemilihan Expert Advisor tidak cukup dilakukan berdasarkan net profit tertinggi. Profit factor, drawdown, Sharpe ratio, jumlah transaksi, dan karakteristik risiko strategi juga perlu dipertimbangkan.

---

## Referensi

* [René Balke – BM Trading](https://www.youtube.com/@ReneBalke)
* [MQL5 Documentation](https://www.mql5.com/en/docs)
* Video referensi untuk setiap strategi tersedia pada tabel Daftar 10 Expert Advisor.

---

## Disclaimer

Seluruh Expert Advisor dan hasil backtest dalam repository ini dibuat untuk tujuan pembelajaran dan tugas akademik. Hasil backtest berdasarkan data historis tidak menjamin performa atau keuntungan yang sama pada perdagangan nyata.

Penggunaan EA pada akun real memiliki risiko kerugian. Strategi grid, khususnya, dapat mengalami kerugian besar ketika pasar bergerak kuat dalam satu arah. Pengujian tambahan seperti forward test, out-of-sample test, dan pengujian pada akun demo diperlukan sebelum EA digunakan pada perdagangan nyata.
