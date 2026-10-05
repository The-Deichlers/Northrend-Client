# Running Northrend

Official platforms are Windows 11 25H2+, macOS Tahoe 26+ on Apple Silicon
(`arm64`), and Ubuntu 26.04 LTS+, including newer releases. See
[Supported Platform Baseline](BUILDING.md#supported-platform-baseline) for the
support policy and the distinction between CI and runtime validation.

Use a complete, legitimately obtained World of Warcraft **3.3.5a build 12340**
data set. Windows-edition MPQ archives are useful on the native macOS client;
a Windows executable or Wine is not needed to read those archives. Never add
game data to this repository. These instructions do not supply game assets.

Point `-datadir` at the **parent of `Data`**, not at `Data` itself:

```text
/path/to/WoW-3.3.5a/
  Data/
    common.MPQ
    common-2.MPQ
    expansion.MPQ
    lichking.MPQ
    patch.MPQ
    patch-2.MPQ
    patch-3.MPQ
    enUS/                     (or your installed locale)
      locale-enUS.MPQ
      speech-enUS.MPQ
      expansion-locale-enUS.MPQ
      lichking-locale-enUS.MPQ
      ... remaining original locale/patch archives ...
```

This illustrates the loader's base/locale/patch search, not a replacement for a
complete installation. MPQ capitalization matters on case-sensitive filesystems.
The loader also supports extracted files such as `DBFilesClient/AreaTable.dbc`
and `Interface/GlueXML/GlueXML.toc` under the selected root. An incomplete
extraction is not sufficient. Version authenticity is supplied by the developer;
Northrend does not validate the entire asset set's build number.

```sh
/path/to/Northrend-Client/build/debug/install/bin/Northrend -datadir '/path/to/WoW-3.3.5a'
/path/to/Northrend-Client/build/release/install/bin/Northrend -datadir '/path with spaces/WoW-3.3.5a'
```

Native forward slashes and inherited backslashes are accepted for the data path.
Quote paths containing spaces. Without `-datadir`, the client selects the
executable's directory, regardless of the shell's working directory. To exercise
that layout, install the client beside an existing legitimate `Data` directory
outside the source checkout. Keep the installed `MainMenu.nib` beside Northrend
on macOS. Do not copy proprietary files into the checkout for testing.

The client changes its working directory to the selected data root, so config
and logs belong there. Give the application read access to assets and write
access for logs/configuration. `Logs/Northrend.log` records configuration,
platform, architecture, selected root, renderer and initialization progress.
`Logs/gx.log`, `Logs/GlueXML.log`, `Logs/FrameXML.log` and (when enabled)
`Logs/Sound.log` provide subsystem diagnostics. Early argument/path failures go
to terminal stderr and return a nonzero exit status.

Common failures:

- `-datadir` without a directory or unknown arguments: command-line error.
- Nonexistent/inaccessible root: select the correct parent of `Data`.
- Missing `AreaTable.dbc` or `GlueXML.toc`: incomplete extraction, archives,
  locale data, or unreadable MPQs; use a complete original data set.
- Graphics capability failure: GLL queries the current OpenGL context and
  requires at least two texture units, fourteen vertex attributes, ARB vertex/
  fragment programs, and S3TC. The diagnostic identifies a failed query or unmet
  requirement; startup exits 1. Effective limits also reflect implemented GLL
  support: one interleaved vertex stream and 2D textures, with unsupported cube/
  rectangle upload targets disabled.
- `cannot read game file`: inspect the filename and archive error in stderr.
  Archive operations are synchronized across synchronous XML/script loading
  and asynchronous texture workers; use complete, readable original MPQs.
- Further initialization failures: inspect startup, graphics and GlueXML logs.
- Movies on macOS: no native decoder is bundled by the default build.
- Audio: optional FMOD is disabled in the default build.

Actual launch and asset-loading results are recorded in the
[milestone report](milestones/MILESTONE-0-REPORT.md). A successful compile or
missing-data diagnostic is not proof of successful game-data startup.

On the validated Apple M2, both the clean 12340 and supplied HD data reach the
login screen. Native window zoom/resize preserves rendering and mouse hit
positions; character entry, backspace, the close button, and Command-Q work.
Do not press Login during startup-only validation. Audio and movie playback
remain outside Milestone 0; fullscreen graphics-mode switching is unvalidated.
