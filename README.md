# vtray

A light cross-platform **system tray module for [V](https://vlang.io)**: show an
icon and a menu in the system tray, with no main window — on **Linux** (X11 and
**Wayland**, via libappindicator/StatusNotifierItem) and **Windows** (native
Win32 `Shell_NotifyIcon`). A **macOS** (AppKit) path exists, inherited from
upstream, but it is untested in this fork — upstream itself reported compile
failures on recent macOS releases.

This is a **fork of [spytheman/vtray](https://github.com/spytheman/vtray)**,
which wraps the tiny C library [zserge/tray](https://github.com/zserge/tray)
(vendored and patched here, MIT). The upstream module had not kept up with
modern V and did not work correctly on Windows; this fork fixes that and adds a
few small features.

## Changes vs upstream

| # | Change | Why |
|---|--------|-----|
| 1 | Flattened layout (`src/` removed) | V >= 0.5 refuses the virtual `src/` module root |
| 2 | Linux build flags: gtk3 + `ayatana-appindicator3-0.1` (cflags **and** libs) | Upstream declared gtk2-era cflags only → link errors; the legacy include path is gone on recent distros |
| 3 | UTF-8 → UTF-16 conversion on Windows (`_tray_wide()`) | V's generated C defines `UNICODE` → *W* (UTF-16) APIs are selected; upstream fed raw UTF-8 into them → garbled CJK-looking menus |
| 4 | Tooltip support: `Tray.set_tooltip()` | Upstream had none (`NIF_TIP` absent, no field in `struct tray`) |
| 5 | `#flag windows -mwindows` | GUI subsystem: no stray console window next to the tray app |
| 6 | Embedded-icon mode: `set_icon('')` loads ICON resource id 1 | File icons break from a network path; a resource lives in the binary. Shared icons never `DestroyIcon`ed |
| 7 | Windows icons must be `.ico` — documented | `ExtractIconEx` never read PNGs; upstream example shipped a `.png` → empty icon slot |

Internal: the C tray window class is now `L"TRAY"` (wide), icon paths are
converted with `MultiByteToWideChar(CP_UTF8, ...)` at the C boundary, and the
menu text is converted per item when the menu is (re)built.

## Requirements

### Linux
- `libayatana-appindicator` and GTK 3 (the module builds against the
  `ayatana-appindicator3-0.1` pkg-config module):
  - Arch: `sudo pacman -S libayatana-appindicator gtk3`
  - Debian/Ubuntu: `sudo apt install libayatana-appindicator3-dev libgtk-3-dev \
libgdk-pixbuf-2.0-dev`
- A desktop environment implementing the StatusNotifierItem protocol (Plasma,
  GNOME with an AppIndicator extension, XFCE, ...). SNI is the only tray
  protocol that works under **Wayland**.

### Windows
Native WinAPI — no external dependency at build or run time. Cross-compile from
Linux with either toolchain:
- `mingw-w64-gcc` (Arch: `sudo pacman -S mingw-w64-gcc`), or
- `llvm-mingw` (clang ≥ 16 treats `incompatible-pointer-types` as an *error*,
  gcc as a warning — pass `-cflags '-Wno-error=incompatible-pointer-types'`).

## Install

Via vpm:

```sh
v install evemarco/vtray
```

then `import evemarco.vtray` in your code. Or vendor the module (git submodule
or plain copy of this folder) and just `import vtray` — the directory name
resolves it locally.

## Usage

```v
import vtray

fn main() {
	mut t := vtray.new()
	$if windows {
		t.set_icon('app.ico') // .ico file...
		// ...or an ICON resource embedded in the exe (see below): t.set_icon('')
	} $else {
		t.set_icon('icon.png') // PNG path, or an icon-theme name
	}
	t.set_tooltip('my app')
	t.set_menu([
		vtray.new_menu_item(text: 'checked by default', checked: 1),
		vtray.new_menu_item(text: 'disabled', disabled: 1),
		vtray.new_menu_item(text: '-'),
		vtray.new_menu_item(
			text: 'quit'
			cb:   fn [mut t] (_ &vtray.MenuItem) {
				t.exit()
			}
		),
	])
	t.init()
	for t.loop(1) == 0 {
	} // blocking loop; returns -1 after t.exit()
}
```

See `examples/simple_tray.v` for a complete runnable demo.

### Embedding the Windows icon in the executable (recommended)

File-based icons break when the exe is launched from a network path. Compile
the icon as a Win32 resource instead, link it, and use `t.set_icon('')`:

```sh
# icon.rc contains:  1 ICON "app.ico"
x86_64-w64-mingw32-windres icon.rc -O coff -o icon.res.o
```

```v
// in your main.v, before building:
#flag windows 'icon.res.o'
```

```sh
v -os windows -o app.exe main.v
```

The icon then travels inside the binary and also shows on the exe file in
Explorer.

### Threading model

All `vtray` calls must happen on the main thread; callbacks fire on that same
thread. For real applications: do the work in `spawn`ed threads, publish
results through a `chan`, and drain it in a non-blocking loop —
`ch.try_pop(mut s) == .success`, then `t.loop(0)`, then a short `time.sleep`.

## Testing

```sh
v test .            # headless unit tests (no tray needed)
v should-compile-all examples/
```

CI builds Linux natively and cross-compiles Windows on every push.

## License

MIT. Contains vendored code from [zserge/tray](https://github.com/zserge/tray)
(MIT) and changes first developed in this fork — see the table above.