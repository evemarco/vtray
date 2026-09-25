// A minimal system tray application.
// Build:  v should-compile-all examples/   (CI check)
// Run:    v run examples/simple_tray.v
import time
import vtray

fn main() {
	mut t := vtray.new()
	$if windows {
		// .ico file — or use an icon resource embedded in the exe: t.set_icon('')
		t.set_icon('${@VMODROOT}/examples/smiley.ico')
	} $else {
		// PNG path or an icon-theme name (e.g. 'indicator-messages')
		t.set_icon('${@VMODROOT}/examples/smiley.png')
	}
	t.set_tooltip('vtray demo')
	t.set_menu([
		vtray.new_menu_item(text: 'checked by default', checked: 1),
		vtray.new_menu_item(
			text: 'click me (toggles)'
			cb:   fn [mut t] (omi &vtray.MenuItem) {
				mut mi := unsafe { omi }
				mi.text = time.now().str()
				mi.checked = if mi.checked == 0 { 1 } else { 0 }
				t.update() // rebuild the menu so the change is visible
			}
		),
		vtray.new_menu_item(text: 'disabled item', disabled: 1),
		vtray.new_menu_item(text: '-', disabled: 1),
		vtray.new_menu_item(
			text: 'quit'
			cb:   fn [mut t] (_ &vtray.MenuItem) {
				t.exit() // makes t.loop() return -1, ending the app
			}
		),
	])
	t.init()
	for t.loop(1) == 0 {
	}
}
