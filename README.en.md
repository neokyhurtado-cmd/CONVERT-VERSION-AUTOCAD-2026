# DWG Version Switch — English

[Español](README.md) · [Official tool](https://trafficlab-panorama.com/dwg-versiones.html) · [Verified test summary](docs/QA_REAL_CAD.md) · [GitHub](https://github.com/neokyhurtado-cmd/CONVERT-VERSION-AUTOCAD-2026)

**Free, open-source DWG version detector and local AutoCAD file converter** by TraficLabPro / PANORAMA LAB.

- **Browser:** identifies a DWG format using only the first 6 local file bytes, without uploading the drawing.
- **Windows:** a PowerShell tool performs native SAVEAS using the user's own **legitimately installed AutoCAD Core Console**, with source SHA-256 checks, output header checks, native reopening and a JSON report.
- **Formats:** DWG 2018, 2013, 2010, 2007, 2004, 2000 and R14.
- **License:** MIT. Use and improve freely, including commercially, retaining the copyright/license notices. Autodesk software is not bundled or licensed here.

### Quick start

1. On Windows with a valid desktop AutoCAD installation, download or clone this project.
2. Run **INICIAR-CONVERSOR.cmd**, choose DWG files and a target version.
3. Review output drawings and the JSON report in **DWG_CONVERTIDOS** on your Desktop.
4. Inspect any critical drawings thoroughly before professional use.

Or run PowerShell:

~~~powershell
.\Convertir-DWG.ps1 -Headless -InputPaths "C:\Drawings\original.dwg" -Target 2013 -OutputDir "C:\Drawings\Converted"
~~~

### Real-world validation (one private engineering DWG)

7/7 native conversions and reopenings passed. Eight independent CAD inventories returned 3,043 entities each; types, layer counts, layout counts, units and extents remained the same. Four anonymous block identifiers were renumbered, and some APPID records changed. Ten browser checks with the actual private drawings passed.

**Important:** One drawing is not a representative compatibility benchmark. Matching counts and successful reopening do not prove 1:1 semantic or geometric equivalence. No client drawing or personally identifying path is published. See [the sanitized evidence](docs/QA_REAL_CAD.md).

**Autodesk DWG TrueView is a free alternative** that supports conversions without your own full AutoCAD desktop license. See the [official Autodesk website](https://www.autodesk.com/products/dwg-trueview/overview).

### Open source and future services

The Community edition is genuinely MIT licensed and is not crippleware. You're welcome to fork, modify, redistribute, contribute, or use the source commercially. Separate professional engineering support, managed integrations, and deep drawing audits may be developed in the future; those are **not currently sold or implemented**.

Please read [CONTRIBUTING](CONTRIBUTING.md), [SECURITY](SECURITY.md), [NOTICE](NOTICE.md), and [LICENSE](LICENSE). No Autodesk trademarks, proprietary binaries, client DWGs, or drawing rights are granted by the MIT license.
