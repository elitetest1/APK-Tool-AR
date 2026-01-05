# APK-Tool AR (AutoRun) 🚀

**APK-Tool AR** is an interactive Bash script designed to streamline the workflow of Android modders and developers. It automates the repetitive tasks of decompiling, compiling, signing, and aligning APK files, managing the directory structure automatically.

Created by **Elite** (Elite Galaxy).

## ✨ Features

- 📂 **Auto-Management:** Automatically creates `input`, `work`, `sign`, and `output` directories.
- 🔄 **Interactive Menu:** Simple numbered interface to handle files without typing long paths.
- 🛠 **Smart Detection:** Auto-detects dependencies and warns if keys are missing.
- 🔐 **Signing & Aligning:** Automates `apksigner` and `zipalign` in a single step.
- 🧹 **Clean Workflow:** Keeps your workspace organized by separating source, work files, and final builds.

## 📋 Prerequisites

You need to have the following tools installed and accessible in your system's `$PATH`:

- `apktool` (for decompiling/building)
- `apksigner` (part of Android SDK Build-Tools)
- `zipalign` (part of Android SDK Build-Tools)
- `java` (required by apktool)

## 🚀 Installation & Usage

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/TU_USUARIO/APK-Tool-AR.git](https://github.com/TU_USUARIO/APK-Tool-AR.git)
   cd APK-Tool-AR
