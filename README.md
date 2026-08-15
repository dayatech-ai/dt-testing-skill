# DT Testing Skill

Skill testing untuk Claude Code, Antigravity, OpenCode, dan Codex. Memilih test sesuai perubahan, menyediakan cara menjalankan test, dan mewajibkan agent menjalankan seluruh suite setelah menambah atau mengubah test.

## Install atau update: satu perintah

Setelah release pertama tersedia. Gunakan perintah yang sama untuk instalasi pertama dan update berikutnya.

**macOS/Linux:**

```sh
curl -fsSL https://github.com/dayatech-ai/dt-testing-skill/releases/latest/download/install.sh | bash
```

**Windows PowerShell:**

```powershell
irm https://github.com/dayatech-ai/dt-testing-skill/releases/latest/download/install.ps1 | iex
```

Installer release sudah memuat nama repository yang diisi otomatis saat build. Tidak perlu parameter tambahan, Python, atau clone repository. Gunakan URL aset release di atas; file source pada branch `main` belum berisi nama repository.

Mode tanpa `--agent` / `-Agent` mendeteksi agent dari perintah CLI atau direktori konfigurasi yang ada. Semua agent yang terdeteksi dipilih. Jika tidak ada yang terdeteksi, installer meminta pilihan agent; untuk terminal noninteraktif berikan nama agent secara eksplisit. Deteksi berdasarkan direktori merupakan petunjuk, bukan jaminan aplikasi masih terpasang.

Default instalasi adalah global. Mode otomatis memasang skill yang belum ada, memperbarui versi lama dengan backup, dan melewati instalasi dari repository serta versi yang sama. Perubahan lokal tetap dipertahankan ketika versi sama dilewati. Metadata versi tetap diperiksa setelah paket terbaru diunduh dan diverifikasi. Gunakan `--agent NAME --update` / `-Agent NAME -Update` untuk memaksa pemasangan ulang versi sama.

### Memilih agent secara eksplisit

Gunakan perintah berikut untuk **install pertama maupun update**. Ganti `dayatech-ai/dt-testing-skill` dengan repository tujuan dan `codex` dengan agent pilihan.

**macOS/Linux:**

```sh
curl -fsSL https://github.com/dayatech-ai/dt-testing-skill/releases/latest/download/install.sh | bash -s -- --agent codex --update
```

**Windows PowerShell:**

```powershell
& ([scriptblock]::Create((irm https://github.com/dayatech-ai/dt-testing-skill/releases/latest/download/install.ps1))) -Agent codex -Update
```

| Nilai agent | Tujuan |
| --- | --- |
| `claude-code` | Claude Code |
| `antigravity` | Antigravity |
| `opencode` | OpenCode |
| `codex` | Codex |
| `all` | Keempat agent, tanpa bergantung pada deteksi |

Default instalasi **global**. Flag `--update` / `-Update` memasang skill jika belum ada, atau mengganti instalasi yang ada dengan backup. Pada mode eksplisit ini, versi yang sama juga dipasang ulang. Jalankan perintah yang sama kapan pun ingin memperbarui skill ke release terbaru.

Untuk instalasi per proyek, tambahkan `--project /path/to/project` pada perintah Bash atau `-Project "C:\work\project"` pada perintah PowerShell. Direktori proyek harus sudah ada.

## Menyiapkan repository dan release otomatis

1. Push seluruh isi paket ini ke repository GitHub milikmu dengan branch `main`. Workflow memakai `${{ github.repository }}` sehingga tidak perlu mengedit URL repository di file workflow.
2. Aktifkan GitHub Actions dan izinkan workflow memakai `contents: write` sesuai kebijakan repository/organisasi. Workflow menggunakan `GITHUB_TOKEN` bawaan; tidak membutuhkan PAT atau secret tambahan.
3. Gunakan Conventional Commits. Jika squash merge, judul commit hasil squash harus mengikuti format tersebut.
4. Setelah commit masuk ke `main`, workflow menjalankan seluruh test dan pemeriksaan ukuran paket. Jika lulus dan terdapat perubahan yang layak dirilis, workflow menentukan versi, membuat tag serta GitHub Release, lalu mengunggah `install.sh`, `install.ps1`, `dt-testing.zip`, dan `SHA256SUMS`.

| Commit sejak tag versi terakhir | Perubahan versi |
| --- | --- |
| `fix: ...`, `fix(scope): ...`, `perf: ...` | Patch, contoh `1.2.3` → `1.2.4` |
| `feat: ...`, `feat(scope): ...` | Minor, contoh `1.2.3` → `1.3.0` |
| `feat!: ...`, `fix(scope)!: ...`, atau footer `BREAKING CHANGE: ...` | Major, contoh `1.2.3` → `2.0.0` |
| Hanya `docs:`, `test:`, `chore:`, atau commit tanpa format yang cocok | Tidak membuat release |

Bump terbesar dari kumpulan commit dipakai. Perhitungan dimulai dari `0.0.0`: commit pertama `feat: initial skill` menghasilkan `v0.1.0`; breaking change tetap menaikkan major meskipun masih versi `0.x`. Riwayat tag `vMAJOR.MINOR.PATCH` yang berada dalam ancestry branch digunakan sebagai acuan. `VERSION` dihasilkan dalam paket release; tidak perlu commit bump versi manual. Catatan release dibuat oleh GitHub, bukan file changelog yang di-commit kembali.

Workflow juga menguji setiap PR. Release menunggu job Linux/macOS dan Windows (PowerShell 5.1 serta 7) berhasil. Publishing dilakukan langsung dari workflow push `main`, tanpa release PR tambahan. Release dibuat draft terlebih dahulu dan baru dipublikasikan setelah semua aset berhasil diunggah. Jika upload gagal, ulangi run yang sama untuk menyelesaikan draft; release yang sudah terbit tidak ditimpa saat rerun. Jangan lanjutkan release baru sebelum draft gagal diselesaikan. Run lama yang sudah tertinggal dari `main` melewati publishing; run commit terbaru mencakup perubahan sebelumnya.

Untuk menjalankan manual, gunakan **Actions → Test and release → Run workflow** pada branch `main`. Tetap tidak ada release baru jika tidak ada commit yang memicu bump. Jika branch utama berbeda, sesuaikan semua referensi `main` di `.github/workflows/release.yml`.

Panduan mekanisme GitHub: [Releases API](https://docs.github.com/en/rest/releases/releases) dan [GITHUB_TOKEN permissions](https://docs.github.com/en/actions/security-for-github-actions/security-guides/automatic-token-authentication). Publishing GitHub belum dapat diuji sebelum paket dipush ke repository tujuan.

## Instalasi lokal dari source

Dari root paket:

```sh
bash scripts/install.sh --agent all --project /path/to/project
```

Untuk Windows dari root paket:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1 -Agent all -Project "C:\work\project"
```

Tambahkan `--update` pada Bash atau `-Update` pada PowerShell untuk mengganti instalasi lama dengan backup. Tanpa `--repo`, installer memakai folder `dt-testing/` lokal; source ini tidak memiliki versi release sampai dikemas.

| Agent | Lokasi dalam proyek | Lokasi global |
| --- | --- | --- |
| Claude Code | `.claude/skills/dt-testing/` | `~/.claude/skills/dt-testing/` |
| Antigravity | `.agents/skills/dt-testing/` | `~/.gemini/config/skills/dt-testing/` |
| OpenCode | `.opencode/skills/dt-testing/` | `~/.config/opencode/skills/dt-testing/` |
| Codex | `.agents/skills/dt-testing/` | `~/.agents/skills/dt-testing/` |

Antigravity dan Codex berbagi salinan pada instalasi proyek. OpenCode juga dapat menemukan skill pada direktori kompatibel `.agents` dan `.claude`; installer menyalin konten yang sama ke lokasi native masing-masing. Jika memakai lokasi global kustom, salin seluruh folder skill ke direktori yang dikonfigurasi. Untuk versi lama Antigravity, `.agent/skills` merupakan lokasi yang kompatibel.

Lokasi mengacu pada dokumentasi resmi: [Claude Code](https://code.claude.com/docs/en/skills), [Antigravity](https://antigravity.google/docs/skills), [OpenCode](https://opencode.ai/docs/skills/), dan [Codex](https://developers.openai.com/codex/skills).

## Pemakaian

Buka proyek tujuan dan mulai sesi agent baru. Di Claude Code gunakan `/dt-testing`; di Codex gunakan `$dt-testing`. Di Antigravity dan OpenCode, minta agent menggunakan skill bernama `dt-testing`:

```text
Gunakan skill dt-testing untuk menambahkan test fitur ini. Siapkan perintah
serta panduan menjalankan test jika belum ada, lalu jalankan seluruh test proyek.
Perbaiki kegagalan dan laporkan hasil akhirnya.
```

Skill mengarahkan agent saat dipakai. Workflow paket ini menguji dan merilis skill/installer; instalasi skill tidak memasang pipeline CI atau hook PR pada proyek pengguna.

## Pengujian dan build lokal

Dari root paket, jalankan seluruh suite:

```sh
python3 -m unittest discover -s tests -v
```

Python 3.8+ hanya diperlukan oleh maintainer untuk pengujian/build internal. Test memakai Python standard library, Bash, utilitas installer di atas, dan Git untuk pengujian riwayat commit. CI menjalankan suite Bash pada Linux/macOS, serta suite release dan installer PowerShell pada Windows. Tidak memerlukan jaringan, layanan eksternal, environment variable, atau kredensial. Direktori sementara dibersihkan otomatis. Test meliputi instalasi empat agent, backup/update, pemulihan ketika gagal, checksum, keamanan path arsip, pemilihan versi, dan perhitungan versi dari Git. Test menjalankan installer Bash asli, dengan perintah curl pengganti untuk mensimulasikan download GitHub; aplikasi agent tidak dijalankan langsung. Test Windows disiapkan untuk runner Windows dan belum dijalankan di lingkungan macOS ini; dukungan native Windows belum terverifikasi sampai CI tersebut lulus. WSL/Git Bash juga belum diuji langsung.

Buat aset percobaan tanpa mempublikasikan:

```sh
python3 scripts/release.py --build v0.1.0
```

Hasil berada di `dist/` yang diabaikan Git. Di repository Git, `python3 scripts/release.py` menampilkan versi release berikutnya tanpa membuat tag atau publikasi.

Pengujian khusus Windows untuk maintainer, setelah build fixture:

```powershell
python scripts/release.py --build v0.0.0
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\test_install.ps1
pwsh -NoProfile -File .\tests\test_install.ps1
```

Suite Windows memakai fixture release lokal dan pengganti fungsi download, sehingga tidak menghubungi GitHub atau memasang skill ke profil pengguna asli.
